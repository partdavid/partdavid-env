$commands = @{
  'Add-CurrentContext' = $true
  'Set-CurrentContext'  = $true
  'Remove-CurrentContext' = $true
  'Get-CurrentContext'  = $true
  'Write-CurrentContext' = $true
  'Add-PathDirectory' = $true
  'Remove-PathDirectory' = $true
  'Enter-Context' = $true
  'Exit-Context' = $true
  'Get-ContextConfiguration' = $true
}

foreach ($command in $commands.keys) {
  . "$PSScriptRoot/$command.ps1"
}

Export-ModuleMember -Function ($commands.keys | ?{ $commands.$_ })
