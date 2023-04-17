function Backup-B2Item {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory, Position=0, ParameterSetName='Path', ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [SupportsWildCards()]
    [string[]]$Path,                 # Get-ChildItem
    [Parameter(Mandatory, ParameterSetName='LiteralPath', ValueFromPipelineByPropertyName)]
    [string[]]$LiteralPath,          # Get-ChildItem
    [Parameter(Position=1)]
    [ValidateScript({$_.Scheme -eq 'b2' -or $_.Scheme -eq $Null })] [uri]$Destination = '/',
    [string]$Bucket,
    [bool]$Container = $True,        # Preserve directory structure, TODO: change Restore-B2Item to honor this option
    [string]$Filter,                 # Get-ChildItem
    [string[]]$Include,              # Get-ChildItem
    [string[]]$Exclude,              # Get-ChildItem
    [switch]$Recurse,                # Get-ChildItem
    [switch]$NoEncrypt,
    [string[]]$Recipients
  )

  begin {
    $gciParameterNames = @(
      'Path'
      'LiteralPath'
      'Filter'
      'Include'
      'Exclude'
      'Recurse'
    )
    if ($Destination.Host -and $Bucket -and ($Destination.Host -ne $Bucket)) {
      throw "Destination is URL that contains bucket name but -Bucket $Bucket was provided"
    }
    if ($Destination.Host -eq $Null -and -not $Bucket) {
      throw "Destination is not a b2:// URL containing the bucket name and no -Bucket was provided"
    }

    if (-not $Recipients) {
      $Recipients = $global:B2Parameters.Recipients
      if (-not $Recipients -and -not $NoEncrypt) {
        throw "No -Recipients and none as part of current B2Session"
      }
    }

    if ($Bucket -eq $Null -or $Bucket -eq '') {
      $Bucket = $Destination.Host
    }
    $DestinationPath = ($Destination.AbsolutePath ?? $Destination.OriginalString).TrimStart('/')
  }

  process {
    $gciParameters = @{}
    foreach ($gciParameterName in $gciParameterNames) {
      if ($PSBoundParameters.ContainsKey($gciParameterName)) {
        $value = $PSBoundParameters[$gciParameterName]
        if ($value -is [switch]) {
          $gciParameters[$gciParameterName] = $value.ToBool()
        } else {
          $gciParameters[$gciParameterName] = $PSBoundParameters[$gciParameterName]
        }
      }
    }
    $spParameters = @{}
    foreach ($spParameterName in 'Path','LiteralPath') {
      if ($PSBoundParameters.ContainsKey($spParameterName)) {
        $spParameters[$spParameterName] = $PSBoundParameters[$spParameterName]
      }
    }
    $relativeRoot = Split-Path @spParameters -Resolve | Select-Object -Unique
    if ($relativeRoot.Count -gt 1) {
      # There's a wildcard in the leading path components, so we need to
      # consider them all relative to ourselves
      $relativeRoot = $PWD
    }
    Write-Debug "will consider files relative to: '$relativeRoot'"

    Write-Debug "Get-ChildItem $($gciParameters | ConvertTo-Json -Compress)"
    foreach ($item in (Get-ChildItem @gciParameters)) {
      if ($item.PSIsContainer) {
        continue
      }
      Write-Debug "processing $($item.FullName)"
      if ($Container) {
        $oldPWD = $PWD
        Set-Location $relativeRoot
        $relativePath = Format-Path (Resolve-Path -Relative $Item.FullName)
        Set-Location $oldPWD
        Write-Debug "relativePath = '$relativePath'"
        $targetPath = $DestinationPath ? (Join-Path $DestinationPath $relativePath) : $relativePath
      } else {
        $targetPath = $DestinationPath ? (Join-Path $DestinationPath $item.Name) : $item.Name
      }
      Write-Debug "bucket / targetPath = $Bucket / $($targetPath.GetType())($targetPath)"
      if (-not $NoEncrypt) {
        $key = [Convert]::ToBase64String((Get-Random -Max 255 -Count 32))
        $recipientOpts = ($Recipients | %{ "--recipient",$_ }) -join ' '
        # gpg will prompt for passphrase if needed
        Write-Debug "<key> | gpg --batch --yes --encrypt $recipientOpts --output $($item.FullName).key.enc"
        if ($PSCmdlet.ShouldProcess("<key (dek)>", "encrypt to $($item.FullName).key.enc")) {
          $key | & gpg --batch --yes --encrypt $recipientOpts --output "$($item.FullName).key.enc"
        }
        # TODO: --passphrase-fd works on Windows? Maybe there we need to use --passphrase <key> :(
        Write-Debug "<key> | gpg --batch --yes --symmetric --passphrase-fd 0 --no-symkey-cache --pinentry-mode loopback --compression-algo none --cipher-algo AES256 --output $($item.FullName).enc $($item.FullName)"
        if ($PSCmdlet.ShouldProcess($item.FullName, "encrypt to $($item.FullName).enc with $($item.FullName).key")) {
          $key | & gpg --batch --yes --symmetric --passphrase-fd 0 --no-symkey-cache --pinentry-mode loopback --compression-algo none --cipher-algo AES256 --output "$($item.FullName).enc" $item.FullName
        }
        if ($PSCmdlet.ShouldProcess("$($item.FullName).enc", "upload to $Bucket ${targetPath}.enc")) {
          Write-Debug "b2 upload-file $Bucket $($item.FullName).enc ${targetPath}.enc"
          $result = & b2 upload-file --quiet $Bucket "$($item.FullName).enc" "${targetPath}.enc" | ConvertFrom-Json
          Add-Member -InputObject $result -NotePropertyName Source -NotePropertyValue "$($item.FullName).enc"
          Add-Member -InputObject $result -NotePropertyName Destination -NotePropertyValue "${targetPath}.enc"
          Write-Output $result
        }
        if ($PSCmdlet.ShouldProcess("$($item.FullName).key.enc", "upload to $Bucket ${targetPath}.key.enc")) {
          Write-Debug "b2 upload-file $Bucket $($item.FullName).key.enc ${targetPath}.enc"
          $result = & b2 upload-file --quiet $Bucket "$($item.FullName).key.enc" "${targetPath}.key.enc" | ConvertFrom-Json
          Add-Member -InputObject $result -NotePropertyName Source -NotePropertyValue "$($item.FullName).key.enc"
          Add-Member -InputObject $result -NotePropertyName Destination -NotePropertyValue "${targetPath}.key.enc"
          Write-Output $result
        }
      } else {
        if ($PSCmdlet.ShouldProcess($item.FullName, "upload to $Bucket $targetPAth")) {
          Write-Debug "b2 upload-file $Bucket $item.FullName $targetPath"
          $result = & b2 upload-file --quiet $Bucket $item.FullName $targetPath | ConvertFrom-Json
          Add-Member -InputObject $result -NotePropertyName Source -NotePropertyValue $item.FullName
          Add-Member -InputObject $result -NotePropertyName Destination -NotePropertyValue $targetPath
          Write-Output $result
        }
      }
    }
  }

}

function Format-Path {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, ValueFromPipeline)] [string[]]$Path
  )

  process {
    foreach ($pathStr in $Path) {
      $components = $pathStr -split [IO.Path]::DirectorySeparatorChar
      $out = [System.Collections.Stack]::new()
      foreach ($component in $components) {
        switch ($component) {
          ''      { continue }
          '.'     { continue }
          '..'    { if ($out.Count -eq 0 -or $out[-1] -eq '..') {
                      # ../.. needs to be preserved at beginning
                      $out.Push($component)
                    } else {
                      # Remove the last component, we're "climbing"
                      # the tree
                      [void]$out.Pop()
                    }
               }
          default { $out.Push($component) }
        }
      }
      $outArr = $out.ToArray()
      [Array]::Reverse($outArr)
      $outArr -join [IO.Path]::DirectorySeparatorChar
    }
  }

}
