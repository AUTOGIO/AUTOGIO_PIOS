# Remediation & Upgrade Summary — 2026-07-29

Final summary of work done after the repository audit (`REPOSITORY_AUDIT.md`).  
This closes remaining operational fixes and records verification results.

---

## Verdict

**Stabilization complete for the current personal-ops toolkit.**  
Critical and high-priority audit items are addressed in code, local install state, and docs.  
Phase ≥2 fabric work (VLANs / IDS / cameras) remains intentionally frozen until Phase 0 gate is explicitly **PASS**.

| Area | Before | After |
|------|--------|-------|
| PIOS Awake install | Drifted under `~/Applications/PIOS_NETWORK/` | Canonical `~/Applications/PIOS Awake.app` + login LaunchAgent |
| Cookie jar | mode `644` | mode `600`, cache dir `700`, enforced on login |
| WAN API session | Broken under Homebrew GNU `stat` + `set -u` | Fixed (`/usr/bin/stat`); live `PASS_WAN_STATUS_READ` |
| Gate status docs | Stale “in progress” Jul 12–14 | Explicit **RESET / reopen required** |
| Personal identifiers in tree | Home path, SSO email, cloud console ID | Removed from tracked sources / helpers |
| Tests | None | 5 offline unit tests (passing) |

---

## What was upgraded

### Security & session handling
- Shared `unifi_curl` helper; optional `UNIFI_CA_CERT` to avoid blind `-k` when a PEM is available
- Login failures log sanitized API **code** only (no raw body in reports)
- Cookie permissions hardened on every login / ensure-session
- Removed SSO email default from UI WAN script; require `UNIFI_USERNAME`
- Removed hardcoded UniFi cloud console ID from repo script and local `.command` helper

### Reliability & paths
- All main scripts resolve `BASE_DIR` from `$0` (repo can move; override via `REPO_ROOT`)
- WAN watch: caffeinate owns PID; start clears stale PIDs; stop kills children + parent
- Fixed **Homebrew gnubin `stat`** bug that broke `unifi_ensure_session` (`File: parameter not set`)
- Intel `collect.zsh` writes API JSON to temp files instead of huge env vars
- Shared score logic in `scripts/lib/network_score.py` (daily health + morning report)

### macOS / Awake
- Rebuilt Awake to `~/Applications/PIOS Awake.app`
- Removed duplicate `~/Applications/PIOS_NETWORK/PIOS Awake.app`
- PID file → `~/Library/Application Support/com.pios.awake/pios_awake.pid`
- Installed `com.pios.awake` login LaunchAgent
- Refreshed `com.pios.unifi-daily-health` LaunchAgent (10:00 / 22:00) with Homebrew PATH

### Docs & hygiene
- README / AGENTS / baseline / gate / roadmap updated (Phase ≥2 freeze; gate RESET)
- Added `config/.pios_wifi.env.example`, daily-health + intel LaunchAgent examples with `__REPO_ROOT__`
- Added `scripts/prune_reports.zsh` (30-day default retention)
- `.gitignore` covers `src/pios_awake/*.pid` and Python caches

### Testing
- `tests/test_network_score.py` — 5 tests, all green

---

## Live verification (2026-07-29)

| Check | Result |
|-------|--------|
| `python3 -m unittest discover -s tests -v` | OK (5 tests) |
| `zsh -n` on critical scripts | OK |
| `./scripts/unifi_wan_status.zsh` | `PASS_WAN_STATUS_READ` (Starlink 260/74, uptime 100%) |
| Cookie mode after login | `-rw-------` (`600`) |
| `./scripts/collect.zsh` | `COLLECT_OK` sample_id=3, 11 clients |
| `./scripts/report_morning.zsh` | Score 100%, report generated |
| Canonical Awake binary | Present and launched |
| Duplicate Awake under `PIOS_NETWORK` | Removed |
| LaunchAgents `com.pios.awake` / `com.pios.unifi-daily-health` | Loaded |

---

## Files touched (high level)

- **Core:** `scripts/unifi_common.zsh`, WAN watch trio, `collect.zsh`, health/morning reports, set-wan scripts, `open_unifi_baseline_pages.zsh`
- **App:** `src/pios_awake/Sources/main.swift` (+ rebuild via `build.zsh`)
- **New:** `scripts/lib/network_score.py`, `scripts/prune_reports.zsh`, `tests/`, env/plist examples, this summary
- **Docs:** README, AGENTS, baseline, gate, roadmap, Awake, intelligence, manual-changes checklist
- **Local machine (not in git):** LaunchAgents, `~/Applications/PIOS Awake.app`, cleaned duplicate app, sanitized `.command` helper

---

## Still deferred (by design)

| Item | Why |
|------|-----|
| Full CA-pinned TLS with no `-k` fallback | Needs exporting/trusting UniFi local CA; `UNIFI_CA_CERT` is ready when you have a PEM |
| Phase 1+ fabric (DHCP bulk, WPA3, VLANs, IDS) | Gate is **RESET** — reopen 48h watch first |
| Git history scrub of old console URL / email | Requires history rewrite + force-push; only if repo is/will be public and you want it gone from old commits |
| Committing these changes | Not done unless you ask |

---

## Operator next steps

1. **Optional commit** of the remediation diff when ready.
2. **Re-open Phase 0 gate** when you want a clean 48h PASS:
   ```bash
   INTERVAL_SECONDS=120 ITERATIONS=3 ./scripts/wan_watch_48h.zsh   # smoke
   ./scripts/wan_watch_start.zsh                                  # full 48h
   ```
3. After PASS, mark the gate checklist and only then consider Phase 1.
4. Optional: export UniFi local CA → set `UNIFI_CA_CERT` in `.unifi.local.env`.
5. Optional: load intel collector LaunchAgent after gate PASS (see `config/com.pios.unifi-intel-collect.plist.example`).

---

## Finding closure map (audit IDs)

| ID | Status |
|----|--------|
| AUDIT-001 Awake / gate drift | **Fixed** |
| AUDIT-002 TLS `-k` | **Mitigated** (helper + `UNIFI_CA_CERT`; full pin deferred) |
| AUDIT-003 Cookie permissions | **Fixed** |
| AUDIT-004 Login body dump | **Fixed** |
| AUDIT-005 Personal identifiers | **Fixed** in working tree |
| AUDIT-006 WAN PID lifecycle | **Fixed** |
| AUDIT-007 JSON via env | **Fixed** |
| AUDIT-008 Ambition mismatch | **Documented freeze** |
| AUDIT-009 No tests | **Fixed** (minimal suite) |
| AUDIT-010 Awake PID path | **Fixed** |
| AUDIT-011 Playwright / SSO default | **Fixed** |
| AUDIT-012 Missing examples / AGENTS drift | **Fixed** |
| AUDIT-013 Hygiene / PIDs / prune | **Fixed** |
| AUDIT-014 Shell / `en5` / gnubin stat | **Fixed** |
| AUDIT-015 Stale docs | **Fixed** |
| *(new)* GNU `stat` session crash | **Fixed** during remaining-actions pass |

---

*Generated 2026-07-29 after audit remediation + remaining operational fixes.*
