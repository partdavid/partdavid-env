<#
.SYNOPSIS

Expand any HTML entities found in the string

.DESCRIPTION

This command substitutes any HTML entities (like &gt; or &#60;) found in
the string, according to two entity lists: an authoritative list from the
W3C (which must be synced to your machine using the Sync-HtmlEntities
command) and any "user-defined" entities you personally wish to use, which
you have added with the Add-UserHtmlEntity command.

I recommend setting an alias of 'xh' for this command, so that it can easily
be used in expressions, e.g., xh '&alpha;tlantis apply'.

#>
function Expand-HtmlEntities {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)] [string]$String
  )

  process {
    $String -replace '&([^;]+);',{ Get-HtmlEntity -Code $_.Groups[1] }
  }
}

