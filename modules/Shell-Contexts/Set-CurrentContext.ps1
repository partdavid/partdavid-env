<#
.SYNOPSIS

Automatically switch to (or from) a command-line context

.DESCRIPTION

You can use this advanced function to set your current "context",
which can be displayed in your prompt (see prompt(), following) and
automatically set/unset related environment variables, and run
commands upon "entry" and "exit" from the context. It works best when
the prompt() function consults the $Env:CURRENT_CONTEXT variable and
$global:context_color variable to display the context. These variables
are always set by Set-CurrentContext.

Contexts are defined in the ~/.contexts.yaml file. The YAML document consists
of a mapping, the keys of which are the named context. Each context can have
the following keys:

color

  The color that the environment should have when appearing in the prompt. The
  valid colors are those you can pass to Write-Host's -ForegroundColor
  parameter. If not set, it will be colored gray.

env

  A mapping of environment variables to values. Set-CurrentContext will set
  each environment variable to the given value. When switching out of the
  context, Set-CurrentContext will remove the variables from the environment.

globals

  A mapping of global variable names to values. Set-CurrentContext will set
  each global variable to the given value. When switching out of the
  context, Set-CurrentContext will remove the global variables.

path

  A list of directories to prepend to the $env:PATH variable. These
  directories will be removed when switching out of the context
  (wherever they appear in the $env:PATH variable).

entry

  A sequence of strings, which will be evaluated as commands using
  Invoke-Expression when switching into the context.

exit

  A sequence of strings, which will be evaluated as commands using
  Invoke-Expression when switching out of the context.

.PARAMETER NewContext

This is the name of the context (usually defined in ~/.contexts.yaml) to
switch to. It can be left blank, in which Set-CurrentContext will switch
out of the current context but won't apply a new one. It also doesn't
have to be defined in ~/contexts.yaml; but if it's not, Set-CurrentContext
will simply set the CURRENT_CONTEXT environment variable and take no
other action.

.INPUTS

None: Set-CurrentContext does not read from a pipeline.

.EXAMPLE

Example ~/.contexts.yaml

  ---
  prod:
    color: red
    env:
      AWS_PROFILE: contoso-production
    globals:
      StoredAWSCredential: contoso-production
    path:
      - /usr/dev-local/bin
    entry:
      - kubectl use-context web-cluster-1

#>
function Set-CurrentContext {
  [CmdletBinding()]

  Param(
    [parameter(mandatory=$false, position=0)] [String]$NewContext
  )

  if (Test-Path -Path ~/.contexts.yaml) {
    $contexts = Get-Content -Raw ~/.contexts.yaml | ConvertFrom-Yaml
  } else {
    $contexts = @{}
  }

  if ($Env:CURRENT_CONTEXT -ne $null) {

    $OldContext = $Env:CURRENT_CONTEXT
    Remove-Item -Path Env:CURRENT_CONTEXT

    if ($contexts[$OldContext] -ne $null) {
      if ($contexts[$OldContext].exit -ne $null) {
        foreach ($cmd in $contexts[$OldContext].exit) {
          Invoke-Expression -Command $cmd
        }
      }

      if ($contexts[$OldContext].env -ne $null) {
        foreach ($var in $contexts[$OldContext].env.keys) {
          Remove-Item -Path Env:$var -errorAction ignore
        }
      }

      if ($contexts[$OldContext].globals -ne $null) {
        foreach ($var in $contexts[$OldContext].globals.keys) {
          Remove-Variable -Name $var -errorAction ignore -Scope global
        }
      }
      
      if ($contexts[$OldContext].path -ne $null) {
        foreach ($dir in $contexts[$OldContext].path) {
          Remove-PathDirectory -Name $dir
        }
      }

    }
  }

  if ($NewContext -ne $null) {
    $Env:CURRENT_CONTEXT = $NewContext
    $global:context_color = 'Gray'
    
    if ($contexts[$NewContext] -ne $null) {
      if ($contexts[$NewContext].color -ne $null) {
        $global:context_color = $contexts[$NewContext].color
      }
      
      if ($contexts[$NewContext].env -ne $null) {
        foreach ($var in $contexts[$NewContext].env.keys) {
          Set-Content -Path Env:$var -Value $contexts[$NewContext].env[$var]
        }
      }

      if ($contexts[$NewContext].globals -ne $null) {
        foreach ($var in $contexts[$NewContext].globals.keys) {
          Set-Variable -Name $var -Value $contexts[$NewContext].globals[$var] -Scope global
        }
      }

      if ($contexts[$NewContext].path -ne $null) {
        foreach ($dir in $contexts[$NewContext].path) {
          Add-PathDirectory -Name $dir
        }
      }
      
      if ($contexts[$NewContext].entry -ne $null) {
        foreach ($cmd in $contexts[$NewContext].entry) {
          Invoke-Expression -Command $cmd
        }
      }
    
    }
  }
}
