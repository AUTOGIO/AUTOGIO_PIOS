# Pre-Bypass Correction

Use this checklist if the Mac is still on Starlink Wi-Fi instead of behind UniFi LAN.

1. Do not enable Starlink Bypass Mode yet.
2. Confirm UniFi WAN is online.
3. Connect the Mac to UniFi LAN using a USB-C Ethernet adapter if no UniFi AP exists.
4. Turn off Wi-Fi temporarily on the Mac.
5. Confirm the Mac receives:
   - IP: `192.168.0.x`
   - Gateway: `192.168.0.1`
6. Confirm the Mac appears in UniFi Clients.
7. Confirm at least one control path remains available after Starlink Wi-Fi is disabled.
8. Only after that, consider Starlink Bypass Mode.

## Stop Condition

Stop immediately if the Mac loses all management paths and no alternate device is confirmed behind UniFi.

