<#

.SYNOPSIS

Generate a date/time at random

.DESCRIPTION

The Get-RandomDate command generates a random date within an
optionally specified interval. The resulting DateTimes are
evenly-distributed in the timespan defined by the start and
end dates. The user can also pass options similar to Get-Date
to set certain date fields--Get-RandomDate preserves the
integrity of the timespan as well as the property that random
dates are evenly distributed in the interval.

The default timespan starts at the Unix epoch and ends at
the current date/time.

Note that in order to do this, Get-Date internally breaks
up the timespan at the resolution required to set the various
fields. Very fine resolution on long time spans result in
a lot of individual intervals and poor performance may
result.

Note that the meaning of passing an -Interval versus passing multiple
intervals in a pipeline are different. When interpreting an explicitly
specified -Interval consisting of an array of intervals,
Get-RandomDate considers the set of intervals all together to be its
time range within which to select a date: that is, it will generate
one date (or -Count dates) which are randomly selected from all
intervals.

When receiving intervals in the pipeline, Get-RandomDate generates
one date (or -Count dates) for each interval piped to it.

.EXAMPLE

PS>Get-RandomDate

Sunday, June 28, 2009 9:54:30 PM

.EXAMPLE

PS>Get-Date

Friday, February 3, 2023 10:19:14 AM

PS>Get-RandomDate -Start (Get-Date).AddDays(-1)

Friday, February 3, 2023 9:15:44 AM

.EXAMPLE

PS>Get-RandomDate -Year 2020 -Month 3

Monday, March 30, 2020 2:03:28 AM

PS>Get-RandomDate -Year 2020 -Month 3

Tuesday, March 24, 2020 5:16:03 AM

.LINK

Get-Date

.LINK

Get-Random

