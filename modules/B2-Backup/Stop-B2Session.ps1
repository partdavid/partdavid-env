<#
.SYNOPSIS

Stop the current Backblaze backup session

.DESCRIPTION

Removes credentials from the session.

#>
function Stop-B2Session {
  [CmdletBinding()]param()

  Remove-Variable -Scope global -Name B2Parameters -ErrorAction SilentlyContinue
}
