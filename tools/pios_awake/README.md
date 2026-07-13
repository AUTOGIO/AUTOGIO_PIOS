# PIOS Awake

Menu bar toggle that keeps your Mac awake using `/usr/bin/caffeinate -dims`.

**Status (Jul 13, 2026):** Installed at `~/Applications/PIOS Awake.app` — verified On/Off toggles `caffeinate -dims`.

## Install / rebuild

```bash
~/AUTOGIO_PIOS/tools/pios_awake/build.zsh
```

Start at login:

```bash
~/AUTOGIO_PIOS/tools/pios_awake/install_login_item.zsh
```

## Use

| Menu | Action |
|------|--------|
| **Awake: On / Off** | Start or stop `caffeinate -dims` |
| **Quit** | Exit app and stop awake (if On) |

- **Cup** icon = awake On  
- **Moon** icon = awake Off  

PID file: `~/AUTOGIO_PIOS/tools/pios_awake/pios_awake.pid`

Independent of the UniFi WAN watch (`wan_watch_start.zsh` has its own `caffeinate`). During the 48h gate, leave **Awake: On**.

## Uninstall login item

```bash
launchctl bootout "gui/$(id -u)/com.pios.awake" 2>/dev/null || true
rm -f ~/Library/LaunchAgents/com.pios.awake.plist
```
