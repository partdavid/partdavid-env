function Exit-Context {
  [CmdletBinding()]

  Param(
    [Parameter(Mandatory=$True, Position=0)] [String]$Context
  )

  $config = Get-ContextConfiguration -Context $Context

  if ($Env:CURRENT_CONTEXT -eq $Context) {
    Remove-Item -Path Env:CURRENT_CONTEXT
  } else {
    Write-Warning "Exiting non-current context $Context (current context is $Env:CURRENT_CONTEXT)--context is probably corrupt"
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
