# Setup steps - Mac

Steps for a new workstation.

`EMAIL` is whatever your main email is, work etc.; for a Mac, probably
the email of your Apple ID. `NAME` is your name.

## From Web

- [ProFont](https://tobiasjung.name/profont/): https://tobiasjung.name/downloadfile.php?file=ProFontWinTweaked.zip
- Install homebrew
    ```
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```

## Homebrew

- [./Brewfile](./Brewfile)
    - iTerm2
    - Alt-Tab
    - Karabiner-Elements
    - Emacs
    - Etc.

## My environment

- git clone https://github.com/partdavid/partdavid-env
    ```
    git config user.name 'P D'
    git config user.email partdavid@gmail.com
    ```
- cd partdavid-env
- ./installenv.ps1

- git configuration

```
git config --global user.email EMAIL
git config --global user.name NAME
```
