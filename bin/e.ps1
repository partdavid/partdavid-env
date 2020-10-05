#!/usr/bin/env pwsh

$cmd = $Args

if (-not $env:ALTERNATE_EDITOR) {
  foreach ($candidate in 'emacs','vim','vi') {
    if (Get-Command $candidate -ErrorAction SilentlyContinue) {
      Set-Content -Path Env:ALTERNATE_EDITOR -Value $candidate
      break
    }
  }
}

if (-not (Get-Command emacsclient -ErrorAction SilentlyContinue)) {
  & $env:ALTERNATE_EDITOR @Args
} else {

  if ($env:SSH_CONNECTION) {
    if ($env:REMOTE_EMACS_CLIENT_NAME) {
      $remote_emacs_client_name = $env:REMOTE_EMACS_CLIENT_NAME
    } else {
      $remote_emacs_client_name = uname -n
    }

    $target = $cmd[-1]
    if ([System.IO.Path]::IsPathRooted($target)) {
      $target = "/ssh:$($remote_emacs_client_name):$target"
    } else {
      $target = "/ssh:$($remote_emacs_client_name):$(Join-Path -Path $PWD -ChildPath $target)"
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
}
