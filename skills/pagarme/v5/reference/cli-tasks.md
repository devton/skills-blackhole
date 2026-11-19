# Pagar.me v5 — CLI tasks (mise)

Read-only ops CLI for debugging Pagar.me v5. **No database** — curl + `SKILL_PAGARME_V5_*` env only.

**Prerequisites:** [mise](https://mise.jdx.dev/) installed, `.env` with `SKILL_PAGARME_V5_SECRET_KEY` (and optional `SKILL_PAGARME_V5_BASE_URL`).

```bash
mise install
mise run pagarme -- ping
```

Pass CLI args after `--`:

```bash
mise run pagarme -- order get or_abc123
mise run pagarme -- payable list --charge-id=ch_xyz --size=10
mise run pagarme -- --env-file=/path/to/env charge get ch_abc
```

Direct script (same behavior):

```bash
bash .agents/skills/pagarme-v5/scripts/pagarme.sh --help
bash .agents/skills/pagarme-v5/scripts/pagarme.sh charge get ch_abc123
```

## Global flags (all subcommands)

| Flag | Description |
|------|-------------|
| `--env-file <FILE>` | Load `SKILL_PAGARME_V5_*` from file (default: `.env` when present) |
| `--raw` | Skip `jq` pretty-print |
| `--quiet` | Suppress non-error stderr |

## Command map

| CLI subcommand | HTTP | Example |
|----------------|------|---------|
| `ping` | `GET /customers?size=1` | `mise run pagarme -- ping` |
| `customer get <id>` | `GET /customers/{id}` | `mise run pagarme -- customer get cus_abc` |
| `customer list` | `GET /customers` | `mise run pagarme -- customer list --page=1 --size=20` |
| `order get <id>` | `GET /orders/{id}` | `mise run pagarme -- order get or_abc` |
| `charge get <id>` | `GET /charges/{id}` | `mise run pagarme -- charge get ch_abc` |
| `recipient get <id>` | `GET /recipients/{id}` | `mise run pagarme -- recipient get re_abc` |
| `recipient balance <id>` | `GET /recipients/{id}/balance` | `mise run pagarme -- recipient balance re_abc` |
| `transfer get <id>` | `GET /transfers/{id}` | `mise run pagarme -- transfer get tr_abc` |
| `transfer list` | `GET /transfers` | `mise run pagarme -- transfer list --status=paid` |
| `payable get <id>` | `GET /payables/{id}` | `mise run pagarme -- payable get pay_abc` |
| `payable list` | `GET /payables` | `mise run pagarme -- payable list --charge-id=ch_abc` |
| `request get <path>` | `GET {path}` | `mise run pagarme -- request get /receivables` |

## Payable list query params

Query flags map to Pagar.me `GET /payables` parameters:

| CLI flag | Query param |
|----------|-------------|
| `--recipient-id` | `recipient_id` |
| `--charge-id` | `charge_id` |
| `--status` | `status` |
| `--start-date` | `start_date` |
| `--end-date` | `end_date` |
| `--page` | `page` |
| `--size` | `size` |

Note: Pagar.me payables API accepts `charge_id`, not `order_id`. Resolve charge via `mise run pagarme -- order get {or}` first.

## Environment variables

From any env file (only `SKILL_PAGARME_V5_*` lines are read; quoted values supported). Values with spaces must be quoted (e.g. `SKILL_PAGARME_V5_FOO="bar baz"`).

| Variable | Purpose |
|----------|---------|
| `SKILL_PAGARME_V5_SECRET_KEY` | Basic auth user (required) |
| `SKILL_PAGARME_V5_BASE_URL` | API host (default `https://api.pagar.me`; `/core/v5` appended automatically) |

Optional curl tuning (seconds):

| Variable | Default |
|----------|---------|
| `SKILL_PAGARME_V5_CURL_CONNECT_TIMEOUT` | `10` |
| `SKILL_PAGARME_V5_CURL_MAX_TIME` | `30` |

The CLI never accepts the secret key as a flag — only `SKILL_PAGARME_V5_*` lines from the env file.

## Safety

- Read-only (GET only).
- `ping` and init log whether the key prefix is `sk_test_*` (sandbox) or `sk_*` (production).
- HTTP 4xx/5xx responses preserve status code and body (no `curl -f` swallowing).
