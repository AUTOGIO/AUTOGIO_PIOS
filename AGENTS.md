# AGENTS.md — AUTOGIO_PIOS

Personal Mac / home-network tooling (UniFi baseline scripts + PIOS Awake).

## Folder rules

| Folder | Put here |
|--------|----------|
| `src/` | Application code (e.g. `src/pios_awake/`) |
| `scripts/` | Runnable helpers (`.zsh`, `.swift`, Shortcuts) |
| `config/` | Non-secret settings and examples (env *examples*, schema, LaunchAgent samples) |
| `data/` | Generated or local data (`data/reports/`, `data/intelligence/`, inventory) |
| `docs/` | Guides, checklists, design notes (`docs/prompts/` for AI prompts) |
| `assets/` | Images, icons, logos |
| `tests/` | Tests only |
| `archive/` | Obsolete files kept for reference |
| Root | Only `README.md`, `AGENTS.md`, `.gitignore`, and toolchain files |

Do not invent new top-level folders. Prefer **move** over copy. Prefer **edit** over rewrite.

## Secrets

Never commit `.env`, `.unifi.local.env`, `.pios_wifi.env`, cookies, or passwords. Keep real secrets under `config/` (gitignored); commit only `*.example` files.

## Paths

Scripts assume the repo lives at `~/Documents/GitHub/AUTOGIO_PIOS`. After moves, update hardcoded paths in scripts, LaunchAgents, and Reminders.
