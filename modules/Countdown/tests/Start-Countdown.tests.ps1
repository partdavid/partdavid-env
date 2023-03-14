BeforeAll {
  Get-Module RandomItems | Remove-Module -Force
  Import-Module -Force (Join-Path $PSScriptRoot '../Countdown.psd1')
}

Describe 'Start-Countdown' {

  Context 'With 0 seconds' {

    It 'returns without errors' {
      { Start-Countdown 0 } | Should -Not -Throw
    }

  }

}
