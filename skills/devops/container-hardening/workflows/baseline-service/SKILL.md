---
name: "container-hardening-baseline-service"
description: "Workflow contract for /container-hardening baseline-service. Loaded by the container-hardening orchestrator."
---

# container-hardening.workflow.baseline-service

## Goal

Bring one service to the baseline: non-root user, `cap_drop: [ALL]` plus justified `cap_add`, `no-new-privileges`, default seccomp, and pids/memory/CPU limits.

## Scope

- Applies to: one service in a docker-compose file and, for own images, its Dockerfile.
- Does not cover: read-only rootfs (`readonly-rootfs`), networks (`namespace-isolation`), daemon settings (`userns-remap`).

## Triggers

- Files: a new `services.<name>` block; a Dockerfile without `USER`; a service without `cap_drop`.
- Intent: "harden service X", "drop capabilities", "stop running as root", "add resource limits".

## Inputs

- `service`: compose service name.
- `imageKind`: `own` (we build it) or `official` (Postgres, Redis, nginx...).
- `uid`: non-root uid for own images (default `10001`).
- Current inventory row from `stack-inventory.md`.

## Invariants

- Hard rules of `SKILL.md`.
- `USER` uses a numeric `uid:gid`.
- Every `cap_add` entry has a comment with the reason; start from the table in `capabilities.md`.
- No `privileged`, no `seccomp=unconfined`.

## Procedure

1. Read the inventory row and the current compose/Dockerfile for `service`.
2. Own image: add a user in the final stage and switch to it.
   ```dockerfile
   # Alpine
   RUN addgroup -S -g 10001 app && adduser -S -D -H -u 10001 -G app app
   # Debian/slim
   RUN groupadd -g 10001 app && useradd -u 10001 -g app -m -s /usr/sbin/nologin app
   USER 10001:10001
   ```
   Fix ownership of existing named volumes once (`chown`) or recreate them.
3. Add the reusable anchor (once per compose file) and merge it into the service:
   ```yaml
   x-hardened: &hardened
     cap_drop: [ALL]
     security_opt:
       - no-new-privileges:true
     ipc: private

   services:
     app:
       <<: *hardened
       pids_limit: 512   # threads count as tasks
       mem_limit: 1g
       cpus: "1.5"
   ```
   Merging several anchors: `<<: [*base, *hardened]`. Lists are not concatenated: a service-level `tmpfs` replaces the anchor's.
4. Official image with a root entrypoint: add only the capabilities from the table, each with a comment. Prefer `user: "UID:GID"` with zero capabilities once the volume is owned by that user.
5. Size limits from real usage (`docker stats --no-stream`, `cat /sys/fs/cgroup/pids.current` under load), with headroom.
6. Recreate the service (`docker compose up -d SERVICE`) and run the app's smoke test.
7. Update the inventory row and run `audit-verify` for `service`.

## Outputs

- Compose (and Dockerfile) diff for one service.
- Updated inventory row.
- audit-verify output for the service.

## Review gate

- [ ] `id` shows a non-zero uid (own images).
- [ ] `CapBnd` is `0000000000000000` or exactly the justified list.
- [ ] `NoNewPrivs: 1` and `Seccomp: 2`.
- [ ] `pids.max` and `memory.max` match the compose values.
- [ ] Negative test: `docker compose exec -u 0 SERVICE chown nobody /tmp` fails.
- [ ] Smoke test passes; no OOM (`docker inspect -f '{{.State.OOMKilled}}'` is false).

## References

- `SKILL.md`, `capabilities.md`, `seccomp.md`
- capabilities(7), prctl(2) `PR_SET_NO_NEW_PRIVS`, Docker "Resource constraints"