#>
function Get-RandomDate {
  [CmdletBinding(DefaultParameterSetName='StartAndEnd')]
  param(
    # Specify the beginning of the timespan (inclusive)
    [Parameter(ParameterSetName='StartAndEnd')] [Parameter(ParameterSetName='StartAndEndFormat')]
    [Parameter(ParameterSetName='StartAndEndUFormat')] [datetime]$Start = (Get-Date -UnixTimeSeconds 0),

    # Specify the end of the timespan (inclusive)
    [Parameter(ParameterSetName='StartAndEnd')] [Parameter(ParameterSetName='StartAndEndFormat')]
    [Parameter(ParameterSetName='StartAndEndUFormat')] [datetime]$End = (Get-Date),

    # Specify an interval
    [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='Interval')]
    [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='IntervalFormat')]
    [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='IntervalUFormat')] [PSCustomObject[]]$Interval,
    [int32]$Year,
    [int32]$Month,
    [int32]$Day,
    [int32]$Hour,
    [int32]$Minute,
    [int32]$Second,
    [int32]$Millisecond,
    [switch]$AsUTC,
    [string]$DisplayHint,
    # Generate multiple dates
    [int]$Count = 1,
    # Set the random seed, allowing repeatable "random" dates
    [int]$SetSeed,
    [Parameter(Mandatory, ParameterSetName='StartAndEndUFormat')]
    [Parameter(Mandatory, ParameterSetName='IntervalUFormat')] [string]$UFormat,

    [Parameter(Mandatory, ParameterSetName='StartAndEndFormat')]
    [Parameter(Mandatory, ParameterSetName='IntervalFormat')] [string]$Format
  )

  begin {
    Write-Debug "Get-RandomDate invoked: $($PSBoundParameters | ConvertTo-Json -Compress)"

    $randomOptions = @{}
    if ($PSBoundParameters.ContainsKey('SetSeed')) {
      $randomOptions['SetSeed'] = $SetSeed
    }

    $fields = 'Year','Month','Day','Hour','Minute','Second','Millisecond'
    # I wish hash slices were easier
    $intervalOptions = @{}
    foreach ($field in $fields) {
      if ($PSBoundParameters.ContainsKey($field)) {
        $intervalOptions[$field] = $PSBoundParameters[$field]
      }
    }
  }

  process {
    if ($PSBoundParameters.ContainsKey('Interval')) {
      $intervals = Get-Intervals -Interval $Interval @intervalOptions
    } else {
      $intervals = Get-Intervals -Start $Start -End $End @intervalOptions
    }

    if ($intervals -eq $Null -or $intervals.Count -eq 0) {
      throw "date constraints cannot be satisfied: no legal intervals found in date range"
    }

    # How intervals are used:
    #
    # random offset
    # [0 - 1000]    ->   @{ start=2020-01-01; ticks = 1000 } -> start + 0 -- start + 1000
    # [1001 - 3001] ->   @{ start=2021-01-01; ticks = 2000 } -> start + (1001 - 1001) -- start + (3001 - 1001)
    # [3002 - 6002] ->   @{ start=2022-01-01; ticks = 3000 } -> start + (3002 - 3002) -- start + (6002 - 3002)
    #
    # [0]           ->   @{ start=2020-01-01; ticks = 0 } -> start + 0 -- start + 0
    #
    # [0]           ->   @{ start=2020-01-01; ticks = 0 } -> start + 0 -- start + 0
    # [1]           ->   @{ start=2020-01-01; ticks = 0 } -> start + (1 - 1) -- start + (1 - 1)
    #
    # [0]           ->   @{ start=2020-01-01; ticks = 0 }   -> start + 0 --
    # [1 - 1001]    ->   @{ start=2021-01-01; ticks = 1000 } -> start + (1 - 1) -- start + (1001 - 1)
    # [1002]        ->   @{ start=2022-01-01; ticks = 0 } -> start + (1002 - 1002) --
    # [1003 - 3003] ->   @{ start=2023-01-01; ticks = 2000 } -> start + (1003 - 1003) -- start + (3003 - 1003)
    #
    # max = sum(ticks) + length() - 1

    $maxTicks = ($intervals | Measure-Object -Property ticks -Sum).Sum + $intervals.length - 1
    Write-Debug "maxTicks=$maxTicks"
    $cursor = 0
    foreach ($interval in $intervals) {
      Write-Debug "[$cursor - $($cursor + $interval.ticks)] -> $($interval | convertto-json -compress)"
      $cursor += $interval.ticks + 1
    }

    for ($dateNum = 0; $dateNum -lt $Count; $dateNum++) {
      if ($maxTicks -gt 0) {
        $ticks = Get-Random -Minimum 0 -Maximum $maxTicks @randomOptions
      } else {
        $ticks = 0
      }
      Write-Debug "${dateNum}: random ticks = $ticks"

      $cursor = 0
      foreach ($interval in $intervals) {
        if ($ticks -le ($cursor + $interval.ticks)) {
          # It's this one
          $randomDate = $interval.start.AddTicks($ticks - $cursor)
          break
        }
        $cursor += $interval.ticks + 1
      }

      $formatOptions = @{}
      foreach ($opt in 'DisplayHint','Format','UFormat','AsUTC') {
        if ($PSBoundParameters.ContainsKey($opt)) {
          $formatOptions[$opt] = $PSBoundParameters[$opt]
        }
      }

      if ($formatOptions.Count -gt 0) {
        Get-Date @formatOptions -Date $randomDate
      } else {
        $randomDate
      }
    }
  }
}

