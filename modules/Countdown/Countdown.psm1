$commands = @(
  'Start-Countdown'
)

foreach ($command in $commands) {
  . "$PSScriptRoot/$command.ps1"
}
