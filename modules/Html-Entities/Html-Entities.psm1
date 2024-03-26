$commands = @(
  'Add-UserHtmlEntity'
  'ConvertFrom-HtmlEntityCsv'
  'Get-HtmlEntity'
  'Expand-HtmlEntities'
  'Sync-HtmlEntities'
)

foreach ($command in $commands) {
  . "$PSScriptRoot/$command.ps1"
}
