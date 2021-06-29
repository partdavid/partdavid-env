function Enter-Context {
  [CmdletBinding()]

  Param(
    [Parameter(Mandatory=$True, Position=0)] [String]$Context
  )

  $config = Get-ContextConfiguration -Context $Context

  $Env:CURRENT_CONTEXT = $Context
  $global:context_color = 'Gray'
    
  if ($config.color -ne $Null) {
    $global:context_color = $config.color
  }
      
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
