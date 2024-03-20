# Pops the 'top' context off the stack and leaves it
function Remove-CurrentContext {
  [CmdletBinding()]

  Param(
    [parameter(mandatory=$false, position=0)] [string[]]$Context
  )

  if (-not $Context) {
    $existing_stack = $env:CURRENT_CONTEXT -split ',' | ?{ $_ }
    if ($existing_stack) {
      $Context = @($existing_stack[-1])
    }
  }

  if ($Context) {
    [array]::Reverse($Context)
    foreach ($ctx in $Context) {
      Exit-Context -Context $ctx
    }
  }
}
