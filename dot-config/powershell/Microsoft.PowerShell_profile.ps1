Import-Module posh-git
Import-Module PSReadLine
Import-Module powershell-yaml

# Dvorak key mappings for vi command-line editing
Set-PSReadLineOption -EditMode Vi
Set-PSReadLineKeyHandler -Key 'h' -Function BackwardChar -ViMode Command
Set-PSReadLineKeyHandler -Key 't' -Function NextHistory -ViMode Command
Set-PSReadLineKeyHandler -Key 'n' -Function PreviousHistory -ViMode Command
Set-PSReadLineKeyHandler -Key 's' -Function ForwardChar -ViMode Command

# Bash-style tab completion
Set-PSReadlineKeyHandler -Key Tab -Function Complete


Function Set-CurrentContext {
  <#
.SYNOPSIS

Automatically switch to (or from) a command-line context

.DESCRIPTION

You can use this advanced function to set your current "context",
which can be displayed in your prompt (see prompt(), following) and
automatically set/unset related environment variables, and run
commands upon "entry" and "exit" from the context. It works best when
the prompt() function consults the $Env:CURRENT_CONTEXT variable and
$global:context_color variable to display the context. These variables
are always set by Set-CurrentContext.

Contexts are defined in the ~/.contexts.yaml file. The YAML document consists
of a mapping, the keys of which are the named context. Each context can have
the following keys:

color

  The color that the environment should have when appearing in the prompt. The
  valid colors are those you can pass to Write-Host's -ForegroundColor
  parameter. If not set, it will be colored gray.

env

  A mapping of environment variables to values. Set-CurrentContext will set
  each environment variable to the given value. When switching out of the
  environment, Set-CurrentContext will remove the variables from the environment.

entry

  A sequence of strings, which will be evaluated as commands using
  Invoke-Expression when switching into the context.

exit
  A sequence of strings, which will be evaluated as commands using
  Invoke-Expression when switching out of the context.

.PARAMETER NewContext

This is the name of the context (usually defined in ~/contexts.yaml) to
switch to. It can be left blank, in which Set-CurrentContext will switch
out of the current context but won't apply a new one. It also doesn't
have to be defined in ~/contexts.yaml; but if it's not, Set-CurrentContext
will simply set the CURRENT_CONTEXT environment variable and take no
other action.

.INPUTS

None: Set-CurrentContext does not read from a pipeline.

.EXAMPLE

Example ~/.contexts.yaml

  ---
  prod:
    color: red
    env:
      AWS_PROFILE: contoso-production
    entry:
      - kubectl use-context web-cluster-1

#>

  [CmdletBinding()]

  Param(
    [parameter(mandatory=$false, position=0)] [String]$NewContext
  )

  if (Test-Path -Path ~/.contexts.yaml) {
    $contexts = Get-Content -Raw ~/.contexts.yaml | ConvertFrom-Yaml
  } else {
    $contexts = @{}
  }

  $PSDefaultParameterValues.Remove("Invoke-Restmethod:Headers")

  if ($Env:CURRENT_CONTEXT -ne $null) {
    $OldContext = $Env:CURRENT_CONTEXT
    Remove-Item -Path Env:CURRENT_CONTEXT
    if ($contexts[$OldContext].env -ne $null) {
      foreach ($var in $contexts[$OldContext].env.keys) {
        Remove-Item -Path Env:$var -errorAction ignore
      }
    }

    if ($contexts[$OldContext].exit -ne $null) {
      foreach ($cmd in $contexts[$OldContext].exit) {
        Invoke-Expression -Command $cmd
      }
    }
  
  }

  if ($NewContext -ne $null) {
    $Env:CURRENT_CONTEXT = $NewContext
    $global:context_color = 'Gray'
    
    if ($contexts[$NewContext] -ne $null) {
      if ($contexts[$NewContext].color -ne $null) {
        $global:context_color = $contexts[$NewContext].color
      }
      
      if ($contexts[$NewContext].env -ne $null) {
        foreach ($var in $contexts[$NewContext].env.keys) {
          Set-Content -Path Env:$var -Value $contexts[$NewContext].env[$var]
          }
      }
      
      if ($contexts[$NewContext].entry -ne $null) {
        foreach ($cmd in $contexts[$NewContext].entry) {
          Invoke-Expression -Command $cmd
        }
      }
    
    }
  }

}

Set-Alias use Set-CurrentContext

$utilities = Join-Path (Split-Path $profile) 'utilities.ps1'

if (Test-Path -Path $utilities) {
  . $utilities
}

Function prompt {
  $lastsuccess = $?
  $realLASTEXITCODE = $LASTEXITCODE

  # Reset color, which can be messed up by Enable-GitColors
  # $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor

  # $chef_qualifier = "`u{}"
  # $gcloud_qualifier = "`u{}"
  # $aws_qualifier = "`u{}"
  # $az_qualifier = "`u{}"

  $host_name = uname -n
  $user_id = id -u
  $gitstatus = Get-GitStatus
  # $chef_org = $Env:CHEF_ORG
  # $aws_profile = $Env:AWS_PROFILE
  # $gcloud_config = try {
  #   Get-Content ~/.config/gcloud/active_config -Raw -ErrorAction stop
  # }
  # catch { $null }

  if ($Env:CURRENT_CONTEXT -ne $null) {
    Write-Host "$Env:CURRENT_CONTEXT " -ForegroundColor $global:context_color -NoNewLine
  }

  Write-Host "$host_name\$Env:USER" -NoNewLine
  if ($gitstatus -ne $null) {
    Write-Host " [" -NoNewLine

    # Git
    if ($gitstatus -ne $null) {
      $prev = $true
      if ($gitstatus.Branch -eq "master") {
        $color = "Red"
      } else {
        $color = "Green"
      }
      Write-Host $gitstatus.Branch -ForegroundColor $color -NoNewLine
    }

    Write-Host "]" -NoNewLine
  }

  # For consistency with the Windows-based profile, I'm just doing owner/not-owner
  # here, because on Windows file permissions are more complicated. I haven't figured
  # out how to make this portable yet.
  Write-Host " " -NoNewLine
  $owner_id = stat -f '%u' $pwd
  if ($owner_id -eq $user_id) {
    $color = "Green"
  } else {
    $color = "Cyan"
  }
  $path = $pwd -replace [Regex]::Escape($HOME), "~"
  Write-Host -ForegroundColor $color -NoNewline $path

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

  if ($Remaining[0] -in 'shell') {
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

  if ($Remaining[0] -in 'shell') {
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
