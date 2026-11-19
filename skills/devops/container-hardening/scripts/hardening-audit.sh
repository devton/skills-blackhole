#!/bin/sh
# Prints one line per running container with the hardening state read from
# /proc/1/status and docker inspect. Optional $1 filters container names.
# Usage: sh hardening-audit.sh [name-filter]
set -eu
filter="${1:-}"
for c in $(docker ps -q ${filter:+--filter "name=$filter"}); do
  name=$(docker inspect -f '{{.Name}}' "$c")
  st=$(docker exec "$c" cat /proc/1/status 2>/dev/null || true)
  if [ -z "$st" ]; then
    pid=$(docker inspect -f '{{.State.Pid}}' "$c")
    st=$(cat "/proc/$pid/status" 2>/dev/null || true)
  fi
  uid=$(echo "$st" | awk '/^Uid:/{print $2}')
  bnd=$(echo "$st" | awk '/^CapBnd:/{print $2}')
  nnp=$(echo "$st" | awk '/^NoNewPrivs:/{print $2}')
  sec=$(echo "$st" | awk '/^Seccomp:/{print $2}')
  docker inspect -f "$name uid=${uid:-?} capbnd=${bnd:-?} nnp=${nnp:-?} seccomp=${sec:-?} ro={{.HostConfig.ReadonlyRootfs}} pids={{.HostConfig.PidsLimit}} priv={{.HostConfig.Privileged}} net={{.HostConfig.NetworkMode}} pidmode={{.HostConfig.PidMode}} sock={{range .Mounts}}{{if eq .Source \"/var/run/docker.sock\"}}yes{{end}}{{end}}" "$c"
done
