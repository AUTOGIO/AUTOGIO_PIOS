# Repository Audit Report

> **Remediation applied 2026-07-29:** Stages 0–4 / quick wins from §25–26 implemented in-tree (Awake rebuild to `~/Applications/PIOS Awake.app`, cookie `600`, sanitized login errors, WAN PID lifecycle, relative `BASE_DIR`, PII redaction, score lib + tests, docs/gate RESET status, report prune helper). Remaining pass also fixed Homebrew GNU `stat` breaking sessions, installed Awake login agent, refreshed daily-health LaunchAgent, removed duplicate Awake, and verified live `PASS_WAN_STATUS_READ` + collect. See [`docs/remediation-summary-2026-07-29.md`](docs/remediation-summary-2026-07-29.md). Full CA pinning and Phase ≥2 fabric work remain deferred. Historical finding text below is preserved as the pre-fix baseline.

## 1. Executive Summary

AUTOGIO_PIOS is a **personal, local-first macOS toolkit** for a home UniFi / Starlink network (PIOS-HOME-01), plus a small **PIOS Awake** menu-bar wrapper around `caffeinate`. It is primarily **zsh + embedded Python + one Swift AppKit binary**, with SQLite intelligence scaffolding and extensive operational checklists.

The repo is **usable for a single operator on a fixed machine path**, but **operationally drifted**: docs still describe a Jul 12–14 2026 WAN gate; the Awake app lives under `~/Applications/PIOS_NETWORK/` while build/docs expect `~/Applications/PIOS Awake.app`; the intel SQLite DB has not advanced past mid-July; stale PID files remain; and Phase 1–4 roadmap ambition exceeds current maintenance capacity.

**Secrets handling is mostly sound** (env files gitignored, mode `600`). Main security concerns are **TLS verification disabled** (`curl -sk`), a **world-readable cookie jar**, **login failure dumping raw API bodies**, and **committed personal identifiers** (absolute home path, SSO email default, UniFi cloud console URL).

**Highest-priority next action:** reconcile documentation and install paths with reality (Awake location, gate status, stale PIDs), then tighten cookie permissions and stop printing raw auth responses — before expanding Phase 1–4 work.

## 2. Audit Scope and Limitations

**In scope**

- Full tracked tree under `/Users/eduardofgiovannini/Documents/GitHub/AUTOGIO_PIOS`
- Local ignored runtime artifacts inspected for hygiene/security (env file *keys* only, cookie permissions, PID liveness, SQLite counts)
- Script/source review for correctness, security, shell, and macOS concerns
- Safe validations: toolchain versions, `zsh -n`, `swiftc -parse`, `git diff --check`, read-only `sqlite3` queries

**Out of scope / not executed**

- Live UniFi API calls (`collect.zsh`, `unifi_wan_status.zsh`, credentialed login)
- `build.zsh` / app launch (would rebuild/kill processes under `~/Applications`)
- Daily health / WAN watch (write reports; long-running)
- Package installs, dependency updates, remediation
- Deep review of `archive/` Playwright PNG dumps (gitignored, ~6.5M)

**Blocked / unverified**

- End-to-end UniFi session login and WAN read
- Whether LaunchAgent `com.pios.unifi-daily-health` currently loads successfully
- Whether `PIOS Awake.app` under `PIOS_NETWORK/` matches current `Sources/main.swift`

## 3. Initial Repository State

| Item | Value |
|------|-------|
| Repository root | `/Users/eduardofgiovannini/Documents/GitHub/AUTOGIO_PIOS` |
| Branch | `main` (tracks `origin/main` at `f21189f`) |
| Remote | `https://github.com/AUTOGIO/AUTOGIO_PIOS.git` |
| Recent commits | `f21189f` reorganize layout; `b466d6f` initial UniFi + Awake |
| Submodules | None |
| Worktrees | Single worktree at repo root |
| Size | ~8.4M total (`archive/` ~6.5M local, gitignored) |
| Uncommitted | Untracked `src/pios_awake/pios_awake 2.pid` only |
| Nested repos | None |
| CI | No `.github/workflows` |
| Package manifests | None (`Package.swift` / `package.json` / `pyproject.toml` absent) |

**Relevant ignored runtime**

- `config/.unifi.local.env`, `config/.pios_wifi.env` (present, mode `600`, not tracked)
- `config/.cache/unifi_cookies.txt` (present, mode `644`)
- `data/intelligence/unifi_intel.sqlite`, `data/reports/*` (local; executive report exception tracked)
- `archive/` (Playwright debug screenshots)

