$local_modules = Join-Path (Split-Path -Path $profile) 'Modules'
if (Test-Path -Path $local_modules) {
  $Env:PSModulePath += '{0}{1}' -f [IO.Path]::PathSeparator,$local_modules
}

foreach ($mod in 'posh-git','powershell-yaml','Microsoft.Powershell.SecretManagement') {
  if (Get-Module -Name $mod -ListAvailable) {
    Import-Module $mod
  } else {
    Install-Module $mod
    Import-Module $mod
  }
}

# Always available because built-in or I installed it.
Import-Module PSReadLine
Import-Module Shell-Contexts
Import-Module Countdown

# Dvorak key mappings for vi command-line editing
Set-PSReadLineOption -EditMode Vi
Set-PSReadLineKeyHandler -Key 'h' -Function BackwardChar -ViMode Command
Set-PSReadLineKeyHandler -Key 't' -Function NextHistory -ViMode Command
Set-PSReadLineKeyHandler -Key 'n' -Function PreviousHistory -ViMode Command
Set-PSReadLineKeyHandler -Key 's' -Function ForwardChar -ViMode Command

# Bash-style tab completion
Set-PSReadlineKeyHandler -Key Tab -Function Complete

Set-Alias use Set-CurrentContext

if ($IsWindows) {
  $env:HOSTNAME = $env:COMPUTERNAME
} else {
  $env:HOSTNAME = uname -n
  $env:USER_ID = id -u
}

# Standard path stuff, less standard things should maybe go in $utilities
if (Test-Path /opt/homebrew/bin/brew) {
  & /opt/homebrew/bin/brew shellenv | Invoke-Expression
}
foreach ($dir in '/usr/local/bin',"${HOME}/bin") {
  Add-PathDirectory $dir
}

# The version of this file produces a broken asdf function
# $asdf_env = "$(brew --prefix asdf)/libexec/asdf.ps1"
# if (Test-Path $asdf_env) {
#   . $asdf_env
# }
$Env:ASDF_DIR = "$(brew --prefix asdf)/libexec"
if (Test-Path "$($Env:ASDF_DIR)/bin") {
  Add-PathDirectory "$($Env:ASDF_DIR)/bin"
  if ($null -eq $Env:ASDF_DATA_DIR -or $Env:ASDF_DATA_DIR -eq '') {
    $_asdf_shims = "${Env:HOME}/.asdf/shims"
  } else {
    $_asdf_shims = "$($Env:ASDF_DATA_DIR)/shims"
  }
  Add-PathDirectory $_asdf_shims
  Remove-Variable -Force _asdf_shims -ErrorAction SilentlyContinue

  # I would do this with a conforming advanced function (Invoke-ASDF
  # and an alias) but this should be removed when the upstream
  # is fixed and it will work the same way.
  function asdf {
    $asdf = Get-Command -CommandType Application asdf | Select-Object -First 1 -ExpandProperty Source
    if ($args.Count -gt 0 -and $args[0] -eq 'shell') {
      Invoke-Expression $(& $asdf 'export-shell-version' pwsh $args[1..($args.Count + -1)])
    }
    else {
      & $asdf $args
    }
  }

  # Maybe put some code in $utilities for the plugins you like
}

$utilities = Join-Path $HOME -ChildPath '.pwsh_hosts' -AdditionalChildPath "$($env:HOSTNAME).ps1"

if (Test-Path -Path $utilities) {
  . $utilities
}


$babylonian = Join-Path (Split-Path $profile) 'ConvertTo-Babylonian.ps1'
if (Test-Path -Path $babylonian) {
  . $babylonian
}

Function prompt {
  $realDollarQuestion = $?
  $realLASTEXITCODE = $LASTEXITCODE

  # Reset color, which can be messed up by Enable-GitColors
  # $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor

  $width = (Get-Host).UI.RawUI.WindowSize.Width
  $position = 0

  if ($IsWindows) {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $me = $user.Name
  } else {
    $host_name = $Env:HOSTNAME
    $user_name = $Env:USER
    $me = "$host_name\$Env:USER"
  }

  $gitstatus = Get-GitStatus

  $position += Write-CurrentContext

  Write-Host "$me" -NoNewLine
  $position += $me.length

  if ($gitstatus -ne $null) {
    Write-Host " [" -NoNewLine
    $position += " [".length

    # Git
    if ($gitstatus -ne $null) {
      $prev = $true
      if ($gitstatus.Branch -in "main", "trunk", "master") {
        $color = "Red"
      } else {
        $color = "Green"
      }
      Write-Host $gitstatus.Branch -ForegroundColor $color -NoNewLine
      $position += $gitstatus.Branch.length
    }

    Write-Host "]" -NoNewLine
    $position += "]".length
  }


  if ($IsWindows) {
    $acl = Get-Acl $pwd
    if ($acl.Owner -eq $user.Name) {
      $color = "Green"
    } else {
      $color = "Cyan"
    }
  } else {
    $owner_id = stat -f '%u' $pwd
    if ($owner_id -eq $Env:USER_ID) {
      $color = "Green"
    } else {
      $color = "Cyan"
    }
  }
  $path = $pwd -replace [Regex]::Escape($HOME), "~"

  if ($position + $path.length -ge $width - 1) {
    Write-Host `u{23ce}
    $position = 0
  } else {
    Write-Host " " -NoNewLine
    $position += " ".length
  }

  Write-Host -ForegroundColor $color -NoNewline $path
  $position += $path.length

  if ($position -gt $width * 0.75) {
    Write-Host `u{23ce}
    $position = 0
  }
  
  if ((-not $realDollarQuestion)) {
    if (Get-Command ConvertTo-Babylonian -ErrorAction Ignore) {
      $errstr = ConvertTo-Babylonian $realLASTEXITCODE
    } else {
      $errstr = $realLASTEXITCODE.ToString()
    }
    Write-Host -ForegroundColor Red -NoNewLine " $errstr "
  }

  $global:LASTEXITCODE = $realLASTEXITCODE
  return "> "
}
Set-Alias rn Rename-Item

$env:EDITOR = 'editor'
