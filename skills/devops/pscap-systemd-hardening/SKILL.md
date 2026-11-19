---
name: pscap-systemd-hardening
description: >
  Linux capabilities (pscap/getpcaps/capsh) + strace-driven systemd hardening.
  Workflow "trace first, configure after" para qualquer daemon.
  Fonte: doc do Thiago Torres Faioli (RTFM - Hardening NGINX Systemd).
---

# pscap & Systemd Hardening

Workflow: usar strace pra descobrir exatamente oq o processo precisa, depois configurar
systemd com a superfície mínima. Nunca chuta — deixa o processo falar.

## Ferramentas Principais

| Comando | Uso |
|---|---|
| `strace -ff -o /tmp/trace -e trace=... <cmd>` | Captura syscalls, `-ff` follow forks |
| `getpcaps <pid>` | Lê caps de PID em execução (inspeção rápida) |
| `capsh --print` | Mostra bounding set + ambient do shell atual |
| `setcap/getcap` | Atribui/lê capabilities em binários (alternativa a root) |
| `grep -E 'EACCES\|EPERM\|ENOENT' /tmp/trace*` | Filtra falhas de permissão |
| `grep -RhoE 'execve\("([^"]+)"' /tmp/trace*` | Extrai bins executados |
| `grep -RhE 'clone\(\|unshare\(\|setns\(' /tmp/trace*` | Verifica uso de namespaces |
| `grep -RhE 'capset\|capget\|setuid\|setgid\|prctl' /tmp/trace*` | Verifica capabilities usadas |

## Workflow Completo

### 1. Baseline build-time (oq o pacote "acha" que usa)

```bash
# Exemplo nginx — adaptar pro binário alvo
nginx -V 2>&1 | tr ' ' '\n' | grep -Eo 'path=.*' | sed 's/^path=//'
```

Lista declarada. A realidade é outra — strace mostra oq realmente acontece.

### 2. Captura runtime com strace

```bash
# Trace completo: arquivo + processo + rede
strace -ff -o /tmp/app.strace -e trace=file,process,network \
  /usr/sbin/app -g 'daemon off;'  # foreground pra capturar tudo
# Ctrl+C pra parar
```

### 3. Analisar falhas de permissão

```bash
# ENOENT = tentou acessar algo que não existe (nem sempre erro)
# EACCES = negado (problema real)
# EPERM = operação não permitida (cap faltando)
grep -R --line-number -E 'EACCES|EPERM|ENOENT' /tmp/app.strace*
```

**Ruído comum (seguro ignorar):**
- `/etc/ld.so.preload` ENOENT — normal, loader sempre checa
- `/var/run/nscd/socket` ENOENT — normal se n roda nscd
- `/var/lib/sss/mc/*` ENOENT — normal se n usa SSSD

### 4. Mapear paths de leitura

```bash
grep -RhoE 'openat\([^,]+, "([^"]+)"' /tmp/app.strace* \
  | sed -E 's/.*"([^"]+)".*/\1/' | sort -u
```

### 5. Mapear paths de escrita (ReadWritePaths)

```bash
grep -Rh 'openat(' /tmp/app.strace* \
  | grep -E 'O_WRONLY|O_RDWR|O_CREAT|O_TRUNC|O_APPEND' \
  | sed -E 's/.*openat\([^,]+, "([^"]+)".*/\1/' | sort -u
```

**IMPORTANTE:** gerar tráfego real antes de coletar. Se o app faz proxy buffering, uploads, etc., precisa forçar isso ou os paths de escrita n aparecem.

### 6. Mapear ExecPaths (bins executados)

```bash
grep -RhoE 'execve\("([^"]+)"' /tmp/app.strace* \
  | sed -E 's/.*"([^"]+)".*/\1/' | sort -u
```

### 7. Verificar uso de namespaces

```bash
strace -ff -o /tmp/app.ns.strace -e trace=clone,unshare,setns \
  /usr/sbin/app -g 'daemon off;'

# Verificar se CLONE_NEW* aparece
grep -RhE 'clone\(' /tmp/app.ns.strace* | grep -v 'CLONE_CHILD'
# Se só CLONE_CHILD_CLEARTID|CLONE_CHILD_SETTID|SIGCHLD → criação normal de processo, sem namespace

# Confirmação via /proc
ls -l /proc/$(pidof app | awk '{print $1}')/ns
```

