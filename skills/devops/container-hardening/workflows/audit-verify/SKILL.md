---
name: "container-hardening-audit-verify"
description: "Workflow contract for /container-hardening audit-verify. Loaded by the container-hardening orchestrator."
---

# container-hardening.workflow.audit-verify

## Goal

Produce a per-container PASS/FAIL report of the live hardening state and its diff against the stack inventory; this is the mandatory closing gate of every other workflow.

## Scope

- Applies to: all running containers on a host, or the services a workflow just touched.
- Does not cover: changing configuration (report only).

## Triggers

- End of any other workflow.
- Intent: "how secure are our containers", "audit", a daily routine, PR review of a Dockerfile or compose file.

## Inputs

- Host shell access with Docker; `stack-inventory.md` for the project. Without host access, audit the compose files statically and label the report "static".

## Invariants

- Read-only: never edits anything.
- Every FAIL cites the audit line; every accepted deviation must be an inventory exception.

## Procedure

1. Run `scripts/hardening-audit.sh` on the host (optionally with a name filter).
2. Evaluate each line:
   | Field | PASS |
   |---|---|
   | `uid` | not `0` (own images) |
   | `capbnd` | `0000000000000000` or the inventory's justified list |
   | `nnp` | `1` |
   | `seccomp` | `2` |
   | `ro` | `true` for stateless services |
   | `pids` | set (not `0`/`<nil>`) |
   | `priv` | `false` |
   | `net` | not `host` |
3. Diff against the inventory; flag drift (new service, new capability, new mount).
4. For distroless images (no `cat`), read the status from the host: `cat /proc/$(docker inspect -f '{{.State.Pid}}' C)/status` (the audit script falls back to this). Do not use `nsenter -t PID -p cat /proc/1/status`: without `-m`, `/proc` is still the host's and it prints the host's PID 1.
5. Optionally, once per release: `docker/docker-bench-security` (CIS Docker Benchmark).

## Outputs

- Report: one row per container with PASS/FAIL per field, drift list, and the next workflow to run for each FAIL (from `routing-matrix.md`).

## Review gate

- [ ] Every container in scope has a row.
- [ ] Every FAIL maps to a workflow or an inventory exception.
- [ ] The raw script output is attached.

## References

- `SKILL.md`, `stack-inventory.md`, `routing-matrix.md`
- proc(5) `/proc/[pid]/status` fields `CapBnd`, `NoNewPrivs`, `Seccomp`, `Seccomp_filters`; CIS Docker Benchmark