## 4. Repository Purpose

| Aspect | Assessment |
|--------|------------|
| **Intended purpose** | Operate and document a UniFi/Starlink home baseline; automate health checks, WAN watch, optional intel collection; keep Mac awake via menu bar |
| **Likely user** | Single home operator (repo owner) on one Mac |
| **Primary workflows** | Daily health → reports/score JSON; WAN 48h watch; UniFi API WAN status; intel collect → SQLite → morning report; build/run PIOS Awake; Reminders/Shortcuts hooks |
| **Inputs** | Local UniFi admin credentials; network state; optional Playwright CLI for UI WAN speed apply |
| **Outputs** | Text/JSON/Markdown under `data/reports/`; SQLite + `ha_state.json`; menu-bar awake process |
| **Persistent data** | SQLite intel DB, reports, cookie jar, PID files, LaunchAgents outside repo |
| **External services** | Local UniFi gateway (`192.168.0.1`); UniFi cloud UI; DNS/ping to public hosts; optional Home Assistant (example only) |
| **Deployment model** | Local scripts + optional LaunchAgents; Swift app to `~/Applications`; no cloud deploy |

**Documented vs implemented**

| Claim | Reality |
|-------|---------|
| README daily health + Awake build | Scripts exist and parse cleanly |
| Awake installed at `~/Applications/PIOS Awake.app` | App found at `~/Applications/PIOS_NETWORK/PIOS Awake.app`; default path absent |
| 48h gate due ~Jul 14, 2026 | Checklist still open-style; stale `wan_watch.pid`; later health reports include `WAN_STABILITY_GATE_RESET` |
| Network Intelligence Phase 3 scaffold | `collect.zsh` / schema / reports exist; DB last sample ~2026-07-13; only 2 samples |
| Secrets gitignored | Confirmed via `git check-ignore` and `git ls-files` |

## 5. Repository Map

| Path | Purpose |
|------|---------|
| `README.md`, `AGENTS.md` | Entry docs + agent layout rules |
| `AUTOGIO_PIOS.code-workspace` | Multi-root workspace (also references iCloud `Config_Gerais`) |
| `scripts/` | UniFi health, WAN watch, intel collect, Reminders, Shortcuts, WAN speed tools |
| `src/pios_awake/` | Swift menu-bar awake app + build/login-item scripts |
| `config/` | Env examples, schema, LaunchAgent example, HA sensor example, anomaly notes |
| `data/reports/` | Generated health/WAN/intel reports (mostly gitignored) |
| `data/intelligence/` | SQLite + HA state snapshot (gitignored) |
| `data/inventory/` | DHCP reservation example |
| `docs/` | Baseline guide, roadmap, Awake, intelligence, Reminders, checklists |
| `archive/` | Obsolete Playwright rename debug dumps (gitignored) |
| `tests/`, `assets/`, `docs/prompts/` | Referenced in `AGENTS.md`; **directories absent** |

## 6. Technology Stack

| Technology | Evidence |
|------------|----------|
| zsh scripts | `scripts/*.zsh`, `src/pios_awake/*.zsh` |
| Python 3 (stdlib) | Embedded heredocs in health/collect/report/common |
| Swift + AppKit | `src/pios_awake/Sources/main.swift`, `swiftc` in `build.zsh` |
| SQLite | `config/schema.sql`, `sqlite3` in `collect.zsh` |
| curl | UniFi HTTPS API in `unifi_common.zsh` |
| macOS tools | `caffeinate`, `launchctl`, `codesign -s -`, `open`, `networksetup`, `dig`, `ping` |
| ripgrep (`rg`) | `wan_watch_48h.zsh`, `pios_reminder_action.zsh`, UI script |
| Playwright CLI (optional) | `unifi_set_wan_speeds_ui.zsh` → `$HOME/.codex/skills/playwright/...` |
| Apple Reminders / Shortcuts | `*.swift` reminder creators, `.shortcut` |
| GitHub remote | No Actions/CI present |
| No npm/pip/Cargo deps | No lockfiles / manifests |

## 7. Architecture Overview

```text
                    ┌─────────────────────────────┐
                    │  Operator (Mac + Ethernet)  │
                    └─────────────┬───────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
        ▼                         ▼                         ▼
┌───────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ PIOS Awake    │       │ zsh UniFi ops   │       │ LaunchAgents /  │
│ (AppKit)      │       │ scripts         │       │ Reminders       │
│ caffeinate    │       │ unifi_common    │       │ Shortcuts       │
└───────────────┘       └────────┬────────┘       └────────┬────────┘
                                 │                         │
                    ┌────────────┼────────────┐            │
                    ▼            ▼            ▼            │
              UniFi API    Local net     SQLite intel      │
              (cookie)     validate      + reports  <──────┘
```

