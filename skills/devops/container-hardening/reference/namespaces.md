# Namespaces digest (namespaces(7) + Docker)

Source: https://man7.org/linux/man-pages/man7/namespaces.7.html, user_namespaces(7), https://docs.docker.com/engine/security/userns-remap/

- Eight types: cgroup, ipc, network, mount, pid, time, user, uts. Each process's are visible in `/proc/<pid>/ns/`.
- Docker creates a new namespace of each type per container **except user and time**. Without a user namespace, uid 0 in the container is uid 0 on the host.
- In a user namespace, capabilities only apply to resources governed by that namespace; container root maps to an unprivileged host uid (e.g. 100000).

## Forbidden in application services

| Key | Leak |
|---|---|
| `network_mode: host` | all host ports and interfaces, including 127.0.0.1 services |
| `pid: host` | see/signal host processes; with `SYS_PTRACE`, read their memory |
| `ipc: host` | host System V / POSIX shared memory |
| `userns_mode: host` | cancels userns-remap |
| mounting `/`, `/proc`, `/sys`, `docker.sock` | host filesystem / full daemon control |

Host metrics exporters may mount `/`, `/proc`, `/sys` read-only, with no published port and with baseline-service applied. Document them as exceptions.

## Networks

- `internal: true` networks have no route out: put data stores there.
- Only services routed by the reverse proxy join its network (`dokploy-network` on Dokploy). Many projects share that network on one host, so a database on it is reachable by every other project.
- Published ports bypass UFW (Docker writes its own iptables rules). Remove them once the proxy routes the service.

## Checks

- `readlink /proc/1/ns/{net,pid,ipc,uts,mnt}` on host vs `docker compose exec SERVICE readlink ...`: inodes must differ.
- `docker inspect -f '{{.HostConfig.NetworkMode}} {{.HostConfig.PidMode}} {{.HostConfig.IpcMode}}' CONTAINER`
- `cat /proc/self/uid_map` inside: `0 0 4294967295` = no remap; `0 100000 65536` = remapped.
