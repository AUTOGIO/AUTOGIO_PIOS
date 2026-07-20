# Cameras VLAN + IPS follow-up — Phase 4

Prerequisites: Phase 2 Guest/IoT stable; IDS detect-only observed ~1 week ([ids_ips_security.md](ids_ips_security.md)).

## Cameras VLAN 50 (only when hardware exists)

| VLAN ID | Name | Subnet (suggested) | Notes |
|---------|------|--------------------|-------|
| 50 | Cameras | `192.168.50.0/24` | NVR + cams; block cams → LAN |

- [ ] Cameras / NVR hardware on site
- [ ] Create VLAN 50 + optional `PIOS-CAM` SSID or wired-only
- [ ] Firewall: allow viewer/NVR UI from Personal only; **deny** cameras → Personal/IoT/Guest
- [ ] Fixed IPs for NVR
- [ ] Config export + 48h soak

Skip this entire section until cameras are purchased/installed.

## Personal / AI VLAN split (optional)

Only if traffic policy requires it after Guest/IoT:

| VLAN ID | Name | Purpose |
|---------|------|---------|
| 10 | Personal | Phones, Macs, HomePod |
| 40 | AI Servers | LM Studio / GPU hosts |

- [ ] Plan Mac Ethernet + UniFi management recovery before moving anything
- [ ] Allow Personal → AI; deny IoT/Guest → AI
- [ ] Move one AI host first; validate; then Personal if needed

## IPS enable

Follow Phase 4 section in [ids_ips_security.md](ids_ips_security.md).

## Done when

- [ ] Cameras isolated **or** explicitly N/A
- [ ] IPS decision recorded (on with watch, or remain detect-only)
- [ ] Personal/AI split done **or** deferred with reason
