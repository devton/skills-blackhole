# Routing matrix

| Request / signal | Slash form | Workflow | Required reads | Gate |
|---|---|---|---|---|
| New service in a compose file; "harden service X"; image runs as root; default capabilities | `/container-hardening baseline-service` | `baseline-service` | `capabilities.md`, `stack-inventory.md` | uid != 0, CapBnd minimal, NoNewPrivs 1, Seccomp 2, pids limit set |
| `EROFS` / "Read-only file system" error; "make the image immutable" | `/container-hardening readonly-rootfs` | `readonly-rootfs` | `stack-inventory.md` | write to code dir fails, smoke test passes |
| `network_mode`/`pid`/`ipc: host`; database reachable from proxy network; new network | `/container-hardening namespace-isolation` | `namespace-isolation` | `namespaces.md` | namespace inodes differ from host; data stores have no egress |
| "Container root must not be host root"; host-wide isolation | `/container-hardening userns-remap` | `userns-remap` | `namespaces.md` | uid_map remapped; every project on the host starts |
| "Seccomp profile for X"; small static binary | `/container-hardening seccomp-profile` | `seccomp-profile` | `seccomp.md` | 7 days without `type=1326`; Seccomp_filters 1 |
| `docker.sock` mount; `privileged: true`; host metrics exporter | `/container-hardening socket-privileged` | `socket-privileged` | `capabilities.md`, `namespaces.md` | no privileged; socket only on the socket proxy and platform services |
| "How secure are we?"; daily routine; PR review of compose/Dockerfile | `/container-hardening audit-verify` | `audit-verify` | `stack-inventory.md` | per-container report, diff against inventory |

## Role contracts

| Role | Owns | Must not | Hands off to |
|---|---|---|---|
| Orchestrator (entry SKILL.md) | Classifying the request, picking one workflow, enforcing the closing gate | Edit compose or daemon files itself | Selected workflow |
| Workflow executor | Editing Dockerfile / compose for the services in scope; writing exception comments | Touch services out of scope; edit `daemon.json` without confirmation; weaken a control to pass | audit-verify |
| Auditor (audit-verify) | Running the audit script, diffing against the inventory, PASS/FAIL per service | Change configuration | Orchestrator (report) |
| Human operator | Approving daemon-wide changes, deploys, accepted exceptions | - | - |
