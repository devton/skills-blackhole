#!/usr/bin/env bash
# Pagar.me API v5 read-only CLI (curl + argc).
# See: reference/cli-tasks.md (relative to skill root)

# @describe Pagar.me API v5 read-only CLI
# @option --env-file <FILE>  Load SKILL_PAGARME_V5_* from this file [.env when present]
# @flag --raw                Skip jq pretty-print
# @flag --quiet              Suppress non-error stderr

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

pagarme_cli_init() {
  if [[ -n "${argc_env_file:-}" ]]; then
    export SKILL_PAGARME_V5_ENV_FILE="$argc_env_file"
  fi
  if [[ "${argc_raw:-0}" == "1" ]]; then
    export SKILL_PAGARME_V5_RAW=1
  fi
  if [[ "${argc_quiet:-0}" == "1" ]]; then
    export SKILL_PAGARME_V5_QUIET=1
  fi
  pagarme_load_config
}

# Only argc flags declared on the active subcommand are set (e.g. payable list vs customer list).
pagarme_query_from_flags() {
  local -a pairs=()
  [[ -n "${argc_page:-}" ]] && pairs+=("page=${argc_page}")
  [[ -n "${argc_size:-}" ]] && pairs+=("size=${argc_size}")
  [[ -n "${argc_status:-}" ]] && pairs+=("status=${argc_status}")
  [[ -n "${argc_recipient_id:-}" ]] && pairs+=("recipient_id=${argc_recipient_id}")
  [[ -n "${argc_charge_id:-}" ]] && pairs+=("charge_id=${argc_charge_id}")
  [[ -n "${argc_start_date:-}" ]] && pairs+=("start_date=${argc_start_date}")
  [[ -n "${argc_end_date:-}" ]] && pairs+=("end_date=${argc_end_date}")
  pagarme_build_query "${pairs[@]}"
}

_pagarme_fetch() {
  local path="$1"
  local query="${2:-}"
  pagarme_cli_init
  pagarme_get "$path" "$query"
}

_pagarme_fetch_by_id() {
  _pagarme_fetch "/$1/${argc_id}"
}

_pagarme_fetch_list() {
  _pagarme_fetch "/$1" "$(pagarme_query_from_flags)"
}

# @cmd ping Smoke-test API auth (GET /customers?size=1)
ping() {
  _pagarme_fetch "/customers" "size=1"
}

# @cmd customer get Get customer by ID
# @arg id! Customer ID (e.g. cus_...)
customer__get() {
  _pagarme_fetch_by_id "customers"
}

# @cmd customer list List customers
# @option --page <PAGE>  Page number
# @option --size <SIZE>  Page size
customer__list() {
  _pagarme_fetch_list "customers"
}

# @cmd order get Get order by ID
# @arg id! Order ID (e.g. or_...)
order__get() {
  _pagarme_fetch_by_id "orders"
}

# @cmd charge get Get charge by ID
# @arg id! Charge ID (e.g. ch_...)
charge__get() {
  _pagarme_fetch_by_id "charges"
}

# @cmd recipient get Get recipient by ID
# @arg id! Recipient ID (e.g. re_...)
recipient__get() {
  _pagarme_fetch_by_id "recipients"
}

# @cmd recipient balance Get recipient balance
# @arg id! Recipient ID
recipient__balance() {
  _pagarme_fetch "/recipients/${argc_id}/balance"
}

# @cmd transfer get Get transfer by ID
# @arg id! Transfer ID
transfer__get() {
  _pagarme_fetch_by_id "transfers"
}

# @cmd transfer list List transfers
# @option --page <PAGE>    Page number
# @option --size <SIZE>    Page size
# @option --status <STATUS>  Transfer status filter
transfer__list() {
  _pagarme_fetch_list "transfers"
}

# @cmd payable get Get payable by ID
# @arg id! Payable ID
payable__get() {
  _pagarme_fetch_by_id "payables"
}

# @cmd payable list List payables
# @option --page <PAGE>           Page number
# @option --size <SIZE>           Page size
# @option --recipient-id <ID>     Filter by recipient_id
# @option --charge-id <ID>        Filter by charge_id
# @option --status <STATUS>       Payable status
# @option --start-date <DATE>     start_date (ISO date)
# @option --end-date <DATE>       end_date (ISO date)
payable__list() {
  _pagarme_fetch_list "payables"
}

# @cmd request get GET a path under /core/v5 (escape hatch)
# @arg path! API path (must start with /, e.g. /receivables)
request__get() {
  if [[ "${argc_path}" != /* ]]; then
    pagarme_die "path must start with / (got: ${argc_path})"
  fi
  _pagarme_fetch "${argc_path}"
}

eval "$(argc --argc-eval "$0" "$@")"
