# Setup

In this directory is a setup script for shell, setup.sh, which
determines the host OS, and then on that basis, selects an
OS-specific setup script. This setup script:

- Installs Microsoft Powershell according to the
  [instructions](https://learn.microsoft.com/en-us/powershell/scripting/install)

It's idempotent and dependent only on standard (POSIX?) /bin/sh.

It's intended to be used in this setup process (on a vanilla install
of anything):

1. Clone https://github.com/partdavid/partdavid-env
2. Run setup/setup.sh
3. Run ./installenv.ps1
