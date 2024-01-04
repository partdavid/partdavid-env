<#

.SYNOPSIS

Produce a random word from the dictionary

.DESCRIPTION

The Get-RandomWord command selects a random word from the English
dictionary, or from a dictionary provided. The dictionary must
be utf8-encoded.

The internal dictionary comes from Linux's standard
/usr/share/dict/words and is quite permissive (its words can contain
hyphens or be composed entirely of numerals, for example).

There is a hardcoded assumption that the maximum line size
(and therefore word size) in the dictionary is less than 100 bytes.
The maximum word size for the built-in dictionary is 45 bytes.

#>
function Get-RandomWord {
  [CmdletBinding(DefaultParameterSetName='DictionaryFile')]
  param(
    [Parameter(ParameterSetName='Dictionary')] [string[]]$Dictionary,
    [Parameter(ParameterSetName='DictionaryFile')] [string]$DictionaryFile = (Join-Path $PSScriptRoot 'words'),
    [int]$Count = 1
  )

  $words = New-Object 'string[]' $Count

  if ($Dictionary) {
    $words = $Dictionary | Get-Random -Count $Count
  } else {
    $dict = Get-Item $DictionaryFile
    $fh = [System.IO.File]::OpenRead($dict.fullname)
    # Should I wrap this in a buffer in case it's something like
    # a character device file where every seek() and read()
    # goes to storage?
    for ($wordNum = 0; $wordNum -lt $Count; $wordNum++) {
      $offset = Get-Random -Maximum ($fh.Length - 1)
      $words[$wordNum] = Get-WordAtOffset -Handle $fh -Offset $offset
    }
  }

  $words
}

function ByteValue {
  param(
    [byte]$byte
  )
  "{0:d3} (0b{1,8})" -f $byte,[Convert]::ToString($byte, 2).PadLeft(8, '0')
}

class StreamCharacter {
  static [char[]]$AdditionalWordCharacters = [System.Text.Encoding]::UTF8.GetChars([System.Text.Encoding]::UTF8.GetBytes("-_"))
  [char]$Character
  [int]$Length

  [string]ToString() {
    return "$($this.Character) $($this.Length)b"
  }

  [bool]IsWordCharacter() {
    return ([System.Char]::IsLetterOrDigit($this.Character) -or [StreamCharacter]::AdditionalWordCharacters `
      -contains $this.Character)
  }
}

# Reads *character* (not byte) at position, leaving
# the position at the beginning of the character (that
# is, if position points to single-byte character, read
# that character and leave position unchanged; if in
# the middle of a wide character, position is updated
# to beginning of character. Returns a StreamCharacter
# consisting of the character and a length of the
# character, in bytes, in the stream.
function ReadCharacter {
  param(
    [System.IO.Stream]$Handle
  )

  $fh = $Handle
  [byte[]]$bytes = @()
  $b = $fh.ReadByte()
  $fh.Seek(-1, 1) | Out-Null
  # Use the self-synchronizing property of UTF-8
  # to find the start of a valid UTF-8 encoded
  # string. Bytes meeting the following condition
  # are in the middle of a wide character
  while ($fh.Position -gt 0 -and ($b -band 0b11000000u) -eq 0b10000000u) {
    $fh.Seek(-1, 1) | Out-Null
    $b = $fh.ReadByte()
    $fh.Seek(-1, 1) | Out-Null
  }
  # Now we know we're at the start of a valid UTF-8
  # character. Let's read the *character*
  $start = $fh.Position
  $bytes += $fh.ReadByte()
  if ($fh.Position -lt $fh.Length -and ($bytes[0] -band 0b11000000u) -eq 0b11000000u) {
    $b = $fh.ReadByte()
    while (($b -band 0b11000000u) -eq 0b10000000u) {
      $bytes += $b
      $pos = $fh.Position
      if ($fh.Position -lt $fh.Length) {
        $b = $fh.ReadByte()
      } else {
        break
      }
    }
  }
  $fh.Seek($start, 0) | Out-Null
  $byteValues = for ($i = 0; $i -lt $bytes.Length; $i++) {
    "[$i] $(ByteValue $bytes[$i])"
  }
  [char[]]$chars = [System.Text.Encoding]::UTF8.GetChars($bytes)
  if ($chars.Length -ne 1) {
    return $Null
  }
  [StreamCharacter]@{
    Character = $chars[0]
    Length = $bytes.Length
  }
}

# Words consist of strings of letters or digits or hyphens
# and are broken at any character that isn't
# one of those, allowing arbitrary UTF-8-encoded
# text files to be used as dictionaries. Possibly
# this should be configurable: an alternate
# approach is to break words at whitespace characters
# instead, allowing symbols and punctuation in "words".
function Get-WordAtOffset {
  [CmdletBinding()]
  param(
    [System.IO.Stream]$Handle,
    [int]$Offset
  )
  
  [char[]]$chars = @()
  $fh = $Handle
  $fh.Seek($Offset, 0) | Out-Null
  $c = ReadCharacter($fh)
  if (! $c.IsWordCharacter()) {
    while (! $c.IsWordCharacter()) {
      # Advance one character
      $fh.Seek($c.Length, 1) | Out-Null
      $c = ReadCharacter($fh)
    }
  } else {
    # Now we should be in the middle of or at
    # the start of our word.
    while ($fh.Position -gt 0 -and $c.IsWordCharacter()) {
      # Back up one byte--this workes because ReadCharacter
      # knows how to back up within a wide character to the
      # beginning of the character--it adjusts the position
      # accordingly as well
      $fh.Seek(-1, 1) | Out-Null
      $pc = ReadCharacter($fh)
      if (! $pc.IsWordCharacter()) {
        # Go back to where we started and stop here--
        # the previous character is a breaker.
        $fh.Seek($pc.Length, 1) | Out-Null
        break
      }
    }
  }

  # We are at the beginning of a word, read it
  $c = ReadCharacter($fh)
  while ($fh.Position -lt $fh.Length -and $c.IsWordCharacter()) {
    $chars += $c.Character
    # Advance one character
    $fh.Seek($c.Length, 1) | Out-Null
    $c = ReadCharacter($fh)
  }

  # Now our char array contains a word, return it as a string
  $chars -join ''
}
