#!/bin/zsh
set -u

# Hourly Mac-path connectivity watch for the 48h WAN stability gate.
# Env: INTERVAL_SECONDS (default 3600), ITERATIONS (default 48)

BASE_DIR="${HOME}/AUTOGIO_PIOS/networking/unifi_baseline"
REPORT_DIR="${BASE_DIR}/reports"
SCRIPT_DIR="${BASE_DIR}/scripts"
PID_FILE="${REPORT_DIR}/wan_watch.pid"
mkdir -p "${REPORT_DIR}"

INTERVAL_SECONDS="${INTERVAL_SECONDS:-3600}"
ITERATIONS="${ITERATIONS:-48}"
timestamp="$(date +%Y%m%d-%H%M%S)"
log_path="${REPORT_DIR}/wan_watch_${timestamp}.log"

print -r -- "$$" > "${PID_FILE}"

section() {
  print -r -- ""
  print -r -- "=================================================="
  print -r -- "$1"
  print -r -- "=================================================="
}

append() {
  print -r -- "$1" | tee -a "${log_path}"
}

evaluate_sample() {
  local default_gw primary_ip ping_ok dns_ok verdict dev

  default_gw="$(route -n get default 2>/dev/null | awk '/gateway:/{print $2; exit}')"
  dev="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"
  primary_ip="$(ipconfig getifaddr "${dev}" 2>/dev/null || true)"

  ping_ok=0
  dns_ok=0
  if ping -c 1 -W 2000 1.1.1.1 >/dev/null 2>&1; then
    ping_ok=1
  fi
  if dig +time=3 +tries=1 +short cloudflare.com 2>/dev/null | head -1 | grep -q .; then
    dns_ok=1
  fi

  if [[ "${default_gw}" == "192.168.0.1" && "${primary_ip}" == 192.168.0.* && ping_ok -eq 1 && dns_ok -eq 1 ]]; then
    verdict="PASS_SAMPLE"
  else
    verdict="FAIL_SAMPLE gw=${default_gw:-none} ip=${primary_ip:-none} ping=${ping_ok} dns=${dns_ok}"
  fi
  print -r -- "VERDICT: ${verdict}"
  [[ "${verdict}" == PASS_SAMPLE ]]
}

{
  section "WAN Watch Started"
  append "PID: $$"
  append "PID file: ${PID_FILE}"
  append "Start time: $(date)"
  append "Iterations: ${ITERATIONS}"
  append "Interval seconds: ${INTERVAL_SECONDS}"
  append "Log path: ${log_path}"
} | tee "${log_path}" >/dev/null

fail_count=0
pass_count=0

for i in $(seq 1 "${ITERATIONS}"); do
  sample_file="$(mktemp)"
  {
    section "Sample ${i}/${ITERATIONS}"
    date
    route -n get default || true
    print -r -- "--- IPv4 on en5 ---"
    ipconfig getifaddr en5 || true
    print -r -- "--- IPv4 on en0 ---"
    ipconfig getifaddr en0 || true
    print -r -- "--- Ping 1.1.1.1 ---"
    ping -c 1 -W 2000 1.1.1.1 || true
    print -r -- "--- DNS cloudflare.com ---"
    dig +short cloudflare.com || true
    print -r -- "--- DNS unifi.ui.com ---"
    dig +short unifi.ui.com || true
    evaluate_sample
    if [[ -f "${BASE_DIR}/.unifi.local.env" ]]; then
      print -r -- "--- WAN API status ---"
      "${SCRIPT_DIR}/unifi_wan_status.zsh" 2>&1 | tail -15 || print -r -- "WARN: unifi_wan_status failed"
    else
      print -r -- "SKIP: WAN API status (.unifi.local.env not configured)"
    fi
  } > "${sample_file}" 2>&1
  tee -a "${log_path}" < "${sample_file}"
  if rg -q '^VERDICT: PASS_SAMPLE$' "${sample_file}"; then
    (( pass_count++ )) || true
  else
    (( fail_count++ )) || true
  fi
  rm -f "${sample_file}"

  if (( i < ITERATIONS )); then
    sleep "${INTERVAL_SECONDS}"
  fi
done

section "WAN Watch Completed"
append "Completed at: $(date)"
append "Samples passed: ${pass_count}/${ITERATIONS}"
append "Samples failed: ${fail_count}/${ITERATIONS}"
append "Log path: ${log_path}"
if (( fail_count == 0 )); then
  append "FINAL_VERDICT: PASS_WAN_WATCH"
else
  append "FINAL_VERDICT: FAIL_WAN_WATCH"
fi

rm -f "${PID_FILE}"
