#!/usr/bin/env python3
"""Unit tests for run_perf_quality_sweep.py that do not require Metal."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import run_perf_quality_sweep as sweep


class PerfQualitySweepTests(unittest.TestCase):
  def test_builtin_candidates_include_baseline_and_diffusion_group_2(self) -> None:
    names = {candidate.name for candidate in sweep.default_candidate_configs()}
    self.assertIn("baseline", names)
    self.assertIn("diffusion-group-2", names)

  def test_spectral_transmittance_manifest_compares_against_baseline(self) -> None:
    manifest = Path(__file__).resolve().parent / "perf_candidates_spectral_transmittance.json"
    candidates = sweep.load_candidate_configs([manifest])
    self.assertEqual(
        [candidate.name for candidate in candidates],
        ["baseline", "spectral-transmittance-exp2", "spectral-transmittance-fast-exp"],
    )
    baseline, exp2, fast_exp = candidates
    self.assertIn("--spectral-transmittance", baseline.perf_args)
    self.assertIn("pow", baseline.perf_args)
    self.assertEqual(baseline.env["SPEKTRAFILM_SPECTRAL_TRANSMITTANCE"], "pow")
    self.assertIn("--spectral-transmittance", exp2.perf_args)
    self.assertIn("exp2", exp2.perf_args)
    self.assertEqual(exp2.env["SPEKTRAFILM_SPECTRAL_TRANSMITTANCE"], "exp2")
    self.assertEqual(exp2.quality_policy, "exact")
    self.assertIn("--spectral-transmittance", fast_exp.perf_args)
    self.assertIn("fast-exp", fast_exp.perf_args)
    self.assertEqual(fast_exp.env["SPEKTRAFILM_SPECTRAL_TRANSMITTANCE"], "fast-exp")
    self.assertEqual(fast_exp.quality_policy, "report_only")

  def test_final_core_manifest_never_promotes_staged_diagnostic(self) -> None:
    manifest = Path(__file__).resolve().parent / "perf_candidates_final_core.json"
    candidates = sweep.load_candidate_configs([manifest])
    by_name = {candidate.name: candidate for candidate in candidates}
    self.assertEqual(by_name["staged-final-core-diagnostic"].quality_policy, "report_only")
    self.assertTrue(by_name["staged-final-core-diagnostic"].quality_required)
    self.assertEqual(by_name["staged-final-core-diagnostic"].env["SPEKTRAFILM_FINAL_CORE_MODE"], "staged")
    self.assertEqual(by_name["final-core-uniform-linear"].quality_policy, "report_only")

  def test_case_list_parsing(self) -> None:
    self.assertEqual(
        sweep.parse_case_tuple("scanner-only, dir-only"),
        ("scanner-only", "dir-only"),
    )
    self.assertEqual(sweep.safe_log_name("scanner-only"), "scanner-only")

  def test_reference_cache_defaults_under_output(self) -> None:
    args = sweep.parse_args(["--output", "/tmp/spektra-sweep-test"])
    self.assertEqual(args.reference_cache_dir, Path("/tmp/spektra-sweep-test/python_reference_cache"))
    self.assertEqual(args.python_data_dir, Path("/tmp/spektra-sweep-test/python_data"))
    self.assertEqual(args.python_runtime_cache_dir, Path("/tmp/spektra-sweep-test/python_runtime_cache"))

  def test_manifest_candidates_are_loaded_and_tag_filter_keeps_baseline(self) -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
      manifest = Path(temp_dir) / "candidates.json"
      manifest.write_text(
          json.dumps({
              "include_defaults": True,
              "candidates": [{
                  "name": "prototype",
                  "quality_policy": "report_only",
                  "tags": ["blur-prototype"],
                  "env": {"SPEKTRAFILM_BLUR_DOWNSAMPLE": "2"},
                  "perf_args": ["--blur-downsample", "2"],
              }],
          }),
          encoding="utf-8",
      )
      candidates = sweep.select_candidates(
          sweep.load_candidate_configs([manifest]),
          None,
          "blur-prototype",
      )
      self.assertEqual([candidate.name for candidate in candidates], ["baseline", "prototype"])
      self.assertEqual(candidates[1].quality_policy, "report_only")

  def test_unknown_candidate_and_tag_raise(self) -> None:
    candidates = sweep.default_candidate_configs()
    with self.assertRaises(SystemExit):
      sweep.select_candidates(candidates, "missing-candidate")
    with self.assertRaises(SystemExit):
      sweep.select_candidates(candidates, None, "missing-tag")

  def test_report_only_candidates_are_excluded_from_best_configs(self) -> None:
    baseline = sweep.CandidateConfig(name="baseline", quality_policy="exact")
    approximate = sweep.CandidateConfig(name="approximate", quality_policy="report_only")
    rows = [
        {
            "candidate": "baseline",
            "perf_status": "OK",
            "case": "all-effects",
            "width": 1920,
            "height": 1080,
            "avg_wall_ms": 10.0,
            "source_format": "float",
            "destination_format": "float",
            "host_layout": "contiguous",
        },
        {
            "candidate": "approximate",
            "perf_status": "OK",
            "case": "all-effects",
            "width": 1920,
            "height": 1080,
            "avg_wall_ms": 5.0,
            "source_format": "float",
            "destination_format": "float",
            "host_layout": "contiguous",
        },
    ]
    quality = {
        "baseline": {"status": "PASSED"},
        "approximate": {"status": "PASSED"},
    }
    best = sweep.select_best_configs(rows, quality, {"baseline": baseline, "approximate": approximate})
    self.assertEqual([row["candidate"] for row in best], ["baseline"])

  def test_candidate_comparison_adds_baseline_deltas_and_promotable(self) -> None:
    baseline = sweep.CandidateConfig(name="baseline", quality_policy="exact")
    exact = sweep.CandidateConfig(name="exact", quality_policy="exact")
    approximate = sweep.CandidateConfig(name="approximate", quality_policy="report_only")
    rows = [
        {
            "candidate": "baseline",
            "perf_status": "OK",
            "quality_status": "PASSED",
            "case": "scanner-only",
            "width": 1920,
            "height": 1080,
            "avg_wall_ms": 20.0,
            "avg_pass_count": 100.0,
            "density_curve_lookup": "binary",
            "spectral_transmittance": "pow",
        },
        {
            "candidate": "exact",
            "perf_status": "OK",
            "quality_status": "PASSED",
            "case": "scanner-only",
            "width": 1920,
            "height": 1080,
            "avg_wall_ms": 10.0,
            "avg_pass_count": 90.0,
            "density_curve_lookup": "binary",
            "spectral_transmittance": "exp2",
        },
        {
            "candidate": "approximate",
            "perf_status": "OK",
            "quality_status": "PASSED",
            "case": "scanner-only",
            "width": 1920,
            "height": 1080,
            "avg_wall_ms": 8.0,
            "avg_pass_count": 80.0,
            "density_curve_lookup": "binary",
            "spectral_transmittance": "fast-exp",
        },
    ]
    comparison = sweep.build_candidate_comparison(
        rows,
        {
            "baseline": {"status": "PASSED"},
            "exact": {"status": "PASSED"},
            "approximate": {"status": "PASSED"},
        },
        {"baseline": baseline, "exact": exact, "approximate": approximate},
    )
    exact_row = next(row for row in comparison if row["candidate"] == "exact")
    approximate_row = next(row for row in comparison if row["candidate"] == "approximate")
    self.assertEqual(exact_row["promotable"], 1)
    self.assertAlmostEqual(exact_row["speedup"], 2.0)
    self.assertAlmostEqual(exact_row["wall_delta_pct"], -50.0)
    self.assertAlmostEqual(exact_row["pass_count_delta"], -10.0)
    self.assertEqual(exact_row["density_curve_lookup"], "binary")
    self.assertEqual(exact_row["spectral_transmittance"], "exp2")
    self.assertEqual(approximate_row["promotable"], 0)


if __name__ == "__main__":
  unittest.main()
