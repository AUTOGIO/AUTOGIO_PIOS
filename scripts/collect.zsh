#!/bin/zsh
set -euo pipefail

# One Network Intelligence collection cycle (session-safe).
# Intended interval: 5 minutes via LaunchAgent — do not cron at 1 minute.

BASE_DIR="${HOME}/Documents/GitHub/AUTOGIO_PIOS"
SCRIPT_DIR="${BASE_DIR}/scripts"
CONFIG_DIR="${BASE_DIR}/config"
DATA_DIR="${BASE_DIR}/data/intelligence"
DB_PATH="${DATA_DIR}/unifi_intel.sqlite"
COOKIE_JAR="${UNIFI_COOKIE_JAR:-${CONFIG_DIR}/.cache/unifi_cookies.txt}"
HA_STATE_PATH="${DATA_DIR}/ha_state.json"

mkdir -p "${DATA_DIR}" "${CONFIG_DIR}/.cache"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/unifi_common.zsh"

unifi_require_credentials || exit 1
unifi_ensure_session "${COOKIE_JAR}" || exit 1

if [[ ! -f "${DB_PATH}" ]]; then
  sqlite3 "${DB_PATH}" < "${CONFIG_DIR}/schema.sql" >/dev/null
fi

wan_json="$(unifi_api_get "${COOKIE_JAR}" "/proxy/network/v2/api/site/${UNIFI_SITE}/wan/enriched-configuration")"
# Clients — UniFi Network API (site default)
clients_json="$(unifi_api_get "${COOKIE_JAR}" "/proxy/network/api/s/${UNIFI_SITE}/stat/sta")"
# Devices (APs / gateway)
devices_json="$(unifi_api_get "${COOKIE_JAR}" "/proxy/network/api/s/${UNIFI_SITE}/stat/device")"

export WAN_JSON="${wan_json}"
export CLIENTS_JSON="${clients_json}"
export DEVICES_JSON="${devices_json}"
export DB_PATH HA_STATE_PATH

python3 - <<'PY'
import json, os, sqlite3, time

db = sqlite3.connect(os.environ["DB_PATH"])
db.execute("PRAGMA foreign_keys=ON")
ts = int(time.time())

def load(env_key):
    raw = os.environ.get(env_key, "")
    try:
        return json.loads(raw) if raw else None
    except json.JSONDecodeError:
        return {"_parse_error": True, "raw_prefix": raw[:300]}

wan = load("WAN_JSON")
clients = load("CLIENTS_JSON")
devices = load("DEVICES_JSON")

wan_uptime = wan_peak_down = wan_peak_up = None
wan_down_cap = wan_up_cap = None
if isinstance(wan, list) and wan:
    w0 = wan[0]
elif isinstance(wan, dict) and "data" in wan and wan["data"]:
    w0 = wan["data"][0]
elif isinstance(wan, dict):
    w0 = wan
else:
    w0 = {}

if isinstance(w0, dict):
    cfg = w0.get("configuration", w0)
    stats = w0.get("statistics", {})
    peak = stats.get("peak_usage", {})
    caps = cfg.get("wan_provider_capabilities", {})
    try:
        wan_uptime = float(stats.get("uptime_percentage")) if stats.get("uptime_percentage") is not None else None
    except (TypeError, ValueError):
        wan_uptime = None
    try:
        wan_peak_down = float(peak.get("download_percentage")) if peak.get("download_percentage") is not None else None
        wan_peak_up = float(peak.get("upload_percentage")) if peak.get("upload_percentage") is not None else None
    except (TypeError, ValueError):
        pass
    try:
        wan_down_cap = int(caps.get("download_kilobits_per_second") or 0) // 1000 or None
        wan_up_cap = int(caps.get("upload_kilobits_per_second") or 0) // 1000 or None
    except (TypeError, ValueError):
        pass

sta_list = []
if isinstance(clients, dict):
    sta_list = clients.get("data") or []
elif isinstance(clients, list):
    sta_list = clients

client_count = len(sta_list)
wireless_count = sum(1 for c in sta_list if not c.get("is_wired"))

dev_list = []
if isinstance(devices, dict):
    dev_list = devices.get("data") or []
elif isinstance(devices, list):
    dev_list = devices

