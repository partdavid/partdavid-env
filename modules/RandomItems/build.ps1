[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $Test,

    [Parameter()]
    [switch]
    $Package,

    [Parameter()]
    [switch]
    $Publish
)

Push-Location $PSScriptRoot

if ($Test) {
    Invoke-Pester tests
}

if ($Package) {
    $outDir = Join-Path 'release' 'RandomItems'
    Remove-Item release -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

    @(
      'RandomItems.psd1'
      'RandomItems.psm1'
      'Get-RandomIp.ps1'
      'Get-RandomDate.ps1'
      'New-RandomItem.ps1'
      'en-US'
      'README.md'
    ) | ForEach-Object {
        Copy-Item -Path $_ -Destination (Join-Path $outDir $_) -Force -Recurse
    }
}

if ($Publish) {
  Write-Host -ForegroundColor Green "Publishing module... here are the details:"
  $moduleData = Import-Module -Force ./release/RandomItems -PassThru
  Write-Host "Version: $($moduleData.Version)"
  Write-Host "Prerelease: $($moduleData.PrivateData.PSData.Prerelease)"
  Write-Host -ForegroundColor Green "Here we go..."
  Write-Error "Publishing not implemented"
}

Pop-Location
