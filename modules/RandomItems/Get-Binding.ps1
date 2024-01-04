<#
.SYNOPSIS

Returns a hashtable of variable bindings

.DESCRIPTION

This command returns a hashtable reflecting the specified variable
bindings. This command accepts Get-Variable parameters to
restrict the variables included. It's designed to be passed
to the -*Template parameters of New-RandomItem (since it always
uses -Safe mode for EPS template expansion).

By default, or if you pass the -Scope Global option, the command
returns a binding of global variables. This also happens automatically
when you invoke New-RandomItem without bindings. This works well
with the shell, but when invoking from a script you may need to
run Get-Variable yourself to capture variables in your local
or script scopes (Get-Binding does not accept Local or Script
as parameter values for -Scope, because its module scope cannot
read these scopes from the perspective of the caller), possibly
with -Include or -Exclude, and pipe the result to Get-Binding
(or pass the result to the -Vars parameter).

.LINK

Get-Variable
#>
function Get-Binding {
  [CmdletBinding(DefaultParameterSetName='Scope')]
  param(
    [Parameter(ParameterSetName='Scope')] [string[]]$Name,
    [Parameter(ParameterSetName='Scope')] [string[]]$Include,
    [Parameter(ParameterSetName='Scope')] [string[]]$Exclude,
    [Parameter(ParameterSetName='Scope')] [ValidateSet('Global')] [string]$Scope = 'Global',
    [Parameter(ValueFromPipeline, ParameterSetName='Vars')] [PSVariable[]]$Vars
  )

  begin {
    if ($PSCmdlet.ParameterSetName -eq 'Scope') {
      # We need to run Get-Variable
      $getVariableParameters = @{}

      foreach ($param in 'Name','Include','Exclude','Scope') {
        if ($PSBoundParameters.ContainsKey($param)) {
          $getVariableParameters[$param] = $PSBoundParameters[$param]
        }
      }

      $getVariableParameters['Exclude'] ??= @()
      $getVariableParameters['Exclude'] += 'Name','Include','Exclude','Scope','getVariableParameters','param','binding'

      $Vars = Get-Variable @getVariableParameters
    }
    $binding = @{}
  }

  process {
    $Vars | %{ $binding[$_.Name] = $_.Value }
  }

  end {
    $binding
  }
}
