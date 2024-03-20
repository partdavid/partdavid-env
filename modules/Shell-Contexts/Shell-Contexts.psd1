#
# Module manifest for module 'Shell-Contexts'
#

@{
  RootModule = 'Shell-Contexts.psm1'
  ModuleVersion = '1.2.1'
  GUID = 'aa653768-02e2-4805-9a36-1ba494b210e1'
  Author = 'partdavid'
  Copyright = '(c) 2024 partdavid. All rights reserved.'
  FileList = @(
    'Add-CurrentContext.ps1',
    'Add-PathDirectory.ps1',
    'Get-ContextConfiguration.ps1',
    'Get-CurrentContext.ps1',
    'Remove-CurrentContext.ps1',
    'Remove-PathDirectory.ps1',
    'Shell-Contexts.psd1',
    'Shell-Contexts.psm1',
    'Set-CurrentContext.ps1',
    'Write-CurrentContext.ps1'
  )
  PrivateData = @{
    PSData = @{
      Tags = @('github')
    } 
  }
}

