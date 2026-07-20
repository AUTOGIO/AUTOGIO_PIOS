# PIOS Health Reminders + Shortcut

Native **Reminders** at **10:00 AM** and **10:00 PM** with a tappable link to run the daily health check and open the log.

## Install (one time)

```bash
~/Documents/GitHub/AUTOGIO_PIOS/scripts/install_pios_health_reminders.zsh
```

1. Accept the **Shortcut import** dialog when it opens (library name may be `PIOS UniFi Daily Health.signed`)
2. Grant **Reminders** access if macOS prompts (for the Swift helper)
3. On first run, allow **Shortcuts → Run Shell Script** if macOS asks (one-time)

**Automated fallback (no Shortcut import needed):** LaunchAgent `com.pios.unifi-daily-health` runs the same script at **10:00** and **22:00**. Double-click **`~/Applications/PIOS UniFi Daily Health.command`** for manual runs.

Creates:

- Reminders list: **PIOS Network**
- `PIOS Daily Health (10am)` — repeats daily, alert at 10:00
- `PIOS Daily Health (10pm)` — repeats daily, alert at 22:00

Each reminder note contains:

```
shortcuts://run-shortcut?name=PIOS%20UniFi%20Daily%20Health.signed
```

Tap that link on Mac or iPhone to run the check and open the newest log.

## Post-health follow-up reminder

Each time the health check runs (via Shortcut or script), a **one-shot** reminder is scheduled **15 minutes later**:

- Title: **PIOS Post-Health Follow-up**
- List: **PIOS Network**
- Checklist: UniFi Topology → Starlink disconnect review, Starlink app cross-check, optional wan_watch log

Override delay (minutes):

```bash
FOLLOWUP_DELAY_MINUTES=30 ~/Documents/GitHub/AUTOGIO_PIOS/scripts/pios_reminder_action.zsh
```

Running a new health check replaces any pending (incomplete) follow-up reminder.

## Test without waiting for alert

```bash
shortcuts run "PIOS UniFi Daily Health.signed"
```

Or run the script directly:

```bash
~/Documents/GitHub/AUTOGIO_PIOS/scripts/pios_reminder_action.zsh
```

## Files

| File | Role |
|------|------|
| `scripts/pios_reminder_action.zsh` | Runs `unifi_daily_health.zsh`, opens latest report |
| `scripts/PIOS UniFi Daily Health.shortcut` | Unsigned shortcut source |
| `scripts/PIOS UniFi Daily Health.signed.shortcut` | Signed shortcut for import |
| `scripts/create_pios_reminders.swift` | EventKit helper (daily repeat) |
| `scripts/create_pios_followup_reminder.swift` | One-shot follow-up after each health run |
| `scripts/install_pios_health_reminders.zsh` | Full installer |

## iPhone

Reminders sync via iCloud. Install the Shortcut on iPhone (same Apple ID) — it syncs after import on Mac, or open the `.signed.shortcut` file on the phone.

## Re-install

Safe to re-run the installer; it removes old `PIOS Daily Health` reminders before creating new ones.
