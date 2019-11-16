Environment Files
=================

This is my specialized set of environment files. It's broken into some
pieces so other users can try out some of them. I've switched to
Powershell, so this includes both bash and Powershell profiles.

I have a weird editor setup so I doubt anyone really wants to share (I
use a Dvorak keyboard layout, prefer Emacs with Viper (vi keybindings)
but can use Vim in a pinch). Using Dvorak with vi keys means I have
shifted the hand position of cursor controls to the left by one
position. That's why `viper`, `vimrc` and `inputrc` all remap `hjkl`
to `htns`.

Files
-----

`Microsoft.PowerShell_profile.ps1`
    My powershell profile. This is not modularized, so it has both
    preference-setting as well as custom prompt and utility function
    code. Namely, the `use` command to set your "context" and some
    hacks around the lack of a proper shell function implementation
    in `rbenv` and `pyenv`.

`bashrc`
    This ties all the bashbits together by setting things like the
    **ENV_HOME** variable, **EDITOR** and things like that. It picks
    up customizations in the home directory, sets the prompt,
    etc. It's what you really don't want to source unless you're in
    for the full ride. Note that `bash_profile` is just a symlink
    to `bashrc`.

`dot-emacs`
    My `.emacs` file.

`dot-vimrc`
    My `.vimrc` file. I use mainly emacs, so this is minimal (just the
    cursor keys and stuff).

`dot-inputrc`
    The readline config that remaps cursor keys for vi-based line
    editing in any program using libreadline.

`dot-viper`
    A small config for VIPER, the Emacs package that emulates Vi.

`bin/editor`
    A convenience script that has the correct command lines for
    invoking Emacs (if installed) and Vim with the right arguments
    to make them pick up the replacement dot-files.

`bin/sup`
    A convenience wrapper for `sudo` that runs a command with sudo if provided;
    but if you run `sup -` it gives you a login-type shell with this environment
    established.

`bash_prompt`
    Code to set your bash prompt. The result of much R&D over the years.

Installation
------------

Install the Powershell environment by doing `bin/installenv`.

Install the bash environment by copying the files to the appropriate
locations.


Use/Features
------------

The following convenience aliases are provided:

* **r** - To re-read environment files

For **bash**:

You can provide various local customizations to the environment (for
example, if you want your enviroment to differ between different
machines).

The `bashrc` environment file sources the following if they exist
(it will source the file in `$ENV_HOME/<file>` or `~/.<file>` both):

* `bash_hosts/<hostname>` - For host-specific settings
* `bash_tz` - For setting the timezone separately
* `bash_path` - For adding things to the path
* `bash_aliases` - For setting aliases
* `bash_functions` - For your bash functions

These are provided as separate files so you can use them for
customization without necessarily editing `bashrc`.

If you have `pyenv`, `rbenv` or `nodeenv` installed, the `bashrc`
will initialize the environment for use.


Prompt
~~~~~~

A bash prompt of the common `user@host:dir$ ` form. It is enhanced
with the following features:

* It sets the window title to the prompt

* The current directory is color-coded according to your
  permissions. It's green if you own it, blue if you can write
  to it and red if you can't.

* Your username is underlined if you have access to an ssh-agent.

* If the last command had a non-zero exit code, it is given in
  parens before the prompt character, bold and in red.

* If you are in a git directory, the branch name is given between
  square brackets. Since caution is often required when you are
  on **master**, this fact is highlighted by bolding the branch.

Those are fairly typical features, but a couple of things make this
really special: namely, the code that determines you are in a git
directory (indeed, the whole prompt command that calculates all these
things), *does not fork*. It does not invoke the `git` command or do
command interpolation in PS1. This is important for sysadmin types who
may need to log into systems which are overloaded and for which a rich
prompt can cause problems.

Secondly, if you are on a terminal that doesn't support ANSI codes
(this is a fixed list and not determined by termcap), various decorations
are substituted for the colors (you can see this in screen, for example).

Namely:

* Instead of being bolded, the branchname **master** is decorated with
  stars (`*`).
* Instead of being underlined when you have an ssh-agent, your username
  has an arrow by it.
* Instead of being colored according to your permissions, your current
  directory has the following characters:
  - star (`*`) if you own it (because you can do everything)
  - plus (`+`) if you have write permission (because you can do some things)
  - nothing () if you cannot write to it
