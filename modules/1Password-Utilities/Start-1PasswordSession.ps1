<#

.SYNOPSIS

Start a 1Password session using the op command.

.DESCRIPTION

This command works with both manually-added accounts, as well
as environments where you have enabled 1password app integration
(where you signin by unlocking the app).

#>
function Start-1PasswordSession {
  [CmdletBinding(SupportsShouldProcess)]

  param(
    [string[]]$Accounts
  )

  $spec = @{}
  op account list --format json | ConvertFrom-Json | %{
    # Integrated CLI authentication doesn't use the 'shorthand'
    # field, only manual accounts.
    $shorthand = $_.shorthand ?? (($_.url -replace '\.1password\.com') -replace '-','_')
    $spec[$shorthand] = $_
  }
  if ($Accounts.Length -eq 0) {
    $Accounts = $spec.Keys
  }
  foreach ($account in $Accounts) {
    if ($PSCmdlet.ShouldProcess($account, "op signin")) {
      op signin --account $spec[$account].user_uuid --raw | Set-Content Env:"OP_SESSION_$($spec[$account].user_uuid)"
    }
  }
}
