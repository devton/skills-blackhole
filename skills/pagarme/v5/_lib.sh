# Shared helpers for pagarme.sh (read-only Pagar.me v5 CLI).
# Sourced by pagarme.sh — do not execute directly.

set -euo pipefail

SKILL_PAGARME_V5_CURL_CONNECT_TIMEOUT="${SKILL_PAGARME_V5_CURL_CONNECT_TIMEOUT:-10}"
SKILL_PAGARME_V5_CURL_MAX_TIME="${SKILL_PAGARME_V5_CURL_MAX_TIME:-30}"

pagarme_die() {
  echo "pagarme: $*" >&2
  exit 1
}

pagarme_log() {
  if [[ "${SKILL_PAGARME_V5_QUIET:-0}" != "1" ]]; then
    echo "pagarme: $*" >&2
  fi
}

pagarme_strip_quotes() {
  local value="$1"
  if [[ "$value" == \"*\" && "$value" == *\" ]]; then
    value="${value:1:${#value}-2}"
  elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
    value="${value:1:${#value}-2}"
  fi
  printf '%s' "$value"
}

pagarme_load_config() {
  local env_file="${SKILL_PAGARME_V5_ENV_FILE:-}"

  if [[ -z "$env_file" && -f .env ]]; then
    env_file=".env"
  fi

  if [[ -n "$env_file" ]]; then
    if [[ ! -f "$env_file" ]]; then
      pagarme_die "env file not found: ${env_file}"
    fi
    local line key value
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line%%#*}"
      line="${line#"${line%%[![:space:]]*}"}"
      line="${line%"${line##*[![:space:]]}"}"
      [[ -z "$line" ]] && continue
      if [[ "$line" == export[[:space:]]* ]]; then
        line="${line#export}"
        line="${line#"${line%%[![:space:]]*}"}"
      fi
      if [[ "$line" =~ ^(SKILL_PAGARME_V5_[A-Za-z0-9_]+)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="$(pagarme_strip_quotes "${BASH_REMATCH[2]}")"
        export "${key}=${value}"
      fi
    done <"$env_file"
    pagarme_log "loaded SKILL_PAGARME_V5_* from ${env_file}"
  fi

  if [[ -z "${SKILL_PAGARME_V5_SECRET_KEY:-}" ]]; then
    pagarme_die "SKILL_PAGARME_V5_SECRET_KEY is not set (use .env or --env-file)"
  fi

  local base_url="${SKILL_PAGARME_V5_BASE_URL:-https://api.pagar.me}"
  base_url="${base_url%/}"

  if [[ "$base_url" == */core/v5 ]]; then
    PAGARME_API_BASE="$base_url"
  else
    PAGARME_API_BASE="${base_url}/core/v5"
  fi
  export PAGARME_API_BASE

  if [[ "$SKILL_PAGARME_V5_SECRET_KEY" == sk_test_* ]]; then
    pagarme_log "environment: sandbox (sk_test_*)"
  elif [[ "$SKILL_PAGARME_V5_SECRET_KEY" == sk_* ]]; then
    pagarme_log "environment: PRODUCTION (sk_*) — double-check before calling the API"
  else
    pagarme_log "environment: unknown key prefix"
  fi

  if [[ "${SKILL_PAGARME_V5_RAW:-0}" != "1" ]] && ! command -v jq >/dev/null 2>&1; then
    pagarme_log "warning: jq not found; output will not be pretty-printed (install via mise or use --raw)"
  fi
}

pagarme_urlencode() {
  local value="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$value" | jq -sRr @uri
    return
  fi
  python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$value"
}

pagarme_build_query() {
  local -a parts=()
  local pair key value encoded
  for pair in "$@"; do
    if [[ -z "$pair" ]]; then
      continue
    fi
    key="${pair%%=*}"
    value="${pair#*=}"
    if [[ -n "${value}" ]]; then
      encoded="$(pagarme_urlencode "$value")"
      parts+=("${key}=${encoded}")
    fi
  done
  local IFS='&'
  echo "${parts[*]}"
}

pagarme_print_response() {
  local body="$1"
  if [[ "${SKILL_PAGARME_V5_RAW:-0}" == "1" ]]; then
    printf '%s\n' "$body"
    return
  fi
  if command -v jq >/dev/null 2>&1; then
    printf '%s\n' "$body" | jq .
  else
    printf '%s\n' "$body"
  fi
}

pagarme_get() {
  local path="$1"
  local query="${2:-}"

  if [[ "$path" != /* ]]; then
    path="/${path}"
  fi

  local url="${PAGARME_API_BASE}${path}"
  if [[ -n "$query" ]]; then
    query="${query#?}"
    url="${url}?${query}"
  fi

  pagarme_log "GET ${path}${query:+?${query}}"

  local body http_code tmp curl_exit=0
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN

  set +e
  http_code="$(
    curl -sS \
      --connect-timeout "${SKILL_PAGARME_V5_CURL_CONNECT_TIMEOUT}" \
      --max-time "${SKILL_PAGARME_V5_CURL_MAX_TIME}" \
      -u "${SKILL_PAGARME_V5_SECRET_KEY}:" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -o "$tmp" \
      -w '%{http_code}' \
      "$url"
  )"
  curl_exit=$?
  set -e

  body="$(cat "$tmp")"

  if [[ $curl_exit -ne 0 ]]; then
    pagarme_die "request failed (curl exit ${curl_exit}). Check network and SKILL_PAGARME_V5_BASE_URL (${PAGARME_API_BASE})"
  fi

  if [[ -z "$http_code" || "$http_code" == "000" ]]; then
    pagarme_die "request failed (no HTTP status). Check network and SKILL_PAGARME_V5_BASE_URL (${PAGARME_API_BASE})"
  fi

  if [[ "$http_code" -lt 200 || "$http_code" -ge 300 ]]; then
    echo "pagarme: HTTP ${http_code}" >&2
    pagarme_print_response "$body" >&2 || true
    exit 1
  fi

  pagarme_print_response "$body"
}
