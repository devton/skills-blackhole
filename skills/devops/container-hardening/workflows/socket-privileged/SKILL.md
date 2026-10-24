---
name: "container-hardening-socket-privileged"
description: "Workflow contract for /container-hardening socket-privileged. Loaded by the container-hardening orchestrator."
---

# container-hardening.workflow.socket-privileged

## Goal

No project container talks to `/var/run/docker.sock` directly and no project container runs `privileged`.

## Scope

- Applies to: metrics collectors, backup tools, admin panels and any service mounting the socket or using `privileged`.
- Does not cover: platform services that need the socket by design (reverse proxy, Dokploy itself); list them in the inventory.

## Triggers

- Files: `/var/run/docker.sock` in `volumes`; `privileged: true`; `devices:` with host devices.
- Intent: "remove privileged", "secure docker.sock".

## Inputs

- Services using the socket and which API calls they need (usually read-only container listing/stats); vendor docs for any `privileged` service.

## Invariants

- Hard rules of `SKILL.md`.
- A `:ro` socket mount is not a control: anyone who reaches the API can start a privileged container with `/` mounted.
- The socket proxy never joins the reverse-proxy network (it has no authentication).

## Procedure

1. Socket consumers: add a socket proxy that allows only what they need, and point them at it.
   ```yaml
   docker-socket-proxy:
     image: tecnativa/docker-socket-proxy:0.3.0
     environment:
       CONTAINERS: 1
       POST: 0
     volumes:
       - /var/run/docker.sock:/var/run/docker.sock:ro
     networks: [metrics]

   stats-collector:
     environment:
       DOCKER_HOST: tcp://docker-socket-proxy:2375
     networks: [metrics]
   ```
2. `privileged` services: replace with the exact `cap_add` + `devices` from vendor docs. If the service is redundant, propose removing it. If unavoidable, keep it isolated (own network, no published port) with an exception comment.
3. Recreate, verify consumers still work.
4. Update the inventory; run `audit-verify`.

## Outputs

- Compose diff, list of remaining platform socket users, inventory exceptions, audit-verify output.

## Review gate

- [ ] `docker ps -q | xargs docker inspect -f '{{.Name}} {{.HostConfig.Privileged}}' | grep true` is empty (or lists only documented exceptions).
- [ ] `docker.sock` is mounted only by the socket proxy and platform services.
- [ ] From a proxy client, `docker run alpine true` fails with 403.

## References

- `SKILL.md`, `capabilities.md`, `namespaces.md`
- Docker "Docker daemon attack surface", "Protect the Docker daemon socket"
