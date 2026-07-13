# Remote Access Validation (Phase 4)

## iPhone on Cellular

1. On iPhone: **Settings → Wi-Fi → Off**
2. Confirm cellular data is on
3. Open Safari → [https://unifi.ui.com](https://unifi.ui.com)
4. Sign in with Ubiquiti account
5. Confirm site **PIOS-HOME-01** / gateway **PIOS-UCG-01** is reachable
6. Confirm dashboard loads (devices, WAN online)

- [ ] Passed — date: ___________

## Starlink App (on UniFi LAN or PIOS-HOME Wi-Fi)

1. Open Starlink app while connected to UniFi network (not neighbor Wi-Fi)
2. Confirm dish stats visible: uptime, obstruction, latency
3. Note router mode / bypass state (document only — do not toggle)

- [ ] Passed — date: ___________
- Router/bypass mode noted: ___________

## Re-validate After Wi-Fi (Phase 3)

After connecting to `PIOS-HOME`:

```bash
~/AUTOGIO_PIOS/networking/unifi_baseline/scripts/unifi_post_change_validate.zsh
```

- [ ] `PASS_UNIFI_BASELINE_READY` on Wi-Fi

See [starlink_bypass_decision.md](starlink_bypass_decision.md) for full bypass gate.
