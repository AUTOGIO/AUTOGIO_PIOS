#!/bin/zsh
set -euo pipefail

# Update UniFi WAN provider capabilities (ISP speed limits) on the local gateway.
#
# Usage:
#   ./unifi_set_wan_speeds.zsh [download_mbps] [upload_mbps]
#
# Credentials: .unifi.local.env (local admin) or UNIFI_USERNAME/UNIFI_PASSWORD env vars.
# Defaults: 260 Mbps down / 74 Mbps up (~80% of 330/92 speed test)

BASE_DIR="${HOME}/Documents/GitHub/AUTOGIO_PIOS"
REPORT_DIR="${BASE_DIR}/data/reports"
SCRIPT_DIR="${BASE_DIR}/scripts"
mkdir -p "${REPORT_DIR}"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/unifi_common.zsh"

DOWN_MBPS="${1:-260}"
UP_MBPS="${2:-74}"
DOWN_KBPS=$((DOWN_MBPS * 1000))
UP_KBPS=$((UP_MBPS * 1000))

timestamp="$(date +%Y%m%d-%H%M%S)"
report_path="${REPORT_DIR}/wan_speed_update_${timestamp}.txt"
cookie_jar="$(mktemp)"
trap 'rm -f "${cookie_jar}"' EXIT

exec > >(tee "${report_path}") 2>&1

section() {
  print -r -- ""
  print -r -- "=================================================="
  print -r -- "$1"
  print -r -- "=================================================="
}

unifi_require_credentials || exit 1

section "Login"
unifi_login "${cookie_jar}" || {
  print -r -- ""
  print -r -- "Use UI automation instead:"
  print -r -- "  UNIFI_USERNAME='${UNIFI_USERNAME}' ${SCRIPT_DIR}/unifi_set_wan_speeds_ui.zsh ${DOWN_MBPS} ${UP_MBPS}"
  exit 1
}
print -r -- "Login OK"

section "Fetch WAN configuration"
wan_json="$(unifi_api_get "${cookie_jar}" "/proxy/network/v2/api/site/${UNIFI_SITE}/wan/enriched-configuration")"

print -r -- "${wan_json}" | python3 -m json.tool > /dev/null 2>&1 || {
  print -r -- "Failed to fetch WAN configuration:"
  print -r -- "${wan_json}"
  exit 1
}

read -r WAN_ID WAN_NAME OLD_DOWN OLD_UP <<EOF
$(print -r -- "${wan_json}" | python3 - <<'PY'
import json, sys
data = json.load(sys.stdin)
items = data if isinstance(data, list) else data.get("data", [data])
if not items:
    raise SystemExit("No WAN entries returned")
wan = items[0]
cfg = wan.get("configuration", wan)
wan_id = cfg.get("_id") or cfg.get("id")
name = cfg.get("name", "WAN")
caps = cfg.get("wan_provider_capabilities") or {}
old_down = caps.get("download_kilobits_per_second", "")
old_up = caps.get("upload_kilobits_per_second", "")
print(wan_id, name, old_down, old_up)
PY
)
EOF

print -r -- "WAN: ${WAN_NAME} (${WAN_ID})"
print -r -- "Current limits: ${OLD_DOWN} kbps down / ${OLD_UP} kbps up"
print -r -- "Target limits:  ${DOWN_KBPS} kbps down / ${UP_KBPS} kbps up"

section "Update WAN provider capabilities"
update_payload="$(
  print -r -- "${wan_json}" | python3 - <<PY
import json, sys
data = json.load(sys.stdin)
items = data if isinstance(data, list) else data.get("data", [data])
cfg = items[0].get("configuration", items[0])
cfg["wan_provider_capabilities"] = {
    "download_kilobits_per_second": ${DOWN_KBPS},
    "upload_kilobits_per_second": ${UP_KBPS},
}
print(json.dumps(cfg))
PY
)"

update_response="$(
  curl -sk \
    -b "${cookie_jar}" \
    -H 'Content-Type: application/json' \
    -X PUT "https://${UNIFI_HOST}/proxy/network/v2/api/site/${UNIFI_SITE}/networks/wan/${WAN_ID}" \
    -d "${update_payload}"
)"

print -r -- "${update_response}" | python3 -m json.tool 2>/dev/null || print -r -- "${update_response}"

section "Verify"
verify_json="$(unifi_api_get "${cookie_jar}" "/proxy/network/v2/api/site/${UNIFI_SITE}/wan/enriched-configuration")"

print -r -- "${verify_json}" | python3 - <<PY
import json, sys
data = json.load(sys.stdin)
items = data if isinstance(data, list) else data.get("data", [data])
cfg = items[0].get("configuration", items[0])
caps = cfg.get("wan_provider_capabilities", {})
down = int(caps.get("download_kilobits_per_second", 0))
up = int(caps.get("upload_kilobits_per_second", 0))
print(f"Verified: {down} kbps down / {up} kbps up")
print(f"Verified: {down // 1000} Mbps down / {up // 1000} Mbps up")
ok = down == ${DOWN_KBPS} and up == ${UP_KBPS}
print("PASS" if ok else "FAIL")
sys.exit(0 if ok else 2)
PY

print -r -- ""
print -r -- "Report path: ${report_path}"
