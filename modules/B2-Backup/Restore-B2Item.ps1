function Restore-B2Item {
  [CmdletBinding()]
  param(
    [uri[]]$Item,
    [string]$Path,
    [switch]$Recurse
  )

  Get-B2Item -Recurse $Recurse -Item $Item
}

