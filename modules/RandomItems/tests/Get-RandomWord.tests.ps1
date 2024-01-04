Get-Module RandomItems | Remove-Module -Force
Import-Module -Force (Join-Path $PSScriptRoot '../RandomItems.psd1')

BeforeAll {
  Get-Module RandomItems | Remove-Module -Force
  $testmod = Import-Module -Force (Join-Path $PSScriptRoot '../RandomItems.psd1') -Passthru

  . "$PSScriptRoot/Helpers.ps1"
}

Describe 'Get-RandomWord' {

  It 'Returns a Word from a specified list' {
    $result = Get-RandomWord -Dictionary 'one','two','three'
    $result | Should -BeIn @('one','two','three')
  }

  It 'Returns a Word from its internal dictionary' {
    Get-RandomWord | Should -BeLike '*'
  }

}

Describe 'ReadCharacter' {

  Context 'Internally' {
    InModuleScope RandomItems {
      # InModuleScope secures its scope or whatever before discovery
      # or before running, the upshot is that it uses the currently-
      # loaded module and not the one loaded in BeforeAll, or it fails
      # if no module is loaded beforehand.

      It "Returns <character> at position <position>" -ForEach @(
        @{ string = "one"; position = 0; character = "o"; after = 0 }
        @{ string = "one"; position = 1; character = "n"; after = 1 }
        @{ string = "one"; position = 2; character = "e"; after = 2 }
        @{ string = "öñé"; position = 0; character = "ö"; after = 0 }
        @{ string = "öñé"; position = 1; character = "ö"; after = 0 }
        @{ string = "öñé"; position = 2; character = "ñ"; after = 2 }
        @{ string = "öñé"; position = 3; character = "ñ"; after = 2 }
        @{ string = "öñé"; position = 4; character = "é"; after = 4 }
        @{ string = "öñé"; position = 5; character = "é"; after = 4 }
      ) {
        $fh = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($string))
        $fh.Seek($position, 0)
        $c = ReadCharacter -Handle $fh
        $got = $c.Character
        $want = ([System.Text.Encoding]::UTF8.GetChars([System.Text.Encoding]::UTF8.GetBytes($character)))[0]
        $got | Should -Be $want
        $fh.Position | Should -Be $after
      }
    }
  }
}

Describe 'Get-WordAtOffset' {

  Context 'Internally' {
    InModuleScope RandomItems {

      It "Returns <word> at offset <offset>" -ForEach @(
        @{ offset = 0; word = 'premier' }
        @{ offset = 1; word = 'premier' }
        @{ offset = 6; word = 'premier' }
        @{ offset = 7; word = 'deuxième' }
        @{ offset = 8; word = 'deuxième' }
        @{ offset = 13; word = 'deuxième' }
        @{ offset = 14; word = 'deuxième' }
        @{ offset = 15; word = 'deuxième' }
        @{ offset = 16; word = 'deuxième' }
        @{ offset = 17; word = 'troisième' }
        @{ offset = 18; word = 'troisième' }
      ) {
        $default_string = 'premier deuxième troisième quatrième'
        $fh = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($string ?? $default_string))
        Get-WordAtOffset -Handle $fh -Offset $offset | Should -Be $word
      }

    }
  }
}
