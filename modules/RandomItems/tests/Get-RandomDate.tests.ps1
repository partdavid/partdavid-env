BeforeAll {
  Get-Module RandomItems | Remove-Module -Force
  Import-Module -Force (Join-Path $PSScriptRoot '../RandomItems.psd1')

  . "$PSScriptRoot/Helpers.ps1"
}

Describe 'Get-RandomDate' {

  It 'Returns a Date' {
    Get-RandomDate | Should -BeOfType [datetime]
  }

  It 'Returns multiple Dates' {
    Get-RandomDate -Count 10 | Should -HaveCount 10
  }

  It 'Returns a Date within the span' {
    $end = Get-Date
    $start = $end.AddDays(-1)
    $r = Get-RandomDate -Start $start -End $end
    $r -ge $start | Should -BeTrue
    $r -le $end | Should -BeTrue
    ($r - $start).Days | Should -BeIn (0..1)
    ($end - $r).Days | Should -BeIn (0..1)
  }

  It 'Returns a specific date' {
    $end = $start = Get-Date
    0..10 | %{
      Get-RandomDate -Start $start -End $end | Should -Be $start
    }
  }

  It 'Rejects a bad span' {
    $end = Get-Date
    $start = $end.AddDays(-1)
    { Get-RandomDate -Start $end -End $start } | Should -Throw '*not be satisfied*'
  }

  It 'Accepts an interval' {
    $end = Get-Date
    $start = $end.AddDays(-1)
    $interval = New-Interval -Start $start -End $end
    $r = Get-RandomDate -Interval $interval
    $r -ge $start | Should -BeTrue
    $r -le $end | Should -BeTrue
    ($r - $start).Days | Should -BeIn (0..1)
    ($end - $r).Days | Should -BeIn (0..1)
  }

  It 'Accepts multiple intervals' {
    $intervals = @(
      New-Interval -Start '2000-02-23T00:00:00.000' -End '2000-02-23T23:59:59.999'
      New-Interval -Start '2001-02-23T00:00:00.000' -End '2001-02-23T23:59:59.999'
      New-Interval -Start '2002-02-23T00:00:00.000' -End '2002-02-23T23:59:59.999'
    )

    $years = @{}

    0..100 | %{
      $r = Get-RandomDate -Interval $intervals
      $r.Month | Should -Be 2
      $r.Day | Should -Be 23
      $years[$r.Year] = $true
    }
    $years.Keys | Sort-Object | Should -Be 2000,2001,2002
  }

  It 'Formats the date with UFormat' {
    $end = Get-Date
    $start = $end.AddDays(-1)
    $got = Get-RandomDate -Start $start -End $end -UFormat '%s'
    $got | Should -BeGreaterOrEqual (Get-Date -Date $start -UFormat '%s')
    $got | Should -BeLessOrEqual (Get-Date -Date $end -UFormat '%s')
  }

  It 'Formats the date with Format' {
    $start = $end = Get-Date
    $expected = Get-Date -Date $start -Format o
    Get-RandomDate -Start $start -End $end -Format o | Should -Be $expected
  }

  It 'Uses a DisplayHint' {
    $start = $end = Get-Date
    $expected = Get-Date -Date $start -DisplayHint Date
    Get-RandomDate -Start $start -End $end -DisplayHint Date | Should -Be $expected
  }

  It 'Returns a UTC date' {
    $start = $end = Get-Date
    $expected = Get-Date -Date $start -AsUTC
    Get-RandomDate -Start $start -End $end -AsUTC | Should -Be $expected
  }

  It 'Allows setting the year' {
    $end = Get-Date
    $start = $end.AddYears(-2)
    0 .. 10 | %{
      Get-RandomDate -Start $start -End $end -Year $end.Year -Format 'yyyy' | Should -Be $end.Year
    }
  }

}

Describe 'New-Interval' {
  BeforeAll {
    $start = '2000-02-23T08:45:18.221'
    $end = '2003-03-08T11:23:52.232'
  }
  It 'Creates an interval using -Start/-End' {
    $expectedStart = Get-Date $start
    $expectedEnd = Get-Date $end
    $expectedDifference = $expectedEnd - $expectedStart
    $interval = New-Interval -Start $expectedStart -End $expectedEnd
    $interval.start | Should -Be $expectedStart
    $interval.end | Should -Be $expectedEnd
    $interval.ticks | Should -Be $expectedDifference.Ticks
  }

  It 'Creates intervals from the pipeline' {
    $a = @{Start='2000-02-23T08:45:18.221'; End='2000-02-24T08:45:18.221'}
    $b = @{Start='2003-03-08T11:23:52.232'; End='2003-03-09T11:23:52.232'}
    $expected_a_start = Get-Date '2000-02-23T08:45:18.221'
    $expected_a_end = $expected_a_start.AddDays(1)
    $expected_b_start = Get-Date '2003-03-08T11:23:52.232'
    $expected_b_end = $expected_b_start.AddDays(1)

    $got = $a,$b  | %{ New-Interval @_ }
    $got[0].start | Should -Be $expected_a_start
    $got[0].end   | Should -Be $expected_a_end
    $got[1].start | Should -Be $expected_b_start
    $got[1].end   | Should -Be $expected_b_end
  }
}

