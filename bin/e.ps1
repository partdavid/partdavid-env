#!/usr/bin/env pwsh

$cmd = $Args

if ($env:REMOTE_EMACS_CLIENT_NAME) {
  $cmd[-1] = "/ssh:$($env:REMOTE_EMACS_CLIENT_NAME):$(Join-Path -Path $PWD -ChildPath $Args[-1])"
}

# I use TCP for the Emacs server, because I also use it remotely
# from other machines
if (Test-Path -Path "~/.emacs.d/server/server") {
  $cmd += '-f','~/.emacs.d/server/server'
}

#Write-Host (@($Args) -join ',')

emacsclient @cmd
