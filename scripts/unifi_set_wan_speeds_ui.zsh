#!/bin/zsh
set -euo pipefail

# Apply WAN ISP speed limits via UniFi UI after manual login (supports MFA).
# Optional escape hatch when local-admin API login fails.
# Requires: Playwright CLI wrapper (default: $CODEX_HOME/skills/playwright/... or set PLAYWRIGHT_CLI).
# Defaults: 260 Mbps down / 74 Mbps up
#
# Prefer scripts/unifi_set_wan_speeds.zsh (local admin API) when possible.

DOWN_MBPS="${1:-260}"
UP_MBPS="${2:-74}"
HOST="${UNIFI_HOST:-192.168.0.1}"
if [[ -z "${UNIFI_USERNAME:-}" ]]; then
  # Load local env if present (do not default to SSO email).
  _env="$(cd "$(dirname "$0")/.." && pwd)/config/.unifi.local.env"
  if [[ -f "${_env}" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${_env}"
    set +a
  fi
fi
if [[ -z "${UNIFI_USERNAME:-}" ]]; then
  print -r -- "ERROR: Set UNIFI_USERNAME (local admin preferred) before running UI apply."
  print -r -- "Example: UNIFI_USERNAME=pios-local-admin $0 ${DOWN_MBPS} ${UP_MBPS}"
  exit 1
fi
USERNAME="${UNIFI_USERNAME}"
SESSION="${PLAYWRIGHT_CLI_SESSION:-unifi-wan-apply}"
WORKDIR="${TMPDIR:-/tmp}/unifi-pw"
PWCLI="${PLAYWRIGHT_CLI:-${CODEX_HOME:-$HOME/.codex}/skills/playwright/scripts/playwright_cli.sh}"

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPORT_DIR="${BASE_DIR}/data/reports"
mkdir -p "${REPORT_DIR}" "${WORKDIR}"
timestamp="$(date +%Y%m%d-%H%M%S)"
report_path="${REPORT_DIR}/wan_speed_ui_${timestamp}.txt"

exec > >(tee "${report_path}") 2>&1

section() {
  print -r -- ""
  print -r -- "=================================================="
  print -r -- "$1"
  print -r -- "=================================================="
}

if [[ ! -x "${PWCLI}" ]]; then
  print -r -- "ERROR: Playwright CLI wrapper not found at ${PWCLI}"
  print -r -- "Install/configure PLAYWRIGHT_CLI, or use scripts/unifi_set_wan_speeds.zsh instead."
  exit 1
fi

cat > "${WORKDIR}/playwright-cli.json" <<'JSON'
{
  "browser": {
    "launchOptions": { "headless": false },
    "contextOptions": {
      "ignoreHTTPSErrors": true,
      "viewport": { "width": 1440, "height": 900 }
    }
  }
}
JSON

cd "${WORKDIR}"
export PLAYWRIGHT_CLI_SESSION="${SESSION}"

bypass_cert_warning() {
  local snap ref
  snap="$("${PWCLI}" snapshot 2>&1 || true)"
  if print -r -- "${snap}" | rg -q "connection is not private|ERR_CERT"; then
    ref="$(print -r -- "${snap}" | rg -o 'button "Advanced" \[ref=([^\]]+)\]' | head -1 | sed 's/.*ref=//;s/\]//')"
    [[ -n "${ref}" ]] && "${PWCLI}" click "${ref}" 2>/dev/null || true
    sleep 1
    snap="$("${PWCLI}" snapshot 2>&1 || true)"
    ref="$(print -r -- "${snap}" | rg -o 'link "Proceed to [^"]+" \[ref=([^\]]+)\]' | head -1 | sed 's/.*ref=//;s/\]//')"
    [[ -n "${ref}" ]] && "${PWCLI}" click "${ref}" 2>/dev/null || true
    sleep 2
  fi
}

section "Open UniFi WAN settings"
"${PWCLI}" close 2>/dev/null || true
"${PWCLI}" open "https://${HOST}/network/default/settings/internet/wan/WAN" 2>&1 || true
sleep 2
bypass_cert_warning
sleep 2

if "${PWCLI}" snapshot 2>&1 | rg -q "Email or Username"; then
  "${PWCLI}" fill "Email or Username" "${USERNAME}" 2>/dev/null || true
  print -r -- "Waiting for manual login + MFA in the Playwright window (up to 3 minutes)..."
  for _ in {1..90}; do
    url="$("${PWCLI}" eval "location.href" 2>/dev/null | tail -1 || true)"
    if [[ "${url}" != *"/login"* && -n "${url}" && "${url}" != "undefined" ]]; then
      print -r -- "Login detected: ${url}"
      break
    fi
    sleep 2
  done
fi

section "Navigate to WAN settings"
bypass_cert_warning
"${PWCLI}" goto "https://${HOST}/network/default/settings/internet/wan/WAN" 2>&1 || true
sleep 4
bypass_cert_warning
"${PWCLI}" snapshot 2>&1 | head -80

section "Set ISP speeds to ${DOWN_MBPS}/${UP_MBPS} Mbps"
# Try common UniFi field labels/selectors
"${PWCLI}" eval "(() => {
  const labels = [...document.querySelectorAll('label,span,div,p')];
  const hit = (t) => labels.find(el => (el.textContent || '').trim().toLowerCase().includes(t));
  const dl = hit('download');
  const ul = hit('upload');
  return JSON.stringify({downloadLabel: dl?.textContent?.trim() || null, uploadLabel: ul?.textContent?.trim() || null});
})()" 2>&1 | tail -5

# Fill by role/name heuristics
"${PWCLI}" eval "(() => {
  const inputs = [...document.querySelectorAll('input')];
  const visible = inputs.filter(i => i.offsetParent !== null);
  const numeric = visible.filter(i => /number|text/.test(i.type) || i.inputMode === 'numeric');
  return JSON.stringify(numeric.map(i => ({type:i.type,name:i.name,id:i.id,placeholder:i.placeholder,aria:i.getAttribute('aria-label'),value:i.value})).slice(0,12));
})()" 2>&1 | tail -8

# Attempt fills via Playwright roles
for target in "Download" "download" "Down" "Upload" "upload" "Up"; do
  :
done

"${PWCLI}" eval "(() => {
  function setByHint(hints, value) {
    const inputs = [...document.querySelectorAll('input')].filter(i => i.offsetParent !== null);
    for (const input of inputs) {
      const ctx = (input.closest('div')?.innerText || input.getAttribute('aria-label') || input.name || '').toLowerCase();
      if (hints.some(h => ctx.includes(h))) {
        input.focus();
        input.value = String(value);
        input.dispatchEvent(new Event('input', { bubbles: true }));
        input.dispatchEvent(new Event('change', { bubbles: true }));
        return true;
      }
    }
    return false;
  }
  const downOk = setByHint(['download', 'down rate', 'downrate', 'down speed'], ${DOWN_MBPS});
  const upOk = setByHint(['upload', 'up rate', 'uprate', 'up speed'], ${UP_MBPS});
  return JSON.stringify({downOk, upOk});
})()" 2>&1 | tail -3

sleep 1
"${PWCLI}" snapshot 2>&1 | head -100

section "Apply changes"
"${PWCLI}" click "Apply Changes" 2>/dev/null || "${PWCLI}" click "Apply" 2>/dev/null || "${PWCLI}" click "Save" 2>/dev/null || true
sleep 3
"${PWCLI}" snapshot 2>&1 | head -80

print -r -- ""
print -r -- "Report path: ${report_path}"
print -r -- "If values were not applied automatically, complete the two Mbps fields manually in the Playwright window, then click Apply Changes."
