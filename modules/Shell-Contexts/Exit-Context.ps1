function Exit-Context {
  [CmdletBinding()]

  Param(
    [Parameter(Mandatory=$True, Position=0)] [String]$Context
  )

  Write-Debug "Exiting context: $Context"

  $config = Get-ContextConfiguration -Context $Context

  Write-Debug "(before) `$Env:CURRENT_CONTEXT = $($Env:CURRENT_CONTEXT)"
  $existing_stack = $Env:CURRENT_CONTEXT -split ',' | ?{ $_ }
  if ($existing_stack -contains $Context) {
    $stack = $existing_stack | ?{ $_ -ne $Context }
    if ($stack) {
      $stack -join ',' | Set-Content Env:CURRENT_CONTEXT
      Write-Debug "(after) `$Env:CURRENT_CONTEXT = $($Env:CURRENT_CONTEXT)"
    } else {
      Remove-Item Env:CURRENT_CONTEXT
    }
  } else {
    Write-Warning "Exiting non-current context $Context (current contexts are $Env:CURRENT_CONTEXT)--context is probably corrupt"
  }

  if ($config.exit -ne $null) {
    foreach ($cmd in $config.exit) {
      Invoke-Expression -Command $cmd
    }
  }

  if ($config.env -ne $null) {
    foreach ($var in $config.env.keys) {
      Remove-Item -Path Env:$var -errorAction ignore
    }
  }

  if ($config.globals -ne $null) {
    foreach ($var in $config.globals.keys) {
      Remove-Variable -Name $var -errorAction ignore -Scope global
    }
  }
      
  if ($config.path -ne $null) {
    foreach ($dir in $config.path) {
      Remove-PathDirectory -Name $dir
    }
  }
}
