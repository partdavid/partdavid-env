function Start-Countdown {
  [CmdletBinding()]

  param(
    [Parameter()] [string]$Seconds
  )

  Start-Sleep -Seconds $Seconds
}