function Get-Intervals {
  [CmdletBinding(DefaultParameterSetName='StartAndEnd')]
  param(
    [Parameter(Mandatory, ParameterSetName='StartAndEnd')] [datetime]$Start,
    [Parameter(Mandatory, ParameterSetName='StartAndEnd')] [datetime]$End,
    [Parameter(Mandatory, ParameterSetName='Interval')] [PSCustomObject[]]$Interval,
    [int32]$Year,
    [int32]$Month,
    [int32]$Day,
    [int32]$Hour,
    [int32]$Minute,
    [int32]$Second,
    [int32]$Millisecond
  )

  Write-Debug "Get-Intervals invoked: $($PSBoundParameters | ConvertTo-Json -Compress)"

  $fields = 'Year','Month','Day','Hour','Minute','Second','Millisecond'
  $finestConstraint = -1

  foreach ($field in $fields) {
    if ($PSBoundParameters.ContainsKey($field)) {
      $finestConstraint = [math]::Max($finestConstraint, $fields.IndexOf($field))
    }
  }

  Write-Debug "finestConstraint: [$finestConstraint]=$($finestConstraint -in 0..6 ? $fields[$finestConstraint]: '')"

  if ($PSBoundParameters.ContainsKey('Interval')) {
    $intervals = $Interval
  } else {
    if ($Start -le $End) {
      $intervals = @(
        New-Interval -Start $Start -End $End
      )
    }
  }

  Write-Debug "Root intervals ($($intervals.length)): $($intervals | ConvertTo-Json -Compress)"

  for ($fieldNum = 0; $fieldNum -le $finestConstraint; $fieldNum++) {
    $field = $fields[$fieldNum]
    Write-Debug "Processing [$field]=$($fields[$fieldNum])"
    $previousField = $fieldNum -eq 0 ? 'interval' : $fields[$fieldNum - 1]
    $nextField = $fieldNum -ge $fields.length ? 'none' : $fields[$fieldNum + 1]

    # First, set anything that needs to be set at the current constraint.
    # All of the coarser field values have the same value in the interval
    # and we are just setting the next-coarsest field.
    #
    # For each field, we need to know the floor and ceiling values for the
    # interval: the minimum and maximum dates that are still in the interval.
    $fieldValue = $PSBoundParameters[$field]
      
    # The rest of the fields in the constraint come from the min and max
    # values, so they reflect the whole span of this interval
    if ($PSBoundParameters.ContainsKey($field)) {

      Write-Debug "-$field $($fieldValue) specified: setting $previousField intervals to $field=$fieldValue"
      
      $intervals = $intervals | %{
        $interval = $_
        $currentConstraint = @{$field = $fieldValue}
        # We replace the corrent interval with a new one which is bounded by this field's
        # value.
        #
        # For example, if we have a root interval and are setting the
        # year, we replace the root interval with a year interval
        # where the year is correct. We do this by getting two new
        # intervals:

        # Case one: setting puts the date(s) outside of interval bounds:
        # start  = 2000-02-23T08:45:18.221
        # end = 2001-03-02T13:09:52.232
        # Get-IntervalBounds -Date 2000-02-23T08:45:18.221 -Resolution Year -Year 2022 ->
        #    2022-01-01T00:00:00.000 -- 2022-12-31T23:59:59.999
        # Get-IntervalBounds -Date 2001-03-02T13:09:52.232 -Resolution Year -Year 2022 ->
        #    2022-01-01T00:00:00.000 -- 2022-12-31T23:59:59.999
        # floor is   max(2000-02-23T08:45:18.221, 2022-01-01T00:00:00.000) -> 2022-01-01T00:00:00.000
        # ceiling is min(2001-03-02T13:09:52.232, 2022-12-31T23:59:59.999) -> 2001-03-02T13:09:52.232
        # since floor > ceiling, the interval is illegal and removed.
        #
        # Case two: setting puts the date outside of one bound:
        # start  = 2000-02-23T08:45:18.221
        # end = 2001-03-02T13:09:52.232
        # Get-IntervalBounds -Date 2000-02-23T08:45:18.221 -Resolution Year -Year 2001 ->
        #   2001-01-01T00:00:00.000 -- 2001-12-31T23:59:59.999
        # Get-IntervalBounds -Date 2001-03-02T13:09:52.232 -Resolution Year -Year 2001 ->
        #   2001-01-01T00:00:00.000 -- 2001-12-31T23:59:59.999
        # floor is   max(2000-02-23T08:45:18.221, 2001-01-01T00:00:00.000) -> 2001-01-01T00:00:00.000
        # ceiling is min(2001-03-02T13:09:52.232, 2001-12-31T23:59:59.999) -> 2001-03-02T13:09:52.232
        #
        # Case three: setting puts the date(s) inside both bounds:
        # start  = 2000-02-23T08:45:18.221
        # end = 2000-03-02T13:09:52.232
        # Get-IntervalBounds -Date 2000-02-23T08:45:18.221 -Resolution Year -Year 2000 ->
        #   2000-01-01T00:00:00.000 -- 2000-12-31T23:59:59.999
        # Get-IntervalBounds -Date 2001-03-02T13:09:52.232 -Resolution Year -Year 2000 ->
        #   2000-01-01T00:00:00.000 -- 2000-12-31T23:59:59.999
        # floor is   max(2000-02-23T08:45:18.221, 2000-01-01T00:00:00.000) -> 2000-02-23T08:45:18.221
        # ceiling is min(2000-03-02T13:09:52.232, 2000-12-31T23:59:59.999) -> 2000-03-02T13:09:52.232
        # 
        $floor = Get-IntervalBounds -Date $interval.start -Resolution $field @currentConstraint
        $ceiling = Get-IntervalBounds -Date $interval.end -Resolution $field @currentConstraint
        Write-Debug "   max($floor, $($interval.start)) - min($ceiling, $($interval.end))"
        # Bring interval start up to floor if necessary
        $new_start = $floor.start,$interval.start | Get-MaximumDate
        # Bring interval end down to ceiling if necessary
        $new_end = $ceiling.end,$interval.end | Get-MinimumDate
        if ($new_start -le $new_end) {
          Write-Debug "   $new_start -- $new_end"
          New-Interval -Start $new_start -End $new_end
        } else {
          Write-Debug "   removing illegal interval: $new_start -- $new_end"
          $Null
        }
      } | ?{ $_ }
      Write-Debug "New $previousField intervals ($($intervals.length)): $($intervals | ConvertTo-Json -Compress)"
    }

    # If our finestConstraint is greater than or equal to the
    # nextFieldNum, then we need to split into finer intervals at this
    # resolution. For example, -Month requires Year resolution and -Day
    # requires Month resolution. So we need to split each interval into
    # intervals of one step greater resolution.
    if ($finestConstraint -ge ($fieldNum + 1)) {
      Write-Debug "Finest constraint is $($fields[$finestConstraint]), requires $($fields[$finestConstraint - 1]) resolution"
      Write-Debug "Splitting $previousField intervals into $field intervals"

      $intervals = $intervals | %{
        $interval = $_
        Write-Debug "Splitting $previousField interval: $($interval.start) - $($interval.end) by $field value [$($interval.start.$field) - $($interval.end.$field)]"
        $lower,$_ = Get-FieldRange -Date $interval.start -Field $field
        $lower = [math]::Max($lower, $interval.start.$field)
        $_,$upper = Get-FieldRange -Date $interval.end -Field $field
        $upper = [math]::Min($upper, $interval.end.$field)
        Write-Debug "Ranging from $lower -- $upper"
        for ($cursor = $lower; $cursor -le $upper; $cursor++) {
          Write-Debug "    - Setting $field=$cursor"

          $cursorConstraint = @{
            $field = $cursor
          }
          $floor = Get-IntervalBounds -Date $interval.start -Resolution $field @cursorConstraint
          $ceiling = Get-IntervalBounds -Date $interval.end -Resolution $field @cursorConstraint
          if ($interval.start.$field -eq $cursor) {
            $new_start = $floor.start,$interval.start | Get-MaximumDate
          } else {
            $new_start = $floor.start
          }
          if ($interval.end.$field -eq $cursor) {
            # Our interval might end with a partial year
            $new_end = $ceiling.end,$interval.end | Get-MinimumDate
          } else {
            $new_end = $ceiling.end
          }
          Write-Debug "      new interval: $new_start - $new_end"
          New-Interval -Start $new_start -End $new_end
        }
      }
      Write-Debug "$field intervals ($($intervals.length)): $($intervals | ConvertTo-Json -Compress)"
    }
  }
  
  $intervals
}


