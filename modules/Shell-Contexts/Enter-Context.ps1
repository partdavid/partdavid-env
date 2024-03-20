function Enter-Context {
  [CmdletBinding()]

  Param(
    [Parameter(Mandatory=$True, Position=0)] [String]$Context
  )

  Write-Debug "Entering context: $Context"
  Write-Debug "(before) `$Env:CURRENT_CONTEXT = $Env:CURRENT_CONTEXT"

  $config = Get-ContextConfiguration -Context $Context

  [array]$contexts = $Env:CURRENT_CONTEXT -split ',' | ?{ $_ }
  $contexts += @($Context)
  $Env:CURRENT_CONTEXT = $contexts -join ','
  Write-Debug "(after) `$Env:CURRENT_CONTEXT = $Env:CURRENT_CONTEXT"
    
  if ($config.env -ne $null) {
    foreach ($var in $config.env.keys) {
      Set-Content -Path Env:$var -Value $config.env[$var]
    }
  }

  if ($config.globals -ne $null) {
    foreach ($var in $config.globals.keys) {
      Set-Variable -Name $var -Value $config.globals[$var] -Scope global
    }
  }

  if ($config.path -ne $null) {
    foreach ($dir in $config.path) {
      Add-PathDirectory -Name $dir
    }
  }
      
  if ($config.entry -ne $null) {
    foreach ($cmd in $config.entry) {
      Invoke-Expression -Command $cmd
    }
  }
}
