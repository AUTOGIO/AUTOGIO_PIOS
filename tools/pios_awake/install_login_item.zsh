#!/bin/zsh
set -euo pipefail

# Install LaunchAgent so PIOS Awake starts at login.

APP="${HOME}/Applications/PIOS Awake.app"
LABEL="com.pios.awake"
PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"
UID_NUM="$(id -u)"

if [[ ! -d "${APP}" ]]; then
  print -r -- "ERROR: ${APP} not found. Run build.zsh first."
  exit 1
fi

mkdir -p "${HOME}/Library/LaunchAgents"

cat > "${PLIST}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>${LABEL}</string>
	<key>ProgramArguments</key>
	<array>
		<string>/usr/bin/open</string>
		<string>-a</string>
		<string>${APP}</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>LimitLoadToSessionType</key>
	<string>Aqua</string>
</dict>
</plist>
EOF

# Unload if already registered
launchctl bootout "gui/${UID_NUM}/${LABEL}" 2>/dev/null || true
launchctl bootstrap "gui/${UID_NUM}" "${PLIST}"
launchctl enable "gui/${UID_NUM}/${LABEL}" 2>/dev/null || true
launchctl kickstart -k "gui/${UID_NUM}/${LABEL}" 2>/dev/null || true

print -r -- "Installed login item: ${PLIST}"
print -r -- "PIOS Awake will open at login."
print -r -- "Remove with: launchctl bootout gui/\$(id -u)/${LABEL} && rm -f ${PLIST}"
