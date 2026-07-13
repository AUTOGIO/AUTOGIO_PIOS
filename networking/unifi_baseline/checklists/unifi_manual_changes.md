# UniFi Manual Changes

Use the UniFi UI only. Do not apply CLI changes to router settings.

## A. Rename UniFi Site

- Current: `DaNigga_Cloud_Gateway`
- Target: `PIOS-HOME-01`

## B. Rename Gateway

- Current: `DaNigga_Cloud_Gateway / UCG Ultra`
- Target: `PIOS-UCG-01`

## C. Confirm WAN

- Provider: `Starlink`
- Role: `Primary`
- Status: `Online`
- Uptime: stable

## D. Confirm LAN

- Gateway IP: `192.168.0.1`
- DHCP: enabled
- Client subnet: `192.168.0.0/24`

## E. Confirm Backups

- Auto backups: enabled

## F. Leave Untouched

- SD-WAN
- API keys
- VLANs
- Secondary WAN
- Intrusion Prevention
- CyberSecure paid upgrade
- Cloudflare integration

## G. Enable Logs Only After Renaming

- Enable UniFi site logs if available
- Do not modify alerting rules yet

## H. Set WAN ISP Speed Limits

Based on speed test **330 Mbps down / 92 Mbps up** (Jul 5, 2026), set ~80%:

- Download: **260 Mbps**
- Upload: **74 Mbps**

### UI path

1. Open **Settings** (gear) → **Internet**
2. Select **Starlink (WAN1)**
3. Scroll to **Expected ISP Speeds** (or **Provider Capabilities**)
4. Set **Download** to `260` Mbps and **Upload** to `74` Mbps
5. Click **Apply Changes**

### Script path

```bash
UNIFI_USERNAME='automacao.giovannini@gmail.com' \
  ~/AUTOGIO_PIOS/networking/unifi_baseline/scripts/unifi_set_wan_speeds_ui.zsh 260 74
```

Sign in + approve MFA in the Playwright window when prompted.

### Status (Jul 5, 2026)

- [x] Speed test baseline: 330 / 92 Mbps (also 342 / 40, 237 / 73, 355 / 84 in same session)
- [x] Target limits applied: **260 / 74 Mbps**
- [x] Verified in Topology → Starlink → Peak Utilization (260 / 74.0 Mbps capacity)
- [x] Upload alert fixed: **805% → 98%** (was caused by old 9 Mbps cap)

**Note:** Download may still show **~121% exceeded** until the 24h peak window rolls past speed-test spikes (237–355 Mbps). That is expected at 260 Mbps cap — not a misconfiguration.

## I. Local Admin (Phase 2 — API automation)

SSO account `automacao.giovannini@gmail.com` requires MFA — API scripts need a **local** admin.

1. **Local gateway Network Admins:** `https://192.168.0.1/network/default/admins` → **+ Create New**
2. Prefer **Local Site** account (not Fabric/SSO invite); fill username `pios-local-admin`
3. Role: **Super Admin** or **Site Admin** (Network)
4. Credentials file (gitignored):
   ```bash
   # Already present after Phase 2 — or copy from example:
   cp ~/AUTOGIO_PIOS/networking/unifi_baseline/.unifi.local.env.example \
      ~/AUTOGIO_PIOS/networking/unifi_baseline/.unifi.local.env
   # Edit UNIFI_USERNAME / UNIFI_PASSWORD to match the account
   ```
5. Test read-only WAN status:
   ```bash
   ~/AUTOGIO_PIOS/networking/unifi_baseline/scripts/unifi_wan_status.zsh
   ```
   Expect: `PASS_WAN_STATUS_READ`
### Status

- [x] Local admin created — **PIOS Local** (`pios-local-admin`), Source: Local Site, Role: Super Admin (Jul 13, 2026)
- [x] `.unifi.local.env` configured (gitignored)
- [x] `unifi_wan_status.zsh` returns `PASS_WAN_STATUS_READ`