### 8. Verificar capabilities usadas

```bash
strace -ff -o /tmp/app.caps.strace \
  -e trace=capget,capset,setuid,setgid,setgroups,prctl,bind,chown,fchownat \
  /usr/sbin/app -g 'daemon off;'

grep -RhE 'capset|capget|setuid|setgid|setgroups|prctl\(|bind\(' /tmp/app.caps.strace*
```

**O que procurar:**
- `bind(...:80) = 0` / `bind(...:443) = 0` → precisa CAP_NET_BIND_SERVICE
- `setuid(N)` / `setgid(N)` / `setgroups(...)` → drop de privilégio
- `prctl(PR_CAPBSET_READ, ...)` → consultando bounding set (informativo, não "precisa")
- `capset()` → manipulando caps de outros processos (raro, CAP_SETPCAP)
- `chown()` / `fchownat()` → precisa CAP_CHOWN (normalmente desnecessário)

### 9. getpcaps (inspeção rápida sem strace)

```bash
# Em processo rodando:
getpcaps $(pidof nginx | awk '{print $1}')
# Output: CapEff: 0000000000000000 ou bitmask com caps ativas

# Verificar bounding set completo:
cat /proc/$(pidof nginx | awk '{print $1}')/status | grep -i cap
```

### 10. capsh (validar estado antes/depois)

```bash
# Caps do shell atual:
capsh --print

# Testar rodar com caps específicas:
capsh --caps="cap_net_bind_service+ep" -- -c "nginx -g 'daemon off;'"
```

## Config Systemd Resultante

### Modelo clássico (master como root, drop pra user)

```ini
[Service]
# Paths
ReadOnlyPaths=/etc/nginx /etc/letsencrypt /usr/lib64 /lib64
ReadWritePaths=/run /var/log/nginx /var/cache/nginx

# Execução
NoExecPaths=/
ExecPaths=/usr/sbin /sbin

# Namespaces
RestrictNamespaces=~user ~net ~pid ~ipc ~mnt ~uts ~cgroup

# Capabilities — só oq strace provou necessário
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_SETUID CAP_SETGID

# Proteção
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
NoNewPrivileges=true
```

### Modelo ideal (User= direto, sem setuid/setgid)

```ini
[Service]
User=nginx
Group=nginx

# Caps — só bind em porta baixa
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE

# Sem CAP_SETUID/CAP_SETGID — já nasce como nginx
# Superfície mínima
```

## Pitfalls

- **ExecPaths é allowlist de DIRETÓRIO, não arquivo.** `/usr/sbin/nginx` é semântica confusa. Use `/usr/sbin`.
- **RestrictNamespaces=yes não existe.** Valores válidos: `~user`, `~net`, lista de flags namespace, ou vazio.
- **CAP_DAC_OVERRIDE mascara problema real.** Se openat() falha com EACCES, o certo é corrigir ownership/perms, não dar DAC_OVERRIDE.
- **CAP_CHOWN:** se n aparece chown/fchownat no strace, remover.
- **CAP_SETPCAP:** se n aparece capset() no strace, remover. Serve pra manipular caps de outros processos.
- **EINVAL em PR_CAPBSET_READ:** normal — processo varre range de CAP IDs, alguns n existem no kernel.
- **clone() com CLONE_CHILD_*:** NÃO é namespace. Flags CLONE_NEW* éq indica namespace.
- **NSS noise:** libs libnss_systemd.so, libnss_sss.so e sockets SSSD/nscd geram ENOENT. Normal se n usa esses daemons.

## Validação Pós-Config

```bash
systemctl daemon-reload && systemctl restart app

# Se quebrar:
journalctl -u app -b --no-pager | tail -200

# Veredito do kernel (confirma sem hardening):
strace -ff -o /tmp/app.check -e trace=process /usr/sbin/app -g 'daemon off;'
grep -RhE 'execve|EPERM|EACCES' /tmp/app.check*
```
