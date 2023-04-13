<#
.SYNOPSIS

Get information about item backed up to B2

.DESCRIPTION

Gets metadata about backed-up item

#>
function Get-B2Item {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [uri[]]$Item,
    [string]$Bucket,
    [switch]$Recurse
  )

  if (-not $Bucket) {
    foreach ($itemUrl in $Item) {
      if (-not $itemUrl.host) {
        Write-Error "Can't determine bucket for $itemUrl (specify -Bucket use full b2://<bucket>/<path> URL)"
      }
    }
  }

  # The output from b2 ls is kind of strange. It lists objects at the level you set
  # (root or optionally, in a "folder"). The results seem to be objects at that level,
  # and a single object in each "folder" at that level. The folders seem to just
  # be file prefixes. There's no way to list a specific item.

  # The item that we get could be:
  # b2://bucket/file.enc
  # b2://bucket/folder
  # b2://bucket/folder/file.enc
  # -Bucket bucket folder
  # -Bucket bucket folder/file.enc

  # So, we have to try it both ways. First, we try it as if the item is a folder, so
  # we pass it on the command line. If it's not a folder, we won't get anything back.

  $items = @()
  $extraItems = @()
  foreach ($itemUrl in $Item) {
    if (-not $itemUrl.Host) {
      $bucketName = $Bucket
      $itemPath = $itemUrl.OriginalString
      Write-Debug "item has no host part, using -Bucket:$Bucket and itemPath=${itemPath}"
    } else {
      $bucketName = $itemUrl.Host
      $itemPath = $itemUrl.AbsolutePath
    }
    $itemPath = $itemPath.TrimStart('/')
    # Note that itemPath could be '' when it's the bucket root
    if ($Recurse) {
      # When recursive, there's no "folders" per se, they don't show up and
      # we don't really want them in the output.
      $entries = & b2 ls --recursive $bucketName $itemPath --json | ConvertFrom-Json
      foreach ($entry in $entries) {
        $items += [B2ItemInfo]::new('File', $bucketName, $entry)
      }
    } else {
      $entriesFromFolder = & b2 ls $bucketName $itemPath --json | ConvertFrom-Json

      if ($entriesFromFolder) {
        # Our item was a folder. So we treat the results as folder contents, which means
        # each result is either a file in the current folder, or it's a file in a subfolder
        foreach ($entry in $entriesFromFolder) {
          Write-Debug "entry in folder='${itemPath}': $($entry.fileName)"
          if (($itemPath -eq '' -and $entry.fileName -like '*/*') -or ($entry.fileName -like "${itemPath}/*/*")) {
            # It's an item in a subfolder, apparently included to indicated a folder
            Write-Debug "adding folder"
            $items += [B2ItemInfo]::new('Folder', $bucketName, $entry)
          } else {
            # It's an entry we want to include, because the item the caller specified is
            # a folder, so the caller wants them all
            Write-Debug "adding entry"
            $items += [B2ItemInfo]::new('File', $bucketName, $entry)
          }
        }
      } else {
        # We have to actually list the parent folder and then filter the results.
        # We use an 'extras' list to walk later and try to match up keys and
        # encrypted files
        $folder = Split-Path $itemPath
        Write-Debug "running b2 ls $bucketName $folder --json"
        $entriesFromParent = & b2 ls $bucketName $folder --json | ConvertFrom-Json
        foreach ($entry in $entriesFromParent) {
          Write-Debug "entry in folder='${folder}': $($entry.fileName)"
          if ($entry.fileName -in $itemPath,"${itemPath}.enc") {
            # It's our item, so we add it to the items list
            Write-Debug "  adding $($entry.fileName) to results list"
            $items += [B2ItemInfo]::new('File', $bucketName, $entry)
          } elseif ($entry.fileName -notlike "${folder}/*/*") {
            # It's not an entry we got to represent a folder, but it
            # might be the key for our item, so we add it to the
            # extras list
            Write-Debug "  adding $($entry.fileName) to extras list"
            $extraItems += [B2ItemInfo]::new('File', $bucketName, $entry)
          } else {
            # It's a subfolder, but we're not interested
            Write-Debug "  ignoring subfolder $($entry.fileName)"
          }
        }
      }
    }
  }

  foreach ($rawItem in $items) {
    if ($rawItem.Encrypted) {
      $expectedKeyItem = $rawItem.DecryptedName + '.key.enc'
      Write-Debug "looking for $expectedKeyItem in results list"
      $fromItems = $items | ?{ $_.ItemType -eq 'File' -and $_.Name -eq $expectedKeyItem }
      if ($fromItems) {
        $rawItem.KeyFile = $fromItems.Name
      } else {
        $fromExtras = $extraItems | ?{ $_.ItemType -eq 'File' -and $_.Name -eq $expectedKeyItem }
        if ($fromExtras) {
          $items += $fromExtras
          $rawItem.KeyFile = $fromExtras.Name
        }
      }
    }
  }

  $items
}

enum B2ItemType {
  File
  Folder
}

class B2ItemInfo {
  [B2ItemType]$ItemType
  [string]$Name
  [string]$Bucket
  [object]$OriginalB2Object
  [bool]$Encrypted
  [string]$DecryptedName
  [string]$KeyFile

  B2ItemInfo(
    [string]$ItemType,
    [string]$Bucket,
    [object]$B2Object
  ){
    $this.ItemType = $ItemType
    $this.OriginalB2Object = $B2Object
    $this.Bucket = $Bucket
    $this.Encrypted = $False

    if ($ItemType -eq 'File') {
      $this.Name = $B2Object.fileName
      if ($B2Object.fileName -like '*.enc') {
        $this.Encrypted = $True
        # We can't know if a keyfile exists that we can point to, so we have to leave it unset for now
        $this.DecryptedName = $B2Object.fileName -replace '\.enc$',''
      }
    } elseif ($ItemType -eq 'Folder') {
      $this.Name = Split-Path $B2Object.fileName
    }
  }

}
