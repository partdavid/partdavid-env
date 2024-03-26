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
Set-Alias add Add-CurrentContext
Set-Alias leave Remove-CurrentContext

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

# Temporary--doesn't work quite right
Function Format-String {
  [CmdletBinding(DefaultParameterSetName = 'Width')]
  param(
    [Parameter(Mandatory, Position=1, ParameterSetName = 'Width')] [ValidateRange('Positive')] [int]$Width,
    [Parameter(ParameterSetName = 'Width')] [int]$MinTrailing = 3,
    [Parameter(ParameterSetName = 'Width')] [int]$MinLeading = 3,
    [Parameter(Mandatory, Position=0, ValueFromPipeline)] [string]$String,
    [string]$Ellipsis = "`u{2026}",
    [switch]$Force = $False
  )

  process {
    if ($Width) {
      if ($String.Length -le $Width) {
        Write-Output $String
      } elseif ($String.Length -gt ($MinTrailing.Length + $Ellipsis.Length + $MinTrailing.Length)) {
        Write-Output ($String.Substring(0, ($Width - ($Ellipsis.Length + $MinTrailing.Length + 2))) + $Ellipsis + `
          $String.Substring(($String.Length - $MinTrailing), $MinTrailing))
      } elseif ($Force) {
        if ($Ellipsis.Length -ge $Width) {
          Write-Output $Ellipsis.Substring(0, $Width)
        } else {
          # $deficit is the number of characters we have to eat into our minimums
          # and the priority is like this: 
          # Width  MinLeading MinTrailing Ellispsis.Length Deficit Leading Trailing
          #     7           3           3                1       0       3        3
          #     6           3           3                1       1       3        2
          #     5           3           3                1       2       2        2
          #     4           3           3                1       3       2        1
          #     3           3           3                1       4       1        1
          #     2           3           3                1       5       1        0
          #     1           3           3                1       6       0        0
          $deficit = ($MinLeading + $Ellipsis.Length + $MinTrailing) - $Width
          $trailing = $MinTrailing - [math]::ceiling($deficit / 2)
          $leading = $MinLeading - [math]::floor($deficit / 2)
          Write-Output ($String.Substring(0, $leading) + $Ellipsis + $String.Substring($String.Length - $trailing, $trailing))
        }
      } else {
        Write-Output ($String.Substring(0, $MinLeading) + $Ellipsis + $String.Substring($String.Length - $MinTrailing, $MinTrailing))
      }
    }
  }
}


function prompt {
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
    $host_name = $Env:HOSTNAME -replace '.local$'
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
      # Make configurable
      if ($gitstatus.Branch -in "main", "trunk", "master") {
        $color = "Red"
      } else {
        $color = "Green"
      }
      $branch = Format-String -Width 25 -String $gitstatus.Branch
      Write-Host $branch -ForegroundColor $color -NoNewLine
      $position += $branch.length
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

# Aliases
Set-Alias rn Rename-Item
Set-Alias cfj ConvertFrom-Json
Set-Alias ctj ConvertTo-Json
Set-Alias cfy ConvertFrom-Yaml
Set-Alias cty ConvertTo-Yaml
Set-Alias -Name sco -Value Select-Object
Set-Alias -Name wrh -Value Write-Host
Set-Alias -Name so -Value Sort-Object
Set-Alias -Name sc -Value Set-Content
Set-Alias -Name to -Value Tee-Object



$env:EDITOR = 'editor'
