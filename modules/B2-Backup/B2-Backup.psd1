@{
  RootModule = 'B2-Backup.psm1'
  ModuleVersion = '0.5.0'
  GUID = '319092f0-e682-43d6-95d6-528ecdf11a77'
  Author = 'partdavid@gmail.com'
  Copyright = '(c) partdavid@gmail.com. All rights reserved.'
  Description = 'Utilities to use BackBlaze (B2) cloud storage for backups'
  FunctionsToExport = @(
    'Start-B2Session'
    'Stop-B2Session'
    'Get-B2Item'
    'Backup-B2Item'
    'Restore-B2Item'
    'Remove-B2Item'
    'Update-B2Key'
    'Format-Path'
  )
  AliasesToExport = @()
  FileList = @(
    'B2-Backup.psd1'
    'B2-Backup.psm1'
    'Start-B2Session.ps1'
    'Stop-B2Session.ps1'
    'Get-B2Item.ps1'
    'Backup-B2Item.ps1'
    'Restore-B2Item.ps1'
    'Remove-B2Item.ps1'
    'Update-B2Key.ps1'
  )
  PrivateData = @{
    PSData = @{
        Tags = @('backblaze','backup')
        # ProjectUri = ''
    }
  }
}


