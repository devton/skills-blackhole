---
name: "container-hardening-namespace-isolation"
description: "Workflow contract for /container-hardening namespace-isolation. Loaded by the container-hardening orchestrator."
---

# container-hardening.workflow.namespace-isolation

## Goal

Every service keeps its own pid/net/ipc/uts/mount namespaces, data stores sit on an internal network, and only proxied services join the reverse-proxy network.

## Scope

- Applies to: compose `networks`, `network_mode`, `pid`, `ipc`, host mounts, published ports.
- Does not cover: user namespaces (`userns-remap`) and `docker.sock`/`privileged` (`socket-privileged`).

## Triggers

- Files: `network_mode: host`, `pid: host`, `ipc: host`, mounts of `/`, `/proc`, `/sys`; a database on the proxy network; a `ports:` entry on a proxied service.
- Intent: "isolate the database", "split networks", "why is this port open".

## Inputs

- Compose file(s); which services receive traffic from the proxy; which need outbound internet; proxy network name (`dokploy-network` on Dokploy).

## Invariants

- Hard rules of `SKILL.md`.
- Data stores only on `internal: true` networks.
- Cross-project access uses a dedicated shared network, never the whole proxy network.
- Long-lived gRPC/WebSocket connections use internal endpoints, not a public domain behind a CDN.

## Procedure

1. Remove host namespace modes from application services; set `ipc: private` explicitly.
2. Define networks:
   ```yaml
   networks:
     backend: { internal: true }
     egress: {}
     dokploy-network: { external: true }
   ```
3. Attach: data stores → `backend`; workers/jobs → `backend, egress`; proxied services → `backend, egress, dokploy-network`.
4. Remove `ports:` from services the proxy routes.
5. Host exporters that need `/proc`, `/sys`, `/`: read-only mounts, no published port, baseline applied, exception comment.
6. Update the inventory; run `audit-verify`.

## Outputs

- Compose diff, inventory "Networks"/"Published ports"/"Host mounts" columns, audit-verify output.

## Review gate

- [ ] Namespace inodes (`readlink /proc/1/ns/<type>`) differ between host and container for net, pid, ipc, uts, mnt.
- [ ] From a data store: `wget -qO- -T 3 https://example.com` fails.
- [ ] `docker network inspect <proxy-network> -f '{{range .Containers}}{{.Name}} {{end}}'` lists only proxied services (plus platform services).
- [ ] No published port on proxied services.

## References

- `SKILL.md`, `namespaces.md`
- namespaces(7), network_namespaces(7), Docker "Networking overview", "Packet filtering and firewalls"
