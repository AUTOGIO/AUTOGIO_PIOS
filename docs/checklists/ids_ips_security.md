# IDS / IPS / Threat Detection — Phase 2 (+ IPS in Phase 4)

**Do not enable during Phase 0 gate.** GeoIP blocking remains **skip / last resort** ([POST_BASELINE_ROADMAP.md](../post-baseline-roadmap.md)).

## Phase 2 — Detect only

- [ ] UniFi → **Settings → Security** (or CyberSecure / Traffic & Security)
- [ ] Enable **Intrusion Detection** / Automatic Threat Detection in **detect / notify** mode
- [ ] Confirm **IPS / Prevention (block)** is **off**
- [ ] Leave GeoIP blocking **disabled**
- [ ] Leave CyberSecure Enhanced **off** unless explicitly purchased later
- [ ] Config export dated

### Observe ~7 days

- [ ] Review threat/detection events daily or via morning intel report
- [ ] Note Starlink/CGNAT false positives
- [ ] Confirm no unexplained throughput collapse vs ISP caps (260/74)

## Phase 4 — IPS (only if IDS quiet)

- [ ] IDS quiet for ~1 week (no critical unexplained blocks needed)
- [ ] Enable IPS / Prevention
- [ ] Watch 48h: latency, WAN uptime, false blocks
- [ ] If breakage: disable IPS, keep detect-only, document offenders

## Explicitly out of scope (default)

- [x] GeoIP blocking — do not enable as a “security win”
- [ ] CyberSecure Enhanced — only with explicit need/budget

## Done when (Phase 2 slice)

- [ ] Detect-only IDS running
- [ ] IPS still off
- [ ] GeoIP still off
- [ ] One week observation log started
