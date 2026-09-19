# Deploy user recipe

Team deploy accounts on a shared `/opt/` deployment box: `docker` group +
Caddy access, plus `docker-escape-watch` as a detection backstop. This is
the actual model in use — arrived at after trying an ACL + sudo-wrapper
scheme to avoid `docker` group entirely (see "Stricter alternative" below)
and deciding the operational overhead wasn't worth it for the real risk
level here. Live on `lando` as of 2026-09-19.

## Why plain `docker` group is an acceptable call here

`docker` group is root-equivalent — anyone in it can get a host root shell:

```bash
docker run -v /:/host -it alpine chroot /host bash
```

This is well-documented (Docker's own docs, GTFOBins), not exotic. The
honest tradeoff:

- **Full isolation** (no docker group at all) means hand-building and
  maintaining a permission layer in front of Docker yourself — a sudo
  wrapper script, or ACLs, or both. That's real ongoing maintenance for a
  fairly low-probability threat (a trusted teammate deliberately or
  accidentally escalating), and it still doesn't give people ordinary
  tools like `docker ps`/`docker exec` without you re-implementing them
  one at a time.
- **Plain `docker` group + detection** gets everyone normal docker
  ergonomics, zero custom code to maintain, and a cheap backstop that logs
  the exact escape pattern if it ever happens. Doesn't prevent it — logs
  it. For a small trusted team that's the better trade than a hand-rolled
  wrapper that grows a new special case every time someone needs one more
  docker verb.

If you're on a box with untrusted or high-turnover users, or actual
compliance requirements, re-evaluate — this call is specific to "small
trusted team, own infra."

## 1. Create the user

```bash
NEWUSER=dreu   # <-- change per server/person

sudo useradd -m -s /bin/bash "$NEWUSER"
sudo passwd -l "$NEWUSER"          # lock password login, SSH key only

sudo mkdir -p /home/"$NEWUSER"/.ssh
sudo chmod 700 /home/"$NEWUSER"/.ssh
sudo touch /home/"$NEWUSER"/.ssh/authorized_keys
sudo chmod 600 /home/"$NEWUSER"/.ssh/authorized_keys
sudo chown -R "$NEWUSER":"$NEWUSER" /home/"$NEWUSER"/.ssh
```

Drop their public key into `authorized_keys` when you have it. Validate it
first — a truncated paste fails silently until they try to log in:

```bash
ssh-keygen -lf /path/to/their_key.pub   # must print a valid fingerprint, not an error
echo "ssh-rsa AAAA... dreu@laptop" | sudo tee -a /home/"$NEWUSER"/.ssh/authorized_keys
```

## 2. Deploy access — docker group

```bash
sudo usermod -aG docker "$NEWUSER"
```

That's the whole step. On boxes where `/opt/sites`/`/opt/stacks` are
`root:docker` setgid, this also grants write access to every project
there, same as everyone else on the team.

## 3. Edit a shared config file (e.g. Caddyfile) without sudo

Use a dedicated group for the file instead of chowning it to the user
personally — works even if the service already has an unused group (Caddy,
nginx, etc. usually create one on install).

```bash
getent group caddy   # confirm it exists; created automatically by the caddy package

sudo usermod -aG caddy "$NEWUSER"
sudo chgrp caddy /etc/caddy/Caddyfile
sudo chmod 664 /etc/caddy/Caddyfile
```

If the config is split into per-site include files under a directory
(`conf.d/*.conf`, `sites-enabled/*`), chgrp/chmod the directory instead so
new files inherit it:

```bash
sudo chgrp caddy /etc/caddy/conf.d
sudo chmod 2775 /etc/caddy/conf.d
```

Caddy reload doesn't need root at all if you grant it directly — it's not
docker-socket-equivalent, so a normal scoped sudoers entry is fine and
worth keeping regardless of docker group:

```bash
sudo visudo -f /etc/sudoers.d/"$NEWUSER"
```

```
dreu ALL=(root) NOPASSWD: /usr/bin/caddy validate --config /etc/caddy/Caddyfile, /usr/bin/systemctl reload caddy, /usr/bin/systemctl restart caddy
```

```bash
sudo chmod 440 /etc/sudoers.d/"$NEWUSER"
sudo visudo -c -f /etc/sudoers.d/"$NEWUSER"
```

## 4. Detection backstop — docker-escape-watch

One-time per server, not per user. Low overhead (~8MB RSS, idle CPU,
hard-capped at 50MB), watches `docker events` for container creates and
flags the escape pattern (`--privileged`, `pid=host`, `net=host`,
`cap_add=SYS_ADMIN/ALL`, or a bind mount to `/`, `/etc`, `/root`, `/home`,
or the docker socket). Logs via `logger`, journal tag
`docker-escape-watch`. Detection only, and it can't attribute *which* user
ran the command — Docker's event log doesn't carry that.

```bash
sudo cp scripts/docker-escape-watch.sh /usr/local/sbin/docker-escape-watch
sudo chown root:root /usr/local/sbin/docker-escape-watch
sudo chmod 755 /usr/local/sbin/docker-escape-watch

sudo cp scripts/docker-escape-watch.service /etc/systemd/system/docker-escape-watch.service
sudo systemctl daemon-reload
sudo systemctl enable --now docker-escape-watch
```

Verify it actually fires before trusting it:

```bash
sudo docker run --rm -d --name escapetest -v /:/host alpine sleep 1
sleep 2
sudo journalctl -t docker-escape-watch -n 5 --no-pager   # expect a SUSPICIOUS line
sudo docker rm -f escapetest
```

## 5. Verify

```bash
id "$NEWUSER"                 # expect: docker + caddy
sudo -l -U "$NEWUSER"         # expect: the caddy commands only
sudo -u "$NEWUSER" docker ps  # expect: works, no permission error
```

## Applying to an existing scoped/full-sudo user

```bash
sudo gpasswd -d "$NEWUSER" sudo    # if downgrading from full sudo — check groups first
sudo usermod -aG docker "$NEWUSER"
```

If they were on the ACL/wrapper scheme below, undo it:

```bash
sudo gpasswd -d "$NEWUSER" deploy 2>/dev/null || true
sudo setfacl -R -x g:deploy /opt/sites /opt/stacks 2>/dev/null || true
sudo setfacl -R -d -x g:deploy /opt/sites /opt/stacks 2>/dev/null || true
sudo rm -f /usr/local/sbin/deploy-restart   # only once no one still depends on it
```

---

## Stricter alternative: no docker group at all

Documented for later — a box with untrusted users, compliance
requirements, or a team large/volatile enough that "detect after the
fact" isn't good enough. Not in use on any current server. The real
structural fixes for that situation are:

- **Rootless Docker** — daemon runs as an unprivileged user, so even full
  access to it doesn't reach host root. Real fix, but a daemon migration:
  existing containers don't move themselves, and check any bind-mounted
  host paths shared with non-container processes (e.g. a directory a
  reverse proxy also reads from) for UID-remap ownership fallout before
  committing.
- **Docker socket proxy** (`tecnativa/docker-socket-proxy` or similar) —
  filters the real API by verb: allow `ps`/`start`/`stop`/`logs`, reject
  the specific calls that mount `/` or set `--privileged`. Prevents the
  escape outright without migrating anything, since the real daemon and
  existing containers are untouched.

The cheap-but-hand-maintained version we tried and backed out of: a
`deploy` group with recursive + default ACLs on `/opt/sites`/`/opt/stacks`
(so access covers every project, present and future, without `docker`
group), plus a root-owned sudo wrapper script validating project
name/path and exposing a fixed whitelist of actions
(`up`/`build`/`down`/`restart`/`pull`/`logs`) instead of raw `docker`
access. It worked and was tested against live prod, but every debugging
need (`exec`, live-following logs, cross-project `ps`) turned into another
wrapper feature to hand-maintain — that's the maintenance liability that
made plain `docker` group + detection the better call for this team.
