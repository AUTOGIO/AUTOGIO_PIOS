#!/usr/bin/env python3
"""Advisory network score helpers (shared by daily health + tests)."""

from __future__ import annotations

import re
from typing import Any


def score_from_report(report: str, wan_ok: bool) -> dict[str, Any]:
    """Derive a simple 0–100 advisory score from a daily health report body."""
    checks = {
        "pass_baseline": "PASS_UNIFI_BASELINE_READY" in report,
        "warn_not_behind": "WARN_CLIENT_NOT_BEHIND_UNIFI" in report,
        "wan_api": wan_ok or "PASS_WAN_STATUS_READ" in report,
        "no_hard_fail": "FAIL_NETWORK_UNSTABLE" not in report,
    }

    uptime = None
    m = re.search(r"Uptime \(24h\):\s+([0-9.]+)%", report)
    if m:
        try:
            uptime = float(m.group(1))
        except ValueError:
            uptime = None

    score = 100
    deductions: list[str] = []
    if "FAIL_NETWORK_UNSTABLE" in report:
        score -= 40
        deductions.append("network_unstable:-40")
    if "WARN_CLIENT_NOT_BEHIND_UNIFI" in report:
        score -= 15
        deductions.append("not_behind_unifi:-15")
    if not checks["wan_api"]:
        score -= 10
        deductions.append("wan_api_unavailable:-10")
    if uptime is not None and uptime < 99.9:
        pen = min(20, int((99.9 - uptime) * 10))
        score -= pen
        deductions.append(f"uptime_{uptime}:-{pen}")

    score = max(0, min(100, score))
    return {
        "network_score": score,
        "uptime_24h_pct": uptime,
        "checks": checks,
        "deductions": deductions,
        "notes": [
            "Score is advisory for PIOS ops; UniFi UI remains source of truth for Topology events.",
            "Weak Wi-Fi clients / DFS / AP util appear in intelligence reports when collector is running.",
        ],
    }


def score_from_intel(
    wan_uptime_pct: float | None,
    weak_client_count: int,
) -> dict[str, Any]:
    """Advisory score used by morning intel digest."""
    score = 100
    notes: list[str] = []
    if wan_uptime_pct is not None:
        u = float(wan_uptime_pct)
        if u < 99.9:
            pen = min(25, int((99.9 - u) * 10))
            score -= pen
            notes.append(f"uptime {u}% → -{pen}")
    if weak_client_count:
        pen = min(15, weak_client_count * 2)
        score -= pen
        notes.append(f"{weak_client_count} weak clients → -{pen}")
    score = max(0, min(100, score))
    return {"network_score": score, "notes": notes}
