---
name: "container-hardening-readonly-rootfs"
description: "Workflow contract for /container-hardening readonly-rootfs. Loaded by the container-hardening orchestrator."
---

# container-hardening.workflow.readonly-rootfs

## Goal

Run one service with a read-only root filesystem, where the only writable areas are explicit tmpfs mounts and declared volumes.

## Scope

- Applies to: stateless services first (static binaries, then interpreted-language apps), data stores last (only their data volume writable).
- Does not cover: user/capability changes (`baseline-service`, which must pass first).

## Triggers

- Files: a service without `read_only: true`.
- Intent: "make the container immutable", "read-only filesystem"; an `EROFS` / "Read-only file system" error after enabling it.

## Inputs

- `service`, its runtime uid/gid.
- Known writable paths (framework cache/pids dir, `$HOME` of CLIs, uploads).

## Invariants

- Hard rules of `SKILL.md`.
- Never turn `read_only` off to fix an `EROFS`; add a narrow tmpfs or volume for that exact path.
- Persistent data goes to volumes, never tmpfs. Logs go to stdout.
- Every tmpfs has a `size=` and, when written by a non-root user, `uid=`/`gid=`.
- Docker mounts tmpfs with `noexec,nosuid,nodev` by default. Add `exec` only to a tmpfs the app must execute files from (native modules or JIT code extracted to `/tmp`), and say why in a comment.

## Procedure

1. List candidate writable paths: `docker diff CONTAINER` on the running service, plus framework knowledge (`tmp/` in Rails, `.next/cache` in Next.js, `__pycache__`, CLI config under `$HOME`).
2. Add to the service:
   ```yaml
   read_only: true
   tmpfs:
     - /tmp:size=128m,mode=1777
     - /app/tmp:size=256m,uid=10001,gid=10001,mode=0755
     - /home/app:size=32m,uid=10001,gid=10001,mode=0700
   volumes:
     - uploads:/app/storage
   ```
   A new named volume copies the ownership of its mount point from the image, and Docker creates a missing mount point as root. Create it in the Dockerfile before `USER`, or the non-root service cannot write to it:
   ```dockerfile
   RUN mkdir -p /app/storage && chown 10001:10001 /app/storage
   ```
3. Recreate and run the smoke test, including flows that call external binaries or write files.
4. For each `EROFS` in the logs, add one tmpfs/volume for that path and repeat step 3.
5. Check tmpfs sizes fit inside `mem_limit` (tmpfs counts as container memory).
6. Record writable paths in the inventory; run `audit-verify`.

## Outputs

- Compose diff, updated "Writable paths" in the inventory, audit-verify output.

## Review gate

- [ ] `docker inspect -f '{{.HostConfig.ReadonlyRootfs}}'` is `true`.
- [ ] `docker compose exec SERVICE sh -c 'touch /app/x'` fails with `Read-only file system`.
- [ ] Writing to each declared tmpfs works as the service user.
- [ ] Smoke test passes and logs have no `EROFS`.

## References

- `SKILL.md`, `namespaces.md`, `stack-inventory.md`
- mount_namespaces(7), Docker "tmpfs mounts", `docker run --read-only`
