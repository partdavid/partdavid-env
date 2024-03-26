<#

.SYNOPSIS

Add a user-defined entity to the database.

.DESCRIPTION

This script allows you to add your own "HTML entity" that you can access
with the HTML entity syntax and which will be expanded by invocations of
Expand-HtmlEntity. It's kept separate from the standard list of entities
from the W3C and won't be overwritten when that list is synchronized
with the Sync-HtmlEntities command.

#>
function Add-UserHtmlEntity {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)] [string]$Code,
    [Parameter(Mandatory, Position=1)] [int[]]$Value,
    [string]$UserEntityLocation = '~/.config/html-entities/user.csv'
  )

  if (Test-Path $UserEntityLocation) {
    $entities = @(Get-Content $UserEntityLocation | ConvertFrom-Csv -Header Name,Value)
  } else {
    $entities = @()
  }

  $entities += @(@{Name="$($Code -replace ';$');";Value=(($Value | %{ 'U+{0:X6}' -f $_ }) -join ' ')})

  write-debug ($entities | convertto-json -compress)

  $entities | ConvertTo-Csv -NoHeader | Set-Content $UserEntityLocation
}

Set-Alias Add-HtmlEntity Add-UserHtmlEntity

