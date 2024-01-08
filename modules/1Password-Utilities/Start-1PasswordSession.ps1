<#

.SYNOPSIS

Start a 1Password session using the op command.

#>
function Start-1PasswordSession {
  [CmdletBinding(SupportsShouldProcess)]

  param(
    [string[]]$Accounts
  )

  $spec = @{}
  op account list --format json | ConvertFrom-Json | %{ $spec[$_.shorthand] = $_ }
  if ($Accounts.Length -eq 0) {
    $Accounts = $spec.Keys
  }
  foreach ($account in $Accounts) {
    if ($PSCmdlet.ShouldProcess($account, "op signin")) {
      op signin --account $account --raw | Set-Content Env:"OP_SESSION_$($spec[$account].user_uuid)"
    }
  }
}
