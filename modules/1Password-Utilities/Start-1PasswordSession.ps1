<#

.SYNOPSIS

Start a 1Password session using the op command.

#>
function Start-1PasswordSession {
  $env:OP_SESSION_bear_run = op signin --raw
}
