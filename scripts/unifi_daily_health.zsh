#!/bin/zsh
set -u

# Daily health check: network validation + WAN API + structured network score.
# Non-interactive runs (LaunchAgent) skip WAN disconnect prompt.

BASE_DIR="${HOME}/Documents/GitHub/AUTOGIO_PIOS"
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
SCORE_REPORT="${report_path}" SCORE_JSON="${score_json_path}" WAN_OK="${wan_ok}" python3 - <<'PY'
import json, os, re, pathlib

report = pathlib.Path(os.environ["SCORE_REPORT"]).read_text(errors="replace")
wan_ok = os.environ.get("WAN_OK") == "1"

checks = {
    "pass_baseline": "PASS_UNIFI_BASELINE_READY" in report,
    "warn_not_behind": "WARN_CLIENT_NOT_BEHIND_UNIFI" in report,
    "wan_api": wan_ok or "PASS_WAN_STATUS_READ" in report,
    "no_hard_fail": "FAIL_NETWORK_UNSTABLE" not in report,
}

# Parse uptime if present
uptime = None
m = re.search(r"Uptime \(24h\):\s+([0-9.]+)%", report)
if m:
    try:
        uptime = float(m.group(1))
    except ValueError:
        uptime = None

score = 100
deductions = []
if "FAIL_NETWORK_UNSTABLE" in report:
    score -= 40
    deductions.append("network_unstable:-40")
if "WARN_CLIENT_NOT_BEHIND_UNIFI" in report:
    score -= 15
    deductions.append("not_behind_unifi:-15")
if not checks["wan_api"]:
    score -= 10
    deductions.append("wan_api_unavailable:-10")
if uptime is not None and uptime < 99.9:
    # Soft penalty during gate / Starlink variance
    pen = min(20, int((99.9 - uptime) * 10))
    score -= pen
    deductions.append(f"uptime_{uptime}:-{pen}")

score = max(0, min(100, score))

payload = {
    "network_score": score,
    "uptime_24h_pct": uptime,
    "checks": checks,
    "deductions": deductions,
    "notes": [
        "Score is advisory for PIOS ops; UniFi UI remains source of truth for Topology events.",
        "Weak Wi-Fi clients / DFS / AP util appear in intelligence reports when collector is running.",
    ],
}
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
