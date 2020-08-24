<#
.SYNOPSIS

Get the current context as a string

.DESCRIPTION

Return the current context as a string. Return the color of the
current context when the -Color switch is given.
#>
function Get-CurrentContext {
  [CmdletBinding()]
  Param(
    [Parameter()] [Switch]$Color
  )
  if ($Color) {
    $global:context_color
  } else {
    $Env:CURRENT_CONTEXT
  }
}
