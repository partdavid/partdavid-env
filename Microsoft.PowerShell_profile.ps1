$local_modules = Join-Path (Split-Path -Path $profile) 'Modules'
if (Test-Path -Path $local_modules) {
  $Env:PSModulePath += '{0}{1}' -f [IO.Path]::PathSeparator,$local_modules
}

foreach ($mod in 'posh-git','powershell-yaml') {
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

  if ($Env:CURRENT_CONTEXT -ne $null) {
    $position += "$Env:CURRENT_CONTEXT ".length
    # I want to keep track of the position, so I don't use Write-CurrentContext here
    Write-Host "$Env:CURRENT_CONTEXT " -ForegroundColor $global:context_color -NoNewLine
  }

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

# Hack until I add a .ps1 version for rbenv/pyenv shell support
Remove-Alias -Name rbenv -ErrorAction ignore
$RBENV_EXE = (Get-Command rbenv -ErrorAction ignore).source

Remove-Alias -Name pyenv -ErrorAction ignore
$PYENV_EXE = (Get-Command pyenv -ErrorAction ignore).source

Function Invoke-Rbenv {
  [CmdletBinding()]
  Param(
    [parameter(mandatory=$false, position=0, ValueFromRemainingArguments=$true)] $Remaining
  )

  if ($Remaining -ne $Null -and $Remaining[0] -in 'shell') {
    if ($Remaining[1]) {
      if ($Remaining[1] -match '--unset') {
        Remove-Item -Path Env:RBENV_VERSION -ErrorAction ignore
      } else {
        $Env:RBENV_VERSION = $Remaining[1]
      }
    } else {
      if (Test-Path Env:RBENV_VERSION) {
        Write-Output $Env:RBENV_VERSION
      } else {
        Write-Output "rbenv: no shell version configured for this session"
      }
    }
  } else {
    & $RBENV_EXE @Remaining
  }
}

# TODO: implement this kind of thing as a closure
Function Invoke-Pyenv {
  [CmdletBinding()]
  Param(
    [parameter(mandatory=$false, position=0, ValueFromRemainingArguments=$true)] $Remaining
  )

  if ($Remaining -ne $Null -and $Remaining[0] -in 'shell') {
    if ($Remaining[1]) {
      if ($Remaining[1] -match '--unset') {
        Remove-Item -Path Env:PYENV_VERSION -ErrorAction ignore
      } else {
        $Env:PYENV_VERSION = $Remaining[1]
      }
    } else {
      if (Test-Path Env:PYENV_VERSION) {
        Write-Output $Env:PYENV_VERSION
      } else {
        Write-Output "pyenv: no shell version configured for this session"
      }
    }
  } else {
    & $PYENV_EXE @Remaining
  }
}

Set-Alias -Name rbenv -Value Invoke-Rbenv
Set-Alias -Name pyenv -Value Invoke-Pyenv

