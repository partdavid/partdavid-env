$commands = @{
  'Set-CurrentContext'  = $true
  'Get-CurrentContext'  = $true
  'Write-CurrentContext' = $true
  'Add-PathDirectory' = $true
  'Remove-PathDirectory' = $true
}

foreach ($command in $commands.keys) {
  . "$PSScriptRoot/$command.ps1"
}

Export-ModuleMember -Function ($commands.keys | ?{ $commands.$_ })
