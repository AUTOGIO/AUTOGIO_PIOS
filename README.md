# AUTOGIO_PIOS

Local-first personal infrastructure for home networking and Mac tooling (UniFi baseline + helpers).

## Layout

| Path | Purpose |
|------|---------|
| [`networking/unifi_baseline/`](networking/unifi_baseline/) | UniFi / Starlink home baseline (PIOS-HOME-01) |
| [`tools/pios_awake/`](tools/pios_awake/) | Menu bar awake toggle (`caffeinate`) |

## Secrets

Do not commit credentials. Copy:

```bash
cp networking/unifi_baseline/.unifi.local.env.example \
   networking/unifi_baseline/.unifi.local.env
```

Wi-Fi password lives in `.pios_wifi.env` (gitignored).

## Latest status

See [`networking/unifi_baseline/reports/executive_report_20260713.md`](networking/unifi_baseline/reports/executive_report_20260713.md).
