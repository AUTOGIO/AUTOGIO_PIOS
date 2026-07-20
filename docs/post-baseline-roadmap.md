# Post-Baseline UniFi Roadmap — PIOS-HOME-01

Phased hardening and Network Intelligence plan derived from the UniFi suggestions analysis.
**Do not start Phases 1–4 until Phase 0 is green.**

| Phase | Name | Gate |
|-------|------|------|
| **0** | Close baseline | Required before any fabric / security / VLAN work |
| **1** | Automation foundation | DHCP reservations, enhanced daily health, WPA3 Transition, light Wi‑Fi review |
| **2** | Security lite + Guest/IoT | IDS detect-only → Guest VLAN 30 → IoT VLAN 20 + isolation + HA allow rules |
| **3** | Network Intelligence v1 | Session-safe 5‑min collector → SQLite → morning report → HA sensors |
| **4** | Expand | Cameras VLAN (if needed), IPS if IDS clean, Personal/AI VLAN split, ActivityWatch correlation |

## Scorecard (summary)

| Item | Verdict |
|------|---------|
| Fixed IP reservations | **Phase 1 — first** |
| Enhanced daily health / morning report | **Phase 1** |
| WPA3 Transition Mode | **Phase 1** (after Wi‑Fi soak) |
| Performance tuning | **Phase 1** — evidence-based only; no Min RSSI on single AP |
| IDS detect-only | **Phase 2** |
| Guest VLAN 30 | **Phase 2 — first VLAN** |
| IoT VLAN 20 + isolation | **Phase 2 — second** |
| Cameras VLAN 50 | **Phase 4 — only when cameras exist** |
| Personal 10 / AI 40 split | **Phase 4 — defer until Guest/IoT proven** |
| IPS (block) | **Phase 4 — after IDS quiet ~1 week** |
| GeoIP blocking | **Skip / last resort** |
| Network Intelligence module | **Phase 3 — incremental** |
| ActivityWatch × UniFi × HA | **Phase 4 — last** |

## What not to do

- Do not implement the full suggestion list before the WAN gate closes
- Do not enable client isolation on the main SSID (`PIOS-HOME`)
- Do not enable GeoIP blocking as a default security win
- Do not poll UniFi with fresh logins every minute (reuse sessions; prefer 5‑min interval)
- Do not create five VLANs on day one on a single-AP Starlink home
- Do not move Mac Ethernet control path (`192.168.0.189`) or UniFi management off a trusted network without a recovery plan

---

## Phase 0 — Gate close

**Due:** ~Jul 14, 2026 20:00

Checklist: [deferred_until_baseline.md](checklists/deferred_until_baseline.md) · [wan_stability_gate.md](checklists/wan_stability_gate.md)

- [ ] `FINAL_VERDICT: PASS_WAN_WATCH` in WAN watch log
- [ ] UniFi Topology → Starlink: zero WAN disconnects over 48h
- [ ] iPhone on cellular → [unifi.ui.com](https://unifi.ui.com) reachable
- [ ] 24h Wi‑Fi soak on `PIOS-HOME` started or complete
- [ ] Mark deferred checklist complete; update README WAN Stability date

**Until then:** no VLANs, IPS, GeoIP, Bypass toggle, Cloudflare Tunnel, or DNS A-record changes.
Offline-only prep allowed: MAC inventory for DHCP reservations ([inventory/dhcp_reservations.example.md](inventory/dhcp_reservations.example.md)).

---

## Phase 1 — Automation foundation

Checklists:

- [dhcp_reservations.md](checklists/dhcp_reservations.md)
- [wpa3_and_wifi_tuning.md](checklists/wpa3_and_wifi_tuning.md)

Order:

1. DHCP / fixed IP reservations (Mac, NAS, HA host, printer, HomePods, primary phones/tablets)
2. Confirm enhanced daily health + morning report scripts produce structured output
3. WPA3 Transition Mode on `PIOS-HOME` (not WPA3-only until all clients verified)
4. Light Wi‑Fi review one change at a time (multicast enhancement, channel/width) — **no Min RSSI**

Config export after each meaningful change.

---

## Phase 2 — Security lite + Guest/IoT

Checklists:

- [ids_ips_security.md](checklists/ids_ips_security.md)
- [vlan_guest_iot.md](checklists/vlan_guest_iot.md)

Order:

1. IDS / Threat Detection in **detect-only** mode
2. Guest VLAN **30** + Guest SSID (internet only)
3. IoT VLAN **20** + IoT SSID + client isolation on IoT only
4. Firewall: allow Home Assistant (trusted LAN) → IoT; mDNS carefully
5. Device presence into HA (after fixed IPs)

Keep Personal devices and AI hosts on Default `192.168.0.0/24` until IoT rules are proven.

---

## Phase 3 — Network Intelligence v1

Module: [network-intelligence.md](network-intelligence.md)

1. Session-safe collector every **5 minutes** → SQLite
2. Morning markdown report from SQLite + daily health
3. HA sensors (MQTT/REST) from the same collector
4. Anomaly thresholds → Shortcuts / HA notify
5. Custom dashboard only after ≥7 days of history

---

## Phase 4 — Expand

Checklists:

- [cameras_vlan_and_ips.md](checklists/cameras_vlan_and_ips.md)
- [activity_correlation.md](checklists/activity_correlation.md)

1. Cameras VLAN **50** when hardware exists
2. IPS enable only if IDS quiet ~1 week
3. Personal VLAN **10** / AI VLAN **40** only if traffic policy requires it
4. ActivityWatch ↔ UniFi ↔ Home Assistant correlation last

---

## Long-term VLAN map (target)

| VLAN | Name | When |
|------|------|------|
| Default / later 10 | Personal | Phones, Macs, HomePod — keep on Default until Phase 4 |
| 20 | IoT | Phase 2 |
| 30 | Guest | Phase 2 |
| 40 | AI Servers | Phase 4 if needed |
| 50 | Cameras | Phase 4 when cameras land |

## Related paths

| Item | Path |
|------|------|
| Baseline guide | [unifi-baseline.md](unifi-baseline.md) |
| Deferred items | [checklists/deferred_until_baseline.md](checklists/deferred_until_baseline.md) |
| Intelligence module | [network-intelligence.md](network-intelligence.md) |
| Daily health | [../scripts/unifi_daily_health.zsh](../scripts/unifi_daily_health.zsh) |
| Morning intel report | [../scripts/report_morning.zsh](../scripts/report_morning.zsh) |
