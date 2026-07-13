#!/bin/zsh
# Start 48h WAN watch in background (caffeinate + nohup). Writes PID to reports/wan_watch.pid

BASE_DIR="${HOME}/AUTOGIO_PIOS/networking/unifi_baseline"
REPORT_DIR="${BASE_DIR}/reports"
SCRIPT="${BASE_DIR}/scripts/wan_watch_48h.zsh"
STDOUT_LOG="${REPORT_DIR}/wan_watch_stdout.log"
PID_FILE="${REPORT_DIR}/wan_watch.pid"

mkdir -p "${REPORT_DIR}"

if [[ -f "${PID_FILE}" ]]; then
  old_pid="$(<"${PID_FILE}")"
  if ps -p "${old_pid}" >/dev/null 2>&1; then
    print -r -- "ERROR: Watcher already running (PID ${old_pid})"
    print -r -- "Stop with: kill ${old_pid}"
    exit 1
  fi
fi

caffeinate -s nohup "${SCRIPT}" >"${STDOUT_LOG}" 2>&1 &
watch_pid=$!
print -r -- "${watch_pid}" > "${PID_FILE}"
print -r -- "Started WAN watch PID ${watch_pid}"
print -r -- "Stdout log: ${STDOUT_LOG}"
print -r -- "Monitor: tail -f ${STDOUT_LOG}"
print -r -- "Status:  ps -p ${watch_pid}"
