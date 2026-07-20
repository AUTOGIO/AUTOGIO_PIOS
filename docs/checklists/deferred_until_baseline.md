# Deferred Until Baseline Complete

Do **not** start these until all items in [starlink_bypass_decision.md](starlink_bypass_decision.md) pass and [wan_stability_gate.md](wan_stability_gate.md) shows 48h clean.

**Gate hold (Phase 0):** Through ~**Jul 14 20:00**, no VLANs, IPS/IDS enablement, GeoIP, Bypass, Cloudflare, or DNS A-record changes. Offline MAC inventory for future DHCP reservations is allowed. Full post-gate sequence: [POST_BASELINE_ROADMAP.md](../post-baseline-roadmap.md).

| Item | Why deferred | Revisit when |
|------|--------------|--------------|
| **Cloudflare Tunnel** | Expose app services only — never UniFi admin | Baseline complete |
| **`giovannini.uk` DNS** | No A record yet; `.us` already resolves | Baseline complete |
| **Smart Queues / QoS** | Not needed at ~260 Mbps; disables HW offload | Latency under sustained load |
| **VLANs** | Adds complexity before stable LAN/WiFi | Baseline complete → Roadmap Phase 2 (Guest/IoT first) |
| **Intrusion Prevention** | Can affect throughput/stability | Baseline complete → IDS detect-only (Phase 2), IPS later (Phase 4) |
| **GeoIP blocking** | High breakage for Apple/CDN + Starlink; low home benefit | Skip / last resort only |
| **CyberSecure Enhanced** | Paid add-on; not required for baseline | Explicit need |
| **SD-WAN** | Not needed for single Starlink WAN | Second WAN added |
| **UniFi Integration API keys** | Local admin is simpler for now | Local admin insufficient |
| **Starlink Bypass toggle** | CGNAT on WAN suggests path may already be correct; toggling risks lockout | Phase 4 checklist + 48h stable |
| **Download cap → 280 Mbps** | Optional; clears 121% peak after speed tests | After 24h without speed tests |
| **DHCP fixed IPs / WPA3 Transition** | Fabric touch during gate | After `PASS_WAN_WATCH` → Roadmap Phase 1 |
| **Network Intelligence collector (scheduled)** | Prefer gate quiet; session-safe scripts may be dry-tested | After Phase 0 → Roadmap Phase 3 |

## Baseline Complete Checklist

- [ ] 48h WAN stability ([wan_stability_gate.md](wan_stability_gate.md)) — **due ~Jul 14 20:00**
- [x] AP online (U7 Lite adopted)
- [x] `PIOS-HOME` Wi-Fi broadcasting (confirmed Jul 13)
- [ ] 24h Wi-Fi soak (start when preferred clients stay on `PIOS-HOME`)
- [ ] iPhone `unifi.ui.com` on cellular
- [x] Local admin + `unifi_wan_status.zsh` working (Jul 13)
- [x] PIOS Awake menu bar toggle installed (Jul 13)
- [x] README + checklists dated (Jul 13)

**Post-gate (Jul 14 evening):** confirm `FINAL_VERDICT: PASS_WAN_WATCH`, zero Topology disconnects, run remote iPhone check, then update README WAN Stability date.

When all checked, open **[POST_BASELINE_ROADMAP.md](../post-baseline-roadmap.md)** Phase 1 (DHCP reservations → health/WPA3), not Cloudflare first unless services are ready. Cloudflare Tunnel (services only) remains a parallel workstream after baseline.
