<#

.SYNOPSIS

Get metric timeseries according to query

.DESCRIPTION

#>

function Get-DatadogTimeseries {
  [CmdletBinding(DefaultParameterSetName='Last')]
  param(
    [Parameter(Mandatory, Position=0)] [string]$Query,
    [Parameter(Position=1, ParameterSetName='Last')] [int]$Last = 15,
    [Parameter(Position=2, ParameterSetName='Last')]
    [ValidateSet('Years', 'Months', 'Days', 'Hours', 'Minutes', 'Seconds')] [string]$TimeUnit = 'Minutes',
    [Parameter(Mandatory, Position=1, ParameterSetName='FromTo')] [datetime]$From,
    [Parameter(Mandatory, Position=2, ParameterSetName='FromTo')] [datetime]$To,
    [string]$APIKey,
    [string]$AppKey,
    [string]$Site
  )

  $opt = @{}

  if ($APIKey) {
    $opt['APIKey'] = $APIKey
  }
  if ($AppKey) {
    $opt['AppKey'] = $AppKey
  }
  if ($Site) {
    $opt['Site'] = $Site
  }

  $To ??= Get-Date

  $From ??= switch ($TimeUnit) {
    'Seconds' { $To.AddSeconds(-1 * $Last) }
    'Minutes' { $To.AddMinutes(-1 * $Last) }
    'Hours'   { $To.AddHours(-1 * $Last) }
    'Days'    { $To.AddHours(-1 * $Last) }
    'Months'  { $To.AddMonths(-1 * $Last) }
    'Years'   { $To.AddYears(-1 * $Last) }
  }


  $opt['Query'] = @{
    from  = Get-Date $From -UFormat %s
    to    = Get-Date $To -UFormat %s
    query = $Query
  }

  Invoke-DatadogAPI -Path /query @opt
}
