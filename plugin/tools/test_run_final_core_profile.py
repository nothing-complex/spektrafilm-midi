#!/usr/bin/env python3
"""Unit tests for run_final_core_profile.py that do not require Metal."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import run_final_core_profile as profile


class FinalCoreProfileTests(unittest.TestCase):
  def test_harness_command_selects_staged_mode(self) -> None:
    command = profile.harness_command(Path("harness"), Path("report"), 3840, 2160, 3, 10, "staged", "auto")
    self.assertIn("--final-core-mode", command)
    self.assertIn("staged", command)
    self.assertIn("--pass-timing", command)

  def test_build_comparison_calculates_stage_percentages_and_overhead(self) -> None:
    with tempfile.TemporaryDirectory() as temp:
      root = Path(temp)
      fused = root / "fused"
      detail = root / "detail"
      staged = root / "staged"
      for directory in (fused, detail, staged):
        directory.mkdir()
      (fused / "summary.json").write_text(json.dumps({"cases": [{"avg_wall_ms": 20.0}]}), encoding="utf-8")
      (detail / "passes.json").write_text(json.dumps({"passes": [{"name": profile.FUSED_PASS, "avg_ms": 10.0}]}), encoding="utf-8")
      (staged / "passes.json").write_text(json.dumps({
          "passes": [{"name": name, "avg_ms": 3.0, "p95_ms": 4.0} for name in profile.STAGED_PASSES],
      }), encoding="utf-8")
      comparison = profile.build_comparison(fused, detail, staged)
      self.assertEqual(comparison["staged_total_ms"], 12.0)
      self.assertEqual(comparison["staged_overhead_ms"], 2.0)
      self.assertAlmostEqual(comparison["staged_overhead_pct"], 20.0)
      self.assertTrue(all(row["percent_of_staged_total"] == 25.0 for row in comparison["stages"]))


if __name__ == "__main__":
  unittest.main()
