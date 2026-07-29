#!/bin/zsh
set -euo pipefail

# Stop background WAN watch using reports/wan_watch.pid (caffeinate parent PID).

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PID_FILE="${BASE_DIR}/data/reports/wan_watch.pid"

if [[ ! -f "${PID_FILE}" ]]; then
  print -r -- "No PID file at ${PID_FILE}"
  exit 1
fi

pid="$(tr -d '[:space:]' <"${PID_FILE}")"
if [[ -z "${pid}" ]]; then
  print -r -- "PID file empty; removing"
  rm -f "${PID_FILE}"
  exit 1
fi

if ps -p "${pid}" >/dev/null 2>&1; then
  # Kill children first (wan_watch_48h.zsh), then caffeinate parent.
  pkill -P "${pid}" 2>/dev/null || true
  kill "${pid}" 2>/dev/null || true
  sleep 1
  if ps -p "${pid}" >/dev/null 2>&1; then
    pkill -9 -P "${pid}" 2>/dev/null || true
    kill -9 "${pid}" 2>/dev/null || true
  fi
  # Belt-and-suspenders if a stray watch shell remains
  pkill -f "${BASE_DIR}/scripts/wan_watch_48h.zsh" 2>/dev/null || true
  print -r -- "Stopped WAN watch PID ${pid}"
else
  print -r -- "Process ${pid} not running (stale PID cleared)"
fi
rm -f "${PID_FILE}"
