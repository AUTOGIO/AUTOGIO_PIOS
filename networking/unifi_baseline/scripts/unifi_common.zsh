#!/bin/zsh
# Shared helpers for UniFi baseline scripts. Source, do not execute.

UNIFI_BASELINE_DIR="${UNIFI_BASELINE_DIR:-${HOME}/AUTOGIO_PIOS/networking/unifi_baseline}"
UNIFI_ENV_FILE="${UNIFI_ENV_FILE:-${UNIFI_BASELINE_DIR}/.unifi.local.env}"

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
    print -r -- "Copy from .unifi.local.env.example and fill in local admin credentials."
    return 1
  fi
  return 0
}

unifi_login() {
  local cookie_jar="$1"
  local login_response

  login_response="$(
    command curl -sk \
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

  if ! UNIFI_LOGIN_RESPONSE="${login_response}" python3 -c "
import json, os, sys
d = json.loads(os.environ['UNIFI_LOGIN_RESPONSE'])
if d.get('code') in ('MFA_AUTH_REQUIRED', 'AUTHENTICATION_FAILED', 'AUTHENTICATION_FAILED_ACCOUNT_LOCKED'):
    sys.exit(1)
sys.exit(0 if d.get('unique_id') or d.get('authenticated') else 1)
" 2>/dev/null; then
    print -r -- "Login failed (use local admin, not SSO — MFA blocks API):"
    print -r -- "${login_response}"
    return 1
  fi
  return 0
}

unifi_api_get() {
  local cookie_jar="$1"
  local api_path="$2"
  /usr/bin/curl -sk -b "${cookie_jar}" "https://${UNIFI_HOST}${api_path}"
}
