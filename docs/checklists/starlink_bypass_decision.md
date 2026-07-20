# Starlink Bypass Decision

Starlink Bypass Mode may be enabled only if **all** items pass.

## Network Path (verified Jul 5, 2026)

- [x] UniFi WAN shows Starlink Online — Jul 5, 2026
- [x] UniFi gateway is reachable (`192.168.0.1`) — Jul 5, 2026
- [x] Mac connected behind UniFi gets IP `192.168.0.x` — Jul 5, 2026 (`192.168.0.189`)
- [x] Mac gateway/router is `192.168.0.1` — Jul 5, 2026
- [x] Mac appears in UniFi Clients — Jul 5, 2026 (Eduardos-Air-16, port 4)
- [x] Internet works from behind UniFi — Jul 5, 2026
- [x] DNS works from behind UniFi — Jul 5, 2026

## Pending Before Bypass Consideration

- [ ] Mac re-validated on **Wi-Fi** (`PIOS-HOME`) after AP adoption — see [wifi_ap_adoption.md](wifi_ap_adoption.md)
- [ ] UniFi remote access works on iPhone using **cellular data** (Wi-Fi off) → [unifi.ui.com](https://unifi.ui.com) — see [remote_access_validation.md](remote_access_validation.md)
- [ ] Starlink app is logged in and accessible from UniFi LAN/Wi-Fi
- [ ] **48h WAN stability** — see [wan_stability_gate.md](wan_stability_gate.md) (started Jul 5, 2026)
- [ ] Eduardo is physically near the Starlink router
- [ ] Eduardo has time to troubleshoot
- [ ] No critical work is in progress

## Documented WAN State (do not toggle blindly)

- UCG WAN IP: `100.72.180.19` (Starlink CGNAT)
- This may indicate bypass or routed mode is already active
- **Do not toggle bypass** until remote access + 48h stability pass

If any required item fails:

**Do NOT enable Bypass Mode.**

See also: [deferred_until_baseline.md](deferred_until_baseline.md)
