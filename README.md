# AUTOGIO_PIOS

Local-first Mac tooling for home UniFi / Starlink networking, plus a menu-bar awake toggle.

## Run

```bash
# Daily network health
~/Documents/GitHub/AUTOGIO_PIOS/scripts/unifi_daily_health.zsh

# Menu bar awake app
~/Documents/GitHub/AUTOGIO_PIOS/src/pios_awake/build.zsh
```

Secrets: copy `config/.unifi.local.env.example` → `config/.unifi.local.env` (gitignored).

## Where things live

| Path | Purpose |
|------|---------|
| `scripts/` | UniFi health, WAN watch, intel collect |
| `src/pios_awake/` | PIOS Awake (Swift) |
| `config/` | Env examples, schema, LaunchAgent samples |
| `data/` | Reports + SQLite intel DB |
| `docs/` | Guides and checklists |
| `archive/` | Old debug output |

Full UniFi guide: [`docs/unifi-baseline.md`](docs/unifi-baseline.md). Layout rules: [`AGENTS.md`](AGENTS.md).