**Actual boundaries:** shared `unifi_common.zsh` session helper; scripts hardcode `~/Documents/GitHub/AUTOGIO_PIOS`; Awake is independent of UniFi; intel is a thin poller writing SQLite; roadmap docs describe future VLANs/IDS/HA/ActivityWatch not present as code.

**Ambition–Capacity Mismatch:** Phase 0–4 docs (VLANs, IDS/IPS, cameras, ActivityWatch, HA Lovelace) far exceed the small script set and single-operator capacity. Prefer freezing Phase ≥2 until gate status and Awake install path are truthful and stable.

## 8. Build, Test, and Run Procedure

### Prepare

1. Clone to `~/Documents/GitHub/AUTOGIO_PIOS` (hardcoded assumption).
2. macOS with `zsh`, `python3`, `curl`, `sqlite3`, `swift`/`swiftc`, preferably `rg`.
3. Copy `config/.unifi.local.env.example` → `config/.unifi.local.env` (local UniFi admin, not SSO).
4. Optional: `config/.pios_wifi.env` (no committed `.example`).

### Build Awake

```bash
~/Documents/GitHub/AUTOGIO_PIOS/src/pios_awake/build.zsh
# expects output: ~/Applications/PIOS Awake.app
# optional: src/pios_awake/install_login_item.zsh
```

### Run common ops

```bash
scripts/unifi_daily_health.zsh
scripts/wan_watch_start.zsh   # / wan_watch_stop.zsh
scripts/unifi_wan_status.zsh  # needs credentials
scripts/collect.zsh
scripts/report_morning.zsh
```

### Tests

**No test suite or test commands exist.** Validation today is manual reports + checklists.

### Conflicts / drift

- Docs/build expect Awake at `~/Applications/PIOS Awake.app`; live app under `~/Applications/PIOS_NETWORK/`.
- LaunchAgent example uses absolute `/Users/eduardofgiovannini/...`; scripts use `$HOME/...`.
- UI WAN script requires Codex Playwright skill path — not documented in README.
- Gate docs dated mid-July while health continues into late July with RESET verdicts.

## 9. Commands Executed

| Command | Exit | Result |
|---------|------|--------|
| `pwd` / `ls` / `find` structure | 0 | Mapped repo |
| `git status/branch/remote/log/worktree/submodule` | 0 | Clean except untracked PID; `main` @ `f21189f` |
| `du -sh` | 0 | ~8.4M |
| `git diff --check` | 0 | No whitespace errors |
| `swift --version` / `python3` / `zsh` / `sqlite3` / `curl` / `git` | 0 | Toolchain present (Swift 6.4 arm64, Python 3.14.6) |
| `zsh -n` on all `*.zsh` | 0 | All OK |
| `swiftc -parse src/pios_awake/Sources/main.swift` | 0 | Parses |
| `git check-ignore` / `git ls-files` secrets | 0 | Env secrets ignored/untracked |
| `sqlite3` schema + counts (read-only) | 0 | 2 samples, 10 clients, 0 events; latest ~2026-07-13 |
| `ps` on PID files | 0 | Both PIDs **stale** (not running) |
| Live UniFi / `build.zsh` / health / collect | **Skipped** | Would use credentials, write reports, or mutate Applications |

## 10. Findings Summary

