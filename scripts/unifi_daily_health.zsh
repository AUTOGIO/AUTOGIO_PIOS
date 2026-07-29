#!/bin/zsh
set -u

# Daily health check: network validation + WAN API + structured network score.
# Non-interactive runs (LaunchAgent) skip WAN disconnect prompt.

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="${BASE_DIR}/scripts"
REPORT_DIR="${BASE_DIR}/data/reports"
mkdir -p "${REPORT_DIR}"

timestamp="$(date +%Y%m%d-%H%M%S)"
report_path="${REPORT_DIR}/daily_health_${timestamp}.txt"
score_json_path="${REPORT_DIR}/daily_health_${timestamp}.score.json"

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
wan_ok=0
if [[ -f "${BASE_DIR}/config/.unifi.local.env" ]]; then
  if "${SCRIPT_DIR}/unifi_wan_status.zsh"; then
    wan_ok=1
  else
    print -r -- "WARN: WAN API status failed (check local admin credentials / rate limit)"
  fi
else
  print -r -- "SKIP: No .unifi.local.env — create from .unifi.local.env.example after Phase 2 local admin setup"
fi

section "Network Score (structured)"
# Derive a simple 0–100 score from latest validate + WAN snippets in this report.
SCORE_REPORT="${report_path}" SCORE_JSON="${score_json_path}" WAN_OK="${wan_ok}" \
PYTHONPATH="${BASE_DIR}/scripts${PYTHONPATH:+:$PYTHONPATH}" python3 - <<'PY'
import json, os, pathlib
from lib.network_score import score_from_report

report = pathlib.Path(os.environ["SCORE_REPORT"]).read_text(errors="replace")
wan_ok = os.environ.get("WAN_OK") == "1"
payload = score_from_report(report, wan_ok)
score = payload["network_score"]
uptime = payload["uptime_24h_pct"]
checks = payload["checks"]
deductions = payload["deductions"]

pathlib.Path(os.environ["SCORE_JSON"]).write_text(json.dumps(payload, indent=2) + "\n")
print(f"Network Score:     {score}%")
print(f"Uptime (24h):      {uptime if uptime is not None else 'n/a'}%")
print(f"WAN API:           {'ok' if checks['wan_api'] else 'fail/skip'}")
print(f"Deductions:        {', '.join(deductions) if deductions else 'none'}")
print(f"Score JSON:        {os.environ['SCORE_JSON']}")
print("")
print("Morning report fields (fill from UniFi UI / intel when available):")
print("  - Internet uptime")
print("  - Latency / packet loss")
print("  - Disconnected devices")
print("  - Weak Wi-Fi clients")
print("  - Firmware updates available")
print("  - Bandwidth yesterday")
print("  - Security / IDS events")
PY

section "Manual WAN Event Check"
print -r -- "During 48h gate: also confirm hourly wan_watch log + UniFi Topology disconnects."
print -r -- "In UniFi → Topology → Starlink (WAN1), note disconnect/high-latency events since last run."
print -r -- "Starlink app: cross-check timestamps."
print -r -- "Avoid speed tests during 48h stability gate."
print -r -- "Post-gate: prefer scripts/report_morning.zsh for structured morning digest."

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

# Optional: append intel morning summary if DB exists (Phase 3+)
if [[ -x "${BASE_DIR}/scripts/report_morning.zsh" && -f "${BASE_DIR}/data/intelligence/unifi_intel.sqlite" ]]; then
  section "Intelligence Morning Snapshot"
  "${BASE_DIR}/scripts/report_morning.zsh" --stdout-only || print -r -- "WARN: intel morning report failed"
fi

print -r -- ""
print -r -- "Report path: ${report_path}"
print -r -- "Score JSON:  ${score_json_path}"
print -r -- "Gate checklist: ${BASE_DIR}/docs/checklists/wan_stability_gate.md"
print -r -- "Post-baseline roadmap: ${BASE_DIR}/docs/post-baseline-roadmap.md"
