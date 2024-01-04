BeforeAll {
  Get-Module RandomItems | Remove-Module -Force
  Import-Module -Force (Join-Path $PSScriptRoot '../RandomItems.psd1')
}

Describe 'New-RandomItem' {

  It 'Creates a random Item' {
    New-RandomItem -Path 'TestDrive:/random-0'
    Get-ChildItem 'TestDrive:/random-0' | Should -HaveCount 1
  }

  It 'Creates multiple items' {
    New-Item -ItemType Directory -Path 'TestDrive:/multiple-out'
    New-RandomItem -Path 'TestDrive:/multiple-out/random-0','TestDrive:/multiple-out/random-1','TestDrive:/multiple-out/random-2'
    Get-ChildItem 'TestDrive:/multiple-out' | Should -HaveCount 3
  }

  It 'Interprets a Path with mktemp-style format' {
    New-Item -ItemType Directory -Path 'TestDrive:/mktemp-0'
    New-RandomItem -Path 'TestDrive:/mktemp-0/random-XXXX'
    $item = Get-ChildItem 'TestDrive:/mktemp-0'
    $item.FullName | Should -BeLike (Join-Path '*' 'mktemp-0' 'random-????')
  }

  It 'Interprets a LiteralPath' {
    New-Item -ItemType Directory -Path 'TestDrive:/literal-0'
    New-RandomItem -LiteralPath 'TestDrive:/literal-0/random-XXXX'
    $item = Get-ChildItem 'TestDrive:/literal-0'
    $item.FullName | Should -BeLike (Join-Path '*' 'literal-0' 'random-XXXX')
  }

  It 'Creates leading path components with -Force' {
    New-RandomItem -Force -LiteralPath 'TestDrive:/leading-0/random'
    Test-Path 'TestDrive:/leading-0/random' | Should -BeTrue
  }

  It 'Creates an item with content' {
    New-RandomItem -Force -LiteralPath 'TestDrive:/content-0/random' -Value 'test-value'
    Get-Content 'TestDrive:/content-0/random' | Should -Be 'test-value'
  }

  # There's no way to suppress the -WhatIf output
  It 'Honors -WhatIf' {
    $out = New-RandomItem -Path 'TestDrive:/random-whatif' -WhatIf
    $item = Get-Item 'TestDrive:/random-whatif' -ErrorAction SilentlyContinue -ErrorVariable err
    Test-Path 'TestDrive:/random-whatif' | Should -BeFalse
    $out | Should -BeNull
    $item | Should -BeNull
    $err | Should -BeLike '*does not exist*'
  }

  It 'Creates an item with a templated path (no dynamic content)' {
    New-Item -ItemType Directory -Path 'TestDrive:/out-0'
    New-RandomItem -PathTemplate 'TestDrive:/out-0/fixed-0'
    Test-Path 'TestDrive:/out-0/fixed-0' | Should -BeTrue
  }

  It 'Creates an item with a templated path' {
    New-Item -ItemType Directory -Path 'TestDrive:/out-1'
    $filename = 'filename-value'
    New-RandomItem -Binding (Get-Variable -Scope Local | Get-Binding) -PathTemplate 'TestDrive:/out-1/<%= $filename %>'
    Test-Path 'TestDrive:/out-1/filename-value' | Should -BeTrue
  }

  It 'Creates multiple items when template expansion is multi-line' {
    New-Item -ItemType Directory -Path 'TestDrive:/out-2'
    New-RandomItem -PathTemplate '<% 0..3 | Each { %>TestDrive:/out-2/file-<%= $_ %><% } -join "`n" %>'
    0..3 | %{
      Test-Path "TestDrive:/out-2/file-$_" | Should -BeTrue -Because "TestDrive:/out-2/file-$_ exists"
    }
  }

  Context 'With a container -Value' {

    BeforeAll {
      function New-TestTree {
        param(
          [string]$Root,
          [hashtable]$Contents
        )

        New-Item -ItemType 'Directory' -Path $Root

        $Contents.GetEnumerator() | %{
          if ($_.Value -is [hashtable]) {
            New-TestTree -Root (Join-Path $Root $_.Name) -Contents $_.Value
          } else {
            New-Item -Path (Join-Path $Root $_.Name) -Value $_.Value
          }
        }
      }

      function Get-TestTree {
        param(
          [string]$Root
        )

        $contents = @{}

        $item = Get-Item -Path $Root
        foreach ($fileInfo in $item.GetFiles()) {
          $contents[$fileInfo.Name] = Get-Content -Raw $fileInfo.fullname
        }
        foreach ($dirInfo in $item.GetDirectories()) {
          $contents[$dirInfo.Name] = Get-TestTree -Root $dirInfo.fullname
        }
        $contents
      }

      function HashTableDiff {
        param(
          [hashtable]$Expected,
          [hashtable]$Actual,
          [string[]]$KeyPath = @()
        )

        $diffs = @()

        foreach ($item in $Expected.GetEnumerator()) {
          $p = ($KeyPath + @($item.Name)) -join '/'
          if ($Actual.ContainsKey($item.Name)) {
            if ($item.Value -is [hashtable]) {
              if ($Actual[$item.Name] -is [hashtable]) {
                $diffs += HashTableDiff $item.Value $Actual[$item.Name]
              } else {
                $diffs += "${p}: expected hashtable, got $($Actual[$item.Name].GetType())($Actual[$item.Name])"
              }
            } else {
              if ($Actual[$item.name] -is [hashtable]) {
                $diffs += "${p}: expected value '$($item.Value)', got $($Actual[$item.Name] | ConvertTo-Json -Compress)"
              } else {
                if ($item.Value -ne $Actual[$item.Name]) {
                  $diffs += "${p}: expected value '$($item.Value)', got '$($Actual[$item.Name])'"
                }
              }
            }
          } else {
            $diffs += "${p}: expected value " + `
              "'$($item.Value -is [hashtable] ? ($item.Value | ConvertTo-Json -Compress) : $item.Value)', " + `
              "key is missing from actual" 
          }
        }

        $extras = $Actual.Keys | ?{ -not $Expected.ContainsKey($_) }
        $diffs += $extras | %{ $p = ($KeyPath + @($_)) -join '/'; "${p}: extra key in actual" }

        return $diffs
      }
    }

    BeforeEach {
      Remove-Item -Recurse -Force 'TestDrive:/out' -ErrorAction SilentlyContinue
    }

    It 'Creates a directory tree with a path' -ForEach @(
      @{
        valuedir = 'vf-0'
        valuecontents = @{
          'data-0' = 'value-0'
          'data-1' = 'value-1'
          'dir-empty' = @{}
          'dir-logs' = @{
            'logs-0' = 'entry-0'
            'logs-1' = 'entry-1'
          }
        }
      }
    ) {
      New-TestTree -Root "TestDrive:/$valuedir" -Contents $valuecontents

      New-RandomItem -Path 'TestDrive:/out' -ValueFile "TestDrive:/$valuedir"
      Test-Path 'TestDrive:/out' | Should -BeTrue

      $actual = Get-TestTree 'TestDrive:/out'

      HashTableDiff $valuecontents $actual | Should -Be @()

    }

    It 'Creates a directory tree with templates' -ForEach @(
      @{
        valuedir = 'vtf-0'
        valuecontents = @{
          'data-0' = '<%= "value-0" %>'
          'data-1' = '<%= "value-1" %>'
          'dir-empty' = @{}
          'dir-logs' = @{
            'logs-0' = '<%= "entry-0" %>'
            'logs-1' = '<%= "entry-1" %>'
          }
        }
        expected = @{
          'data-0' = 'value-0'
          'data-1' = 'value-1'
          'dir-empty' = @{}
          'dir-logs' = @{
            'logs-0' = 'entry-0'
            'logs-1' = 'entry-1'
          }
        }
      }
      @{
        valuedir = 'vtf-1'
        valuecontents = @{
          '<% 0..1 | Each { %>data-<%= $_ %><% } -join "`n" %>' = 'value-<%= $filename[-1] %>'
          'dir-empty' = @{}
          '<%= "dir-logs" %>' = @{
            '<% 0..1 | Each {%>logs-<%= $_ %><% } -join "`n" %>' = 'entry-<%= $filename[-1] %>'
          }
        }
        expected = @{
          'data-0' = 'value-0'
          'data-1' = 'value-1'
          'dir-empty' = @{}
          'dir-logs' = @{
            'logs-0' = 'entry-0'
            'logs-1' = 'entry-1'
          }
        }
      }
    ) {
      New-TestTree -Root "TestDrive:/$valuedir" -Contents $valuecontents

      New-RandomItem -Path 'TestDrive:/out' -ValueTemplateFile "TestDrive:/$valuedir"
      Test-Path 'TestDrive:/out' | Should -BeTrue

      $actual = Get-TestTree 'TestDrive:/out'
      HashTableDiff $expected $actual | Should -Be @()
    }

  }

}
