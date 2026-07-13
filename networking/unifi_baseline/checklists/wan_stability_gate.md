# WAN Stability Gate (48 Hours)

Start clock: **Jul 12, 2026** (48h gate restarted — prior Jul 5 watch stopped after 1/48 samples)

## Rules During Gate

- Do **not** run UniFi ISP speed tests (inflates 24h peak chart)
- Do **not** change Starlink bypass, SD-WAN, VLANs, or firewall policies
- Run **automated hourly watch** (below) **plus** manual health check **twice daily**
- Keep **PIOS Awake** On (menu bar cup) in addition to watch `caffeinate`

## Automated Hourly Watch (recommended)

Mac-path connectivity every hour for 48h. Survives terminal close (`nohup` + `caffeinate`).

### Smoke test first (~4 min, foreground)

```bash
env INTERVAL_SECONDS=120 ITERATIONS=3 \
  ~/AUTOGIO_PIOS/networking/unifi_baseline/scripts/wan_watch_48h.zsh \
  >~/AUTOGIO_PIOS/networking/unifi_baseline/reports/wan_watch_stdout.log 2>&1
```

Confirm 3× `VERDICT: PASS_SAMPLE` in the log.

### Start full 48h background watch

```bash
~/AUTOGIO_PIOS/networking/unifi_baseline/scripts/wan_watch_start.zsh
```

Or manually:

```bash
caffeinate -s nohup \
  ~/AUTOGIO_PIOS/networking/unifi_baseline/scripts/wan_watch_48h.zsh \
  >~/AUTOGIO_PIOS/networking/unifi_baseline/reports/wan_watch_stdout.log 2>&1 &
echo $! > ~/AUTOGIO_PIOS/networking/unifi_baseline/reports/wan_watch.pid
```

### Monitor / stop

```bash
tail -f ~/AUTOGIO_PIOS/networking/unifi_baseline/reports/wan_watch_stdout.log
ps -p "$(cat ~/AUTOGIO_PIOS/networking/unifi_baseline/reports/wan_watch.pid)"
~/AUTOGIO_PIOS/networking/unifi_baseline/scripts/wan_watch_stop.zsh
```

### Short test durations (corrected)

| Intent | Command |
|--------|---------|
| Smoke (~4 min, 3 samples / 2 min) | `INTERVAL_SECONDS=120 ITERATIONS=3` |
| 10 min total soak | `INTERVAL_SECONDS=300 ITERATIONS=2` |
| 2h soak, every 10 min | `INTERVAL_SECONDS=600 ITERATIONS=12` |
| Full gate (48h, hourly) | defaults: `3600` × `48` |

**Note:** `INTERVAL_SECONDS=600` with `ITERATIONS=12` is **2 hours total**, not 10 minutes.

### What the watcher covers

- Default route, gateway `192.168.0.1`, ping, DNS
- Per-sample `PASS_SAMPLE` / `FAIL_SAMPLE`
- Optional `unifi_wan_status.zsh` when `.unifi.local.env` exists

**Does not replace:** UniFi Topology disconnect event review (manual UI).

## Daily Checks (still required 2×/day)

**Reminders:** list `PIOS Network` — alerts at **10:00 AM** and **10:00 PM** daily. Tap the `shortcuts://` link in the reminder notes to run the check and open the log.

Re-install reminders + shortcut:

```bash
~/AUTOGIO_PIOS/networking/unifi_baseline/setup/install_pios_health_reminders.zsh
```

Manual run:

```bash
~/AUTOGIO_PIOS/networking/unifi_baseline/scripts/unifi_daily_health.zsh
```

Or tap-to-run via Shortcuts:

```bash
shortcuts run "PIOS UniFi Daily Health"
```

## UniFi UI (Topology → Starlink WAN1)

- [ ] No new "WAN went down" events since last check
- [ ] No new "high latency" alerts since last check
- [ ] 24h uptime ≥ 99.9%

## Starlink App

- [ ] Cross-check disconnect timestamps vs UniFi event log
- [ ] Obstructions remain low (< 1%)

## Pass Criteria

- **48 consecutive hours** with zero WAN disconnect events (UniFi UI)
- Watcher: `FINAL_VERDICT: PASS_WAN_WATCH` (all samples pass)
- Every `unifi_daily_health` run: `PASS_UNIFI_BASELINE_READY`
- Record confirmation date in [README.md](../README.md) under **WAN Stability**

## If Disconnects Continue

1. Reseat Ethernet: Starlink → UCG WAN port 5
2. Try a different cable
3. Note event timestamps in `reports/` via daily health script

## Gate Status

| Date | Validator | UniFi disconnects? | Verdict |
|------|-----------|-------------------|---------|
| 2026-07-05 | post_change_validate + daily_health | prior 24h had some | **IN_PROGRESS** — gate started |
| 2026-07-05 21:24 | post_change_validate | user to confirm in UniFi UI | **IN_PROGRESS** — `PASS_UNIFI_BASELINE_READY` |
| 2026-07-05 22:17 | wan_watch smoke (3×2min) | — | **PASS** — `PASS_WAN_WATCH` |
| 2026-07-05 22:21 | wan_watch 48h started (PID in `reports/wan_watch.pid`) | monitor UniFi UI 2×/day | **STOPPED** — only 1/48 samples |
| 2026-07-12 20:00 | wan_watch 48h restarted (PID in `reports/wan_watch.pid`) | monitor UniFi UI 2×/day | **IN_PROGRESS** |
| 2026-07-12 21:18 | daily_health + gate verify | WAN watch PID 39191 ~1h19m | **IN_PROGRESS** |
| 2026-07-12 21:18 | WiFi UI verify | PIOS-HOME in settings; AP online | **IN_PROGRESS** |
| 2026-07-13 00:59 | `unifi_wan_status.zsh` | local admin API OK; Starlink 260/74 | **PASS_WAN_STATUS_READ** |
| 2026-07-13 01:15 | gate mid-point | WAN watch ~5h15m elapsed; PIOS Awake installed | **IN_PROGRESS** |
| ~2026-07-14 20:00 | 48h gate complete | confirm Topology zero disconnects | **SCHEDULED** |
