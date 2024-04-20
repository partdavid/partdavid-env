<#

.SYNOPSIS

Generically invoke Datadog API endpoints

.DESCRIPTION

#>

function Invoke-DatadogAPI {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory, Position=0)] [string]$Path,
    [ValidateSet('Get', 'Post', 'Head', 'Put', 'Delete')] [string]$Method = 'Get',
    [object]$Body,
    [hashtable]$Query,
    [string]$APIKey = $Env:DD_API_KEY ?? $Env:DATADOG_API_KEY,
    [string]$AppKey = $Env:DD_APP_KEY ?? $Env:DATADOG_APP_KEY,
    [string]$Site = ($Env:DD_SITE ? "app.$($Env:DD_SITE -replace '^app\.','')" : "app.datadoghq.com")
  )

  Write-Debug "Site=$Site"

  $urlb = New-Object System.UriBuilder -ArgumentList $Site
  $urlb.Scheme = 'https'
  $urlb.Port = 443
  $urlb.Path = Join-Path '/api/v1/' $Path
  $q = [System.Web.HttpUtility]::ParseQueryString('')
  if ($Query) {
    $Query.GetEnumerator() | %{ $q[$_.Key] = $_.Value }
  }
  $urlb.Query = $q.ToString()

  $headers = @{
    Accept = 'application/json'
  }

  if ($APIKey) {
    $headers['DD-API-KEY'] = $APIKey
  }

  if ($AppKey) {
    $headers['DD-APP-KEY'] = $AppKey
  }

  $opt = @{
    Method = $Method
    Uri = $urlb.Uri
    Headers = $headers
  }

  if ($Body) {
    $opt['Body'] = $Body
  }

  Write-Debug ($opt | ConvertTo-Json -Compress)

  Invoke-RestMethod @opt -SkipHttpErrorCheck
}
