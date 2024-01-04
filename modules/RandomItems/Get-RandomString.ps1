<#
.SYNOPSIS

Return a random string, suitable for most identifiers

.DESCRIPTION

The Get-RandomString command returns a random string of the specified
length, composed of letters, numbers and undescores by default (with
the initial character always a letter). You can specify alternate
alphabets as single strings.

.LINK

New-Item
#>
function Get-RandomString {
  [CmdletBinding()]
  param(
    [Parameter(Position=0)] [ValidateRange(1, 2000)] [int]$Length,
    [string]$InitAlphabet = ('a' .. 'z' -join '') + ('A' .. 'Z' -join ''),
    [string]$Alphabet = ('a' .. 'z' -join '') + ('A' .. 'Z' -join '') + '_'
  )

  $s = $InitAlphabet.ToCharArray() | Get-Random

  if ($Length -gt 1) {
    $s += ($Alphabet.ToCharArray() | Get-Random -Count ($Length - 1)) -join ''
  }

  $s
}
