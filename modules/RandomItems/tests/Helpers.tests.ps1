BeforeDiscovery {
  . "$PSScriptRoot/Helpers.ps1"
}

Describe 'Testing Should -BeInterval' {

  It 'Succeeds' {
    $expectedStart = Get-Date '2000-02-23T08:45:18.221'
    $expectedEnd = Get-Date '2003-03-08T11:23:52.232'
    $expectedInterval = New-Interval -Start $expectedStart -End $expectedEnd
    New-Interval -Start $expectedStart -End $expectedEnd | Should -BeInterval $expectedInterval
  }

  It 'Succeeds in pipelines' {
    $expected = @(
      New-Interval -Start '2000-03-01T00:00:00.000' -End '2000-03-31T23:59:59.999'
      New-Interval -Start '2001-03-01T00:00:00.000' -End '2001-03-31T23:59:59.999'
      New-Interval -Start '2002-03-01T00:00:00.000' -End '2002-03-31T23:59:59.999'
      New-Interval -Start '2003-03-01T00:00:00.000' -End '2003-03-08T11:23:52.232'
    )
    $expected | Should -BeInterval $expected
  }
}
