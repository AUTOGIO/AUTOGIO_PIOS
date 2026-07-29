#!/bin/zsh
# Shared helpers for UniFi baseline scripts. Source, do not execute.

# Resolve repo root from this file's location unless REPO_ROOT is already set.
_unifi_common_src="${(%):-%x}"
_unifi_scripts_dir="$(cd "$(dirname "${_unifi_common_src}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "${_unifi_scripts_dir}/.." && pwd)}"
UNIFI_CONFIG_DIR="${UNIFI_CONFIG_DIR:-${REPO_ROOT}/config}"
UNIFI_ENV_FILE="${UNIFI_ENV_FILE:-${UNIFI_CONFIG_DIR}/.unifi.local.env}"
UNIFI_CACHE_DIR="${UNIFI_CACHE_DIR:-${UNIFI_CONFIG_DIR}/.cache}"
UNIFI_COOKIE_JAR="${UNIFI_COOKIE_JAR:-${UNIFI_CACHE_DIR}/unifi_cookies.txt}"
# Reuse cookies this many seconds before forcing a re-login (default 25m).
UNIFI_SESSION_MAX_AGE_SEC="${UNIFI_SESSION_MAX_AGE_SEC:-1500}"

# Local UniFi OS presents a self-signed cert. Prefer UNIFI_CA_CERT (PEM) when available.
# Without a CA file, curl uses -k (MITM risk on an untrusted LAN — documented tradeoff).
unifi_curl() {
  local -a tls_args
  if [[ -n "${UNIFI_CA_CERT:-}" && -f "${UNIFI_CA_CERT}" ]]; then
    tls_args=(--cacert "${UNIFI_CA_CERT}")
  else
    tls_args=(-k)
  fi
  command curl -s "${tls_args[@]}" "$@"
}

unifi_secure_cookie_paths() {
  local cookie_jar="$1"
  local cache_dir
  cache_dir="$(dirname "${cookie_jar}")"
  mkdir -p "${cache_dir}"
  chmod 700 "${cache_dir}" 2>/dev/null || true
  if [[ -f "${cookie_jar}" ]]; then
    chmod 600 "${cookie_jar}" 2>/dev/null || true
  fi
}

unifi_load_env() {
  if [[ -f "${UNIFI_ENV_FILE}" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${UNIFI_ENV_FILE}"
    set +a
  fi
  UNIFI_HOST="${UNIFI_HOST:-192.168.0.1}"
  UNIFI_SITE="${UNIFI_SITE:-default}"
  export UNIFI_HOST UNIFI_SITE
  [[ -n "${UNIFI_USERNAME:-}" ]] && export UNIFI_USERNAME
  [[ -n "${UNIFI_PASSWORD:-}" ]] && export UNIFI_PASSWORD
}

unifi_require_credentials() {
  unifi_load_env
  if [[ -z "${UNIFI_USERNAME:-}" || -z "${UNIFI_PASSWORD:-}" ]]; then
    print -r -- "ERROR: Set UNIFI_USERNAME and UNIFI_PASSWORD, or create:"
    print -r -- "  ${UNIFI_ENV_FILE}"
    print -r -- "Copy from config/.unifi.local.env.example and fill in local admin credentials."
    return 1
  fi
  return 0
}

unifi_login() {
  local cookie_jar="$1"
  local login_response
  local login_code=""

  unifi_secure_cookie_paths "${cookie_jar}"

  login_response="$(
    unifi_curl \
      -c "${cookie_jar}" \
      -H 'Content-Type: application/json' \
      -X POST "https://${UNIFI_HOST}/api/auth/login" \
      -d "$(python3 - <<PY
import json, os
print(json.dumps({
    "username": os.environ["UNIFI_USERNAME"],
    "password": os.environ["UNIFI_PASSWORD"],
    "remember": True,
}))
PY
)"
  )"
  unifi_secure_cookie_paths "${cookie_jar}"

  if ! UNIFI_LOGIN_RESPONSE="${login_response}" python3 -c "
import json, os, sys
raw = os.environ.get('UNIFI_LOGIN_RESPONSE', '')
try:
    d = json.loads(raw)
except Exception:
    sys.exit(1)
if d.get('code') in ('MFA_AUTH_REQUIRED', 'AUTHENTICATION_FAILED', 'AUTHENTICATION_FAILED_ACCOUNT_LOCKED'):
    sys.exit(1)
sys.exit(0 if d.get('unique_id') or d.get('authenticated') else 1)
" 2>/dev/null; then
    login_code="$(
      print -r -- "${login_response}" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('code') or d.get('message') or 'unknown')
except Exception:
    print('unparseable')
" 2>/dev/null || print -r -- "unparseable"
    )"
    print -r -- "Login failed (use local admin, not SSO — MFA blocks API)."
    print -r -- "API code: ${login_code}"
    return 1
  fi
  # Touch mtime for session age tracking
  command touch "${cookie_jar}" 2>/dev/null || true
  unifi_secure_cookie_paths "${cookie_jar}"
  return 0
}

unifi_api_get() {
  local cookie_jar="$1"
  local api_path="$2"
  unifi_curl -b "${cookie_jar}" "https://${UNIFI_HOST}${api_path}"
}

# Returns 0 if cookie jar can read a lightweight authenticated endpoint.
unifi_session_ok() {
  local cookie_jar="$1"
  local body
  [[ -f "${cookie_jar}" ]] || return 1
  body="$(unifi_api_get "${cookie_jar}" "/proxy/network/api/self")"
  print -r -- "${body}" | command grep -q '"email"\|"name"\|"unique_id"\|"is_super"' 2>/dev/null && return 0
  # UniFi OS sometimes returns different self shapes; accept non-auth-error JSON object
  print -r -- "${body}" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(1)
if isinstance(d, dict) and d.get('code') in (
    'AUTHENTICATION_FAILED', 'AUTHENTICATION_FAILED_ACCOUNT_LOCKED', 'UNAUTHORIZED', 'NO_AUTH'
):
    sys.exit(1)
sys.exit(0 if isinstance(d, (dict, list)) and d != {} else 1)
" 2>/dev/null
}

# Prefer cached cookies; login only when missing, stale, or invalid.
# Avoids hammering /api/auth/login (rate limits). Writes to UNIFI_COOKIE_JAR by default.
unifi_ensure_session() {
  local cookie_jar="${1:-${UNIFI_COOKIE_JAR}}"
  local max_age="${UNIFI_SESSION_MAX_AGE_SEC}"
  local age=999999

  unifi_secure_cookie_paths "${cookie_jar}"
  unifi_require_credentials || return 1

  if [[ -f "${cookie_jar}" ]]; then
    # Prefer BSD /usr/bin/stat — Homebrew gnubin `stat` breaks -f %m and trips set -u.
    age="$(( $(date +%s) - $(/usr/bin/stat -f %m "${cookie_jar}" 2>/dev/null || echo 0) ))"
  fi

  if (( age < max_age )) && unifi_session_ok "${cookie_jar}"; then
    print -r -- "Session OK (cached, age ${age}s): ${cookie_jar}"
    return 0
  fi

  print -r -- "Session refresh (login)…"
  unifi_login "${cookie_jar}" || return 1
  if ! unifi_session_ok "${cookie_jar}"; then
    print -r -- "ERROR: login succeeded but session probe failed"
    return 1
  fi
  print -r -- "Session OK (fresh): ${cookie_jar}"
  return 0
}
