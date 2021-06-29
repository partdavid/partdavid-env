$commands = @{
  'Send-Dotfiles' = $true
}

foreach ($command in $commands.keys) {
  . "$PSScriptRoot/$command.ps1"
}

Export-ModuleMember -Function ($commands.keys | ?{ $commands.$_ })