| ID | Severity | Priority | Category | Finding | Confidence |
|---|---|---|---|---|---|
| AUDIT-001 | High | P0 | Reliability | Operational docs and install paths drifted from reality | Confirmed |
| AUDIT-002 | High | P1 | Security | TLS verification disabled for UniFi API (`curl -sk`) | Confirmed |
| AUDIT-003 | Medium | P1 | Security | Session cookie jar world-readable (`644`) | Confirmed |
| AUDIT-004 | Medium | P1 | Security | Failed login prints raw API response body | Confirmed |
| AUDIT-005 | Medium | P1 | Security | Personal identifiers committed (home path, SSO email, console URL) | Confirmed |
| AUDIT-006 | Medium | P1 | Reliability | WAN watch PID / process lifecycle fragile; stale PID left behind | High confidence |
| AUDIT-007 | Medium | P2 | Correctness | Large UniFi JSON passed via environment variables | Probable |
| AUDIT-008 | Medium | P2 | Architecture | Ambition–capacity mismatch (Phases 1–4 vs script toolkit) | Confirmed |
| AUDIT-009 | Medium | P2 | Testing | No automated tests for critical paths | Confirmed |
| AUDIT-010 | Medium | P2 | macOS | Awake PID path hardcodes repo location under Documents | Confirmed |
| AUDIT-011 | Medium | P2 | Dependency | Playwright UI path tied to Codex skill; brittle default username | Confirmed |
| AUDIT-012 | Low | P2 | Documentation | AGENTS.md / docs reference missing dirs and wifi example | Confirmed |
| AUDIT-013 | Low | P3 | Repository hygiene | Stale/odd PID files; unbounded report growth; large ignored archive | Confirmed |
| AUDIT-014 | Low | P3 | Shell | Inconsistent strict mode; machine-specific `en5` logging | Confirmed |
| AUDIT-015 | Informational | P3 | Documentation | Baseline/status docs frozen mid-July while ops continued | Confirmed |

## 11. Critical Findings

None confirmed. Credentials are not committed; env files are mode `600` and gitignored. No `curl \| sh` or credential-in-git history found for the env files.

## 12. High Findings

### [AUDIT-001] Operational docs and install paths drifted from reality

- Severity: High
- Priority: P0
- Confidence: Confirmed
- Category: Reliability
- File: `docs/pios-awake.md`, `docs/unifi-baseline.md`, `src/pios_awake/build.zsh`, `data/reports/wan_watch.pid`
- Location: Install path claims; WAN gate section; PID file dated 2026-07-12
- Evidence:
  - Docs claim Awake at `~/Applications/PIOS Awake.app`; filesystem has `~/Applications/PIOS_NETWORK/PIOS Awake.app` only.
  - `build.zsh` / `install_login_item.zsh` target `~/Applications/PIOS Awake.app`.
  - Gate docs still center Jul 12–14 2026; `wan_watch.pid` points to dead PID `39191`; intel DB last sample 2026-07-13; health reports through Jul 28 include `WAN_STABILITY_GATE_RESET`.
- Impact:
  - Operator follows docs and misses the real app; gate/status decisions based on stale narrative; automation may point at wrong binary path.
- Recommendation:
  - Update docs to current Awake path **or** move/rebuild to the documented path; clear stale PIDs; record an explicit gate PASS/FAIL/RESET decision dated today.
- Validation:
  - `ls ~/Applications/PIOS\ Awake.app` matches docs; `ps` shows no stale PID files; baseline doc gate section matches latest report verdict.

### [AUDIT-002] TLS verification disabled for UniFi API (`curl -sk`)

- Severity: High
- Priority: P1
- Confidence: Confirmed
- Category: Security
- File: `scripts/unifi_common.zsh`
- Location: `unifi_login` (~L44), `unifi_api_get` (~L78); also `unifi_set_wan_speeds.zsh` PUT
- Evidence:
  - `command curl -sk` and `/usr/bin/curl -sk` against `https://${UNIFI_HOST}/...`.
  - UI helper also sets Playwright `ignoreHTTPSErrors: true`.
- Impact:
  - On a compromised LAN/DNS, credentials and session cookies can be intercepted despite HTTPS.
- Recommendation:
  - Prefer pinning the UniFi local CA / `--cacert`, or document explicit acceptance of MITM risk for RFC1918-only hosts; avoid `-k` for any non-local URL.
- Validation:
  - Successful API call with verification enabled against the gateway’s certificate trust store.

## 13. Medium Findings

### [AUDIT-003] Session cookie jar world-readable (`644`)

- Severity: Medium
- Priority: P1
- Confidence: Confirmed
- Category: Security
- File: `config/.cache/unifi_cookies.txt` (created via `unifi_common.zsh`)
- Location: `unifi_login` / `unifi_ensure_session` mkdir + curl `-c`
- Evidence:
  - `ls -l` shows `-rw-r--r--` on the cookie jar; env secrets are correctly `600`.
- Impact:
  - Any local account can read UniFi session cookies and reuse the API session.
- Recommendation:
  - `umask 077` before creating jar, or `chmod 600` after write; ensure directory `700`.
- Validation:
  - Fresh login produces cookie file mode `600`.

### [AUDIT-004] Failed login prints raw API response body

- Severity: Medium
- Priority: P1
- Confidence: Confirmed
- Category: Security
- File: `scripts/unifi_common.zsh`
- Location: `unifi_login` L66–L67
- Evidence:
  - On failure: `print -r -- "${login_response}"` (also teed into report files by callers).
