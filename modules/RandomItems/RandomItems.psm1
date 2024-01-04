$commands = @(
  'Get-Binding'
  'Get-RandomIp'
  'Get-RandomDate'
  'Get-RandomWord'
  'Get-RandomString'
  'New-Password'
  'New-RandomItem'
)

foreach ($command in $commands) {
  . "$PSScriptRoot/$command.ps1"
}
