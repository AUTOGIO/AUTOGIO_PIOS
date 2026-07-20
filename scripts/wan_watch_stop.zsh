#!/bin/zsh
# Stop background WAN watch using reports/wan_watch.pid

PID_FILE="${HOME}/Documents/GitHub/AUTOGIO_PIOS/data/reports/wan_watch.pid"

if [[ ! -f "${PID_FILE}" ]]; then
  print -r -- "No PID file at ${PID_FILE}"
  exit 1
fi

pid="$(<"${PID_FILE}")"
if ps -p "${pid}" >/dev/null 2>&1; then
  kill "${pid}" 2>/dev/null || true
  sleep 1
  if ps -p "${pid}" >/dev/null 2>&1; then
    kill -9 "${pid}" 2>/dev/null || true
  fi
  print -r -- "Stopped WAN watch PID ${pid}"
else
  print -r -- "Process ${pid} not running"
fi
rm -f "${PID_FILE}"
