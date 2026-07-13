#!/bin/zsh
set -euo pipefail

# Read-only WAN status via local UniFi API (requires local admin in .unifi.local.env).

BASE_DIR="${HOME}/AUTOGIO_PIOS/networking/unifi_baseline"
REPORT_DIR="${BASE_DIR}/reports"
SCRIPT_DIR="${BASE_DIR}/scripts"
mkdir -p "${REPORT_DIR}"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/unifi_common.zsh"

timestamp="$(date +%Y%m%d-%H%M%S)"
report_path="${REPORT_DIR}/wan_status_${timestamp}.txt"
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
unifi_login "${cookie_jar}" || exit 1
print -r -- "Login OK (${UNIFI_USERNAME}@${UNIFI_HOST})"

section "WAN Enriched Configuration"
wan_json="$(unifi_api_get "${cookie_jar}" "/proxy/network/v2/api/site/${UNIFI_SITE}/wan/enriched-configuration")"

WAN_JSON="${wan_json}" python3 - <<'PY'
import json, os, sys

raw = os.environ.get("WAN_JSON", "")
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    print("ERROR: invalid JSON response")
    print(raw[:500])
    sys.exit(1)

items = data if isinstance(data, list) else data.get("data", [data])
if not items:
    print("ERROR: no WAN entries")
    sys.exit(1)

wan = items[0]
cfg = wan.get("configuration", wan)
stats = wan.get("statistics", {})
peak = stats.get("peak_usage", {})
caps = cfg.get("wan_provider_capabilities", {})
details = wan.get("details", {}).get("service_provider", {})

down_kbps = int(caps.get("download_kilobits_per_second") or 0)
up_kbps = int(caps.get("upload_kilobits_per_second") or 0)
down_mbps = down_kbps // 1000
up_mbps = up_kbps // 1000
uptime = stats.get("uptime_percentage", "n/a")
peak_down = peak.get("download_percentage", "n/a")
peak_up = peak.get("upload_percentage", "n/a")

print(f"WAN name:           {cfg.get('name', 'n/a')}")
print(f"WAN networkgroup:   {cfg.get('wan_networkgroup', 'n/a')}")
print(f"WAN type:           {cfg.get('wan_type', 'n/a')}")
print(f"ISP:                {details.get('name', 'Starlink')}")
print(f"Uptime (24h):       {uptime}%")
print(f"ISP cap download:   {down_mbps} Mbps ({down_kbps} kbps)")
print(f"ISP cap upload:     {up_mbps} Mbps ({up_kbps} kbps)")
print(f"Peak download:      {peak_down}%")
print(f"Peak upload:        {peak_up}%")
print("")
print("PASS_WAN_STATUS_READ")
PY

print -r -- ""
print -r -- "Report path: ${report_path}"
