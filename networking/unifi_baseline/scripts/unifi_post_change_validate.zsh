#!/bin/zsh
set -u

BASE_DIR="${HOME}/AUTOGIO_PIOS/networking/unifi_baseline"
REPORT_DIR="${BASE_DIR}/reports"
mkdir -p "${REPORT_DIR}"

timestamp="$(date +%Y%m%d-%H%M%S)"
report_path="${REPORT_DIR}/post_change_validate_${timestamp}.txt"

exec > >(tee "${report_path}") 2>&1

section() {
  print -r -- ""
  print -r -- "=================================================="
  print -r -- "$1"
  print -r -- "=================================================="
}

primary_ip="$(ipconfig getifaddr $(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}') 2>/dev/null || true)"
default_gw="$(route -n get default 2>/dev/null | awk '/gateway:/{print $2; exit}')"

section "Connectivity Checks"
ping -c 1 -W 2000 1.1.1.1 || true
for host in cloudflare.com unifi.ui.com giovannini.us giovannini.uk; do
  print -r -- ""
  print -r -- "Resolve: ${host}"
  dig +short "${host}" || true
done

section "Gateway and Network State"
route -n get default || true
networksetup -listallhardwareports
ifconfig | awk '/inet / && $2 != "127.0.0.1" {print}'

section "Verdict"
internet_ok=0
dns_ok=0
gateway_ok=0
behind_unifi=0

if ping -c 1 -W 2000 1.1.1.1 >/dev/null 2>&1; then
  internet_ok=1
fi

dns_ok=1
missing_zones=""
for _d in cloudflare.com unifi.ui.com; do
  _ans="$(dig +time=3 +tries=1 +short "${_d}" 2>/dev/null | head -1)"
  if [[ -z "${_ans// }" ]]; then
    dns_ok=0
    print -r -- "DNS FAIL (required): ${_d}"
  fi
done
for _d in giovannini.us giovannini.uk; do
  _ans="$(dig +time=3 +tries=1 +short "${_d}" 2>/dev/null | head -1)"
  if [[ -z "${_ans// }" ]]; then
    missing_zones="${missing_zones} ${_d}"
    print -r -- "DNS INFO (owned zone, no A record yet): ${_d}"
  fi
done

if [[ "${default_gw}" == "192.168.0.1" ]]; then
  gateway_ok=1
fi

if [[ "${primary_ip}" == 192.168.0.* ]]; then
  behind_unifi=1
fi

if (( internet_ok == 0 || dns_ok == 0 )); then
  verdict="FAIL_NETWORK_UNSTABLE"
elif (( behind_unifi == 0 || gateway_ok == 0 )); then
  verdict="WARN_CLIENT_NOT_BEHIND_UNIFI"
else
  verdict="PASS_UNIFI_BASELINE_READY"
fi

if [[ -n "${missing_zones// }" ]]; then
  print -r -- "Note: no A record yet for:${missing_zones}. Not a network failure; configure on Cloudflare when ready."
fi

print -r -- "${verdict}"
print -r -- ""
print -r -- "Report path: ${report_path}"

