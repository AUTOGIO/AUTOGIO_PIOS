#!/bin/zsh
set -euo pipefail

# Install PIOS UniFi Daily Health: sign Shortcut + create 10am/10pm Reminders.

BASE_DIR="${HOME}/AUTOGIO_PIOS/networking/unifi_baseline"
SETUP_DIR="${BASE_DIR}/setup"
UNSIGNED="${SETUP_DIR}/PIOS UniFi Daily Health.shortcut"
SIGNED="${SETUP_DIR}/PIOS UniFi Daily Health.signed.shortcut"
ACTION_SCRIPT="${BASE_DIR}/scripts/pios_reminder_action.zsh"
SHORTCUT_NAME="PIOS UniFi Daily Health"
REMINDER_LIST="PIOS Network"
# URL-encoded shortcut name for Reminders notes link
SHORTCUT_URL="shortcuts://run-shortcut?name=PIOS%20UniFi%20Daily%20Health"

chmod +x "${ACTION_SCRIPT}"
chmod +x "${BASE_DIR}/scripts/unifi_daily_health.zsh"

print -r -- "Signing Shortcut..."
shortcuts sign --mode anyone --input "${UNSIGNED}" --output "${SIGNED}"

print -r -- "Import Shortcut (accept the Add Shortcut dialog if shown)..."
open "${SIGNED}" 2>/dev/null || true
sleep 3
if shortcuts list 2>/dev/null | rg -Fq "${SHORTCUT_NAME}"; then
  print -r -- "Shortcut installed: ${SHORTCUT_NAME}"
else
  print -r -- "WARN: Shortcut not in library yet — accept the import dialog, then run:"
  print -r -- "  shortcuts run \"${SHORTCUT_NAME}\""
fi

print -r -- "Creating Reminders in list: ${REMINDER_LIST}"
swift "${SETUP_DIR}/create_pios_reminders.swift"

print -r -- ""
print -r -- "Done."
print -r -- "  Shortcut: ${SHORTCUT_NAME}"
print -r -- "  Run link: ${SHORTCUT_URL}"
print -r -- "  Reminders list: ${REMINDER_LIST}"
print -r -- "  Alerts: 10:00 AM and 10:00 PM daily"
print -r -- "  Follow-up: PIOS Post-Health Follow-up (15 min after each health run)"
print -r -- ""
print -r -- "Test now: shortcuts run \"${SHORTCUT_NAME}\""
