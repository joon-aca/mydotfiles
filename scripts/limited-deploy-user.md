# Limited-access deploy user recipe

Creates a deploy account that can work on **any** project under `/opt/` (a
shared team deployment box, not a personal sandbox) and restart docker
compose projects, without `docker` group membership and without full sudo.
No `sudo`/`wheel` group. Tested end-to-end on a live team box on
2026-09-17/18: verified a limited user can write into a teammate's existing
prod project, that new projects auto-inherit the same access, that
`deploy-restart` works against a real running prod stack, and that raw
`docker` access is denied throughout. Also used to downgrade three existing
full-sudo/docker-group users without breaking their live prod deploy.

## Status / known limitation

`deploy-restart` (step 4) covers `up`/`build`/`down`/`restart`/`pull`/`logs`
scoped to one project — enough for "deploy and keep it running," not enough
for interactive debugging (no `exec`, no live-following logs, no `ps`
across projects). Hand-extending a root-run wrapper script every time
someone needs one more docker verb is a maintenance liability, not a
long-term interface — treat it as a stopgap. The structural fixes are
rootless Docker (real fix, but a daemon migration — check bind-mounted
volumes for UID-remap fallout first) or a docker-socket-proxy filtering the
real API by verb (prevents the group escalation below without migrating
anything). Neither is set up here yet; this recipe is still the "cheap
enough to actually deploy today" version.

## Why not just add them to `docker` group

That was the first draft of this recipe and it's wrong — don't do it.

