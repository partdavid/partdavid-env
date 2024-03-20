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
    $contexts = $Env:CURRENT_CONTEXT -split ',' | ?{ $_ }
    foreach ($ctx in $contexts) {
      $cfg = Get-ContextConfiguration -Context $ctx
      $color = $cfg.color ?? 'gray'
      if ($length -gt 0) {
        Write-Host ',' -NoNewLine
        $length += 1
      }
      Write-Host $ctx -ForegroundColor $color -NoNewLine
      $length += $ctx.length
    }

    if (-not $NoPadding) {
      Write-Host ' ' -NoNewLine
      $length += 1
    }
  }

  return $length
}
