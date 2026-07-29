#!/bin/zsh
set -euo pipefail

# Start 48h WAN watch in background (caffeinate).
# PID file always refers to the caffeinate parent; wan_watch_48h must not overwrite it.

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPORT_DIR="${BASE_DIR}/data/reports"
SCRIPT="${BASE_DIR}/scripts/wan_watch_48h.zsh"
STDOUT_LOG="${REPORT_DIR}/wan_watch_stdout.log"
PID_FILE="${REPORT_DIR}/wan_watch.pid"

mkdir -p "${REPORT_DIR}"

if [[ -f "${PID_FILE}" ]]; then
  old_pid="$(tr -d '[:space:]' <"${PID_FILE}")"
  if [[ -n "${old_pid}" ]] && ps -p "${old_pid}" >/dev/null 2>&1; then
    print -r -- "ERROR: Watcher already running (PID ${old_pid})"
    print -r -- "Stop with: ${BASE_DIR}/scripts/wan_watch_stop.zsh"
    exit 1
  fi
  print -r -- "Removing stale PID file (process ${old_pid:-unknown} not running)"
  rm -f "${PID_FILE}"
fi

# caffeinate waits on the utility; killing this PID stops the watch tree via stop script.
caffeinate -s "${SCRIPT}" >"${STDOUT_LOG}" 2>&1 &
watch_pid=$!
print -r -- "${watch_pid}" > "${PID_FILE}"
disown "${watch_pid}" 2>/dev/null || true

print -r -- "Started WAN watch PID ${watch_pid} (caffeinate)"
print -r -- "Stdout log: ${STDOUT_LOG}"
print -r -- "Monitor: tail -f ${STDOUT_LOG}"
print -r -- "Status:  ps -p ${watch_pid}"
print -r -- "Stop:    ${BASE_DIR}/scripts/wan_watch_stop.zsh"
