<#
.SYNOPSIS

Get a description of a context from the configuration file

.DESCRIPTION

Produces a Hashtable with a context specification, by reading
the appropriate shell contexts configuration file and expanding
any inherited-from contexts.

.PARAMETER Context

The name of the context to retrieve.

.PARAMETER ConfigurationFile

The identity of the YAML configuration file to read.

#>
function Get-ContextConfiguration {
  [CmdletBinding()]

  Param(
    [Parameter(Mandatory=$True)] [String]$Context,
    [Parameter(Mandatory=$False)] [String[]]$ConfigurationFile = ('~/.config/shell-contexts/contexts.yaml','~/.contexts.yaml')
  )

  foreach ($file in @($ConfigurationFile)) {
    if (Test-Path -Path $file) {
      $contexts = Get-Content -Raw $file | ConvertFrom-Yaml
      $config = $contexts[$Context]
    }
  }

  if ($config -eq $Null) {
    $config = @{}
  }

  if ($config.parent -eq $Null) {
    $config.parent = '_all'
  }

  $config = Expand-Context -Contexts $contexts -Context $config -ContextName $Context

  $config
}

function Expand-Context {
  [CmdletBinding()]

  Param(
    [Parameter(Mandatory=$True)] [HashTable]$Contexts,
    [Parameter(Mandatory=$True)] [HashTable]$Context,
    [Parameter(Mandatory=$True)] [String]$ContextName
  )

  if ($ContextName -eq '_all') {
    return $Context
  }

  $MyContext = $Context.Clone()

  if ($MyContext.parent -ne $Null) {
    if ($Contexts.ContainsKey($MyContext.parent)) {
      $Parent = Expand-Context -Contexts $Contexts -Context $Contexts[$MyContext.parent] -ContextName $MyContext.parent
      # The Hash-like attribute groups are env and globals
      foreach ($attrgroup in 'env','globals') {
        if ($Parent[$attrgroup]) {
          if (-not $MyContext[$attrgroup]) {
            $MyContext[$attrgroup] = $Parent[$attrgroup].Clone()
          } else {
            foreach ($var in $Parent[$attrgroup].keys) {
              if (-not $MyContext[$attrgroup].ContainsKey($var)) {
                $MyContext[$attrgroup][$var] = $Parent[$attrgroup][$var]
              }
            }
          }
        }
      }

      # The Array-like attribute groups are path, entry and exit
      foreach ($attrgroup in 'path','entry','exit') {
        if ($Parent[$attrgroup]) {
          if (-not $MyContext[$attrgroup]) {
            $MyContext[$attrgroup] = @()
          }
          foreach ($entry in [array]::Reverse($Parent[$attrgroup])) {
            if ($MyContext[$attrgroup] -notcontains $entry) {
              $MyContext[$attrgroup] = @($entry) + $MyContext[$attrgroup]
            }
          }
        }
      }
      
      # The scalar attribute groups are color
      foreach ($attrgroup in ,'color') {
        if ($Parent[$attrgroup]) {
          $MyContext[$attrgroup] = $Parent[$attrgroup]
        }
      }
    } else {
      # It's okay if _all isn't defined
      if ($MyContext.parent -ne '_all') {
        Write-Warning "The parent of $ContextName is $($MyContext.parent), but that isn't defined"
      }
    }
  }
  $MyContext
}