- Impact:
  - Tokens/error details may land in `data/reports/*.txt` logs.
- Recommendation:
  - Log only `code` / sanitized message; never dump full body to reports.
- Validation:
  - Force a bad password in a disposable env and confirm reports lack raw JSON bodies.

### [AUDIT-005] Personal identifiers committed

- Severity: Medium
- Priority: P1
- Confidence: Confirmed
- Category: Security
- File: `config/com.pios.unifi-intel-collect.plist.example`, `scripts/unifi_set_wan_speeds_ui.zsh`, `scripts/open_unifi_baseline_pages.zsh`
- Location: Absolute `/Users/eduardofgiovannini/...`; default `USERNAME=...@gmail.com`; hardcoded UniFi cloud console URL
- Evidence:
  - LaunchAgent example embeds full home path.
  - UI script defaults SSO email (despite docs preferring local admin for API).
  - `open_unifi_baseline_pages.zsh` embeds a long `unifi.ui.com/consoles/...` identifier.
- Impact:
  - Public clone leaks username, email, and cloud console handle; copy-paste LaunchAgent breaks on other machines without edit.
- Recommendation:
  - Use `$HOME` placeholders in examples; remove email default (require env); parameterize console URL.
- Validation:
  - `git grep` shows no personal home path / personal email / console ID in tracked files.

### [AUDIT-006] WAN watch PID lifecycle fragile; stale PID left behind

- Severity: Medium
- Priority: P1
- Confidence: High confidence
- Category: Reliability
- File: `scripts/wan_watch_start.zsh`, `scripts/wan_watch_48h.zsh`, `scripts/wan_watch_stop.zsh`
- Location: PID write in start (~L21–23) vs overwrite in watch (~L18); stop kills PID file target
- Evidence:
  - Start backgrounds `caffeinate -s nohup script` and writes `$!`, then the script overwrites PID with `$$`.
  - `data/reports/wan_watch.pid` exists with dead PID from 2026-07-12.
  - Start lacks `set -euo pipefail`.
- Impact:
  - Stop may not kill the intended process tree; stale PID confuses “already running” checks.
- Recommendation:
  - Single owner PID (process group); trap cleanup; `kill` process group; refuse start if PID file stale after `ps` check (partially present — ensure stop always clears).
- Validation:
  - Start → `ps` matches PID file → stop → no orphan `caffeinate`/`wan_watch` → PID file removed.

### [AUDIT-007] Large UniFi JSON passed via environment variables

- Severity: Medium
- Priority: P2
- Confidence: Probable
- Category: Correctness
- File: `scripts/collect.zsh`
- Location: L33–L36 `export WAN_JSON` / `CLIENTS_JSON` / `DEVICES_JSON`
- Evidence:
  - Full API payloads exported into the environment for Python; client lists can grow large.
- Impact:
  - Risk of `E2BIG` / truncated env on busy networks; silent parse errors via `_parse_error`.
- Recommendation:
  - Write JSON to temp files and pass paths; or pipe via stdin.
- Validation:
  - Collect with a large synthetic clients JSON without env export failures.

### [AUDIT-008] Ambition–capacity mismatch (Phases 1–4 vs script toolkit)

- Severity: Medium
- Priority: P2
- Confidence: Confirmed
- Category: Architecture
- File: `docs/post-baseline-roadmap.md`, `docs/network-intelligence.md`
- Location: Phases 1–4 (VLANs, IDS/IPS, HA, ActivityWatch)
- Evidence:
  - Implementation is ~17 zsh scripts + one Swift file; roadmap describes multi-phase network fabric redesign.
- Impact:
  - Risk of incomplete half-migrations (VLANs without recovery plan) and doc sprawl without code ownership.
- Recommendation:
  - Explicitly park Phase ≥2; finish Phase 0 truthfulness + Awake path + cookie hardening first.
- Validation:
  - Roadmap header states freeze criteria; checklists for deferred phases marked deferred-only.

### [AUDIT-009] No automated tests for critical paths

- Severity: Medium
- Priority: P2
- Confidence: Confirmed
- Category: Testing
- File: `AGENTS.md` (claims `tests/`); repository root
- Location: `tests/` directory missing; no CI
- Evidence:
  - `ls tests` fails; no pytest/swift test targets; scoring logic duplicated in health vs morning report.
- Impact:
  - Regressions in session reuse, scoring, or verdict strings go unnoticed until live failure.
