@{
  RootModule = 'DatadogClient.psm1'
  ModuleVersion = '0.0.1'
  GUID = 'fd87a913-51d1-4deb-b588-ff03243539a9'
  Author = 'partdavid'
  Copyright = '(c) 2024 partdavid. All rights reserved.'
  Description = 'Perform API client operations'
  FunctionsToExport = @(
    'Get-DatadogTimeseries'
    'Invoke-DatadogAPI'
    'Test-DatadogAPIKey'
  )
  FileList = @(
    'DatadogClient.psd1'
    'DatadogClient.psm1'
    'Get-DatadogTimeseries.ps1'
    'Invoke-DatadogAPI.ps1'
    'Test-DatadogAPIKey.ps1'
  )

  PrivateData = @{
    PSData = @{
      Tags = @('')
      ProjectUri = 'https://github.com/partdavid/partdavid-env/tree/trunk/modules/DatadogClient'
    }
  }
}


