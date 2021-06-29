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

parent

  A single value identifying a context from which this one inherits
  the above values. Every context implicitly inherits from "_all",
  so if you define an "_all" context, its settings will apply
  to every context.

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

.EXAMPLE

Here's another example, a little more complicated:

  --
  _all:
    entry:
      - stty sane
  prod:
    color: red
    env:
      AWS_PROFILE: contoso-production
    entry:
      - kubectl use-context web-cluster-$AWS_DEFAULT_REGION
  prod-east:
    parent: prod
    env:
      AWS_DEFAULT_REGION: us-east-1
  prod-west:
    parent: prod
    env:
      AWS_DEFAULT_REGION: us-west-2

Since an "_all" section is defined, every context will run
the `stty sane` command when they're entered.

The "prod-east" context inherits from the "prod" context.
Note how you can use environment variables in entry/exit
commands.

#>
function Set-CurrentContext {
  [CmdletBinding()]

  Param(
    [parameter(mandatory=$false, position=0)] [String]$NewContext
  )

  if ($Env:CURRENT_CONTEXT -ne $null) {
    Exit-Context -Context $Env:CURRENT_CONTEXT
  }

  if ($NewContext -ne $null) {
    Enter-Context -Context $NewContext
  }
}