InModuleScope 'RandomItems' {

  Describe 'Get-Intervals' {

    It 'Returns intervals when setting: <Parameters>' -ForEach @(
      @{
        Parameters = 'Nothing'
        Root = '2000-02-23T08:45:18.221','2003-03-08T11:23:52.232'
        Expected = @(
          New-Interval -Start '2000-02-23T08:45:18.221' -End '2003-03-08T11:23:52.232'
        )
      }
      @{
        Parameters = 'Year=2000'
        Root = '2000-02-23T08:45:18.221','2003-03-08T11:23:52.232'
        Expected = @(
          New-Interval -Start '2000-02-23T08:45:18.221' -End '2000-12-31T23:59:59.999'
        )
      }
      @{
        Parameters = 'Month=3'
        Root = '2000-02-23T08:45:18.221','2003-03-08T11:23:52.232'
        Expected = @(
          New-Interval -Start '2000-03-01T00:00:00.000' -End '2000-03-31T23:59:59.999'
          New-Interval -Start '2001-03-01T00:00:00.000' -End '2001-03-31T23:59:59.999'
          New-Interval -Start '2002-03-01T00:00:00.000' -End '2002-03-31T23:59:59.999'
          New-Interval -Start '2003-03-01T00:00:00.000' -End '2003-03-08T11:23:52.232'
        )
      }
      @{
        Parameters = 'Month=3 Day=22'
        Root = '2000-02-23T08:45:18.221','2003-03-08T11:23:52.232'
        Expected = @(
          New-Interval -Start '2000-03-22T00:00:00.000' -End '2000-03-22T23:59:59.999'
          New-Interval -Start '2001-03-22T00:00:00.000' -End '2001-03-22T23:59:59.999'
          New-Interval -Start '2002-03-22T00:00:00.000' -End '2002-03-22T23:59:59.999'
        )
      }
      @{
        Parameters = 'Day=31'
        Root = '2000-02-23T08:45:18.221','2001-03-08T11:23:52.232'
        Expected = @(
          New-Interval -Start '2000-03-31T00:00:00.000' -End '2000-03-31T23:59:59.999'
          New-Interval -Start '2000-05-31T00:00:00.000' -End '2000-05-31T23:59:59.999'
          New-Interval -Start '2000-07-31T00:00:00.000' -End '2000-07-31T23:59:59.999'
          New-Interval -Start '2000-08-31T00:00:00.000' -End '2000-08-31T23:59:59.999'
          New-Interval -Start '2000-10-31T00:00:00.000' -End '2000-10-31T23:59:59.999'
          New-Interval -Start '2000-12-31T00:00:00.000' -End '2000-12-31T23:59:59.999'
          New-Interval -Start '2001-01-31T00:00:00.000' -End '2001-01-31T23:59:59.999'
        )
      }
      @{
        Parameters = 'Second=22'
        Root = '2000-02-23T08:45:18.221','2000-02-23T08:48:18.232'
        Expected = @(
          New-Interval -Start '2000-02-23T08:45:22.000' -End '2000-02-23T08:45:22.999'
          New-Interval -Start '2000-02-23T08:46:22.000' -End '2000-02-23T08:46:22.999'
          New-Interval -Start '2000-02-23T08:47:22.000' -End '2000-02-23T08:47:22.999'
        )
      }
      @{
        Parameters = 'Millisecond=20'
        Root = '2000-02-23T08:45:18.221','2000-02-23T08:45:21.232'
        Expected = @(
          New-Interval -Start '2000-02-23T08:45:19.020' -End '2000-02-23T08:45:19.020'
          New-Interval -Start '2000-02-23T08:45:20.020' -End '2000-02-23T08:45:20.020'
          New-Interval -Start '2000-02-23T08:45:21.020' -End '2000-02-23T08:45:21.020'
        )
      }
    ) {
      $passParams = @{}
      if ($Parameters -and $Parameters -ne 'Nothing') {
        $Parameters -split ' ' | %{ $key,$value = $_ -split '=',2; $passParams[$key] = $value }
      }
      Get-Intervals -Start $Root[0] -End $Root[1] @passParams | Should -BeInterval $Expected
    }
  }

  Describe 'Get-IntervalBounds' {
    BeforeAll {
      $testDate = Get-Date -Date '2000-02-23T08:45:18.221'
    }

    It 'Returns a whole <Resolution>' -ForEach @(
      @{ Resolution = 'Year';        Expected = '2000-01-01T00:00:00.000','2000-12-31T23:59:59.999' }
      @{ Resolution = 'Month';       Expected = '2000-02-01T00:00:00.000','2000-02-29T23:59:59.999' }
      @{ Resolution = 'Day';         Expected = '2000-02-23T00:00:00.000','2000-02-23T23:59:59.999' }
      @{ Resolution = 'Hour';        Expected = '2000-02-23T08:00:00.000','2000-02-23T08:59:59.999' } # Ignores Leap seconds
      @{ Resolution = 'Minute';      Expected = '2000-02-23T08:45:00.000','2000-02-23T08:45:59.999' }
      @{ Resolution = 'Second';      Expected = '2000-02-23T08:45:18.000','2000-02-23T08:45:18.999' }
      @{ Resolution = 'Millisecond'; Expected = '2000-02-23T08:45:18.221','2000-02-23T08:45:18.221' }
    ) {
      $expectedInterval = New-Interval -Start $Expected[0] -End $Expected[1]
      Get-IntervalBounds -Date $testDate -Resolution $Resolution | Should -BeInterval $expectedInterval
    }

  }

  Describe 'Get-FieldRange' {
    BeforeAll {
      $testDate = Get-Date '2000-02-23T08:45:18.221'
    }

    It 'Returns range for <Field>' -ForEach @(
      @{ Field = 'Year';        Expected = 1,9999 }
      @{ Field = 'Month';       Expected = 1,12 }
      @{ Field = 'Day';         Expected = 1,29 }
      @{ Field = 'Hour';        Expected = 0,23 }
      @{ Field = 'Minute';      Expected = 0,59 }
      @{ Field = 'Second';      Expected = 0,59 }
      @{ Field = 'Millisecond'; Expected = 0,999 }
    ) {
      Get-FieldRange -Field $Field -Date $testDate | Should -Be $Expected
    }

  }
}


