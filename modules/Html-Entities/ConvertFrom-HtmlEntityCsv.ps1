<#

.SYNOPSIS

Convert from the W3C input file format to CSV

.DESCRIPTION

The Expand-HtmlEntity command looks entity codes up in a CSV database which
is generated from the W3C documentation input file downloaded by Sync-HtmlEntities.
This is a utility command not normally needed by users.

#>
function ConvertFrom-HtmlEntityCsv {
  [CmdletBinding()]
  param(
    [string]$EntityLocation
  )

  $ret = @{}
  if (Test-Path $EntityLocation) {
    Get-Content $EntityLocation | ConvertFrom-Csv -Header Name,Value | %{
      $bvs = -split $_.Value | %{ [int]("0x" + $_.Substring(2)) }
      $ret[$_.Name -replace ';$'] = ($bvs | %{ [char]::ConvertFromUtf32($_) }) -join ''
    }
  } else {
    Write-Warning "No file $EntityLocation, conversion is empty"
  }
  $ret
}

