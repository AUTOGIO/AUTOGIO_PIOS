# DHCP Fixed IP Reservations — Phase 1

**Do not apply until Phase 0 gate closes** ([POST_BASELINE_ROADMAP.md](../post-baseline-roadmap.md)).

Stable addressing is the foundation for Home Assistant presence, firewall allowlists, and later VLAN moves.

## Prep (allowed during gate)

- [ ] Copy [dhcp_reservations.example.md](../inventory/dhcp_reservations.example.md) → `inventory/dhcp_reservations.md` (gitignored)
- [ ] Fill MAC + intended IP for each device below from UniFi **Clients** (read-only)

## Target reservations

| Role | Suggested IP | Notes |
|------|--------------|-------|
| UCG gateway | `192.168.0.1` | Fixed by UniFi |
| U7 Lite AP | `192.168.0.160` | Confirm still reserved / static |
| Mac control (Ethernet) | `192.168.0.189` | Do not move without recovery plan |
| NAS | `192.168.0.10` | Pick free address in inventory |
| Home Assistant host | `192.168.0.20` | Required before IoT firewall rules |
| Printer | `192.168.0.30` | |
| HomePod (primary) | `192.168.0.40` | Add more as `.41`, `.42`… |
| iPhone (primary) | `192.168.0.50` | Presence trigger |
| iPad (primary) | `192.168.0.51` | |
| Mac Wi‑Fi (if distinct client) | `192.168.0.52` | Only if separate from Ethernet client |

Adjust addresses if already taken; document final map in private inventory.

## UniFi UI steps

- [ ] **Clients** → select device → **Settings** → **Fixed IP Address** (or Networks → DHCP → reservations)
- [ ] Apply one device at a time; renew DHCP on client if needed
- [ ] Verify client retains IP after disconnect/reconnect
- [ ] **Settings → System → Backups** — confirm auto backups still enabled
- [ ] **Export configuration** dated after batch complete

## Validation

```bash
~/Documents/GitHub/AUTOGIO_PIOS/scripts/unifi_post_change_validate.zsh
~/Documents/GitHub/AUTOGIO_PIOS/scripts/unifi_daily_health.zsh
```

- [ ] Mac Ethernet still `192.168.0.189`, gateway `192.168.0.1`
- [ ] HA / NAS / printer reachable at reserved IPs
- [ ] No duplicate-IP warnings in UniFi

## Done when

- [ ] All critical automation hosts have fixed IPs
- [ ] Private inventory file updated
- [ ] Config exported
