BeforeAll {
  Get-Module RandomItems | Remove-Module -Force
  Import-Module -Force (Join-Path $PSScriptRoot '../RandomItems.psd1')

  . "$PSScriptRoot/Helpers.ps1"
}

Describe 'Get-Binding' {
  It 'Captures global bindings' {
    $binding = Get-Binding -Scope global
    Get-Variable -Scope global | %{
      if ($_.Value -eq $_.Value) {
        if ($_.Value.Count -eq 1) {
          $binding[$_.Name] | Should -Be $_.Value -Because "$($_.Name) = $($_.Value.GetType())($($_.Value)), binding[$($_.Name)]=$($binding[$_.Name].GetType())($($binding[$_.Name]))"
        }
      }
    }
  }

  It 'Captures local bindings' {
    $one = 1
    $two = 2
    $binding = Get-Variable -Scope Local -Include 'one','two' | Get-Binding
    $binding['one'] | Should -Be $one
    $binding['two'] | Should -Be $two
  }
}
