<#
.SYNOPSIS

Create an item, possibly with random name and content

.DESCRIPTION

The New-RandomItem command creates an item in a manner similar to
New-Item.

The target path of the new item can be specified with the -Path,
-LiteralPath or -PathTemplate parameters. When giving -Path, any
trailing 'X' characters are replaced with random characters, in
a manner similar to the mktemp Unix command. With -LiteralPath,
no expansion like this is done. With -PathTemplate, the parameter
is interpreted as an EPS template and the result is used as
the target.

The value of the item (that is, its contents) can be specified with
the -Value, -ValueFile, -ValueTemplate or -ValueTemplateFile
parameters. When using -Value, the parameter is used as the value
of the item (without any dynamic processing). With -ValueFile,
the contents of the file referred to by the parameter is used.
With -ValueTemplate, the parameter is interpreted as an EPS
template and the result used for the value of the item. With
-ValueTemplateFile, the file is used as a template.

When specifying -ValueFile and -ValueTemplateFile, the arguments
can be directories, in which case, New-RandomItem will create
a new directory at the target path. It will then invoke New-RandomItem
recursively on the directory (interpreting files as EPS templates
to expand if -ValueTemplateFile) in order to recursively create
random items.

EPS templates require variable bindings to operate on. New-RandomItem
always invokes EPS templates with the -Safe option and explicitly
passes variable bindings. By default (that is, if you don't pass
the -Bindings parameter), these are the global variable bindings.
You can pipe the output of Get-Variable (with its filters and other
options) to Get-Binding to produce a Hashtable suitable for passing
to the -Bindings parameter. The reason for this somewhat awkward dance
is that New-RandomItem only has visibility into its module scope and
the global scope--it can't find variables in the local scope of its
caller.

When recursing directories using -ValueTemplateFile, the filenames of
files and directories can themselves be EPS templates--New-RandomItem
will interpret them. This allows you to have dynamic filenames
embedded in the structure of your skeleton. When the result of
expanding the EPS template that is the source filename contains
newlines, each line is interpreted as a separate New-RandomItem to
create, allowing you to dynamically create multiple files or
directories. Doing so is most easily done using the EPS library's
Each function, as seen in the Examples.

.EXAMPLE
PS> New-RandomItem foo

    Directory: /home/user0

UnixMode   User             Group                 LastWriteTime           Size Name
--------   ----             -----                 -------------           ---- ----
-rw-r--r-- user0            staff               4/11/2023 10:23              0 foo

.EXAMPLE
PS> New-RandomItem fooXXXXXX

    Directory: /home/user0

UnixMode   User             Group                 LastWriteTime           Size Name
--------   ----             -----                 -------------           ---- ----
-rw-r--r-- user0            staff               4/11/2023 10:26              0 fooMoBCVv

.EXAMPLE
PS> New-RandomItem -PathTemplate '<% 0..3 | Each { %>foo/file-<%= $_ %><% } -join "`n" %>' -ValueTemplateFile file.tmpl

.LINK

New-Item
EPS
Get-Binding

