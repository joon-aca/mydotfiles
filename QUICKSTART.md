# QUICKSTART

Provisioning a fresh Mac is a two-step process:

1. **`mydotfiles`** (this repo) — shell, git, tmux, editors, CLI tools
2. **[`macos-ssh-vault`](https://github.com/joon-aca/macos-ssh-vault)** — SSH config and keys, deployed from an AES-256 encrypted iCloud vault

## macOS

```bash
xcode-select --install

# Step 1 — base dev environment
git clone https://github.com/joon-aca/mydotfiles.git ~/.mydotfiles
~/.mydotfiles/bootstrap.sh

# Step 2 — SSH identity (config + keys, from encrypted vault)
git clone git@github.com:joon-aca/macos-ssh-vault.git ~/.macos-ssh-vault
~/.macos-ssh-vault/bootstrap ssh-canonical

exec zsh
```

> Step 2 is macOS-only and requires an iCloud account with the vault sparsebundle synced.
> `mydotfiles` does not manage `~/.ssh` — that's entirely owned by `macos-ssh-vault`.

## Ubuntu / Debian

Linux servers don't use the SSH vault — only step 1 applies.

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/joon-aca/mydotfiles.git ~/.mydotfiles
~/.mydotfiles/bootstrap.sh
exec zsh
```

## Optional: server hardening (run first on fresh boxes)

```bash
./harden.sh -u joon -h myhostname
```

## Optional: server software (Docker, Caddy, Dockge)

```bash
./server-setup.sh
```