function Get-MaximumDate {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline=$True)] [datetime[]]$Date
  )

  begin {
    $maximum = $null
  }

  process {
    foreach ($candidate in $Date) {
      if ($maximum -eq $null -or $maximum -lt $candidate) {
        $maximum = $candidate
      }
    }
  }

  end {
    return $maximum
  }
}

function Get-MinimumDate {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline=$True)] [datetime[]]$Date
  )

  begin {
    $minimum = $null
  }

  process {
    foreach ($candidate in $Date) {
      if ($minimum -eq $null -or $minimum -gt $candidate) {
        $minimum = $candidate
      }
    }
  }

  end {
    return $minimum
  }
}

# Essentially, we take a date, and its resolution (the finest-grained
# field we want to preserve). It returns a new date with the resolution
# field (and all coarser fields) preserved, and the finer fields
# zeroed out (minimized) or maximized, and returns the pair of dates
function Get-IntervalBounds {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [datetime]$Date,
    [int32]$Year,
    [int32]$Month,
    [int32]$Day,
    [int32]$Hour,
    [int32]$Minute,
    [int32]$Second,
    [int32]$Millisecond,
    [Parameter(Mandatory)] [ValidateSet('Year','Month','Day','Hour','Minute','Second','Millisecond')] [string]$Resolution
  )

  $fields = @('Year','Month','Day','Hour','Minute','Second','Millisecond')
  $setOptions = @{}
  $floorOptions = @{}
  $ceilingOptions = @{}

  # It's convenient to not have to do this as a separate step before passing
  # to Get-IntervalBounds, because the question you want to ask is often
  # "What are the interval bounds once I set this field"?
  foreach ($field in $fields) {
    if ($PSBoundParameters.ContainsKey($field)) {
      if ($fields.IndexOf($field) -gt $fields.IndexOf($Resolution)) {
        Write-Warning "Setting -$field has no effect since -Resolution is $Resolution"
      }
      $setOptions[$field] = $PSBoundParameters[$field]
    }
  }

  if ($setOptions.count -gt 0) {
    $Date = Get-Date -Date $Date @setOptions
  }

  Write-Debug "Finding interval bounds for the $Resolution in which $Date occurs"

  for ($fieldNum = $fields.IndexOf($Resolution) + 1; $fieldNum -lt $fields.length; $fieldNum++) {
    $field = $fields[$fieldNum]
    $floorOptions[$field] = [datetime]::MinValue.$field
    if ($fields[$fieldNum] -eq 'Day') {
      # Special logic required for maximum Day
      $ceilingOptions[$field] = [datetime]::DaysInMonth($Date.Year, ($ceilingOptions['Month'] ?? $Date.Month))
    } else {
      $ceilingOptions[$field] = [datetime]::MaxValue.$field
    }
  }

  $floor = Get-Date -Date $Date @floorOptions
  $ceiling = Get-Date -Date $Date @ceilingOptions

  Write-Debug "   $floor -- $ceiling"

  New-Interval -Start $floor -End $ceiling
}

