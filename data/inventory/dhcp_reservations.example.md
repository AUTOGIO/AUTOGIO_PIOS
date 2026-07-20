# DHCP reservation inventory (example)

Copy to `dhcp_reservations.md` in this folder (gitignored) and fill real MACs.
Do **not** commit live MAC inventories if you treat them as sensitive.

| Hostname / role | MAC | Fixed IP | Network / VLAN | Notes |
|-----------------|-----|----------|----------------|-------|
| PIOS-UCG-01 | — | 192.168.0.1 | Default | Gateway |
| U7 Lite | | 192.168.0.160 | Default | AP |
| Eduardos-Air-16 (Ethernet) | | 192.168.0.189 | Default | Control path — do not move casually |
| NAS | | 192.168.0.10 | Default | |
| Home Assistant | | 192.168.0.20 | Default | HA → IoT allowlist source |
| Printer | | 192.168.0.30 | Default or IoT | |
| HomePod | | 192.168.0.40 | Default | |
| iPhone | | 192.168.0.50 | Default | Presence |
| iPad | | 192.168.0.51 | Default | |

## Offline prep during Phase 0

1. UniFi → Clients — copy MAC/hostname only (no fabric changes)
2. Paste into private `dhcp_reservations.md`
3. Apply Fixed IP in UI only after `PASS_WAN_WATCH`