ap_count = sum(1 for d in dev_list if d.get("type") == "uap" or str(d.get("model", "")).startswith("U7") or d.get("type") == "uap")
# Broader AP detect
if ap_count == 0:
    ap_count = sum(1 for d in dev_list if (d.get("type") or "") in ("uap", "ubb") or "UAP" in str(d.get("model", "")).upper() or "U7" in str(d.get("model", "")).upper())

gateway_cpu = gateway_mem = None
for d in dev_list:
    # UCG / ugw / udm
    t = (d.get("type") or "").lower()
    model = str(d.get("model") or "")
    if t in ("ugw", "udm", "uxg") or "UCG" in model or d.get("is_gateway") or (d.get("network_table") and d.get("system-stats")):
        ss = d.get("system-stats") or d.get("sys_stats") or {}
        try:
            if ss.get("cpu") is not None:
                gateway_cpu = float(ss.get("cpu"))
            if ss.get("mem") is not None:
                gateway_mem = float(ss.get("mem"))
        except (TypeError, ValueError):
            pass
        if gateway_cpu is None:
            try:
                gateway_cpu = float((d.get("system-stats") or {}).get("cpu"))
            except (TypeError, ValueError, AttributeError):
                pass
        break

raw = json.dumps({"wan_ok": not (isinstance(wan, dict) and wan.get("_parse_error")), "clients": client_count})
cur = db.execute(
    """INSERT INTO samples(
        ts, wan_uptime_pct, wan_peak_down_pct, wan_peak_up_pct,
        wan_down_cap_mbps, wan_up_cap_mbps, client_count, wireless_count,
        ap_count, gateway_cpu_pct, gateway_mem_pct, raw_json
    ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)""",
    (
        ts, wan_uptime, wan_peak_down, wan_peak_up,
        wan_down_cap, wan_up_cap, client_count, wireless_count,
        ap_count, gateway_cpu, gateway_mem, raw,
    ),
)
sample_id = cur.lastrowid

weak = []
for c in sta_list:
    mac = c.get("mac")
    hostname = c.get("hostname") or c.get("name") or c.get("oui") or ""
    ip = c.get("ip") or c.get("last_ip") or ""
    essid = c.get("essid") or ""
    is_wired = 1 if c.get("is_wired") else 0
    rssi = c.get("rssi") or c.get("signal")
    try:
        rssi_i = int(rssi) if rssi is not None else None
    except (TypeError, ValueError):
        rssi_i = None
    rx = c.get("rx_bytes")
    tx = c.get("tx_bytes")
    db.execute(
        """INSERT INTO clients(sample_id, ts, mac, hostname, ip, essid, is_wired, rssi, rx_bytes, tx_bytes)
           VALUES (?,?,?,?,?,?,?,?,?,?)""",
        (sample_id, ts, mac, hostname, ip, essid, is_wired, rssi_i, rx, tx),
    )
    if rssi_i is not None and rssi_i < -75 and not is_wired:
        weak.append({"hostname": hostname, "mac": mac, "rssi": rssi_i, "ip": ip})

# Lightweight anomaly events
def add_event(kind, severity, message, payload=None):
    db.execute(
        "INSERT INTO events(ts, kind, severity, message, payload_json) VALUES (?,?,?,?,?)",
        (ts, kind, severity, message, json.dumps(payload) if payload else None),
    )

if wan_uptime is not None and wan_uptime < 99.0:
    add_event("wan_uptime_low", "warning", f"WAN 24h uptime {wan_uptime}%", {"uptime": wan_uptime})
if weak:
    add_event("weak_wifi_clients", "info", f"{len(weak)} weak Wi-Fi client(s) RSSI<-75", {"clients": weak[:20]})

db.commit()

ha_state = {
    "timestamp": ts,
    "network_score_hint": None,
    "wan_uptime_pct": wan_uptime,
    "wan_peak_down_pct": wan_peak_down,
    "wan_peak_up_pct": wan_peak_up,
    "client_count": client_count,
    "wireless_count": wireless_count,
    "ap_count": ap_count,
    "gateway_cpu_pct": gateway_cpu,
    "gateway_mem_pct": gateway_mem,
    "weak_wifi_count": len(weak),
}
with open(os.environ["HA_STATE_PATH"], "w") as f:
    json.dump(ha_state, f, indent=2)
    f.write("\n")

print(f"COLLECT_OK sample_id={sample_id} ts={ts} clients={client_count} wireless={wireless_count} aps={ap_count}")
print(f"DB={os.environ['DB_PATH']}")
print(f"HA_STATE={os.environ['HA_STATE_PATH']}")
db.close()
PY
