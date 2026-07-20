# Executive Report — PIOS UniFi Baseline

**Date:** 2026-07-13 01:15 (−03)  
**Site:** PIOS-HOME-01  
**Gateway:** PIOS-UCG-01 (UCG Ultra)  
**Owner account:** automacao.giovannini@gmail.com (Fabric Owner)

---

## 1. Verdict

| Area | Status |
|------|--------|
| Core LAN / WAN naming & ISP caps | **Complete** |
| Phase 2 — Wi‑Fi `PIOS-HOME` | **Complete** (broadcasting; iPhone confirmed) |
| Phase 2 — Local API admin | **Complete** (`PASS_WAN_STATUS_READ`) |
| PIOS Awake (menu bar) | **Complete** (installed & verified) |
| 48h WAN stability gate | **In progress** (~5h15m of 48h as of report time) |
| Baseline fully closed | **Not yet** — wait for gate + soak + cellular remote check |

**Bottom line:** Home UniFi baseline is operational for day-to-day use. Do not start Cloudflare Tunnel, Bypass, VLANs, or DNS changes until the 48h gate passes (~Jul 14 20:00).

---

## 2. What was delivered

### Network fabric
- Site renamed **PIOS-HOME-01**; gateway **PIOS-UCG-01**
- Starlink on WAN5; ISP expected speeds **260 / 74 Mbps**
- LAN `192.168.0.0/24`, gateway `192.168.0.1`
- Mac control path: Ethernet dock → UCG LAN4 (`192.168.0.189`)

### Wi‑Fi
- AP **U7 Lite** online at `192.168.0.160` (LAN port 1)
- SSID **PIOS-HOME** live (WPA2, All APs)
- Password stored in gitignored `.pios_wifi.env`
- Confirmed visible on iPhone (Minhas Redes)

### Local admin (API)
- Account **PIOS Local** / username `pios-local-admin`
- Source: **Local Site**; Role: **Super Admin**
- Credentials: `.unifi.local.env` (gitignored)
- Verified: `Login OK` + `PASS_WAN_STATUS_READ`  
  Sample: Starlink, uptime ~99.5%, caps 260/74, peaks ~11% / ~3%

### Tooling
- **PIOS Awake** — `~/Applications/PIOS Awake.app`  
  Menu bar cup/moon → `caffeinate -dims` On/Off  
  Source: `~/Documents/GitHub/AUTOGIO_PIOS/src/pios_awake/`
- Daily health Reminders (10:00 / 22:00, list **PIOS Network**)
- Scripts under `scripts/` (health, WAN watch, WAN status, page opener)

### Script fixes (Jul 13)
- `unifi_common.zsh`: avoid zsh `path` shadowing `PATH`; use absolute curl
- `unifi_wan_status.zsh`: pass JSON via env (pipe + heredoc was broken)

---

## 3. Live status at report time

| Process | State |
|---------|--------|
| WAN watch (`wan_watch_48h.zsh`) | Running — PID **39191**, ~**5h15m** elapsed (started Jul 12 20:00) |
| PIOS Awake | Running |
| `caffeinate -dims` (Awake On) | Running |
| Gate deadline | ~**Jul 14 20:00** |

---

## 4. Operator actions (now → Jul 14)

1. Keep Mac on **power + Ethernet**; leave **PIOS Awake → On**
2. **Do not** stop the WAN watch PID unless restarting deliberately
3. **2×/day** (Reminders or):
   ```bash
   ~/Documents/GitHub/AUTOGIO_PIOS/scripts/unifi_daily_health.zsh
   ```
4. UniFi → **Topology → Starlink**: no new WAN-down / high-latency events
5. Prefer clients on **`PIOS-HOME`** to begin 24h soak
6. **Do not:** speed tests, Bypass toggle, VLANs, IPS, Cloudflare, `giovannini.uk` A records

---

## 5. After gate passes (~Jul 14 evening)

1. Confirm watcher log: `FINAL_VERDICT: PASS_WAN_WATCH`
2. Confirm UniFi UI: 48h with zero WAN disconnects
3. iPhone on **cellular** → [unifi.ui.com](https://unifi.ui.com) reachable
4. Mark [deferred_until_baseline.md](../checklists/deferred_until_baseline.md) complete
5. Only then open Phase 4 (Starlink Bypass decision) / Cloudflare Tunnel (services only)

---

## 6. Key paths

| Item | Path |
|------|------|
| Baseline README | `~/Documents/GitHub/AUTOGIO_PIOS/docs/unifi-baseline.md` |
| This report | `~/Documents/GitHub/AUTOGIO_PIOS/data/reports/executive_report_20260713.md` |
| Post-baseline roadmap | `~/Documents/GitHub/AUTOGIO_PIOS/docs/post-baseline-roadmap.md` |
| Network Intelligence | `~/Documents/GitHub/AUTOGIO_PIOS/docs/` |
| WAN watch log | `~/Documents/GitHub/AUTOGIO_PIOS/data/reports/wan_watch_stdout.log` |
| WAN API sample | `~/Documents/GitHub/AUTOGIO_PIOS/data/reports/wan_status_20260713-005945.txt` |
| Local admin env | `~/Documents/GitHub/AUTOGIO_PIOS/config/.unifi.local.env` |
| Wi‑Fi env | `~/Documents/GitHub/AUTOGIO_PIOS/config/.pios_wifi.env` |
| PIOS Awake | `~/Applications/PIOS Awake.app` |

---

## 7. Risk / notes

- Earlier failed login polling hit UniFi **login attempt limit** briefly; resolved after cool-down. Avoid hammering `/api/auth/login`.
- ChatGPT Atlas cannot be automated by Playwright; UI work used Atlas + headed Chromium as needed.
- WAN watch and PIOS Awake use **separate** `caffeinate` processes — both may run during the gate.

---

*Report generated for PIOS / AUTOGIO_PIOS UniFi baseline workstream.*
