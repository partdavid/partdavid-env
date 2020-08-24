<#
.SYNOPSIS

Write the current context (in color) to the host, with a padding space, for the prompt

.DESCRIPTION

This writes out the current context, decorated with the context color, in a form suitable
for a prompt.

#>
function Write-CurrentContext {
  [CmdletBinding()]
  Param(
    [Parameter()] [Switch]$NoPadding
  )

  if ($Env:CURRENT_CONTEXT) {
    Write-Host "$Env:CURRENT_CONTEXT" -ForegroundColor $global:context_color -NoNewLine
  }

  if (-not $NoPadding) {
    Write-Host ' ' -NoNewLine
  }
}
