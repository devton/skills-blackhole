# Stack inventory (template)

Fill one row per service before changing anything; update it in the same change as any hardening step. audit-verify diffs the live audit against this table. Keep the filled table in the project (e.g. `docs/security/stack-inventory.md`).

| Service | Image (own/official) | uid | cap_add (justified) | read_only | Writable paths (tmpfs / volume) | Networks | Published ports | Host mounts | pids / mem / cpus | seccomp | Exceptions (why) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| app | own | 10001 | none | true | /tmp, /app/tmp (tmpfs); uploads (volume) | backend, egress, dokploy-network | none | none | 512 / 1g / 1.5 | default | - |

## How to collect each field

| Field | Command |
|---|---|
| uid | `docker compose exec SERVICE id` |
| capabilities | `grep CapBnd /proc/1/status` |
| read_only | `docker inspect -f '{{.HostConfig.ReadonlyRootfs}}' C` |
| writable paths | `EROFS` lines after readonly-rootfs, or `docker diff C` |
| host namespaces | `docker inspect -f '{{.HostConfig.NetworkMode}} {{.HostConfig.PidMode}} {{.HostConfig.IpcMode}}' C` |
| mounts | `docker inspect -f '{{range .Mounts}}{{.Source}} {{end}}' C` |
| networks | `docker inspect -f '{{json .NetworkSettings.Networks}}' C` |
| ports | `docker compose ps` |

## Red flags

uid 0 in an own image; `CapBnd` `00000000a80425fb` (untouched default) or all ones (privileged); `docker.sock` / `/` mounted; `host` namespace modes; data store on the proxy network; published port on a proxied service.
