#!/bin/zsh
set -euo pipefail

# Open UniFi baseline pages for manual UI steps (login required).

CONSOLE="https://unifi.ui.com/consoles/58D61F5BCE690000000009A34F0A000000000A2B2BEB00000000691F42E0:909862115"
LOCAL="https://192.168.0.1"
BROWSER="${PIOS_UNIFI_BROWSER:-ChatGPT Atlas}"

open -a "${BROWSER}" "${CONSOLE}/network/default/topology"
sleep 1
open -a "${BROWSER}" "${CONSOLE}/network/default/settings/wifi"
sleep 1
open -a "${BROWSER}" "${LOCAL}/network/default/admins"

print -r -- "Opened in ${BROWSER}:"
print -r -- "  1. Topology (48h WAN gate — Starlink disconnects)"
print -r -- "  2. WiFi settings (verify PIOS-HOME)"
print -r -- "  3. Local Network → Admins (PIOS Local / pios-local-admin)"
print -r -- ""
print -r -- "Awake toggle: open -a \"PIOS Awake\"  (or menu bar cup/moon)"
