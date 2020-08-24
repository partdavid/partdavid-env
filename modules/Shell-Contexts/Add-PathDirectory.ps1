<#
.SYNOPSIS

Add a directory to the PATH (or PATH-like) item

.DESCRIPTION

Correctly adds a directory to the search PATH (Env:PATH item, or the
one specified).
#>
function Add-PathDirectory {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, Position=0)] [String]$Name,
    [Parameter()] [String]$Item = 'Env:PATH'
  )

  $existing = Get-Content -Path $Item -ErrorAction SilentlyContinue
  if ($existing) {
    (@($Name) + ($existing -split [IO.Path]::PathSeparator).Where({ $_ -ne $Name })) -join [IO.Path]::PathSeparator | `
      Set-Content -Path $Item
  } else {
    Set-Content -Path $Item -Value $Name
  }
}
