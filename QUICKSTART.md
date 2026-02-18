# QUICKSTART

## macOS

```bash
xcode-select --install
git clone git@github.com:joon-aca/mydotfiles.git ~/mydotfiles
cd ~/mydotfiles
./bootstrap.sh
exec zsh
```

## Ubuntu / Debian

```bash
sudo apt update && sudo apt install -y git
git clone git@github.com:joon-aca/mydotfiles.git ~/mydotfiles
cd ~/mydotfiles
./bootstrap.sh
exec zsh
```

## Optional: server hardening (run first on fresh boxes)

```bash
./harden.sh -u joon -h myhostname
```
