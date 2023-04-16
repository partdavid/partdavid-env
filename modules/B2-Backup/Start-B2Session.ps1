<#
.SYNOPSIS

Sign in to Backblaze account and make sure encryption key is in-place

.DESCRIPTION

This command uses the secrets in the vault you specify to authorize
your Backblaze session.

You can specify a vault which contains the appropriate credential with
the -Vault parameter.

This will also check for a valid RSA public key to be used for
encrypting backups, and for a private key to be used for restoring
(decrypting) backups and rotating keys.

.NOTES

.LINK

https://github.com/cdhunt/SecretManagement.1Password

.LINK

https://github.com/cdhunt/op-powershell

#>
function Start-B2Session {
  [CmdletBinding()]
  param(
    [PSCredential]$Credential,
    [string]$Vault,
    [string]$SecretName = 'B2Credential',
    [string]$KeySecretName = 'B2BackupKey',
    [string[]]$Recipients,
    [string]$PublicKey = "${HOME}/.b2/key.pub",
    [string]$PrivateKey = "${HOME}/.b2/key",
    [switch]$InsecureLegacy
  )

  $global:B2Parameters = @{
    PublicKey = $PublicKey
    PrivateKey = $PrivateKey
  }

  if ($Credential) {
    $global:B2Parameters.Credential = $Credential
  } elseif ($Vault) {
    $global:B2Parameters.Credential = { Get-Secret -Vault $Vault $SecretName }
  } else {
    $global:B2Parameters.Credential = Get-Credential
  }

  $env:B2_APPLICATION_KEY_ID = $global:B2Parameters.Credential.UserName
  $env:B2_APPLICATION_KEY = ConvertFrom-SecureString $global:B2Parameters.Credential.Password -AsPlainText # :(
  & b2 authorize-account $global:B2Parameters.Credential.UserName
  Remove-Item Env:/B2_APPLICATION_KEY,Env:/B2_APPLICATION_KEY_ID

  if ($InsecureLegacy) {
    if (-not (Test-Path $PrivateKey)) {
      Write-Warning "Cannot restore files without RSA private key $PrivateKey"
    } else {
      if (-not $NoCheckPrivateKey) {
        $passphrase = Read-Host -Prompt "Passphrase for $PrivateKey" -AsSecureString
        $publicKeyValue = ConvertFrom-SecureString $passphrase -AsPlainText | & openssl rsa -in $PrivateKey -pubout -passin stdin
        if ($?) {
          Write-Verbose "Overwriting $PublicKey with value from private key $PrivateKey"
          Set-Content $PublicKey $publicKeyValue
          $global:B2Parameters.KeyPassphrase = $passphrase
        }
      }
    }

    if (-not (Test-Path $PublicKey)) {
      Write-Warning "Cannot backup files without RSA public key $PublicKey"
    }
  }

  if (! $Recipients) {
    # By default, we use the list of ultimately trusted keys, because
    # that's probably you. But we still print a warning, since you didn't
    # specify -Recipients
    $Recipients = gpg --list-keys --with-colons | %{
      $f = $_ -split ':'
      if ($f[0] -eq 'uid' -and $f[1] -eq 'u') {
        $f[9] -replace '.*(<[^>]*>).*','$1'
      }
    }
    if ($Recipients.Count -gt 0) {
      Write-Warning "No -Recipients specified, using default list of ultimately trusted keys: $($Recipients -join ', ')"
      $global:B2Parameters.Recipients = $Recipients
    } else {
      Write-Warning "No -Recipients specified and no keys are ultimately trusted: Backup-B2Item and Update-B2Key will require -Recipients"
    }
  }
}
