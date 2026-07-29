# AGENTS.md — AUTOGIO_PIOS

Personal Mac / home-network tooling (UniFi baseline scripts + PIOS Awake).

## Folder rules

| Folder | Put here |
|--------|----------|
| `src/` | Application code (e.g. `src/pios_awake/`) |
| `scripts/` | Runnable helpers (`.zsh`, `.swift`, Shortcuts); shared Python under `scripts/lib/` |
| `config/` | Non-secret settings and examples (env *examples*, schema, LaunchAgent samples) |
| `data/` | Generated or local data (`data/reports/`, `data/intelligence/`, inventory) |
| `docs/` | Guides, checklists, design notes |
| `tests/` | Tests only |
| `archive/` | Obsolete files kept for reference (gitignored) |
| Root | Only `README.md`, `AGENTS.md`, `.gitignore`, audit/toolchain files |

Optional (create when needed): `assets/`, `docs/prompts/`.

Do not invent new top-level folders beyond the table. Prefer **move** over copy. Prefer **edit** over rewrite.

## Secrets

Never commit `.env`, `.unifi.local.env`, `.pios_wifi.env`, cookies, or passwords. Keep real secrets under `config/` (gitignored); commit only `*.example` files.

## Paths

Scripts resolve the repo root from their own location (`$(cd "$(dirname "$0")/.." && pwd)`). LaunchAgent examples use `__REPO_ROOT__` placeholders — substitute before loading. Prefer `$HOME` / relative paths over hard-coded `/Users/<name>/...`.
