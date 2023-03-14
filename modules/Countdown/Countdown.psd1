@{
  ModuleVersion = '0.0.1'
  GUID = 'f1764693-d47f-4ad3-b64e-1057b4c9a55d'
  Author = 'partdavid@gmail.com'
  Copyright = '(c) 2023 partdavid@gmail.com. All rights reserved.'
  Description = 'Pleasing countdown CLI'
  RootModule = 'Countdown.psm1'
  FunctionsToExport = @(
    'Start-Countdown'
  )
  AliasesToExport = @()
  FileList = @(
    'Countdown.psd1'
    'Countdown.psm1'
    'Start-Countdown.ps1'
  )
  PrivateData = @{
    PSData = @{
        Tags = @()
        ProjectUri = 'https://github.com/partdavid/partdavid-env/tree/trunk/modules/Countdown'
    }
  }
}
