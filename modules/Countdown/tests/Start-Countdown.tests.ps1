BeforeAll {
  Get-Module RandomItems | Remove-Module -Force
  Import-Module -Force (Join-Path $PSScriptRoot '../Countdown.psd1')
}

Describe 'Start-Countdown' {

  Context 'With 0 seconds' {

    It 'returns without errors' {
      { Start-Countdown 0 -NoBeep } | Should -Not -Throw
    }

  }

  Context 'With 1 second' {

    It 'returns after the correct time (with 10 ms)' {
      $start = Get-Date
      Start-Countdown 1 -NoBeep
      $finish = Get-Date
      1000 - ($finish - $start).TotalMilliseconds | Should -BeLessThan 10
    }

  }

}
