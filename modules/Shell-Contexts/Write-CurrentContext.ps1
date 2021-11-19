<#
.SYNOPSIS

Write the current context (in color) to the host, with a padding space, for the prompt

.DESCRIPTION

This writes out the current context, decorated with the context color, in a form suitable
for a prompt. It returns the number of characters written (in case you're keepin track
of the prompt length for wrapping logic, for example).

#>
function Write-CurrentContext {
  [CmdletBinding()]
  Param(
    [Parameter()] [Switch]$NoPadding
  )

  $length = 0

  if ($Env:CURRENT_CONTEXT) {
    Write-Host "$Env:CURRENT_CONTEXT" -ForegroundColor $global:context_color -NoNewLine
    $length += $Env:CURRENT_CONTEXT.length

    if (-not $NoPadding) {
      Write-Host ' ' -NoNewLine
      $length += 1
    }
  }

  return $length
}
