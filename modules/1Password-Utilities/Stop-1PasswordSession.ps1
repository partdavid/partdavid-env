<#

.SYNOPSIS

End a 1Password session

#>
function Stop-1PasswordSession {
  Remove-Item Env:OP_SESSION_bear_run
}

