<#

.SYNOPSIS

Get a 1Password item

.DESCRIPTION

.LIMITATIONS

The default assumption for the CopyCommand parameter is 'pbcopy', that
is, that you are running on MacOS. The default should probably be
platform-sensitive and/or use Set-Clipboard.

There should be a bunch more options here so you can search by
pattern and use the op command's native --categories and --tags
options, and types.

#>

function Get-1PasswordItem {
  [CmdletBinding()]
  Param(
    [Parameter(Position=0)] [String]$ItemTitle,
    [Switch]$CopyPassword,
    [string[]]$Show,
    [switch]$Fields,
    [String]$ClipboardCommand = 'pbcopy' # Not a portable default
  )

  if ($PSBoundParameters.ContainsKey('ItemTitle')) {
    # Get a specific item. Has secrets :/ And OTP secrets :/ :/
    $item = op item get $ItemTitle --format=json | ConvertFrom-Json
    $ret = [PSCustomObject]@{
      title = $item.title
      username = ''
      url = $item.urls | ?{ $_.primary } | %{ $_.href }
      totp = ''
    }
    $item.fields | ForEach-Object {
      if ($_.label -eq 'username') {
        $ret.username = $_.value
      }
      if (($_.label -eq 'password') -and $CopyPassword) {
        $_.value | & $ClipboardCommand
      }
      if ($_.type -eq 'OTP') {
        $ret.totp = $_.totp
      }
      if ($_.label -in $Show) {
        Add-Member -InputObject $ret -NotePropertyName $_.label -NotePropertyValue $_.value
      } elseif ($Fields -and $_.label -notin 'username','password','totp') {
        Add-Member -InputObject $ret -NotePropertyName $_.label -NotePropertyValue $null
      }
    }
    $ret
  } else {
    $items = op item list --format=json | ConvertFrom-Json
    $items | ForEach-Object { [PSCustomObject]@{
                                title = $_.title
                                url = $_.urls | ?{ $_.primary } | %{ $_.href }
                              }
                            }
  }
}
