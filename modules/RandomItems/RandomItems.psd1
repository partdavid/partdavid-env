@{
  ModuleVersion = '0.2.0'
  GUID = 'cd8e4c43-b849-4403-872f-ca06778ad889'
  Author = 'partdavid'
  Copyright = '(c) 2024 partdavid. All Rights Reserved.'
  Description = 'Generate random data'
  RootModule = 'RandomItems.psm1'
  RequiredModules = @('EPS')
  FileList = @(
    'RandomItems.psd1'
    'RandomItems.psm1'
    'Get-Binding.ps1'
    'Get-RandomIp.ps1'
    'Get-RandomDate.ps1'
    'Get-RandomString.ps1'
    'Get-RandomWord.ps1'
    'New-Password.ps1'
    'New-RandomItem.ps1'
  )
  FunctionsToExport = @(
    'Get-Binding'
    'Get-RandomIp'
    'Get-RandomDate'
    'Get-RandomString'
    'Get-RandomWord'
    'New-Interval'
    'New-Password'
    'New-RandomItem'
    'Test-NetworkMember'
  )
  CmdletsToExport = @()
  PrivateData = @{
    PSData = @{
      Tags = @('')
      ProjectUri = 'https://github.com/partdavid/partdavid-env/tree/trunk/modules/RandomItems'
    }
  }
}