#>
function New-RandomItem {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory, Position=0, ParameterSetName = 'Path')]
    [Parameter(Mandatory, Position=0, ParameterSetName = 'PathAndValue')]
    [Parameter(Mandatory, Position=0, ParameterSetName = 'PathAndValueFile')]
    [Parameter(Mandatory, Position=0, ParameterSetName = 'PathAndValueTemplate')]
    [Parameter(Mandatory, Position=0, ParameterSetName = 'PathAndValueTemplateFile')]
    # Specify a path, trailing XXX's are substituted with random characters
    [string[]]$Path,
    [Parameter(Mandatory, ParameterSetName = 'LiteralPath')]
    [Parameter(Mandatory, ParameterSetName = 'LiteralPathAndValue')]
    [Parameter(Mandatory, ParameterSetName = 'LiteralPathAndValueFile')]
    [Parameter(Mandatory, ParameterSetName = 'LiteralPathAndValueTemplate')]
    [Parameter(Mandatory, ParameterSetName = 'LiteralPathAndValueTemplateFile')]
    # Specify a path, no substitution or wildcard processing is done
    [string[]]$LiteralPath,
    [Parameter(Mandatory, ParameterSetName = 'PathTemplate')]
    [Parameter(Mandatory, ParameterSetName = 'PathTemplateAndValue')]
    [Parameter(Mandatory, ParameterSetName = 'PathTemplateAndValueFile')]
    [Parameter(Mandatory, ParameterSetName = 'PathTemplateAndValueTemplate')]
    [Parameter(Mandatory, ParameterSetName = 'PathTemplateAndValueTemplateFile')]
    # Specify a template expression that results in (a) path(s)
    [string[]]$PathTemplate,
    [Parameter(Mandatory, Position=1, ParameterSetName = 'PathAndValue')]
    [Parameter(Mandatory, ParameterSetName = 'LiteralPathAndValue')]
    [Parameter(Mandatory, ParameterSetName = 'PathTemplateAndValue')]
    # Specify a value, like file contents, for the item
    [object]$Value,
    [Parameter(Mandatory, ParameterSetName = 'PathAndValueFile')]
    [Parameter(Mandatory, ParameterSetName = 'LiteralPathAndValueFile')]
    [Parameter(Mandatory, ParameterSetName = 'PathTemplateAndValueFile')]
    # Specify a path to an object to use as the value for the item (can be container or non-container)
    [string]$ValueFile,
    [Parameter(Mandatory, ParameterSetName = 'PathAndValueTemplate')]
    [Parameter(Mandatory, ParameterSetName = 'LiteralPathAndValueTemplate')]
    [Parameter(Mandatory, ParameterSetName = 'PathTemplateAndValueTemplate')]
    # Specify a template string to determine the item contents
    [string]$ValueTemplate,
    [Parameter(Mandatory, ParameterSetName = 'PathAndValueTemplateFile')]
    [Parameter(Mandatory, ParameterSetName = 'LiteralPathAndValueTemplateFile')]
    [Parameter(Mandatory, ParameterSetName = 'PathTemplateAndValueTemplateFile')]
    # Specify a template file to determine the item contents
    [string]$ValueTemplateFile,
    [Parameter(ParameterSetName = 'PathTemplate')]
    [Parameter(ParameterSetName = 'PathAndValueTemplate')]
    [Parameter(ParameterSetName = 'PathAndValueTemplateFile')]
    [Parameter(ParameterSetName = 'LiteralPathAndValueTemplate')]
    [Parameter(ParameterSetName = 'LiteralPathAndValueTemplateFile')]
    [Parameter(ParameterSetName = 'PathTemplateAndValue')]
    [Parameter(ParameterSetName = 'PathTemplateAndValueFile')]
    [Parameter(ParameterSetName = 'PathTemplateAndValueTemplate')]
    [Parameter(ParameterSetName = 'PathTemplateAndValueTemplateFile')]
    # Specify a variable binding for templates (default is globals-only), see Get-Binding
    [hashtable]$Binding = @{},
    [switch]$Force,
    [PSCredential]$Credential
  )
  
  if ($PSCmdlet.ParameterSetName -like '*Template*') {
    if (-not $PSBoundParameters.ContainsKey('Binding')) {
      $Binding = Get-Binding -Scope Global
    }
  }

  $newItemParameters = @{}
  $descend = @()

  switch ($PSCmdlet.ParameterSetName) {
    { $_ -in 'LiteralPath','LiteralPathAndValue','LiteralPathAndValueTemplate','LiteralPathAndValueTemplateFile' } {
      $newItemParameters['Path'] = $LiteralPath
    }
    { $_ -in 'Path','PathAndValue','PathAndValueFile','PathAndValueTemplate','PathAndValueTemplateFile' } {
      $newItemParameters['Path'] = $Path | %{ $_ -replace 'X+$',{ Get-RandomString -Length $_.Value.length } }
    }
    { $_ -in @('PathTemplate','PathTemplateAndValue','PathTemplateAndValueFile','PathTemplateAndValueTemplate',
               'PathTemplateAndValueTemplateFile') } {
      $newItemParameters['Path'] = $PathTemplate | `
        %{ (Invoke-EpsTemplate -Safe -Binding $Binding -Template $_) -split "`n" } | `
        %{ $_ }
    }
  }

  foreach ($niParam in 'Force','Value','Credential') {
    if ($PSBoundParameters.ContainsKey($niParam)) {
      $newItemParameters[$niParam] = $PSBoundParameters[$niParam]
    }
  }

  if ($PSBoundParameters.ContainsKey('ValueTemplate')) {
    $newItemParameters['Value'] = Invoke-EpsTemplate -Template $ValueTemplate
  }

  if ($PSBoundParameters.ContainsKey('ValueFile')) {
    $valueItem = Get-Item -Path $ValueFile
    if ($valueItem.Attributes -contains 'Directory') {
      $newItemParameters['ItemType'] = 'Directory'
      foreach ($dirInfo in $valueItem.GetDirectories()) {
        $descend += @{
          Path = Join-Path $newItemParameters['Path'] $dirInfo.Name
          ValueFile = $dirInfo.Fullname
        }
      }
      foreach ($fileInfo in $valueItem.GetFiles()) {
        $descend += @{
          Path = Join-Path $newItemParameters['Path'] $fileInfo.Name
          ValueFile = $fileInfo.Fullname
        }
      }
    } else {
      $newItemParameters['Value'] = $valueItem | Get-Content -Raw
    }
  }

  if ($PSBoundParameters.ContainsKey('ValueTemplateFile')) {
    $valueTemplateItem = Get-Item -Path $ValueTemplateFile
    # At this level, we don't expand the template in the filename, if any, because
    # we are given a destination via -Path, -LiteralPath or -PathTemplate, and
    # that's authoritative. We well expand when finding children (thus, you can't
    # make the "top level" of your template tree a template).
    if ($valueTemplateItem.Attributes -contains 'Directory') {
      # Note that you can't really use -PathTemplate on the name of the subdirectory,
      # because it is interpreted a little differently: -PathTemplate is expected to
      # produce all the -Path arguments you need, but this template-in-the-filename
      # thing is relative to its current directory. So this call:
      # New-RandomItem -PathTemplate '<% 0..3 | Each { %>/root/data-<%= $_ %>/file.txt<% } -join "`n" %>' -ValueFile ./file.txt
      # is sort of the same as this call:
      # New-RandomItem -Path /root -ValueTemplateFile /tmpl
      # when there is this file: /tmpl/<% 0..3 | Each { %>data-<%= $_ %><% } -join "`n" %>/file.txt
      # but you can't plug in the template in the second case to something in the first place, without
      # trying to munge/edit it.
      $newItemParameters['ItemType'] = 'Directory'
      foreach ($item in (Get-ChildItem $valueTemplateItem)) {
        $outputItemNames = (Invoke-EpsTemplate -Safe -Binding $Binding -Template $item.Name) -split "`n"
        foreach ($outputItemName in $outputItemNames) {
          $newBinding = $Binding.Clone()
          $newBinding.Filename = $outputItemName
          $descend += @{
            Path = Join-Path $newItemParameters['Path'] $outputItemName
            ValueTemplateFile = $item.Fullname
            Binding = $newBinding
          }
        }
      }
    } else {
      $newItemParameters['Value'] = Invoke-EpsTemplate -Safe -Binding $Binding -Path $ValueTemplateItem
    }
  }

  $item = New-Item @newItemParameters
  foreach ($callParams in $descend) {
    New-RandomItem @callParams
  }
  $item
}
