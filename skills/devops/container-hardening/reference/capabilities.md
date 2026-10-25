# Capabilities digest (capabilities(7) + Docker)

Source: https://man7.org/linux/man-pages/man7/capabilities.7.html, https://docs.docker.com/engine/containers/run/#runtime-privilege-and-linux-capabilities

- Root privileges are split into units (`CAP_CHOWN`, `CAP_NET_RAW`, `CAP_SYS_ADMIN`, ...).
- Each thread has five sets: permitted, effective, inheritable, bounding, ambient. The **bounding set** is the ceiling: nothing outside it can be gained, not even through `execve` of a setuid binary.
- A non-root process without file capabilities ends `execve` with empty permitted and effective sets. Dropping the bounding set still matters as defence in depth (setuid binaries, `docker exec -u 0`).
- Docker default set (14): `AUDIT_WRITE CHOWN DAC_OVERRIDE FOWNER FSETID KILL MKNOD NET_BIND_SERVICE NET_RAW SETFCAP SETGID SETPCAP SETUID SYS_CHROOT`. `CapBnd` = `00000000a80425fb`. `privileged` = the host's full bounding set (`000001ffffffffff` on recent kernels; less if the host itself drops some).
- `CAP_SYS_ADMIN` is effectively root; adding it also relaxes Docker's default seccomp profile.
- Since Docker 20.10, `net.ipv4.ip_unprivileged_port_start=0` inside the container network namespace: ports below 1024 need no `NET_BIND_SERVICE`.
- `no-new-privileges` (`PR_SET_NO_NEW_PRIVS`): `execve` never grants new privileges (setuid bits and file caps ignored). `gosu`/`su-exec` still work because they call `setuid()` with `CAP_SETUID`.

## Starting cap_add lists (verify with the gate)

| Service type | cap_add |
|---|---|
| Own non-root app (API, worker, job) | none |
| Official Postgres image (root entrypoint) | `CHOWN DAC_OVERRIDE FOWNER SETUID SETGID` |
| Official Redis image (root entrypoint) | `SETUID SETGID` (+`CHOWN` if the volume is not owned by redis) |
| Official nginx on port 80 | `CHOWN SETUID SETGID` (or use nginx-unprivileged with none) |

Better for data stores: once the volume is owned by the image user, run with `user: "UID:GID"` and no capabilities.

## Checks

- `grep -E 'Cap(Prm|Eff|Bnd)|NoNewPrivs' /proc/1/status`
- `capsh --decode=<hex>` (Alpine `libcap`, Debian `libcap2-bin`)
- Negative test: `docker compose exec -u 0 SERVICE chown nobody /tmp` must fail with `Operation not permitted`.
