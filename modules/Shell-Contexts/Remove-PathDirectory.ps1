<#
.SYNOPSIS

Remove a directory from the PATH or PATH-like item

.DESCRIPTION

Removes the specified directory from the PATH or the specified
PATH-like item.
#>
function Remove-PathDirectory {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, Position=0)] [String]$Name,
    [Parameter()] [String]$Item = 'Env:PATH'
  )

  $existing = Get-Content -Path $Item -ErrorAction SilentlyContinue
  if ($existing) {
    $existing.Split([IO.Path]::PathSeparator).Where({ $_ -ne $Name }) -join [IO.Path]::PathSeparator `
      | Set-Content -Path $Item
  }
}
