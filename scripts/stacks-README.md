# /opt/stacks

Docker compose deploys for the team. One directory per project. If you
have a deploy account on this box, you can read/write everything here and
run docker directly — see **Access** below for what that actually means.

## Adding a new project

```bash
cd /opt/stacks
git clone <repo-url> <project-name>
cd <project-name>
```

- Directory name = project name = Dockge stack name. Keep it short and
  unambiguous (`simple-social-prod`, not `prod` or `app2`).
- Compose file goes at the top of the directory:
  `docker-compose.yml` / `compose.yaml` / `compose.yml`, any of the three.
- Bind container ports to `127.0.0.1:<port>`, never `0.0.0.0`. Public
  traffic comes in through Caddy, not directly to the container.
- Pick a port that's not already in use — check `docker ps` and
  `/etc/caddy/Caddyfile` before hardcoding one.
- Most stacks here `build:` from the checked-out Dockerfile rather than
  pulling a published `image:`. Match whatever the project already does.

## Deploying an update

```bash
cd /opt/stacks/<project>
git pull
docker compose up -d --build
```

`--build` matters — without it, a `git pull` that changed the Dockerfile
or source won't actually take effect, compose will just restart the
existing image.

## Dockge (web UI)

`http://<host>:5001`. Reads/writes `/opt/stacks` directly — a stack
created or edited in Dockge shows up as normal files here, and vice versa.
Good for a quick look at what's running or a one-off restart; for real
changes, still edit the compose file and deploy via git like above so the
change is tracked.

## Caddy (public routing)

One block per hostname in `/etc/caddy/Caddyfile`. New site:

```
yourapp.africacode.org {
	reverse_proxy 127.0.0.1:<port>
}
```

After any edit:

```bash
caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

Both commands work via sudo even for deploy accounts without full root —
no need to `sudo su` for this.

DNS is **not** on this box — it's in the ACA Cloudflare account. A new
hostname needs a DNS record added there (pointing at this host) before
the matching Caddy block does anything for anyone outside the server.

## Access — what you actually have

Deploy accounts are in the `docker` and `caddy` groups. In practice that
means:

- Full `docker`/`docker compose` — build, run, exec, logs, the works.
- **This is root-equivalent on the host.** `docker` group membership is
  not a sandboxed permission — anyone in it can get a real root shell via
  `docker run -v /:/host ...`. We know, and we've deliberately kept it
  this way rather than fighting it with wrapper scripts (tried that,
  turned into a maintenance mess). Don't do anything you wouldn't do as
  root, because you effectively are.
- `docker-escape-watch` runs as a backstop and logs (not blocks) container
  creates that look like a host-escape attempt — privileged mode, host
  pid/net namespace, or a mount of `/`, `/etc`, `/root`, `/home`, or the
  docker socket. It's a tripwire, not a guardrail.
- No full `sudo` — only the two Caddy commands above are permitted via
  sudoers.

Full reasoning and how accounts here are provisioned:
`~/.mydotfiles/scripts/limited-deploy-user.md`.

## Useful commands

```bash
docker ps                              # what's running, across all projects
docker compose logs -f                 # follow logs for the current project
docker compose down                    # stop + remove a project's containers
docker network prune                   # clean up orphaned networks after a `down` you forgot
```
