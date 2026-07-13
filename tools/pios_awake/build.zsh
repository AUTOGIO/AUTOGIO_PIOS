#!/bin/zsh
set -euo pipefail

# Build PIOS Awake menu bar app into ~/Applications/PIOS Awake.app

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="${ROOT}/Sources/main.swift"
PLIST_SRC="${ROOT}/Info.plist"
APP_DIR="${HOME}/Applications/PIOS Awake.app"
MACOS_DIR="${APP_DIR}/Contents/MacOS"
BIN_NAME="PIOSAwake"
BIN="${MACOS_DIR}/${BIN_NAME}"

if [[ ! -f "${SRC}" ]]; then
  print -r -- "ERROR: missing ${SRC}"
  exit 1
fi

pkill -x "${BIN_NAME}" 2>/dev/null || true
pkill -f "PIOS Awake.app/Contents/MacOS" 2>/dev/null || true
sleep 0.3
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
# Bundle Info.plist with matching executable name
python3 - <<PY
from pathlib import Path
src = Path("${PLIST_SRC}").read_text()
src = src.replace("<string>PIOS Awake</string>", "<string>${BIN_NAME}</string>", 1)
# Only replace CFBundleExecutable line — do it via plist carefully
import plistlib
with open("${PLIST_SRC}", "rb") as f:
    d = plistlib.load(f)
d["CFBundleExecutable"] = "${BIN_NAME}"
d["CFBundleName"] = "PIOS Awake"
d["CFBundleDisplayName"] = "PIOS Awake"
out = Path("${APP_DIR}/Contents/Info.plist")
out.parent.mkdir(parents=True, exist_ok=True)
with open(out, "wb") as f:
    plistlib.dump(d, f)
print("Wrote", out)
PY

print -r -- "Compiling PIOS Awake..."
swiftc -O \
  -framework AppKit \
  -o "${BIN}" \
  "${SRC}"

chmod +x "${BIN}"
codesign --force --deep -s - "${APP_DIR}" >/dev/null 2>&1 || true
/usr/bin/touch "${APP_DIR}"

print -r -- "Built: ${APP_DIR}"
print -r -- "Launching..."
open "${APP_DIR}" 2>/dev/null || "${BIN}" &
sleep 1
if pgrep -x "${BIN_NAME}" >/dev/null 2>&1 || pgrep -f "PIOS Awake.app/Contents/MacOS" >/dev/null 2>&1; then
  print -r -- "Running. Look for the cup/moon icon in the menu bar."
else
  print -r -- "WARN: process not detected — try: open \"${APP_DIR}\""
fi
print -r -- "Optional login item: ${ROOT}/install_login_item.zsh"
