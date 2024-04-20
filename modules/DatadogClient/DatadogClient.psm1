foreach ($script in (Get-ChildItem $PSScriptRoot/*.ps1)) {
  Write-Host "Sourcing $($script.FullName)"
  . $script.FullName
}
