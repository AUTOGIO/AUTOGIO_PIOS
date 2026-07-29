#!/bin/zsh
set -euo pipefail

# Open UniFi baseline pages for manual UI steps (login required).
#
# Set UNIFI_CONSOLE_URL to your UniFi Site Manager console base, e.g.:
#   export UNIFI_CONSOLE_URL="https://unifi.ui.com/consoles/<YOUR_CONSOLE_ID>"
# If unset, only the local gateway admin page is opened.

LOCAL="${UNIFI_LOCAL_URL:-https://192.168.0.1}"
BROWSER="${PIOS_UNIFI_BROWSER:-ChatGPT Atlas}"
CONSOLE="${UNIFI_CONSOLE_URL:-}"

if [[ -n "${CONSOLE}" ]]; then
  open -a "${BROWSER}" "${CONSOLE}/network/default/topology"
  sleep 1
  open -a "${BROWSER}" "${CONSOLE}/network/default/settings/wifi"
  sleep 1
else
  print -r -- "NOTE: UNIFI_CONSOLE_URL unset — skipping cloud Topology/WiFi tabs."
  print -r -- "Export UNIFI_CONSOLE_URL to open Site Manager pages."
fi
open -a "${BROWSER}" "${LOCAL}/network/default/admins"

print -r -- "Opened in ${BROWSER}:"
if [[ -n "${CONSOLE}" ]]; then
  print -r -- "  1. Topology (48h WAN gate — Starlink disconnects)"
  print -r -- "  2. WiFi settings (verify PIOS-HOME)"
  print -r -- "  3. Local Network → Admins (PIOS Local / pios-local-admin)"
else
  print -r -- "  1. Local Network → Admins (PIOS Local / pios-local-admin)"
fi
print -r -- ""
print -r -- "Awake toggle: open -a \"PIOS Awake\"  (or menu bar cup/moon)"
