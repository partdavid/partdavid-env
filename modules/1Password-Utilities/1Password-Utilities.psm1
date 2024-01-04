$commands = @(
  'Get-1PasswordItem',
  'Start-1PasswordSession',
  'Stop-1PasswordSession'
)

foreach ($command in $commands) {
  . "$PSScriptRoot/$command.ps1"
}

Export-ModuleMember -Function $commands
