# UniFi AP Adoption and Wi-Fi

Target SSID: `PIOS-HOME` on network **Default** (`192.168.0.0/24`)

## Physical Wiring

- [x] PoE injector **LAN/data port** → UCG **LAN port 1, 2, or 3** (Mac stays on port 4 if wired)
- [x] PoE injector **PoE port** → UniFi AP (white cable to AP)
- [x] AP LED: solid **blue** = adopted and healthy
- [x] Starlink remains on UCG **WAN port 5** only

```
Starlink → [WAN5] UCG [LAN1-3] → PoE injector → AP
                      [LAN4] → Mac (Ethernet dock, fallback)
```

## UniFi UI — Adoption

- [x] **Devices** — AP appears online
- [x] If **Pending Adoption**, click Adopt
- [x] Firmware up to date after adoption
- [x] Note AP model/name in [README.md](../README.md) — U7 Lite `192.168.0.160`

## UniFi UI — Wi-Fi SSID

- [x] **Settings → WiFi → Create New**
- [x] SSID: `PIOS-HOME`
- [x] Network: **Default** (`192.168.0.0/24`)
- [x] Security: WPA2/WPA3 (WPA3 if all clients support it)
- [x] **Do not** enable Wi-Fi Speed Limits yet
- [ ] Advanced: start **Conservative**; 5 GHz **40 MHz** until coverage validated

## Mac Validation

Run with Ethernet still connected as fallback:

```bash
~/Documents/GitHub/AUTOGIO_PIOS/scripts/unifi_post_change_validate.zsh
```

- [ ] Connect Mac Wi-Fi to `PIOS-HOME`
- [ ] IP: `192.168.0.x`, gateway: `192.168.0.1`, DNS: `192.168.0.1`
- [ ] Mac appears in **Clients** as **wireless**
- [ ] Validation script: `PASS_UNIFI_BASELINE_READY`
- [ ] Toggle Wi-Fi off — Ethernet path still works

## 24h Soak

- [ ] Client stable on Wi-Fi 24h without drops
- [ ] AP stays solid blue, no reboot loop

## Stop Condition

If adoption fails or AP reboots repeatedly:

1. Revert to wired-only (disconnect PoE LAN from UCG)
2. Check PoE injector power and cable negotiation
3. Do not change WAN/bypass settings while troubleshooting

## Status

| Item | Date | Notes |
|------|------|-------|
| Physical wiring | 2026-07-12 | U7 Lite online on LAN (Devices UI) |
| AP adopted | 2026-07-12 | U7 Lite `192.168.0.160`, GbE port 1 |
| SSID PIOS-HOME live | 2026-07-13 | Confirmed broadcasting (iPhone sees `PIOS-HOME` under Minhas Redes); password in `.pios_wifi.env` |
| Mac Wi-Fi validated | 2026-07-13 | SSID visible / joinable — Ethernet validate still `PASS_UNIFI_BASELINE_READY` |
| 24h soak | | Start after preferred clients stay on `PIOS-HOME` |
