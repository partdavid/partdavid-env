#!/usr/bin/env pwsh

function install-object {

  Param(
    [Parameter(mandatory=$true, position=0)] [String]$Destination,
    [parameter(mandatory=$false, position=1, ValueFromRemainingArguments=$true)] $Remaining
  )

  $copied = 0

  foreach ($from in @($Remaining)) {
    $to = Join-Path -Path $Destination -ChildPath ($from -replace 'dot-','.')
    $destdir = Split-Path $to

    Write-Host "Copying $from -> $to"

    if (-not (Test-Path -Path $destdir)) {
      New-Item -ItemType Directory -Force -Path $destdir
    }

    if (Test-Path -PathType Container -Path $from) {
      Remove-Item -Path $to -Recurse -Force -ErrorAction ignore
      Copy-Item -Path $from -Destination $to -Recurse
      $copied += 1
    } else {
      Remove-Item -Path $to -ErrorAction ignore
      Copy-Item -Path $from -Destination $to
      $copied += 1
    }
  }

}

if ($IsWindows) {
  $emacs_home = "${HOME}/AppData/Roaming"
  $powershell_config_dir = "${HOME}/Documents/PowerShell"
} else {
  $emacs_home = "${HOME}"
  $powershell_config_dir = "${HOME}/.config/powershell"
}

# emacs
install-object $emacs_home dot-emacs dot-viper emacs.d

# Copy other files
install-object $HOME dot-vimrc dot-inputrc bin

# Copy powershell profile
install-object $powershell_config_dir Microsoft.PowerShell_profile.ps1
install-object $powershell_config_dir ConvertTo-Babylonian.ps1

# Copy iTerm2 profile
if (! $IsWindows) {
  install-object "${HOME}" "./Library/Application Support/iTerm2/DynamicProfiles/partdavid-pwsh.json"
}

# Install Modules
$local_modules_dir = $env:PSModulePath.split([IO.Path]::PathSeparator).where({ $_ -match "$HOME*" }) | Select -First 1

foreach ($module_source_dir in (Get-ChildItem -Path modules)) {
  Remove-Item -Recurse -Force -Path (Join-Path -Path $local_modules_dir -ChildPath $module_source_dir.name) -ErrorAction Ignore
  Copy-Item -Recurse -Force -Path $module_source_dir.fullname -Destination $local_modules_dir
}

