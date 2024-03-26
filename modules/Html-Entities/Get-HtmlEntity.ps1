<#

.SYNOPSIS

Look up an HTML entity code

.DESCRIPTION

Returns the actual character represented by the entity code passed
in (for example, if 'lt' is passed, returns '<'). Not usually used
on its own (use Expand-HtmlEntities instead).

#>
function Get-HtmlEntity {
  [CmdletBinding()]
  param(
    [string]$Code,
    [string]$UserEntityLocation = '~/.config/html-entities/user.csv',
    [string]$StandardEntityLocation = '~/.config/html-entities/standard.csv'
  )

  if ($Code.StartsWith('#x')) {
    Write-Debug "Numerical substitution of &# hexadecimal code ($Code)"
    [char][int]("0x" + $Code.Substring(2))
  } elseif ($Code.StartsWith('#')) {
    Write-Debug "Numerical substitution of &# decimal code ($Code)"
    [char][int]$Code.Substring(1)
  } else {
    Write-Debug "Symbolic substitution of & entity name ($Code)"
    if (Test-Path $UserEntityLocation) {
      Write-Debug "UserEntityLocation exists: $UserEntityLocation"
      if (-not $global:UserHtmlEntitiesTS -or (Test-Path $UserEntityLocation -OlderThan $global:UserHtmlEntitiesTS)) {
        Write-Debug "Re-caching UserHtmlEntities"
        $global:UserHtmlEntitiesTS = Get-Item $UserEntityLocation | Select-Object -ExpandProperty LastWriteTime
        $global:UserHtmlEntities = ConvertFrom-HtmlEntityCsv -EntityLocation $UserEntityLocation
      }
    }
    if (Test-Path $StandardEntityLocation) {
      Write-Debug "StandardEntityLocation exists: $StandardEntityLocation"
      if (-not $global:StandardHtmlEntitiesTS -or (Test-Path $StandardEntityLocation -OlderThan $global:StandardHtmlEntitiesTS)) {
        Write-Debug "Re-caching StandardHtmlEntities"
        $global:StandardHtmlEntitiesTS = Get-Item $StandardEntityLocation | Select-Object -ExpandProperty LastWriteTime
        $global:StandardHtmlEntities = ConvertFrom-HtmlEntityCsv -EntityLocation $StandardEntityLocation
      }
      if ($global:UserHtmlEntities -and $global:UserHtmlEntities[$Code]) {
        Write-Debug "Found user-defined code"
        $global:UserHtmlEntities[$Code]
      } elseif ($global:StandardHtmlEntities -and $global:StandardHtmlEntities[$Code]) {
        Write-Debug "Found standard code"
        $global:StandardHtmlEntities[$Code]
      } else {
        Write-Debug "Found nothing"
        ""
      }
    }
  }
}

