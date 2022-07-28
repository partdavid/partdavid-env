#!pwsh

function New-BabylonianDigitTable {
  # Babylonian cuneiform number is sexagesimal, but each base-60 digit
  # is composed of counters that are kind of base-10

  $zero = "`u{1244a}"
  $base10units = @(
    "",          # 0
    "`u{12415}", # 1 - one gesh
    "`u{12416}", # 2 - two gesh
    "`u{12417}", # 3 - three gesh
    "`u{12418}", # 4 - four gesh
    "`u{12419}", # 5 - five gesh
    "`u{1241a}", # 6 - six gesh
    "`u{1241b}", # 7 - seven gesh
    "`u{1241c}", # 8 - eight gesh
    "`u{1241d}"  # 9 - nine gesh
  )

  $base10tens = @(
    "",                   #  0 - no U
    "`u{1230b}",          # 10 - one U
    "`u{1230b}`u{1230b}", # 20 - two U
    "`u{1230d}",          # 30 - three U
    "`u{1240f}",          # 40 - four U
    "`u{12410}"           # 50 - five U
  )

  $numerals = foreach ($tens in $base10tens) {
    foreach ($unit in $base10units) {
      $tens + $unit
    }
  }
  $numerals[0] = $zero

  return $numerals
}

Set-Variable -Scope Global -Name BabylonianDigitTable -Value $(New-BabylonianDigitTable)

<#
.SYNOPSIS

Convert a positive integer to a Babylonian Cuneiform numeral string

#>
function ConvertTo-Babylonian {
  [CmdletBinding()]

  Param(
    [Parameter(Position=0)] [ValidateRange('Nonnegative')] [Int]$Number
  )

  if ($Number -eq 0) {
    return ''
  }

  $digits = [Math]::Floor([Math]::Log($Number) / [Math]::Log(60))

  [Int[]]$base60number = $digits .. 0 | `
    %{ $digit = [int]($number / [Math]::Pow(60, $_)); $number = $number % [Math]::Pow(60, $_); $digit }

  Write-Verbose ("base-60 places: " + (($base60number | %{ $_.ToString() }) -join ', '))
  $babylonian_number = ($base60number | %{ $global:BabylonianDigitTable[$_] }) -join ''
  return $babylonian_number
}
