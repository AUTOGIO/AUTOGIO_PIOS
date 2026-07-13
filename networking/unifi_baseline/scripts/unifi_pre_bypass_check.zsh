#!/bin/zsh
set -u

BASE_DIR="${HOME}/AUTOGIO_PIOS/networking/unifi_baseline"
REPORT_DIR="${BASE_DIR}/reports"
mkdir -p "${REPORT_DIR}"

timestamp="$(date +%Y%m%d-%H%M%S)"
report_path="${REPORT_DIR}/pre_bypass_${timestamp}.txt"

exec > >(tee "${report_path}") 2>&1

section() {
  print -r -- ""
  print -r -- "=================================================="
  print -r -- "$1"
  print -r -- "=================================================="
}

trim() {
  print -r -- "$1" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

get_primary_ip() {
  local route dev ip
  route="$(/sbin/route -n get default 2>/dev/null)"
  dev="$(print -r -- "${route}" | awk '/interface:/{print $2; exit}')"
  if [[ -n "${dev}" ]]; then
    ip="$(/usr/sbin/ipconfig getifaddr "${dev}" 2>/dev/null || true)"
    print -r -- "${ip}"
  fi
}

get_default_gw() {
  /sbin/route -n get default 2>/dev/null | awk '/gateway:/{print $2; exit}'
}

get_wifi_info() {
  local wifi_dev
  wifi_dev="$(/usr/sbin/networksetup -listallhardwareports 2>/dev/null | awk '/Hardware Port: Wi-Fi|Hardware Port: AirPort/{getline; print $2; exit}')"
  if [[ -n "${wifi_dev}" ]]; then
    /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null || true
  else
    print -r -- "Wi-Fi interface not found"
  fi
}

primary_ip="$(get_primary_ip)"
default_gw="$(get_default_gw)"

section "Date and Host"
date
hostname
scutil --get LocalHostName 2>/dev/null || true
sw_vers

section "Network Services"
networksetup -listallnetworkservices

section "Default Route"
route -n get default || true

section "Wi-Fi Info"
get_wifi_info

section "Ethernet Status"
networksetup -listallhardwareports
ifconfig | awk 'BEGIN{RS=""} /status:/{print}'

section "IP Addresses"
ifconfig | awk '/inet / && $2 != "127.0.0.1" {print}'

section "DNS Servers"
scutil --dns | awk '/nameserver\[[0-9]+\]/{print}'

section "Connectivity Tests"
for host in 1.1.1.1 cloudflare.com unifi.ui.com; do
  print -r -- ""
  print -r -- "Ping: ${host}"
  ping -c 3 -W 2000 "${host}" || true
done

section "DNS Tests"
for host in cloudflare.com unifi.ui.com giovannini.us giovannini.uk; do
  print -r -- ""
  print -r -- "Resolve: ${host}"
  dscacheutil -q host -a name "${host}" || true
  dig +short "${host}" || true
done

section "Public IP"
curl -fsS https://ifconfig.me || true

section "Gateway and Subnet Checks"
if [[ "${default_gw}" == "192.168.0.1" ]]; then
  print -r -- "Gateway check: PASS (192.168.0.1)"
else
  print -r -- "Gateway check: FAIL (current=${default_gw:-unknown})"
fi

if [[ "${primary_ip}" == 192.168.0.* ]]; then
  print -r -- "Subnet check 192.168.0.0/24: PASS (current=${primary_ip:-unknown})"
else
  print -r -- "Subnet check 192.168.0.0/24: FAIL (current=${primary_ip:-unknown})"
fi

if [[ "${primary_ip}" == 192.168.1.* ]]; then
  print -r -- "Starlink subnet check 192.168.1.0/24: PASS (current=${primary_ip:-unknown})"
else
  print -r -- "Starlink subnet check 192.168.1.0/24: FAIL (current=${primary_ip:-unknown})"
fi

internet_ok=0
dns_ok=0
has_gateway=0
gateway_is_unifi=0
gateway_is_starlink=0
behind_unifi=0
on_starlink=0

if ping -c 1 -W 2000 1.1.1.1 >/dev/null 2>&1; then
  internet_ok=1
fi

# DNS is OK only when cloudflare.com actually resolves to a non-empty answer.
dns_answer="$(dig +time=3 +tries=1 +short cloudflare.com 2>/dev/null | head -1)"
if [[ -n "${dns_answer// }" ]]; then
  dns_ok=1
fi

if [[ -n "${default_gw}" ]]; then
  has_gateway=1
fi

if [[ "${default_gw}" == "192.168.0.1" ]]; then
  gateway_is_unifi=1
fi

if [[ "${default_gw}" == "192.168.1.1" ]]; then
  gateway_is_starlink=1
fi

if [[ "${primary_ip}" == 192.168.0.* ]]; then
  behind_unifi=1
fi

if [[ "${primary_ip}" == 192.168.1.* ]]; then
  on_starlink=1
fi

section "Final Verdict"
# Priority order (per AUTOGIO PIOS plan):
#   1. No default gateway               -> FAIL_NO_GATEWAY
#   2. Cannot reach 1.1.1.1              -> FAIL_NO_INTERNET
#   3. DNS resolution broken             -> FAIL_NO_DNS
#   4. Mac still on Starlink LAN         -> WARN_MAC_STILL_ON_STARLINK_NETWORK
#   5. Mac behind UniFi and gw=0.1       -> PASS_READY_FOR_BYPASS_VALIDATION
#   6. Anything else                     -> MANUAL_CHECKS_REQUIRED
if (( has_gateway == 0 )); then
  verdict="FAIL_NO_GATEWAY"
elif (( internet_ok == 0 )); then
  verdict="FAIL_NO_INTERNET"
elif (( dns_ok == 0 )); then
  verdict="FAIL_NO_DNS"
elif (( on_starlink == 1 || gateway_is_starlink == 1 )); then
  verdict="WARN_MAC_STILL_ON_STARLINK_NETWORK"
elif (( behind_unifi == 1 && gateway_is_unifi == 1 )); then
  verdict="PASS_READY_FOR_BYPASS_VALIDATION"
else
  verdict="MANUAL_CHECKS_REQUIRED"
fi

print -r -- "${verdict}"
print -r -- ""
print -r -- "Report path: ${report_path}"

