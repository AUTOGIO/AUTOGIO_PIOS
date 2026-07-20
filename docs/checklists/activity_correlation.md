# ActivityWatch × UniFi × Home Assistant Correlation — Phase 4

**Last** automation layer. Requires: fixed IPs (Phase 1), HA presence from UniFi (Phase 2+), Network Intelligence history (Phase 3).

## Goal

Correlate:

1. UniFi client join/leave (e.g. MacBook joins Wi‑Fi)
2. ActivityWatch session start
3. Home Assistant automations / scripted workspace launch

Example chain:

```
08:05  MacBook joins Wi‑Fi (UniFi)
  → ActivityWatch starts (or already running)
  → Launch development workspace
  → LM Studio starts
  → Obsidian opens
  → Health check executes
```

## Prerequisites

- [ ] DHCP reservations for Mac / iPhone
- [ ] HA UniFi integration (or MQTT sensors from [network-intelligence.md](../network-intelligence.md)) showing device presence
- [ ] ActivityWatch running on Mac with export/API accessible to HA or a PIOS script
- [ ] ≥7 days intel SQLite history (optional but useful for debugging false presence)

## Implementation sketch

- [ ] HA: `device_tracker` / binary sensors for primary Mac + iPhone
- [ ] HA automation: `MacBook home + AW idle→active` → notify or run Shortcut
- [ ] macOS: Shortcut or launchd job for workspace bundle (LM Studio, Obsidian, health)
- [ ] Optional: write correlation events to intel SQLite `events` table
- [ ] Document false-positive rules (VPN, sleep/wake, Ethernet vs Wi‑Fi dual client)

## Out of scope for v1

- Full ML anomaly on user behavior
- Replacing HA with a custom orchestrator

## Done when

- [ ] One end-to-end morning correlation works on primary Mac
- [ ] Failure modes documented (device still “home” when away, etc.)
