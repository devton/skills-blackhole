---
name: "container-hardening-userns-remap"
description: "Workflow contract for /container-hardening userns-remap. Loaded by the container-hardening orchestrator."
---

# container-hardening.workflow.userns-remap

## Goal

Enable daemon-wide user namespace remapping so container uid 0 maps to an unprivileged host uid, as a planned and reversible migration.

## Scope

- Applies to: `/etc/docker/daemon.json` on one host and every project running on it.
- Does not cover: Docker rootless mode (mention as alternative only); per-service hardening.

## Triggers

- Intent: "container root must not be host root", "enable user namespaces", "userns-remap".

## Inputs

- Host access, list of all projects/containers on the host, maintenance window, a test host if available.

## Invariants

- Hard rules of `SKILL.md`; this is a daemon-wide change: explicit human confirmation before applying.
- Test on a non-production host first.
- Services that need `privileged`, `network_mode: host` or `pid: host` get `userns_mode: host` with an exception comment.

## Procedure

1. Confirm baseline-service, socket-privileged and namespace-isolation passed for the projects on the host.
2. Plan the migration: enabling remap switches Docker's data root to `/var/lib/docker/<uid>.<gid>`; existing images and volumes are not visible until it is turned off. Plan rebuild/pull and volume migration (copy + `chown` to the remapped uid range). On Docker 29+, remapping also turns off the containerd image store and falls back to the `overlay2` graph driver (the daemon logs `userns remapping enabled, disabling containerd snapshotter`).
3. Propose the diff and wait for confirmation:
   ```json
   {
     "userns-remap": "default",
     "no-new-privileges": true
   }
   ```
4. Restart the daemon in the window; redeploy every project (platform services first, e.g. the Dokploy proxy).
5. Add `userns_mode: host` only where unavoidable.
6. Rollback plan: remove the key, restart the daemon, old data root is back.
7. Run `audit-verify` for all containers on the host.

## Outputs

- daemon.json diff, migration and rollback notes, audit-verify output for the whole host.

## Review gate

- [ ] `docker info -f '{{.SecurityOptions}}'` shows `name=userns`.
- [ ] `cat /proc/self/uid_map` inside a container shows a non-zero host start (e.g. `0 100000 65536`).
- [ ] Every project on the host is up and passes its smoke test.
- [ ] Exceptions with `userns_mode: host` are in the inventory.

## References

- `SKILL.md`, `namespaces.md`
- user_namespaces(7), Docker "Isolate containers with a user namespace", "Rootless mode"
