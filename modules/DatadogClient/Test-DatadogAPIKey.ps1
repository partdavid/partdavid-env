<#

.SYNOPSIS

Test whether the provided API key is valid

.DESCRIPTION

#>
function Test-DatadogAPIKey {
  [CmdletBinding()]
  param(
    [string]$APIKey,
    [string]$Site
  )

  $opt = @{}

  if ($APIKey) {
    $opt['APIKey'] = $APIKey
  }
  if ($Site) {
    $opt['Site'] = $Site
  }

  invoke-DatadogAPI -Path /validate @opt
}
