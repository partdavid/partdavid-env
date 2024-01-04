# Test Helpers

function Should-BeInterval {
  param(
    [PSCustomObject]$ActualValue,
    [PSCustomObject]$ExpectedValue,
    [switch]$Negate,
    [string]$Because,
    $CallerSessionState
  )

  [bool]$isEqual = $True
  [string[]]$errors = @()

  if ($ActualValue.length -eq 1 -and $ActualValue -Is [PSCustomObject]) {
    $ActualValue = @($ActualValue)
  }
  if ($ExpectedValue.length -eq 1 -and $ExpectedValue -Is [PSCustomObject]) {
    $ExpectedValue = @($ExpectedValue)
  }

  if (($comp = $ActualValue.length.CompareTo($ExpectedValue.length)) -ne 0) {
    if ($comp -eq -1) {
      $errors += "didn't get enough actual values ($($ActualValue.length)) to compare to $($ExpectedValue.length) expected values"
    } else {
      $errors += "got too many actual values ($($ActualValue.length)) to compare to $($ExpectedValue.length) expected values"
    }
  }

  for ($i = 0; $i -lt [math]::Min($ActualValue.length, $ExpectedValue.length); $i++) { 

    if (($ExpectedValue[$i].end - $ExpectedValue[$i].start).Ticks -ne $ExpectedValue[$i].ticks) {
      $isEqual = $False
      $errors += "can't compare expected corrupt interval ${i}: " + `
        "($ExpectedValue[$i].end - $ExpectedValue[$i].start != $ExpectedValue[$i].ticks)"
    }

    if (($ActualValue[$i].end - $ActualValue[$i].start).Ticks -ne $ActualValue[$i].ticks) {
      $isEqual = $False
      $errors += "got corrupt interval ${i}: ($ActualValue[$i].end - $ActualValue[$i].start != $ActualValue[$i].ticks)"
    }

    if (-not $isEqual) {
      continue
    }

    try {
      foreach ($field in 'start','end') {
        if (($comp = $ActualValue[$i].$field.CompareTo($ExpectedValue[$i].$field)) -ne 0) {
          $isEqual = $False
          $errors += "interval $i ${field}s $($comp -eq -1 ? 'before' : 'after') expected " + `
            "(got:$($ActualValue[$i].$field) $($comp -eq -1 ? '<' : '>') expected:$($ExpectedValue[$i].$field))"
        }
      }
    } catch {
      $errors += "error in interval ${i} comparing got: $($ActualValue[$i]) expected: $($ExpectedValue[$i])"
      $isEqual = $False
    }
  }

  $succeeded = $Negate ? (-not $isEqual) : $isEqual
  if (-not $succeeded) {
    $failureMessage = ($errors -join ', ') + ($Because ? " because $Because" : '')
  }

  return [PSCustomObject]@{
    Succeeded = $succeeded
    FailureMessage = $failureMessage
  }
}

# This is a little janky--how are you supposed to iterate
# if this isn't idempotent?
if (-not (Get-ShouldOperator | ?{ $_.Name -eq 'BeInterval' })) {
  Add-ShouldOperator -Name 'BeInterval' `
    -InternalName 'Should-BeInterval' `
    -Test ${function:Should-BeInterval} `
    -SupportsArrayInput
}
