---
name: "container-hardening"
description: "Harden Docker/docker-compose services (also on Dokploy) with capabilities, namespaces, seccomp, read-only rootfs and limits, then prove it with an audit gate."
---

# container-hardening

Project-agnostic orchestrator for hardening containers run with Docker Engine + Compose v2, including projects deployed by Dokploy. Grounded in capabilities(7), namespaces(7), seccomp(2) and the Docker security docs.

## Layout

```
container-hardening/
  SKILL.md                      <- this orchestrator
  workflows/<cmd>/SKILL.md      <- one contract per command
  reference/                    <- routing matrix, role contracts, digests, inventory template
  scripts/hardening-audit.sh    <- live audit used by audit-verify
```

## Orchestrator

1. **Classify** the request with [`reference/routing-matrix.md`](reference/routing-matrix.md). Pick exactly one workflow. If the request spans several (e.g. "harden everything"), run them in the rollout order below, one workflow per pass.
2. **Inventory first.** If the project has no filled `reference/stack-inventory.md` yet, fill it before changing anything (run `scripts/hardening-audit.sh` on the host, or derive it from the compose files when there is no host access, and say which).
3. **Load only the selected contract** `workflows/<cmd>/SKILL.md` and the references it lists.
4. **Close with the gate.** Every workflow ends by running `workflows/audit-verify/SKILL.md` for the services it touched. Without that output the task is not done.

## Command routing (router-only)

Invoke as `/container-hardening <cmd>`. If subcommands are not parsed, read `cmd` from the user message. No flat alias skills.

| cmd | Contract |
|---|---|
| `baseline-service` | `workflows/baseline-service/SKILL.md` |
| `readonly-rootfs` | `workflows/readonly-rootfs/SKILL.md` |
| `namespace-isolation` | `workflows/namespace-isolation/SKILL.md` |
| `userns-remap` | `workflows/userns-remap/SKILL.md` |
| `seccomp-profile` | `workflows/seccomp-profile/SKILL.md` |
| `socket-privileged` | `workflows/socket-privileged/SKILL.md` |
| `audit-verify` | `workflows/audit-verify/SKILL.md` |

## Rollout order (highest impact per hour first)

`baseline-service` → `socket-privileged` → `namespace-isolation` → `readonly-rootfs` → `seccomp-profile` → `userns-remap`. `audit-verify` closes each step.

## Hard rules

- Never add `privileged: true`, `seccomp=unconfined`, `network_mode: host`, `pid: host`, `ipc: host` or a `docker.sock` mount to an application service. Any exception needs a comment in the compose file stating why, plus a row in the stack inventory.
- `cap_drop: [ALL]` is the default; every `cap_add` entry is justified in a comment.
- One workflow per service per change (PR/commit), so a rollback undoes one thing.
- Changes to `/etc/docker/daemon.json` affect every project on the host: show the diff and get explicit confirmation before applying.
- Never weaken a control to make something pass (e.g. turning read-only off for an `EROFS` error); add the narrow exception instead (a specific tmpfs, a specific capability).
- On Dokploy, the project must deploy in **Docker Compose** mode, not Stack/Swarm: Swarm ignores `security_opt`.
- Evidence over assumption: every claim in the final report cites an audit line or a command output.
