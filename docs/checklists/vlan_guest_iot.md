# Guest + IoT VLANs — Phase 2

**Do not create VLANs until Phase 0 is green.** Ship **Guest first**, then **IoT**. Keep Personal + AI on Default until proven.

## Target

| VLAN ID | Name | Subnet (suggested) | SSID | Isolation |
|---------|------|--------------------|------|-----------|
| 30 | Guest | `192.168.30.0/24` | `PIOS-GUEST` | Client isolation **on**; internet only |
| 20 | IoT | `192.168.20.0/24` | `PIOS-IOT` | Client isolation **on** |

Do **not** enable isolation on `PIOS-HOME` (Personal).

## A — Guest VLAN 30

- [ ] **Settings → Networks → Create New** — VLAN 30 `Guest` / `PIOS-GUEST-NET`
- [ ] DHCP on; gateway `192.168.30.1`
- [ ] Create Wi‑Fi `PIOS-GUEST` → network Guest; guest policy / isolation on
- [ ] Firewall: Guest → LAN **deny**; Guest → WAN **allow**
- [ ] Test phone on guest SSID: internet works; cannot reach `192.168.0.1` admin or LAN hosts
- [ ] Config export

## B — IoT VLAN 20

- [ ] Create VLAN 20 `IoT` — `192.168.20.0/24`, gateway `192.168.20.1`
- [ ] Create Wi‑Fi `PIOS-IOT` → IoT network; **client isolation on**
- [ ] Move IoT devices (lights, plugs, speakers, non-critical gadgets) one at a time
- [ ] Printer: IoT **or** Personal — prefer Personal if AirPrint from Macs is primary

### Firewall / discovery (required for Home Assistant)

- [ ] Allow **Home Assistant host** (fixed IP on Default, e.g. `192.168.0.20`) → IoT subnet (needed ports or established)
- [ ] Allow return traffic IoT → HA only as required
- [ ] Deny IoT → Personal LAN (except HA allowlist)
- [ ] Deny IoT → Guest
- [ ] mDNS / IGMP: enable reflector or UniFi mDNS carefully so HA can discover devices **without** opening Guest
- [ ] Multicast Enhancement on IoT SSID if casting/speakers need it

### Validation

- [ ] HA can control a test IoT device on VLAN 20
- [ ] IoT device cannot reach Mac SMB / NAS shares
- [ ] Personal AirPlay/Continuity on `PIOS-HOME` still works
- [ ] Config export

## Recovery

- [ ] Document how to move a device back to Default/`PIOS-HOME` if broken
- [ ] Mac Ethernet control path remains on Default `192.168.0.189`

## Done when

- [ ] Guest proven internet-only
- [ ] IoT proven with HA allow rules
- [ ] Isolation **not** enabled on Personal SSID
- [ ] Personal/AI still on Default (Phase 4 later)
