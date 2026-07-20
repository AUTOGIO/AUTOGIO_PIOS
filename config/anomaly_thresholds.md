# Anomaly thresholds — Phase 3+ (reference)

Used conceptually by `collect.zsh` (partial) and future alert hooks.
Do not page aggressively until after Phase 0 and a few quiet days of samples.

| Condition | Severity | Action (planned) |
|-----------|----------|------------------|
| WAN uptime 24h below 99.0% | warning | Event in SQLite; morning report |
| Packet loss / latency high | warning | Future: probe from Mac + UniFi ISP metrics |
| Wireless RSSI below -75 | info | Listed in morning report |
| AP overload / high util | warning | Future: from device `satisfaction` / util fields |
| Gateway CPU above 85% sustained | warning | Future: Shortcuts notify |
| Collector login failures | critical | Stop LaunchAgent; cool down (rate limit) |

## Notification hooks (not installed yet)

1. Append to Reminders list **PIOS Network**
2. Apple Shortcut “PIOS UniFi Alert”
3. Home Assistant `notify.notify` when `weak_wifi_count` or uptime crosses threshold

Wire these only after `data/intelligence/unifi_intel.sqlite` has ≥24h of samples.
