#!/bin/zsh
set -u

# Daily health check: network validation + optional WAN API status + manual WAN event note.

BASE_DIR="${HOME}/AUTOGIO_PIOS/networking/unifi_baseline"
SCRIPT_DIR="${BASE_DIR}/scripts"
REPORT_DIR="${BASE_DIR}/reports"
mkdir -p "${REPORT_DIR}"

timestamp="$(date +%Y%m%d-%H%M%S)"
report_path="${REPORT_DIR}/daily_health_${timestamp}.txt"

exec > >(tee "${report_path}") 2>&1

section() {
  print -r -- ""
  print -r -- "=================================================="
  print -r -- "$1"
  print -r -- "=================================================="
}

section "Date"
date
hostname

section "Network Validation"
"${SCRIPT_DIR}/unifi_post_change_validate.zsh" || true

section "WAN API Status (local admin)"
if [[ -f "${BASE_DIR}/.unifi.local.env" ]]; then
  "${SCRIPT_DIR}/unifi_wan_status.zsh" || print -r -- "WARN: WAN API status failed (check local admin credentials)"
else
  print -r -- "SKIP: No .unifi.local.env — create from .unifi.local.env.example after Phase 2 local admin setup"
fi

section "Manual WAN Event Check"
print -r -- "During 48h gate: also confirm hourly wan_watch log + UniFi Topology disconnects."
print -r -- "In UniFi → Topology → Starlink (WAN1), note disconnect/high-latency events since last run."
print -r -- "Starlink app: cross-check timestamps."
print -r -- "Avoid speed tests during 48h stability gate."

if [[ -t 0 ]]; then
  print -r -n "New WAN disconnect events since last check? [y/N]: "
  read -r ans
  case "${ans}" in
    [yY]|[yY][eE][sS])
      print -r -- "VERDICT: WAN_STABILITY_GATE_RESET"
      print -r -- "Action: log timestamps in checklists/wan_stability_gate.md and investigate cable/port 5"
      ;;
    *)
      print -r -- "VERDICT: WAN_STABILITY_GATE_CONTINUE"
      ;;
  esac
else
  print -r -- "VERDICT: WAN_STABILITY_GATE_CONTINUE (non-interactive — confirm disconnects manually in UniFi UI)"
fi

print -r -- ""
print -r -- "Report path: ${report_path}"
print -r -- "Gate checklist: ${BASE_DIR}/checklists/wan_stability_gate.md"
