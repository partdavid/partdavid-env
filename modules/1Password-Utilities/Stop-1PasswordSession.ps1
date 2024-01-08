<#

.SYNOPSIS

End a 1Password session

#>
function Stop-1PasswordSession {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [string[]]$Accounts
  )
  $by_var = @{}
  $by_shorthand = @{}
  op account list --format json | ConvertFrom-Json | `
    %{ $by_var["OP_SESSION_$($_.user_uuid)"] = $_; $by_shorthand[$_.shorthand] = $_ }
  if ($Accounts.Length -eq 0) {
    $Accounts = Get-ChildItem Env:OP_SESSION_* | %{ $by_var[$_.Name].shorthand ?? ($_.Name -replace '^OP_SESSION_')}
  }
  foreach ($account in $Accounts) {
    if ($PSCmdlet.ShouldProcess($account, 'sign out')) {
      Remove-Item Env:"OP_SESSION_$($by_shorthand[$account].user_uuid)" -Force -ErrorAction SilentlyContinue
      Remove-Item Env:"OP_SESSION_${account}" -Force -ErrorAction SilentlyContinue
    }
  }
}

