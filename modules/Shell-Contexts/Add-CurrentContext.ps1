# Adds the specified context to the stack
function Add-CurrentContext {
  [CmdletBinding()]

  Param(
    [parameter(mandatory=$true, position=0)] [string[]]$NewContext
  )

  foreach ($ctx in $NewContext) {
    Enter-Context -Context $ctx
  }
}

