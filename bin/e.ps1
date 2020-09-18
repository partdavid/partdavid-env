#!/usr/bin/env pwsh

$cmd = $Args

if ($env:REMOTE_EMACS_CLIENT_NAME) {
  $target = $cmd[-1]
  if ([System.IO.Path]::IsPathRooted($target)) {
    $target = "/ssh:$($env:REMOTE_EMACS_CLIENT_NAME):$target"
  } else {
    $target = "/ssh:$($env:REMOTE_EMACS_CLIENT_NAME):$(Join-Path -Path $PWD -ChildPath $target)"
  }
  $cmd[-1] = $target
}

# I use TCP for the Emacs server, because I also use it remotely
# from other machines
if (Test-Path -Path "~/.emacs.d/server/server") {
  $cmd += '-f','~/.emacs.d/server/server'
}

Write-Host (@($cmd) -join ',')

emacsclient @cmd
