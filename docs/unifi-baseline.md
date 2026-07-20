# UniFi Baseline — PIOS-HOME-01

## Current Observed State (Jul 13, 2026)

| Item | Value |
|------|-------|
| Site name | `PIOS-HOME-01` |
| Gateway name | `PIOS-UCG-01` (UCG Ultra) |
| UniFi OS | `5.1.19` (up to date) |
| Network app | `10.4.57` (up to date) |
| Auto backups | Enabled |
| WAN provider | Starlink (Primary, WAN port 5) |
| WAN | DHCP / CGNAT; ISP caps **260 / 74 Mbps** |
| LAN | `192.168.0.0/24`, gateway `192.168.0.1` |
| Control device | Mac `192.168.0.189` via Ethernet dock (port 4) |
| AP | **U7 Lite** online (`192.168.0.160`, LAN port 1) |
| Wi-Fi | SSID **`PIOS-HOME`** live (Jul 13 — iPhone confirmed) |
| Local admin / API | **Done** — `pios-local-admin` / **PIOS Local** (Local Site, Super Admin); `PASS_WAN_STATUS_READ` |
| Menu bar awake | **[PIOS Awake](pios-awake.md)** installed (`~/Applications/PIOS Awake.app`) |
| Remote access (iPhone cellular) | **Pending** — after 48h gate |

## WAN Stability Gate

- **Hourly watch started:** Jul 12, 2026 20:00 (PID in `data/reports/wan_watch.pid`)
- **Due:** ~Jul 14, 2026 20:00
- **Confirmed stable 48h:** _pending_
- **Checklist:** [wan_stability_gate.md](checklists/wan_stability_gate.md)

Keep Mac on **power + Ethernet**. Use watch `caffeinate` and/or **PIOS Awake** (menu bar cup = On). Run health **2×/day** (10:00 / 22:00).

```bash
~/Documents/GitHub/AUTOGIO_PIOS/scripts/unifi_daily_health.zsh
```

## Target State

- Site / gateway / LAN / Starlink WAN — **done**
- Ethernet control path — **done**
- `PIOS-HOME` Wi-Fi — **live**; 24h soak pending
- Local admin API — **done**
- 48h stable WAN — **in progress**
- Starlink Bypass — **do not toggle** until checklist complete

## Naming Standard

- Site: `PIOS-HOME-01`
- Gateway: `PIOS-UCG-01`
- Wi-Fi SSID: `PIOS-HOME`
- Local API user: `pios-local-admin` (display: PIOS Local)

## Scripts

| Script | Purpose |
|--------|---------|
| [unifi_post_change_validate.zsh](../scripts/unifi_post_change_validate.zsh) | Network/DNS/gateway validation from Mac |
| [unifi_daily_health.zsh](../scripts/unifi_daily_health.zsh) | Daily validation + Network Score JSON (2×/day) |
| [wan_watch_48h.zsh](../scripts/wan_watch_48h.zsh) / [wan_watch_start.zsh](../scripts/wan_watch_start.zsh) / [wan_watch_stop.zsh](../scripts/wan_watch_stop.zsh) | 48h hourly Mac-path watch |
| [unifi_wan_status.zsh](../scripts/unifi_wan_status.zsh) | Read-only WAN stats (session-safe local admin) |
| [collect.zsh](../scripts/collect.zsh) | Network Intelligence sample → SQLite (5‑min cadence) |
| [report_morning.zsh](../scripts/report_morning.zsh) | Morning digest from intel DB |
| [open_unifi_baseline_pages.zsh](../scripts/open_unifi_baseline_pages.zsh) | Open Topology / WiFi / Admins in Atlas |
| [unifi_pre_bypass_check.zsh](../scripts/unifi_pre_bypass_check.zsh) | Pre-bypass diagnostic (Phase 4) |
| [unifi_set_wan_speeds.zsh](../scripts/unifi_set_wan_speeds.zsh) / [_ui](../scripts/unifi_set_wan_speeds_ui.zsh) | ISP cap updates |
| [PIOS Awake](pios-awake.md) | Menu bar awake toggle (`caffeinate -dims`) |
| [install_pios_health_reminders.zsh](../scripts/install_pios_health_reminders.zsh) | 10am/10pm Reminders |

Credentials: [`config/.unifi.local.env`](../config/.unifi.local.env) (gitignored). Wi-Fi password: [`config/.pios_wifi.env`](../config/.pios_wifi.env) (gitignored).

## Decisions

- Local admin for API (not SSO — MFA blocks it)
- No Integration API keys / VLANs / IPS / SD-WAN until baseline complete
- No Cloudflare Tunnel for UniFi admin; services-only later
- No Starlink Bypass until [starlink_bypass_decision.md](checklists/starlink_bypass_decision.md) passes
- Session-safe API access via `unifi_ensure_session` (cookie reuse; avoid login rate limits)

Deferred: [deferred_until_baseline.md](checklists/deferred_until_baseline.md)

## Post-baseline roadmap

After the 48h WAN gate: [post-baseline-roadmap.md](post-baseline-roadmap.md)

| Phase | Focus |
|-------|--------|
| 0 | Close gate — no fabric changes until PASS |
| 1 | DHCP reservations, enhanced daily health, WPA3 Transition |
| 2 | IDS detect-only, Guest VLAN 30, IoT VLAN 20 |
| 3 | [Network Intelligence](network-intelligence.md) (SQLite collector, morning report, HA sensors) |
| 4 | Cameras VLAN / IPS / ActivityWatch correlation |

## Checklists

- [unifi_manual_changes.md](checklists/unifi_manual_changes.md)
- [wan_stability_gate.md](checklists/wan_stability_gate.md)
- [wifi_ap_adoption.md](checklists/wifi_ap_adoption.md)
- [starlink_bypass_decision.md](checklists/starlink_bypass_decision.md)
- [remote_access_validation.md](checklists/remote_access_validation.md)
- [deferred_until_baseline.md](checklists/deferred_until_baseline.md)
- [dhcp_reservations.md](checklists/dhcp_reservations.md) (Phase 1)
- [wpa3_and_wifi_tuning.md](checklists/wpa3_and_wifi_tuning.md) (Phase 1)
- [ids_ips_security.md](checklists/ids_ips_security.md) (Phase 2 / 4)
- [vlan_guest_iot.md](checklists/vlan_guest_iot.md) (Phase 2)
- [cameras_vlan_and_ips.md](checklists/cameras_vlan_and_ips.md) (Phase 4)
- [activity_correlation.md](checklists/activity_correlation.md) (Phase 4)

## Executive report

Latest: [executive_report_20260713.md](../data/reports/executive_report_20260713.md)
