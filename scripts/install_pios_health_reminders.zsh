#!/bin/zsh
set -euo pipefail

# Install PIOS UniFi Daily Health: sign Shortcut + create 10am/10pm Reminders.

BASE_DIR="${HOME}/Documents/GitHub/AUTOGIO_PIOS"
SETUP_DIR="${BASE_DIR}/scripts"
UNSIGNED="${SETUP_DIR}/PIOS UniFi Daily Health.shortcut"
SIGNED="${SETUP_DIR}/PIOS UniFi Daily Health.signed.shortcut"
ACTION_SCRIPT="${BASE_DIR}/scripts/pios_reminder_action.zsh"
SHORTCUT_NAME="PIOS UniFi Daily Health"
SHORTCUT_NAME_SIGNED="${SHORTCUT_NAME}.signed"
REMINDER_LIST="PIOS Network"

chmod +x "${ACTION_SCRIPT}"
chmod +x "${BASE_DIR}/scripts/unifi_daily_health.zsh"

print -r -- "Signing Shortcut..."
shortcuts sign --mode anyone --input "${UNSIGNED}" --output "${SIGNED}"

print -r -- "Import Shortcut (accept the Add Shortcut dialog if shown)..."
open "${SIGNED}" 2>/dev/null || true
sleep 3

RESOLVED_NAME=""
if shortcuts list 2>/dev/null | rg -Fxq "${SHORTCUT_NAME}"; then
  RESOLVED_NAME="${SHORTCUT_NAME}"
elif shortcuts list 2>/dev/null | rg -Fxq "${SHORTCUT_NAME_SIGNED}"; then
  RESOLVED_NAME="${SHORTCUT_NAME_SIGNED}"
  print -r -- "NOTE: Library has '${SHORTCUT_NAME_SIGNED}' (macOS import name). Reminders will use that."
fi

if [[ -n "${RESOLVED_NAME}" ]]; then
  print -r -- "Shortcut installed: ${RESOLVED_NAME}"
else
  print -r -- "WARN: Shortcut not in library yet — accept the import dialog, then re-run this installer."
  print -r -- "  Expected: shortcuts run \"${SHORTCUT_NAME}\"  (or \"${SHORTCUT_NAME_SIGNED}\")"
fi

print -r -- "Creating Reminders in list: ${REMINDER_LIST}"
swift "${SETUP_DIR}/create_pios_reminders.swift"

SHORTCUT_URL="shortcuts://run-shortcut?name=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "${RESOLVED_NAME:-${SHORTCUT_NAME_SIGNED}}")"

print -r -- ""
print -r -- "Done."
print -r -- "  Shortcut: ${RESOLVED_NAME:-"(pending import)"}"
print -r -- "  Run link: ${SHORTCUT_URL}"
print -r -- "  Reminders list: ${REMINDER_LIST}"
print -r -- "  Alerts: 10:00 AM and 10:00 PM daily"
print -r -- "  Follow-up: PIOS Post-Health Follow-up (15 min after each health run)"
print -r -- ""
print -r -- "Test now: shortcuts run \"${RESOLVED_NAME:-${SHORTCUT_NAME_SIGNED}}\""
