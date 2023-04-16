$Files = @(
  'Start-B2Session'
  'Stop-B2Session'
  'Get-B2Item'
  'Backup-B2Item'
  'Restore-B2Item'
  # 'Remove-B2Item'
  # 'Update-B2Key'
)

foreach ($file in $Files) {
  . "$PSScriptRoot/${file}.ps1"
}
