<#
.SYNOPSIS

Generate a decent password

.DESCRIPTION

This operates quite similarly to Get-RandomString, with different
defaults and outputting the result as a SecureString.

#>
function New-Password {
  [CmdletBinding()]

  param(
    # Specify password length
    [Parameter(Position=0)] [ValidateRange(2, 10000)] [int]$Length = 20,
    # Specify possible symbols (to not include symbols, pass empty string)
    [string]$Symbols = '!+-@&._', # Nothing too weird
    # Specify possible letters (to not include letters, pass empty string)
    [string]$Letters = ('a' .. 'z' + 'A' .. 'Z' -join ''),
    # Specify possible numbers to use (to not include numbers, pass empty string)
    [string]$Numbers = ('0' .. '9' -join '')
  )

  $initalphabet = $Letters
  $alphabet = $Symbols + $Letters + $Numbers

  ($initalphabet.ToCharArray() | Get-Random) + (($alphabet.ToCharArray() | Get-Random -Count ($Length - 1) ) -join '') `
    | ConvertTo-SecureString -AsPlainText
}