1. **`docker` group is root-equivalent.** Anyone in it can mount the host
   filesystem via a container and get root, no sudo needed:

   ```bash
   docker run -v /:/host -it alpine chroot /host bash
   ```

   This is a well-documented escalation (Docker's own docs, GTFOBins), not
   exotic.

2. **On boxes where `/opt/sites`/`/opt/stacks` are `root:docker` setgid,**
   `docker` group also happens to be what grants deploy write access — so
   removing it to fix (1) breaks git pulls into `/opt/` unless you replace
   it with something else. That something else is ACLs (step 2 below), not
   sudoers — sudoers can't grant plain filesystem write.

If a user genuinely needs broad docker access (not just "restart my one
compose project"), don't use this recipe as-is — use rootless Docker or a
filtered socket proxy (e.g. `tecnativa/docker-socket-proxy`) instead.

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

Drop their public key into `authorized_keys` when you have it:

```bash
echo "ssh-ed25519 AAAA... dreu@laptop" | sudo tee -a /home/"$NEWUSER"/.ssh/authorized_keys
```

## 2. Deploy write access — a `deploy` group with recursive ACL

**This is a team box** — deployers need to be able to fix/update each
other's live projects, not just their own. A plain per-user ACL scoped to
"can create their own new directory" is the wrong shape here (that's the
sandboxed-contractor variant, see note at the end). Use a dedicated group
plus a *recursive* ACL so access covers every project that exists today,
and a *default* ACL so it automatically covers every project created from
now on — reproducing exactly what `docker` group gave you for free, minus
the root-equivalent socket.

```bash
sudo apt-get install -y acl   # only libacl1 ships by default; the CLI tools don't

getent group deploy || sudo groupadd deploy
sudo usermod -aG deploy "$NEWUSER"

# one-time per server: wire the group into the deploy roots
sudo setfacl -R -m g:deploy:rwx /opt/sites /opt/stacks
sudo setfacl -R -d -m g:deploy:rwx /opt/sites /opt/stacks
```

The recursive `-m` covers files/dirs that already exist; the recursive
`-d` (default ACL) makes every *future* file or directory created anywhere
under `/opt/sites`/`/opt/stacks` — by anyone — inherit `deploy` group
access automatically. Run the two `setfacl` lines once per server; after
that, onboarding a new deployer is just the `groupadd`-if-missing +
`usermod` above.

Verify against a project that already exists and belongs to someone else
(don't just check a fresh dir — that proves nothing about the team-wide
case):

```bash
getfacl /opt/stacks/<some-existing-project-you-dont-own> | grep -E "^# file|^group:deploy"
sudo -u "$NEWUSER" touch /opt/stacks/<that-project>/.write-test && echo OK && sudo rm /opt/stacks/<that-project>/.write-test
```

If `docker` group membership was already granted (e.g. from an earlier,
wrong pass at this), remove it:

```bash
sudo gpasswd -d "$NEWUSER" docker
```

**Sandboxed variant** (contractor who should only touch their own new
project, not teammates' work): skip the group, use a non-recursive
per-user ACL instead —

```bash
sudo setfacl -m u:"$NEWUSER":rwx /opt/sites /opt/stacks
```

— which only grants permission to create a new directory at the top level;
whatever they create there they own outright as creator, and existing
projects belonging to others stay untouched.

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
new files inherit it — cleaner than editing one shared file directly:

```bash
sudo chgrp caddy /etc/caddy/conf.d
sudo chmod 2775 /etc/caddy/conf.d
```

## 4. Docker compose restart — via a validated wrapper, not raw sudoers

Raw `docker compose -f /opt/sites/<project>/docker-compose.yml up -d` in
sudoers only works for one project whose path you already know, and using a
sudoers wildcard to cover future projects is an injection risk. Use a
small root-owned wrapper instead — one fixed sudoers entry covers any
project the user creates under `/opt/sites` or `/opt/stacks`, forever.

```bash
sudo tee /usr/local/sbin/deploy-restart > /dev/null <<'SCRIPT'
#!/usr/bin/env bash
# Pull + (re)start a docker compose project under /opt/sites or /opt/stacks.
# Invoked via sudo by deploy accounts with no general docker/root access.
set -euo pipefail

usage() {
  echo "usage: deploy-restart <sites|stacks> <project-name> [up|down|restart|pull|logs]" >&2
  exit 1
}

[[ $# -ge 2 ]] || usage

BASE=$1
PROJECT=$2
ACTION=${3:-up}

case "$BASE" in
  sites)  ROOT=/opt/sites ;;
  stacks) ROOT=/opt/stacks ;;
  *) echo "invalid base: $BASE (must be 'sites' or 'stacks')" >&2; exit 1 ;;
esac

[[ "$PROJECT" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "invalid project name: $PROJECT" >&2; exit 1; }

TARGET="$ROOT/$PROJECT"
REAL=$(readlink -f -- "$TARGET" 2>/dev/null || true)
[[ -n "$REAL" && "$REAL" == "$ROOT"/* ]] || { echo "refusing to operate outside $ROOT" >&2; exit 1; }
[[ -d "$TARGET" ]] || { echo "no such project: $TARGET" >&2; exit 1; }

COMPOSE_FILE=""
for f in docker-compose.yml compose.yaml compose.yml; do
  [[ -f "$TARGET/$f" ]] && COMPOSE_FILE="$f" && break
done
[[ -n "$COMPOSE_FILE" ]] || { echo "no compose file found in $TARGET" >&2; exit 1; }

cd "$TARGET"

case "$ACTION" in
  up)      docker compose pull && docker compose up -d --remove-orphans ;;
  down)    docker compose down ;;
  restart) docker compose restart ;;
  pull)    docker compose pull ;;
  logs)    docker compose logs --tail=200 ;;
  *) echo "invalid action: $ACTION" >&2; exit 1 ;;
esac
SCRIPT
sudo chown root:root /usr/local/sbin/deploy-restart
sudo chmod 755 /usr/local/sbin/deploy-restart
```

Why the script is safe to grant NOPASSWD as a whole (not per-argument):
project name is regex-validated (`[a-zA-Z0-9_-]` only, no `../`), the
resolved real path is checked to still be inside the intended root, and
the action is a fixed whitelist — there's no way to smuggle in an arbitrary
shell command through the arguments.

## 5. Scoped sudoers drop-in

```bash
sudo visudo -f /etc/sudoers.d/"$NEWUSER"
```

```
dreu ALL=(root) NOPASSWD: /usr/local/sbin/deploy-restart, /usr/bin/caddy validate --config /etc/caddy/Caddyfile, /usr/bin/systemctl reload caddy, /usr/bin/systemctl restart caddy
```

`visudo` validates syntax on save so a typo can't lock out sudo entirely.
Adjust the Caddy commands to whatever service/commands this user actually
needs — keep every entry to a full, specific path (no wildcards, no bare
`systemctl`) so the grant can't be leveraged into unrelated root actions.

Lock the file down and re-validate:

```bash
sudo chmod 440 /etc/sudoers.d/"$NEWUSER"
sudo visudo -c -f /etc/sudoers.d/"$NEWUSER"
```

## 6. Verify

```bash
id "$NEWUSER"                 # expect: deploy + caddy, NOT docker, NOT sudo/wheel
sudo -l -U "$NEWUSER"         # expect: only deploy-restart + the caddy commands
```

Prove it actually works end-to-end before handing over the account — test
against your **own throwaway project**, then separately against an
**existing teammate's live project**, since that second case is the whole
point of the `deploy` group and a self-created dir won't catch a bad ACL:

```bash
sudo -u "$NEWUSER" bash -c 'mkdir -p /opt/sites/smoketest && cd $_ && cat > docker-compose.yml <<EOF
services:
  hello:
    image: hello-world
EOF'
sudo -u "$NEWUSER" sudo deploy-restart sites smoketest up
sudo -u "$NEWUSER" bash -c 'cd /opt/sites/smoketest && docker compose down' \
  && echo "FAIL: user has raw docker access" \
  || echo "OK: raw docker access correctly denied"
sudo rm -rf /opt/sites/smoketest

# team-wide access check — pick a real existing project owned by someone else
sudo -u "$NEWUSER" sudo deploy-restart stacks <existing-project> logs | tail -5
```

## Applying to an existing full-sudo/docker-group user

```bash
sudo gpasswd -d "$NEWUSER" sudo             # or 'wheel' — check `groups $NEWUSER` first
sudo gpasswd -d "$NEWUSER" docker
```

If they're covered by a shared `sudoers.d` alias file used by other users
who are *not* being downgraded, don't delete the whole file — edit the
`User_Alias` to drop just this user and leave the rest intact:

```bash
sudo visudo -f /etc/sudoers.d/<the-shared-file>
```

Then run steps 2–5 above for them (the `deploy`/`caddy` group setup is
idempotent — safe to run against an existing user).

Confirm their actual deploy workflow first (which projects, which compose
actions, any other services they restart) — full sudo can be papering over
a need you haven't scoped yet, and downgrading without checking is how you
get the "it's broken" call. Prove it *didn't* break anything by testing the
downgraded user against a real live project they actually run (see the
`deploy-restart ... logs` check in step 6) before considering it done —
don't just trust that removing access "should" be fine.

## Backstop: detect docker-group escape attempts

`docker` group membership isn't a separate vulnerability that leads to
root — it *is* root, by design (anyone who can talk to the daemon socket
can ask it to mount `/` into a container it then runs as root). There's no
partial-trust tier built into the Docker API itself. If anyone on a box
still has `docker` group (admins who need it, or before you've migrated
everyone off it), `scripts/docker-escape-watch.sh` is a cheap detection
backstop — not prevention, and it doesn't record *which* user issued the
command (Docker's event log doesn't carry that), just that a container
matching the escape pattern got created.

It watches `docker events` for container creates and flags anything with
`--privileged`, `pid=host`, `net=host`, a dangerous `cap_add`
(`SYS_ADMIN`/`ALL`), or a bind mount to `/`, `/etc`, `/root`, `/home`, or
the docker socket. Logs via `logger` to the journal, tag
`docker-escape-watch`. Idle CPU, ~8MB RSS, hard-capped at 50MB.

Install on a new server:

```bash
sudo cp scripts/docker-escape-watch.sh /usr/local/sbin/docker-escape-watch
sudo chown root:root /usr/local/sbin/docker-escape-watch
sudo chmod 755 /usr/local/sbin/docker-escape-watch

sudo cp scripts/docker-escape-watch.service /etc/systemd/system/docker-escape-watch.service
sudo systemctl daemon-reload
sudo systemctl enable --now docker-escape-watch
```

Verify it actually fires before trusting it — don't just check the service
is "active":

```bash
sudo docker run --rm -d --name escapetest -v /:/host alpine sleep 1
sleep 2
sudo journalctl -t docker-escape-watch -n 5 --no-pager   # expect a SUSPICIOUS line
sudo docker rm -f escapetest
```
