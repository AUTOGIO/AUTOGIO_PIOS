# PIOS Awake

Menu bar toggle that keeps your Mac awake using `/usr/bin/caffeinate -dims`.

**Status (2026-07-29):** Canonical install path is `~/Applications/PIOS Awake.app` (rebuild with `build.zsh`). PID file lives in `~/Library/Application Support/com.pios.awake/pios_awake.pid`.

## Install / rebuild

```bash
./src/pios_awake/build.zsh
```

Start at login:

```bash
./src/pios_awake/install_login_item.zsh
```

## Use

| Menu | Action |
|------|--------|
| **Awake: On / Off** | Start or stop `caffeinate -dims` |
| **Quit** | Exit app and stop awake (if On) |

- **Cup** icon = awake On  
- **Moon** icon = awake Off  

PID file: `~/Library/Application Support/com.pios.awake/pios_awake.pid`

Independent of the UniFi WAN watch (`wan_watch_start.zsh` has its own `caffeinate`). During a 48h gate, leave **Awake: On**.

## Uninstall login item

```bash
launchctl bootout "gui/$(id -u)/com.pios.awake" 2>/dev/null || true
rm -f ~/Library/LaunchAgents/com.pios.awake.plist
```
