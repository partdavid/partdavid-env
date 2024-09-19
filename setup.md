# Debian/arm64 (like chromebook)

## Initial packages

- `sudo apt-get update`
- `sudo apt-get upgrade`
- `sudo apt-get install -y 7zip emacs`

## Profont

- Download [Profont tweaked archive](https://tobiasjung.name/downloadfile.php?file=ProFontWinTweaked.7z)
- Unpack: `7zz x ProFontWinTweaked.7z && sudo cp -R ProFontWinTweaked /usr/share/fonts/truetype`

## Powershell

Download and install

```
curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.4.5/powershell-7.4.5-linux-arm64.tar.gz
sudo mkdir -p /opt/microsoft/powershell/7
sudo tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7
sudo chmod +x /opt/microsoft/powershell/7/pwsh
sudo ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
```

Once you're sure it works:

```
mkdir -p ~/.bash_hosts
cat <<EOF >~/.bash_hosts/"${HOSTNAME}"
#!bash
if [[ $(ps -o comm= | grep pwsh | wc -l) -lt 1 ]]
then
  pwsh
fi
```

## Install 1Password

Download and install from [binary file](https://support.1password.com/install-linux/#other-distributions-or-arm-targz)

```
curl -sSO https://downloads.1password.com/linux/tar/stable/aarch64/1password-latest.tar.gz
sudo tar -xf 1password-latest.tar.gz
sudo mkdir -p /opt/1Password
sudo mv 1password-*/* /opt/1Password
sudo /opt/1Password/after-install.sh
```

Run:

```
1password
```

Probably enable CLI integration and SSH agent. Set your SSH agent in the environment.

## Clone this repo

```
git clone https://github.com/partdavid/partdavid-env
cd partdavid-env
./installenv.ps1
```

Maybe add other environment stuff in `~/.pwsh_hosts/${env:HOSTNAME}.ps1`

## Work Stuff for AWS

- Configure AWS

