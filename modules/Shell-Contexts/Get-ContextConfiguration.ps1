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
    @{}
  } else {

    $config
  }
}

function Expand-Context {
  [CmdletBinding()]

  Param(
    [Parameter(Mandatory=$True)] [HashTable]$Contexts,
    [Parameter(Mandatory=$True)] [HashTable]$Context
    [Parameter(Mandatory=$True)] [String]$ContextName
  )

  $MyContext = $Context.Clone()

  if ($MyContext.parent -ne $Null) {
    $Parent = $Contexts[$MyContext.parent]
    if ($Parent -eq $Null) {
      Write-Warning "The parent of $ContextName is $($MyContext.parent), but that isn't defined"
    } else {
      # The Hash-like attribute groups are env and globals
      foreach ($attrgroup in 'env','globals') {
      if ($Parent[$attrgroup])
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

      foreach ($attrgroup in 'path','entry') {
        if ($Parent[$attrgroup]) {
          if (-not $MyContext[$attrgroup]

    env
    globals
    path
    entry
