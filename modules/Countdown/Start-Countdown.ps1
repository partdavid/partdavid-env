function Start-Countdown {
  [CmdletBinding(DefaultParameterSetName='Seconds')]

  param(
    [Parameter(Position=0, ParameterSetName='Seconds')] [int]$Seconds,
    [Parameter(ParameterSetName='Milliseconds')] [int]$Milliseconds,
    [Parameter()] [ValidateSet('Bar', 'None', 'Spinner')] [string]$Progress = 'Bar',
    [Parameter()] [string]$Name = 'Countdown',
    [Parameter()] [ValidateScript({ $_ -is [ScriptBlock] -or ($_ -is [string] -and ('Beep','None','Null' -Contains $_)) })]
    [object]$Notify = 'Beep',
    [Parameter()] [string]$SpinnerSequence = '-/|\-/|\',
    [Parameter()] [int]$SpinnerRPM = 120
  )

  # This update interval should work fine for progress bar, too
  $updateIntervalMS = 1000 / ($SpinnerSequence.Length * $SpinnerRPM / 60)

  Write-Debug "updateIntervalMS: $updateIntervalMS"

  $start = Get-Date
  $deadline = $PSCmdlet.ParameterSetName -eq 'Milliseconds' ? $start.AddMilliseconds($Milliseconds) : $start.AddSeconds($Seconds)
  $interval = $deadline - $start
  if ($Progress -eq 'Spinner') {
    [int32]$remainingSeconds = $interval.TotalSeconds
    $len = ('{0:d}' -f $remainingSeconds).Length
    Write-Host -NoNewLine ("{0}: {1,${len}:d}s {2}" -f $Name,$remainingSeconds,$SpinnerSequence[0])
    $SpinnerSequence = $SpinnerSequence.Substring(1, $SpinnerSequence.Length - 1) + $SpinnerSequence[0]
    Write-Debug "    rotated spinner sequence '${SpinnerSequence}' and set eraseLen to $eraseLen"
  }
  while ((Get-Date) -lt $deadline) {
    Write-Debug "write loop"
    $now = Get-Date
    $remaining = $deadline - $now
    [int32]$pct = (($remaining.Ticks / $interval.Ticks) * 100)
    [int32]$remainingSeconds = $remaining.TotalSeconds
    Write-Debug "  loop calcs completed (remainingSeconds=${remainingSeconds})"
    if ($Progress -eq 'Bar') {
      Write-Progress -Activity $Name `
        -Status "Counting down to $(Get-Date -Date $deadline -UFormat %H:%M:%S)" `
        -PercentComplete $pct `
        -SecondsRemaining $remainingSeconds
    } elseif ($Progress -eq 'Spinner') {
      Write-Debug "    writing spinner progress from $($SpinnerSequence[0]) '${SpinnerSequence}'"
      Write-Host -NoNewLine ("{0}{1,${len}:d}s {2}" -f ("`b" * ($len + 3)),$remainingSeconds,$SpinnerSequence[0])
      Write-Debug "    written, rotating"
      $newEraseLen = "${remainingSeconds}s ".Length + 1
      if ($newEraseLen -lt $eraseLen) {
        Write-Host -NoNewLine (' ' * ($eraseLen - $newEraseLen))
      }
      # Rotate sequence string
      $SpinnerSequence = $SpinnerSequence.Substring(1, $SpinnerSequence.Length - 1) + $SpinnerSequence[0]
      Write-Debug "    rotated spinner sequence '${SpinnerSequence}' and set eraseLen to $eraseLen"
    }
    Write-Debug "  progress written"
    $left = [math]::Max(($deadline - (Get-Date)).TotalMilliseconds, 0)
    Write-Debug "  $left ms left (updateIntervalMS=$updateIntervalMS) sleep..."
    Start-Sleep -Milliseconds ([math]::Min($updateIntervalMS, $left))
    Write-Debug "  sleep done"
  }
  if ($Progress -eq 'Bar') {
    Write-Progress -Activity 'Countdown' `
      -PercentComplete 0 `
      -SecondsRemaining 0 `
      -Completed
  }
  if ($Notify -eq 'Beep') {
    Write-Host "`a"
  } elseif ($Notify -is [ScriptBlock]) {
    $Notify.Invoke()
  }


}
