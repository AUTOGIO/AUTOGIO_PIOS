# AUTOGIO_PIOS

Local-first Mac tooling for home UniFi / Starlink networking, plus a menu-bar awake toggle.

## Prerequisites

- macOS with `zsh`, `python3`, `curl`, `sqlite3`, `swift` / `swiftc`
- [`rg` (ripgrep)](https://github.com/BurntSushi/ripgrep) — used by WAN watch and reminder helpers
- Repo path can live anywhere; scripts resolve the root from their own location

## Run

```bash
# Daily network health
./scripts/unifi_daily_health.zsh

# Menu bar awake app → ~/Applications/PIOS Awake.app
./src/pios_awake/build.zsh

# Offline score unit tests
python3 -m unittest discover -s tests -v

# Optional: prune reports older than 30 days
./scripts/prune_reports.zsh
```

Secrets:

- `config/.unifi.local.env.example` → `config/.unifi.local.env` (gitignored)
- `config/.pios_wifi.env.example` → `config/.pios_wifi.env` (gitignored)

Optional TLS: set `UNIFI_CA_CERT` to a PEM trust bundle for the gateway to avoid `curl -k`.

Optional cloud UI helper: set `UNIFI_CONSOLE_URL` before `scripts/open_unifi_baseline_pages.zsh`.

## Where things live

| Path | Purpose |
|------|---------|
| `scripts/` | UniFi health, WAN watch, intel collect |
| `scripts/lib/` | Shared Python helpers (network score) |
| `src/pios_awake/` | PIOS Awake (Swift) |
| `config/` | Env examples, schema, LaunchAgent samples |
| `data/` | Reports + SQLite intel DB |
| `docs/` | Guides and checklists |
| `tests/` | Offline unit tests |
| `archive/` | Old debug output (gitignored) |

Full UniFi guide: [`docs/unifi-baseline.md`](docs/unifi-baseline.md). Layout rules: [`AGENTS.md`](AGENTS.md).

Remediation summary (2026-07-29): [`docs/remediation-summary-2026-07-29.md`](docs/remediation-summary-2026-07-29.md).

## WAN Stability (Phase 0)

**Status (2026-07-29): RESET / reopen required** — interactive daily health on 2026-07-20 and 2026-07-28 recorded `WAN_STABILITY_GATE_RESET`. Stale watch PID cleared during audit remediation. Re-run the [WAN stability gate](docs/checklists/wan_stability_gate.md) before Phase 1+ fabric changes.

Phases **≥2 remain frozen** until Phase 0 is explicitly PASS — see [`docs/post-baseline-roadmap.md`](docs/post-baseline-roadmap.md).
