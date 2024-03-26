@{
  RootModule = 'Html-Entities.psm1'
  ModuleVersion = '0.5.0'
  GUID = 'f6d7429e-80f1-4059-a645-ccd2d19e1a37'
  Author = 'partdavid'
  Copyright = '(c) 2024 partdavid. All rights reserved.'
  Description = 'Expand HTML entities in strings'
  FunctionsToExport = @(
    'Add-UserHtmlEntity'
    'Get-HtmlEntity'
    'Expand-HtmlEntities'
    'Sync-HtmlEntities'
  )
  AliasesToExport = @(
    'Add-HtmlEntity'
  )
  PrivateData = @{
    PSData = @{
      Tags = @()
      ProjectUri = 'https://github.com/partdavid/partdavid-env/tree/trunk/modules/Html-Entities'
    }
  }
}