- Recommendation:
  - Add a minimal `tests/` with pure Python unit tests for score parsing and JSON shape fixtures (no live UniFi).
- Validation:
  - `python3 -m pytest` (or equivalent) runs offline and passes.

### [AUDIT-010] Awake PID path hardcodes repo location

- Severity: Medium
- Priority: P2
- Confidence: Confirmed
- Category: macOS
- File: `src/pios_awake/Sources/main.swift`
- Location: `pidFileURL` L8–L13
- Evidence:
  - PID written under `Documents/GitHub/AUTOGIO_PIOS/src/pios_awake` via `NSHomeDirectory()` append.
  - Untracked Finder-style `pios_awake 2.pid` present; `.gitignore` only matches `**/pios_awake.pid`.
- Impact:
  - App breaks or mis-tracks state if repo moves; duplicate PID filenames if copies created.
- Recommendation:
  - Use Application Support (`~/Library/Application Support/com.pios.awake/`) for PID; ignore `*.pid` under `src/pios_awake/`.
- Validation:
  - Rebuild; toggle On/Off; PID appears only under Application Support.

### [AUDIT-011] Playwright UI path tied to Codex skill; brittle default username

- Severity: Medium
- Priority: P2
- Confidence: Confirmed
- Category: Dependency
- File: `scripts/unifi_set_wan_speeds_ui.zsh`
- Location: L10–L13
- Evidence:
  - `PWCLI="${CODEX_HOME:-$HOME/.codex}/skills/playwright/scripts/playwright_cli.sh"`.
  - Default username is SSO email, conflicting with local-admin API guidance.
- Impact:
  - Script fails on machines without Codex Playwright skill; encourages SSO/MFA path.
- Recommendation:
  - Document optional dependency; require `UNIFI_USERNAME`; fail if unset.
- Validation:
  - Fresh shell without Codex path prints clear ERROR; with env set, proceeds to UI wait loop.

## 14. Low and Informational Findings

### [AUDIT-012] AGENTS.md / docs reference missing dirs and wifi example

- Severity: Low
- Priority: P2
- Confidence: Confirmed
- Category: Documentation
- File: `AGENTS.md`, `docs/unifi-baseline.md`
- Location: Folder rules; credentials section referencing `.pios_wifi.env`
- Evidence:
  - `tests/`, `assets/`, `docs/prompts/` absent; no `config/.pios_wifi.env.example` while real wifi env exists locally.
- Impact:
  - Agents/humans create wrong layout or lack a safe template for wifi secrets.
- Recommendation:
  - Add missing example **or** remove references; create empty stub dirs only if intentional.
- Validation:
  - Every path in `AGENTS.md` exists or is explicitly optional.

### [AUDIT-013] Stale/odd PID files; unbounded report growth; large ignored archive

- Severity: Low
- Priority: P3
- Confidence: Confirmed
- Category: Repository hygiene
- File: `src/pios_awake/pios_awake 2.pid`, `data/reports/`, `archive/`
- Location: Working tree / local disk
- Evidence:
  - 113 report files (~680K); archive Playwright PNGs ~6.5M gitignored; odd spaced PID untracked.
- Impact:
  - Clutter; confusion; disk growth over months of LaunchAgent health runs.
- Recommendation:
  - Retention script or periodic prune; delete stale PIDs; keep archive out of sync (already ignored).
- Validation:
  - Report count policy documented; no dead `*.pid` in tree.

### [AUDIT-014] Inconsistent strict mode; machine-specific `en5` logging

- Severity: Low
- Priority: P3
- Confidence: Confirmed
- Category: Shell
- File: `scripts/unifi_daily_health.zsh`, `scripts/wan_watch_48h.zsh`, others
- Location: `set -u` without `-e`; `wan_watch_48h.zsh` L75–78 hardcodes `en5`/`en0`
- Evidence:
  - Several operational scripts intentionally continue after failures (`|| true`) but omit `pipefail`.
  - Interface names are host-specific.
- Impact:
  - Partial failures may be missed; logs less portable.
- Recommendation:
  - Standardize on `set -euo pipefail` with explicit `|| true` at known soft-fail points; derive primary iface from `route`.
- Validation:
  - Smoke health run still produces verdicts on a Mac without `en5`.

### [AUDIT-015] Baseline/status docs frozen mid-July while ops continued

