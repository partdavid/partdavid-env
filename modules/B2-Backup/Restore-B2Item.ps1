function Restore-B2Item {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [uri[]]$Item,
    [string]$Path = '.',
    [string]$Bucket,
    [switch]$NoPreserveRelativePath,
    [switch]$NoDecrypt,
    [switch]$NoClean,
    [switch]$Force,
    [switch]$InsecureLegacy, # My shame, but also B2's instructions were incorrect at the time
    [switch]$Recurse
  )

  $b2items = Get-B2Item -Bucket:$Bucket -Item:$Item

  if (-not (Test-Path $Path -PathType Container)) {
    Write-Verbose "Directory does not exist: $Path (will create)"
  }

  $localPath = {
    param([string]$remotePath,
         [string]$relativeTo = '')
    $NoPreserveRelativePath ? (Join-Path $Path (Split-Path -Leaf $remotePath)) : `
      (Join-Path $Path ($remotePath -replace ('^' + [Regex]::Escape($relativeTo))))
  }

  foreach ($b2item in $b2items) {
    Write-Debug "$($b2item.Bucket) $($b2item.Name)"
    $dst = $localPath.Invoke($b2item.Name, $b2item.RelativeTo)
    $dir = Split-Path $dst
    if ($dir -and -not (Test-Path -PathType Container $dir)) {
      New-Item -Type Directory $dir -WhatIf:$WhatIfPreference
    }
    if (-not (Test-Path $dst) -or $Force) {
      if ($PSCmdlet.ShouldProcess($dst, "b2 download-file-by-name --noProgress $($b2item.Bucket) $($b2item.Name)")) {
        # https://github.com/Backblaze/B2_Command_Line_Tool/issues/748
        # https://bugs.python.org/issue46391
        & b2 download-file-by-name --noProgress $b2item.Bucket $b2item.Name $dst
      }
    }
  }
  if (-not $NoDecrypt) {
    foreach ($b2item in $b2items) {
      if ($b2item.Encrypted -and $b2item.KeyFile) {
        $localName = $localPath.Invoke($b2item.Name, $b2item.RelativeTo)
        $localDecryptedName = $localPath.Invoke($b2item.DecryptedName, $b2item.RelativeTo)
        $localKeyFile = $localPath.Invoke($b2item.KeyFile, $b2item.RelativeTo)
        if ((Test-Path $localKeyFile) -and $InsecureLegacy) {
          # This is the "legacy" method used for only a handful of files in private store in 2021.
          # The problem is that the symmetric key was generated with base64 encoding, then RSA used
          # to encrypt it, and the file was encrypted using -kfile so that only the first line of
          # the base64-encoded symmetric key was used. That's not enough key material: indeed, only
          # 177 bits of randomness were used in the first place due to base64 padding, and then only
          # the first line of the file was used due to how -kfile works. But that's how this handful
          # of files were encrypted, and I had to figure out the broken protocal from a few years ago,
          # so that's why this exists. This error is not supported for encryption, of course.
          #
          # The cure is possibly to use gpg --symmetric which may be a little more ergonomic, and
          # gpg offers encryption to multiple recipients (for the keyfile) which may ease key rotation
          # and other access concerns.
          if ($global:B2Parameters.KeyPassphrase) {
            Write-Debug ("<passphrase> | openssl rsautl -decrypt -in $localKeyFile " + `
              "-inkey $($global:B2Parameters.PrivateKey) -passin stdin")
            $symmetricKey = ConvertFrom-SecureString $global:B2Parameters.KeyPassphrase -AsPlainText | `
              & openssl rsautl -decrypt -in $localKeyFile -inkey $global:B2Parameters.PrivateKey -passin stdin
          } else {
            Write-Debug "openssl rsautil -decrypt -in $localKeyFile -inkey $($global:B2Parameters.PrivateKey)"
            $symmetricKey = & openssl rsautl -decrypt -in $localKeyFile -inkey $global:B2Parameters.PrivateKey
          }
          Write-Debug "<key> | openssl enc -v -aes-256-cbc -salt -d -a -kfile /dev/fd/0 -out $localDecryptedName -in $localName"
          if ($PSCmdlet.ShouldProcess(
                $localName, "<key> | openssl enc -v -aes-256-cbc -salt -d -a -kfile /dev/fd/0 -out $localDecryptedName -in")) {
            $symmetricKey |  & openssl enc -v -aes-256-cbc -salt -d -a -kfile /dev/fd/0 -out $localDecryptedName -in $localName
          }
        }
      }
    }
  }
}
