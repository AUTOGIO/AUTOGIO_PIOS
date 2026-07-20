#!/bin/zsh
set -euo pipefail

# Run daily health check, open the newest report, schedule post-health follow-up reminder.

BASE_DIR="${HOME}/Documents/GitHub/AUTOGIO_PIOS"
SCRIPT="${BASE_DIR}/scripts/unifi_daily_health.zsh"
REPORT_DIR="${BASE_DIR}/data/reports"
FOLLOWUP_SWIFT="${BASE_DIR}/scripts/create_pios_followup_reminder.swift"
FOLLOWUP_DELAY_MINUTES="${FOLLOWUP_DELAY_MINUTES:-15}"

"${SCRIPT}"

latest="$(ls -t "${REPORT_DIR}"/daily_health_*.txt 2>/dev/null | head -1)"
if [[ -n "${latest}" && -f "${latest}" ]]; then
  open "${latest}"
  print -r -- "Opened: ${latest}"
else
  print -r -- "WARN: No daily_health report found under ${REPORT_DIR}" >&2
  exit 1
fi

verdict_parts=()
while IFS= read -r _v; do
  [[ -n "${_v}" ]] && verdict_parts+=("${_v}")
done < <(rg -o 'PASS_UNIFI_BASELINE_READY|FAIL_[A-Z0-9_]+|WARN_[A-Z0-9_]+|WAN_STABILITY_GATE_[A-Z]+' "${latest}" 2>/dev/null | sort -u)
if (( ${#verdict_parts[@]} > 0 )); then
  verdict_line="Verdict: $(printf '%s, ' "${verdict_parts[@]}" | sed 's/, $//')"
else
  verdict_line="Verdict: see report"
fi

if [[ -f "${FOLLOWUP_SWIFT}" ]]; then
  if swift "${FOLLOWUP_SWIFT}" "${FOLLOWUP_DELAY_MINUTES}" "${verdict_line}"; then
    print -r -- "Follow-up reminder scheduled in ${FOLLOWUP_DELAY_MINUTES} minutes (PIOS Network list)"
  else
    print -r -- "WARN: Could not create follow-up reminder — check Reminders privacy access" >&2
  fi
fi