- Severity: Informational
- Priority: P3
- Confidence: Confirmed
- Category: Documentation
- File: `docs/unifi-baseline.md`, `docs/checklists/wan_stability_gate.md`
- Location: “Current Observed State (Jul 13, 2026)”
- Evidence:
  - Health reports continue through late July; doc “current state” not refreshed.
- Impact:
  - Misleading onboarding for future-you / agents.
- Recommendation:
  - Add a “Last verified” date field updated when health passes.
- Validation:
  - Doc date ≥ latest `daily_health_*.txt` considered authoritative.

## 15. Security Assessment

**Strengths**

- Real secrets gitignored; `config/.unifi.local.env` / `.pios_wifi.env` mode `600`
- No secret values found in `git ls-files`
- Shared session reuse reduces login hammering / lockouts
- Docs correctly warn against SSO/MFA for API

**Risks**

- `curl -sk` (AUDIT-002)
- Cookie `644` (AUDIT-003)
- Raw login dumps (AUDIT-004)
- PII/path/console ID in git (AUDIT-005)
- Mutating WAN API script (`unifi_set_wan_speeds.zsh`) is powerful — acceptable if intentional; ensure only local admin uses it

**Not found**

- Committed passwords, private keys, `sudo` abuse, `curl | sh`, SQL injection (queries parameterized)

## 16. Correctness Assessment

- Verdict string / score logic is heuristic and duplicated (health vs morning) — consistent enough for advisory use.
- Awake `quitApp` stops caffeinate; comment on `applicationWillTerminate` is slightly misleading but Quit path matches docs.
- `collect.zsh` AP detection heuristics are best-effort; empty/mis-shaped JSON becomes `_parse_error` without failing the sample insert hard.
- Hardcoded LAN `192.168.0.1` / `192.168.0.*` matches documented home design — correct for this site, not portable.

## 17. Reliability and Operational Stability

- Daily health LaunchAgent exists on the machine and points at absolute repo paths — works for this user, brittle if repo moves.
- Intel collector not producing ongoing samples (DB stale) — LaunchAgent example likely not loaded.
- Stale WAN watch PID and RESET gate verdicts indicate the 48h automation is not a trustworthy continuous control right now.
- Report directory grows without rotation.
- Awake path mismatch is the clearest stability break for the menu-bar tool.

## 18. Architecture and Complexity Assessment

- **Appropriate core:** thin scripts + shared session helper + optional SQLite.
- **Excess complexity:** Playwright UI automation, large Phase 2–4 checklist surface, HA/ActivityWatch hooks before Phase 0 closure is honest.
- **Simplification target:** one canonical Awake install path; one status doc; defer VLAN/IDS/HA code and docs expansion.

## 19. Dependency Assessment

- No package manager lockfiles — low supply-chain surface.
- Runtime relies on macOS builtins + `python3` + `rg` + optional Codex Playwright.
- Risk is **environment coupling** (Codex path, absolute LaunchAgent paths), not vulnerable npm packages.

## 20. Testing Assessment

- **None.** Critical paths (session ensure, score JSON, verdict classification, Awake PID adopt/kill) are untested.
- Manual checklists are strong operational substitutes but do not catch script regressions.

## 21. Documentation Assessment

- Strong operational narrative for a home lab; README is concise and mostly accurate for script locations.
- Drift: Awake path, gate dates, Phase status, missing folders named in `AGENTS.md`, wifi env without example.
- `docs/unifi-baseline.md` links to real scripts — good; treat status tables as claims requiring refresh.

## 22. macOS and Apple-Specific Assessment

- Swift AppKit accessory app (`LSUIElement`), ad-hoc `codesign -s -`, Login Agent via `launchctl bootstrap` — appropriate for personal unsigned tools.
- Hardcoded `Documents/GitHub/AUTOGIO_PIOS` everywhere (scripts, Swift PID, Shortcuts, LaunchAgents).
- Apple Silicon toolchain present (`arm64`); no Intel-only binaries in tree.
- Reminders/Shortcuts need TCC permissions — documented in `docs/setup-reminders.md` (not fully re-audited line-by-line).

## 23. Shell Script Assessment

- Many scripts use `set -euo pipefail`; several intentional soft-fail scripts use only `set -u`.
- Quoting is generally careful (`print -r`, quoted paths).
- `rm -rf` in `build.zsh` targets only the app bundle path after `pkill` — acceptable with awareness.
- `wan_watch_start` / PID handling is the main shell reliability gap (AUDIT-006).
- Dependency on `rg` should be documented or replaced with `grep -E` for portability.

## 24. Repository Hygiene

