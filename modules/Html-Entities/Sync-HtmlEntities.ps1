<#

.SYNOPSIS

Download the latest authoritative list of standard HTML 5 entities

.DESCRIPTION

This command downloads the list of HTML 5 entities from the W3C
(or alternative URL), converts that input file into its own
format and stores it in the standard location (an alternate location
can be specified, but then the other commands in this suite will
also need the have this location passed).

#>
function Sync-HtmlEntities {
  [CmdletBinding()]
  param(
    $Url = 'https://raw.githubusercontent.com/valievkarim/html5-entities/master/HTMLEntityNames.in',
    $StandardEntityLocation = '~/.config/html-entities/standard.csv'
  )

  New-Item -Type Directory -Path (Split-Path $StandardEntityLocation) -ErrorAction SilentlyContinue
  Invoke-WebRequest -Uri $Url -Outfile $StandardEntityLocation
}

