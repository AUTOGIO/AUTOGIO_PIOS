# WPA3 Transition + Wi‑Fi Tuning — Phase 1

**Do not apply until Phase 0 gate closes** and preferably after 24h Wi‑Fi soak on `PIOS-HOME`.

## WPA3 Transition Mode

- [ ] UniFi → **Settings → WiFi → PIOS-HOME**
- [ ] Security: **WPA2/WPA3** (Transition) — **not** WPA3-only yet
- [ ] Save; wait for AP provision
- [ ] Verify reconnect: iPhone, iPad, Mac, HomePod, any IoT still on main SSID
- [ ] If any client fails: revert to WPA2, note device, revisit later

## Performance review (one change at a time)

Baseline AP: **U7 Lite** single-AP home. Prefer evidence from daily health / intel reports (weak RSSI list) before tuning.

| Knob | Guidance | Done |
|------|----------|------|
| Transmit power | Medium/Auto first; lower only if neighbor/self-interference | [ ] |
| Channel width (5 GHz) | 80 MHz typical; avoid 160 unless DFS/noise checked | [ ] |
| Multicast Enhancement | Useful for HomePod / AirPlay | [ ] |
| DTIM | Leave default unless battery IoT issues | [ ] |
| Minimum RSSI | **Do not enable** on single AP | N/A |
| Band Steering | Optional after soak; enable alone, observe 24h | [ ] |
| Airtime Fairness | Optional; enable alone after Band Steering proven | [ ] |
| Client Load Balancing | Low value with one AP — skip | N/A |

After each change:

```bash
~/Documents/GitHub/AUTOGIO_PIOS/scripts/unifi_daily_health.zsh
```

- [ ] No new weak-client surge or disconnects for 24h before next knob
- [ ] Config export after final accepted settings

## Done when

- [ ] WPA3 Transition confirmed on all primary Apple clients
- [ ] At most the safe knobs above adjusted with notes in inventory or report
- [ ] Min RSSI still disabled
