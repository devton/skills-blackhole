---
name: "container-hardening-seccomp-profile"
description: "Workflow contract for /container-hardening seccomp-profile. Loaded by the container-hardening orchestrator."
---

# container-hardening.workflow.seccomp-profile

## Goal

Replace the default seccomp profile of one small, stable service with an allowlist of only the syscalls it uses, observed in log mode before enforcing.

## Scope

- Applies to: small static binaries (Go, Rust), proxies, jobs.
- Does not cover: large apps with many native dependencies or external binary calls; they stay on Docker's default profile (keep it on, never `unconfined`).

## Triggers

- Intent: "seccomp profile for X", "restrict syscalls".

## Inputs

- `service`, host access to kernel/audit logs, an observation window (default 7 days covering every scheduled task of the service).

## Invariants

- Hard rules of `SKILL.md`; baseline-service passed (it provides `no-new-privileges`).
- Start from moby's `profiles/seccomp/default.json`; a custom profile replaces the default entirely.
- The profile file is versioned in the project directory (on Dokploy, the cloned repo).
- Re-run the observation step on every base image or language runtime bump.

## Procedure

1. Observe: profile with `"defaultAction": "SCMP_ACT_LOG"` and a small allow list; attach it:
   ```yaml
   security_opt:
     - no-new-privileges:true
     - seccomp=./seccomp/SERVICE.audit.json
   ```
2. Collect after the window:
   ```sh
   journalctl -k --since "7 days ago" | grep 'type=1326' \
     | grep -o 'syscall=[0-9]*' | sort | uniq -c | sort -rn
   # ausyscall NNN to map numbers to names
   ```
3. Build `seccomp/SERVICE.json` from the moby default: `defaultAction: SCMP_ACT_ERRNO`, allowlist = observed syscalls + language runtime needs (Go: `rt_sigreturn`, `sched_yield`, `mmap`, `madvise`, `clone`/`clone3` without namespace flags...).
4. Switch the service to the enforcing profile, recreate, run a full cycle.
5. Debug with a separate container on the same network (`docker exec` shells inherit the filter).
6. Update the inventory "seccomp" column; run `audit-verify`.

## Outputs

- `seccomp/SERVICE.audit.json`, `seccomp/SERVICE.json`, compose diff, syscall list with counts, audit-verify output.

## Review gate

- [ ] `Seccomp: 2` and `Seccomp_filters: 1` in `/proc/1/status`.
- [ ] A full service cycle runs without errors.
- [ ] No new `type=1326` events after enforcing.
- [ ] Negative test: `unshare -r true` fails.

## References

- `SKILL.md`, `seccomp.md`
- seccomp(2), Docker "Seccomp security profiles", github.com/moby/profiles
