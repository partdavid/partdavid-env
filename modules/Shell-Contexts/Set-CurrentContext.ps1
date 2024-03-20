<#
.SYNOPSIS

Automatically switch to (or from) a command-line context

.DESCRIPTION

You can use this advanced function to set your current "context",
which can be displayed in your prompt (see prompt(), following) and
automatically set/unset related environment variables, and run
commands upon "entry" and "exit" from the context. It works best when
the prompt() function uses the Write-CurrentContext cmdlet to write
it into the prompt.

I suggest making "use" an alias for this Cmdlet (see below for
other suggested aliases).

It's simplest to understand if you just 'use' one context at a time.
However, you can actually pass multiple contexts to this command,
or use the Add-CurrentContext and Remove-CurrentContext cmdlets
to add contexts. For example, you may have 'dev', 'stage' and 'prod'
contexts to interact with yor clusters in those environments, and
you may have 'gh' and 'hg' contexts to interact with two source
code control systems. You can do "Set-CurrentContext gh,prod" to
use the gh and prod contexts simultaneously. It's up to you to make
sure the contexts are miscible in this way.

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
  Invoke-Expression when switching into the context. See note on
  Variable Scope, below.

exit

  A sequence of strings, which will be evaluated as commands using
  Invoke-Expression when switching out of the context. See note on
  Variable Scope, below.

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

.PARAMETER ListOnly

Set this parameter to list the names of available contexts instead
(equivalent to Get-ContextConfiguration | Select-Object -ExpandProperty Name).
This parameter is provided because users will probably use the 'use'
alias as an interface to contexts and it's useful to be able to
'use <context>' and 'use -l'.

.EXAMPLE

Example ~/.contexts.yaml

  ---
  prod:
    color: red
    env:
      AWS_PROFILE: contoso-production
    path:
      - /usr/dev-local/bin
    entry:
      - aws sso login
      - Set-AWSDefaultCredential -Scope global $env:AWS_PROFILE
      - kubectl use-context web-cluster-1
    exit:
      - Clear-AWSCredential

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
      - aws sso login
      - kubectl use-context web-cluster-$Env:AWS_DEFAULT_REGION
      - Set-AWSCredentials -Scope global $Env:AWS_PROFILE
      - Set-AWSDefaultRegion -Scope global $Env:AWS_DEFAULT_REGION
    exit:
      - Remove-Variable -Scope global StoredAWSCredentials
      - Remove-Variable -Scope global StoredAWSRegion
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

.INPUTS

None: Set-CurrentContext does not read from a pipeline.

.NOTES

Variable Scope - Note that the commands in the Shell-Contexts module
execute in their module scope, not yours. Therefore, while you can
invoke whatever expression you like under the "entry" and "exit" keys,
if these commands set variables in the current scope, they will not
be visible.

Commands that are affected by this, such as the AWS toolkit
commands Set-DefaultAWSRegion and Set-AWSCredentials (which set
the variables $StoredAWSRegion and $StoredAWSCredentials respectively),
may offer a way to escape the scope (passing the -Scope parameter,
just as you would need to do to use Set-Variable as an entry
command). This may also require you to do manual fixups of
these variables for exit.

I suggest making the following aliases:

  Set-Alias use Set-CurrentContext
  Set-Alias add Add-CurrentContext
  Set-Alias leave Remove-CurrentContext

Of course you can use whatever aliases you find most ergonomic.
The 'leave' command is a standard Unix command, though rarely used.

#>
function Set-CurrentContext {
  [CmdletBinding()]

  Param(
    [parameter(mandatory=$false, position=0)] [string[]]$NewContext,
    [parameter(mandatory=$false)] [switch]$ListOnly
  )

  if ($ListOnly) {
    Get-ContextConfiguration | Select-Object -ExpandProperty Name
  } else {
    $existing_stack = $env:CURRENT_CONTEXT -split ',' | ?{ $_ }
    if ($existing_stack) {
      Remove-CurrentContext -Context $existing_stack
    }

    if ($NewContext) {
      Add-CurrentContext -NewContext $NewContext
    }
  }
}
