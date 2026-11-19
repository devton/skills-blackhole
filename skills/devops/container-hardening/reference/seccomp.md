# Seccomp digest (seccomp(2) + Docker)

Source: https://man7.org/linux/man-pages/man2/seccomp.2.html, https://docs.docker.com/engine/security/seccomp/, https://github.com/moby/profiles

- Modes: strict (only read/write/_exit/sigreturn) and filter (BPF program per syscall).
- Installing a filter requires `no_new_privs` or `CAP_SYS_ADMIN`. Filters are inherited across `fork`/`execve` and can never be removed; with several filters, the highest-precedence action wins.
- Actions (precedence high to low): `KILL_PROCESS`, `KILL_THREAD`, `TRAP`, `ERRNO`, `USER_NOTIF`, `TRACE`, `LOG` (kernel 4.14+), `ALLOW`. Docker names: `SCMP_ACT_KILL_PROCESS`, `SCMP_ACT_ERRNO`, `SCMP_ACT_LOG`, `SCMP_ACT_ALLOW`, ...
- Docker's default profile: `defaultAction: SCMP_ACT_ERRNO` (EPERM) with an allowlist of 300+ syscalls; blocks e.g. `mount`, `umount2`, `kexec_load`, `add_key`, `keyctl`, `bpf`, `unshare`, namespace-creating `clone`. Some rules are conditional on capabilities (adding `SYS_ADMIN` opens more).
- A custom profile **replaces** the default entirely. Always start from moby's `profiles/seccomp/default.json`.
- `SCMP_ACT_LOG` events are audit records `type=1326` with `syscall=NNN`; map with `ausyscall NNN` (auditd). With auditd running they go to `/var/log/audit/audit.log` (`ausearch -m SECCOMP`); without it they go to the kernel log, where printk rate limiting drops most of them unless `kernel.printk_ratelimit=0`.

## Profile skeleton

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "defaultErrnoRet": 1,
  "architectures": ["SCMP_ARCH_X86_64", "SCMP_ARCH_AARCH64"],
  "syscalls": [
    { "names": ["read", "write", "futex"], "action": "SCMP_ACT_ALLOW" }
  ]
}
```

## Checks

- `grep -E 'Seccomp(_filters)?' /proc/1/status`: `Seccomp: 2` = filter mode, `0` = none.
- `docker info -f '{{.SecurityOptions}}'` includes `name=seccomp,profile=builtin`.
- Negative test: `unshare -r true` inside the container fails with `Operation not permitted`.
