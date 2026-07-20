# Network Intelligence — PIOS UniFi Module (v1 scaffold)

Session-safe telemetry collector for PIOS-HOME-01. Extends existing local-admin API helpers; does **not** replace UniFi UI.

## Design constraints

- Poll every **5 minutes** (not 1) — LaunchAgent example below
- **Reuse cookie jar** via `scripts/unifi_common.zsh` → `unifi_ensure_session` (avoid login rate limits)
- Store history in **SQLite** at `data/intelligence/unifi_intel.sqlite` (gitignored)
- Morning report + optional HA MQTT/REST sensors
- Anomaly thresholds and ActivityWatch correlation are **later** (roadmap Phases 3–4)

## Layout

| Path | Purpose |
|------|---------|
| [schema.sql](../config/schema.sql) | SQLite schema |
| [collect.zsh](../scripts/collect.zsh) | One collection cycle |
| [report_morning.zsh](../scripts/report_morning.zsh) | Daily digest from SQLite |
| [ha_sensors.example.yaml](../config/ha_sensors.example.yaml) | Home Assistant sensor examples |
| [com.pios.unifi-intel-collect.plist.example](../config/com.pios.unifi-intel-collect.plist.example) | 5‑min LaunchAgent |
| `data/intelligence/` | SQLite DB + HA state snapshot (gitignored) |

## Prerequisites

1. Phase 0 gate preferably closed (dry-run collect OK if careful with logins)
2. [`config/.unifi.local.env`](../config/.unifi.local.env) with local admin credentials
3. `sqlite3` + `python3` on PATH (macOS defaults)

## Usage

```bash
# One-shot collect (session-safe)
~/Documents/GitHub/AUTOGIO_PIOS/scripts/collect.zsh

# Morning markdown report
~/Documents/GitHub/AUTOGIO_PIOS/scripts/report_morning.zsh

# Optional: install LaunchAgent after Phase 0 (copy example, load)
# cp ~/Documents/GitHub/AUTOGIO_PIOS/config/com.pios.unifi-intel-collect.plist.example \
#    ~/Library/LaunchAgents/com.pios.unifi-intel-collect.plist
# launchctl load ~/Library/LaunchAgents/com.pios.unifi-intel-collect.plist
```

## Metrics collected (v1)

- WAN: uptime %, peak usage % (from enriched-configuration)
- Health snapshot: client count, AP count, gateway CPU/mem when available
- Per-client sample: hostname, IP, RSSI, ESSID, wired/wireless (best-effort)

## Roadmap hooks

- Phase 3: anomaly alerts → Shortcuts / HA notify
- Phase 3: Lovelace dashboard after ≥7 days history
- Phase 4: ActivityWatch correlation ([activity_correlation.md](checklists/activity_correlation.md))

See [post-baseline-roadmap.md](post-baseline-roadmap.md).
