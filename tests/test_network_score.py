#!/usr/bin/env python3
"""Offline unit tests for advisory network score helpers."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from lib.network_score import score_from_intel, score_from_report


class TestScoreFromReport(unittest.TestCase):
    def test_perfect_baseline(self):
        report = "PASS_UNIFI_BASELINE_READY\nPASS_WAN_STATUS_READ\nUptime (24h): 100.0%\n"
        out = score_from_report(report, wan_ok=True)
        self.assertEqual(out["network_score"], 100)
        self.assertEqual(out["deductions"], [])

    def test_unstable_and_not_behind(self):
        report = "FAIL_NETWORK_UNSTABLE\nWARN_CLIENT_NOT_BEHIND_UNIFI\n"
        out = score_from_report(report, wan_ok=False)
        # -40 unstable, -15 not behind, -10 wan
        self.assertEqual(out["network_score"], 35)

    def test_uptime_penalty(self):
        report = "PASS_UNIFI_BASELINE_READY\nUptime (24h): 99.0%\n"
        out = score_from_report(report, wan_ok=True)
        self.assertLess(out["network_score"], 100)
        self.assertTrue(any(d.startswith("uptime_") for d in out["deductions"]))


class TestScoreFromIntel(unittest.TestCase):
    def test_no_penalties(self):
        out = score_from_intel(100.0, 0)
        self.assertEqual(out["network_score"], 100)

    def test_weak_clients_cap(self):
        out = score_from_intel(100.0, 20)
        self.assertEqual(out["network_score"], 85)  # min(15, 40) = 15


if __name__ == "__main__":
    unittest.main()