- Layout matches `AGENTS.md` intent; root is clean of random tooling files.
- `.gitignore` covers secrets, reports, sqlite, archive, caches well.
- Gaps: spaced PID filename not ignored; no wifi env example; `REPOSITORY_AUDIT.md` not ignored (should be committed if kept as project record).
- Workspace file references a second iCloud folder outside this repo — fine for local IDE, irrelevant to GitHub clone alone.

## 25. Prioritized Remediation Plan

### Stage 0 — Preserve and Validate

- Confirm Awake binary location and LaunchAgent paths.
- Snapshot latest health + gate decision in a dated note (no fabric changes).
- Backup `config/.unifi.local.env` offline (do not commit).
- **Rollback:** none (read-only inventory).

### Stage 1 — Critical Stabilization

1. Fix Awake path docs **or** reinstall to documented path (AUDIT-001).
2. Clear stale PID files; fix WAN watch start/stop PID ownership (AUDIT-006).
3. `chmod 600` cookie jar + enforce in `unifi_login` (AUDIT-003).
4. Stop printing raw login bodies (AUDIT-004).
5. Redact personal defaults from tracked files (AUDIT-005).

**Validation:** docs paths resolve; PID lifecycle smoke; cookie mode 600; `git grep` clean of personal email/home.

### Stage 2 — Reliability Improvements

- Replace env-exported JSON in collect (AUDIT-007).
- Document/replace Codex Playwright dependency (AUDIT-011).
- Move Awake PID to Application Support (AUDIT-010).
- Add report retention policy (AUDIT-013).

### Stage 3 — Simplification

- Freeze Phase ≥2 roadmap work (AUDIT-008).
- Prefer local-admin API path; treat UI Playwright as optional escape hatch only.
- Collapse duplicate score logic later if tests exist.

### Stage 4 — Maintainability

- Add offline unit tests for scoring/verdicts (AUDIT-009).
- Align `AGENTS.md` with real folders; add `.pios_wifi.env.example` (AUDIT-012).
- Consider `REPO_ROOT` derivation from script location instead of hardcoding (incremental).

**Do not attempt yet:** VLAN/IDS/IPS rollout; Starlink bypass; committing secrets; broad rewrites into a “platform.”

## 26. Quick Wins

1. Delete stale `data/reports/wan_watch.pid` and `src/pios_awake/pios_awake 2.pid`.
2. `chmod 600 config/.cache/unifi_cookies.txt` and `chmod 700 config/.cache`.
3. One-line doc fix for actual Awake path under `PIOS_NETWORK` (or rebuild to standard path).
4. Remove SSO email default from `unifi_set_wan_speeds_ui.zsh`.
5. Replace absolute user path in LaunchAgent example with `$HOME`-style instructions.
6. Ignore `*.pid` under `src/pios_awake/`.
7. Sanitize `unifi_login` failure logging.
8. Add `config/.pios_wifi.env.example` with keys only.
9. Mark Phase 0 gate status explicitly PASS/FAIL/RESET in `wan_stability_gate.md`.
10. Document `rg` as a prerequisite in README.

## 27. Deferred Improvements

- Full CA-pinned TLS to UniFi
- Offline pytest suite + optional CI
- Application Support migration for all runtime state
- HA MQTT integration and Lovelace
- VLAN / IDS Phase 2+
- ActivityWatch correlation
- Removing Playwright UI automation entirely if API path covers WAN caps

## 28. Unresolved Questions

1. Was the 48h WAN gate formally closed after Jul 14, or repeatedly reset (Jul 20 / Jul 28 RESET verdicts)?
2. Is `~/Applications/PIOS_NETWORK/PIOS Awake.app` intentional packaging or an accidental move?
3. Should intel LaunchAgent be loaded now, or wait until gate is explicitly closed?
4. Is the UniFi cloud console URL in `open_unifi_baseline_pages.zsh` considered sensitive for a public GitHub repo?
5. Does the public remote visibility require scrubbing historical commits if sensitive URLs were always present (likely yes for console ID/email if repo is/will be public)?

## 29. Final Recommendation

Treat this repository as a **working personal ops kit that needs a truth-and-hardening pass**, not a rewrite. Stabilize path/docs/PID/cookie handling and redact personal defaults **before** any Phase 1+ network fabric changes. Keep architecture thin; defer VLAN/IDS/HA ambition until the baseline narrative matches the machine.

**Audit completion status:** Complete (with live UniFi and Awake rebuild intentionally unverified).  
**Application source/config:** not modified; only `REPOSITORY_AUDIT.md` written.
