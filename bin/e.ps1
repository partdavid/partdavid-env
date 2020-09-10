#!/usr/bin/env pwsh


if ($env:REMOTE_EMACS_CLIENT_NAME) {
  $Args[-1] = "/ssh:$($env:REMOTE_EMACS_CLIENT_NAME):$(Join-Path -Path $PWD -ChildPath $Args[-1])"
}

Write-Host (@($Args) -join ',')

emacsclient @Args