function Get-FieldRange {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [datetime]$Date,
    [Parameter(Mandatory)] [string]$Field
  )

  $lower = [datetime]::MinValue.$field
  if ($field -eq 'Day') {
    $upper = [datetime]::DaysInMonth($Date.Year, $Date.Month)
  } else {
    $upper = [datetime]::MaxValue.$field
  }

  return $lower,$upper
}

<#

.SYNOPSIS

Create an interval from a pair of datetimes

.DESCRIPTION

Creates a datetime interval based on the start and end times
given. This is a data structure used by other RandomItem
date utilities like Get-RandomDate.

.EXAMPLE

PS>New-Interval -Start 2003-01-01T00:00:00.000 -End 2003-12-31T23:59:59.999

.EXAMPLE

PS>New-Interval -Start 2003-01-01T00:00:00.000

#>
function New-Interval {
  param(
    [Parameter(Mandatory)] [datetime]$Start,
    [Parameter(Mandatory)] [datetime]$End
  )

  process {
    if ($PSBoundParameters.ContainsKey('Span')) {
      $Start = $Span.Start
      $End = $Span.End ?? $Span.Start
    }

    [PSCustomObject]@{
      start = $Start
      end = $End
      ticks = ($End - $Start).Ticks
    }
  }
}

# ROADMAP: Add -Unique ? This could be tricky, I'm not liking the "multiple
# attempts" approach especially given how the user can constrain the date
# fields.
