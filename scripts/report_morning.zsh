#!/bin/zsh
set -euo pipefail

# Morning Network Intelligence digest from SQLite.
# Usage: report_morning.zsh [--stdout-only]

BASE_DIR="${HOME}/Documents/GitHub/AUTOGIO_PIOS"
DATA_DIR="${BASE_DIR}/data/intelligence"
DB_PATH="${DATA_DIR}/unifi_intel.sqlite"
REPORT_DIR="${BASE_DIR}/data/reports"
mkdir -p "${REPORT_DIR}"

stdout_only=0
if [[ "${1:-}" == "--stdout-only" ]]; then
  stdout_only=1
fi

if [[ ! -f "${DB_PATH}" ]]; then
  print -r -- "SKIP: No intel DB yet. Run scripts/collect.zsh first."
  exit 0
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
day="$(date +%Y-%m-%d)"
report_path="${REPORT_DIR}/intel_morning_${timestamp}.md"

export DB_PATH day report_path

python3 - <<'PY'
import json, os, sqlite3, time
from datetime import datetime, timezone

db = sqlite3.connect(os.environ["DB_PATH"])
db.row_factory = sqlite3.Row
now = int(time.time())
day_ago = now - 86400
week_ago = now - 7 * 86400

latest = db.execute("SELECT * FROM samples ORDER BY ts DESC LIMIT 1").fetchone()
day_rows = db.execute("SELECT * FROM samples WHERE ts >= ? ORDER BY ts", (day_ago,)).fetchall()
events = db.execute(
    "SELECT * FROM events WHERE ts >= ? ORDER BY ts DESC LIMIT 50", (day_ago,)
).fetchall()

# Weak clients from latest sample
weak = []
if latest:
    weak = db.execute(
        """SELECT hostname, mac, ip, rssi, essid FROM clients
           WHERE sample_id = ? AND is_wired = 0 AND rssi IS NOT NULL AND rssi < -75
           ORDER BY rssi ASC LIMIT 25""",
        (latest["id"],),
    ).fetchall()

def avg(key):
    vals = [r[key] for r in day_rows if r[key] is not None]
    return round(sum(vals) / len(vals), 2) if vals else None

uptime_avg = avg("wan_uptime_pct")
clients_avg = avg("client_count")
cpu_avg = avg("gateway_cpu_pct")

# Advisory score from latest uptime + weak clients
score = 100
notes = []
if latest and latest["wan_uptime_pct"] is not None:
    u = float(latest["wan_uptime_pct"])
    if u < 99.9:
        pen = min(25, int((99.9 - u) * 10))
        score -= pen
        notes.append(f"uptime {u}% → -{pen}")
if weak:
    pen = min(15, len(weak) * 2)
    score -= pen
    notes.append(f"{len(weak)} weak clients → -{pen}")
score = max(0, min(100, score))

lines = []
lines.append(f"# PIOS Network Intelligence — Morning Report")
lines.append("")
lines.append(f"**Date:** {os.environ['day']}  ")
lines.append(f"**Generated:** {datetime.now().astimezone().isoformat(timespec='seconds')}  ")
lines.append("")
lines.append(f"## Network Score: {score}%")
lines.append("")
if notes:
    lines.append("Deductions: " + "; ".join(notes))
    lines.append("")
lines.append("## Last 24h summary")
lines.append("")
if latest:
    lines.append(f"| Metric | Latest | 24h avg |")
    lines.append(f"|--------|--------|---------|")
    lines.append(f"| WAN uptime % | {latest['wan_uptime_pct']} | {uptime_avg} |")
    lines.append(f"| Peak down % | {latest['wan_peak_down_pct']} | {avg('wan_peak_down_pct')} |")
    lines.append(f"| Peak up % | {latest['wan_peak_up_pct']} | {avg('wan_peak_up_pct')} |")
    lines.append(f"| Client count | {latest['client_count']} | {clients_avg} |")
    lines.append(f"| Wireless count | {latest['wireless_count']} | {avg('wireless_count')} |")
    lines.append(f"| AP count | {latest['ap_count']} | — |")
    lines.append(f"| Gateway CPU % | {latest['gateway_cpu_pct']} | {cpu_avg} |")
    lines.append(f"| Gateway mem % | {latest['gateway_mem_pct']} | {avg('gateway_mem_pct')} |")
    lines.append(f"| Samples (24h) | {len(day_rows)} | — |")
else:
    lines.append("_No samples yet._")
lines.append("")
lines.append("## Weak Wi‑Fi clients (RSSI < -75)")
lines.append("")
if weak:
    lines.append("| Hostname | IP | RSSI | ESSID | MAC |")
    lines.append("|----------|----|------|-------|-----|")
    for w in weak:
        lines.append(f"| {w['hostname'] or '—'} | {w['ip'] or '—'} | {w['rssi']} | {w['essid'] or '—'} | {w['mac'] or '—'} |")
else:
    lines.append("_None in latest sample (or no wireless RSSI data)._")
lines.append("")
lines.append("## Events (24h)")
lines.append("")
if events:
    for e in events:
        ts = datetime.fromtimestamp(e["ts"]).astimezone().strftime("%H:%M")
        lines.append(f"- `{ts}` **{e['kind']}** ({e['severity'] or 'n/a'}): {e['message']}")
else:
    lines.append("_No events._")
lines.append("")
lines.append("## Operator checklist")
lines.append("")
lines.append("- [ ] UniFi Topology — Starlink disconnects / high latency")
lines.append("- [ ] Firmware updates (Gateway + U7 Lite)")
lines.append("- [ ] Security / IDS events (post Phase 2)")
lines.append("- [ ] Bandwidth yesterday (UniFi dashboard)")
lines.append("")
lines.append("---")
lines.append(f"_DB: `{os.environ['DB_PATH']}`_")

text = "\n".join(lines) + "\n"
path = os.environ["report_path"]
with open(path, "w") as f:
    f.write(text)
print(text)
print(f"Report path: {path}")
PY

if (( stdout_only == 0 )); then
  : # report already printed and written
fi
