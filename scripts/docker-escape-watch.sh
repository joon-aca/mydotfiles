#!/usr/bin/env bash
# Low-overhead backstop: watches for docker container creations that look like
# a docker-group -> host-root escape (bind-mounting /, --privileged, host
# pid/net namespace, dangerous capabilities) and logs them. Detection only —
# does not block anything. Blocks on `docker events`, near-zero CPU at idle.
set -euo pipefail

log() {
  logger -t docker-escape-watch -p auth.warning "$1"
}

docker events --filter type=container --filter event=create --format '{{.Actor.ID}}' 2>/dev/null |
while read -r cid; do
  [[ -z "$cid" ]] && continue
  json=$(docker inspect "$cid" 2>/dev/null) || continue

  privileged=$(jq -r '.[0].HostConfig.Privileged' <<<"$json")
  pidmode=$(jq -r '.[0].HostConfig.PidMode' <<<"$json")
  netmode=$(jq -r '.[0].HostConfig.NetworkMode' <<<"$json")
  capadd=$(jq -r '.[0].HostConfig.CapAdd // [] | join(",")' <<<"$json")
  binds=$(jq -r '.[0].HostConfig.Binds // [] | join(" ")' <<<"$json")
  mountsrcs=$(jq -r '.[0].Mounts // [] | map(.Source) | join(" ")' <<<"$json")
  image=$(jq -r '.[0].Config.Image' <<<"$json")

  flag=""
  [[ "$privileged" == "true" ]] && flag+="privileged "
  [[ "$pidmode" == "host" ]] && flag+="pid=host "
  [[ "$netmode" == "host" ]] && flag+="net=host "
  [[ "$capadd" =~ (SYS_ADMIN|ALL) ]] && flag+="cap_add=$capadd "

  for src in $binds $mountsrcs; do
    src="${src%%:*}"
    case "$src" in
      /|/root|/etc|/home|/var/run/docker.sock)
        flag+="sensitive_mount=$src "
        ;;
    esac
  done

  if [[ -n "$flag" ]]; then
    log "SUSPICIOUS container create id=${cid:0:12} image=$image flags=[$flag]"
  fi
done
