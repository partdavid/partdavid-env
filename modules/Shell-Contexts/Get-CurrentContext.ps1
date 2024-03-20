<#
.SYNOPSIS

Get the current context as an array

.DESCRIPTION

Return the current contexts as a string. Return the colors of the
current contexts when the -Color switch is given.
#>
function Get-CurrentContext {
  [CmdletBinding()]
  Param(
    [Parameter()] [Switch]$Color
  )
  if ($Color) {
    $Env:CURRENT_CONTEXT -split ',' | ?{ $_ } | %{
      $cfg = Get-ContextConfiguration -Context
      $cfg.color ?? 'gray'
    }
  } else {
    $Env:CURRENT_CONTEXT -split ',' | ?{ $_ }
  }
}
