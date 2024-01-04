BeforeAll {
  Get-Module RandomItems | Remove-Module -Force
  $testmod = Import-Module -Force (Join-Path $PSScriptRoot '../RandomItems.psd1') -Passthru

  . "$PSScriptRoot/Helpers.ps1"
}

Describe 'Get-RandomString' {

  It 'Returns a string' {
    Get-RandomString -Length 9 | Should -BeLike '?????????'
  }

}

Describe 'New-Password' {

  It 'Returns a password' {
    $p = New-Password
    $p | Should -BeOfType System.Security.SecureString
    $p | ConvertFrom-SecureString -AsPlainText | Should -BeLike ('?' * 20)
  }

}
