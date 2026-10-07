#!/usr/bin/env python3
"""Run focused Metal profiling for the fused final-from-film-density core."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
from pathlib import Path
from typing import Any


STAGED_PASSES = (
    "spektrafilm_print_raw_from_film_density",
    "spektrafilm_print_density_from_print_raw",
    "spektrafilm_profile_print_scan_from_density",
    "spektrafilm_profile_finalize_output",
)
FUSED_PASS = "spektrafilm_final_from_film_density"
THREADGROUPS = ("auto", "16x16", "32x8", "8x32", "64x4")


def load_json(path: Path) -> dict[str, Any]:
  return json.loads(path.read_text(encoding="utf-8"))


def first_case(summary: dict[str, Any]) -> dict[str, Any]:
  cases = summary.get("cases", [])
  if not cases:
    raise ValueError("Profile summary has no cases.")
  return dict(cases[0])


def pass_by_name(passes: dict[str, Any], name: str) -> dict[str, Any] | None:
  return next((dict(row) for row in passes.get("passes", []) if row.get("name") == name), None)


def build_comparison(fused_dir: Path, fused_detail_dir: Path, staged_dir: Path) -> dict[str, Any]:
  fused_summary = first_case(load_json(fused_dir / "summary.json"))
  fused_detail = pass_by_name(load_json(fused_detail_dir / "passes.json"), FUSED_PASS)
  staged_passes = load_json(staged_dir / "passes.json")
  stages = []
  staged_total_ms = 0.0
  for name in STAGED_PASSES:
    row = pass_by_name(staged_passes, name)
    if row is None:
      raise ValueError(f"Staged report is missing {name}.")
    staged_total_ms += float(row["avg_ms"])
    stages.append(row)
  for row in stages:
    row["percent_of_staged_total"] = float(row["avg_ms"]) / staged_total_ms * 100.0 if staged_total_ms else 0.0
  fused_kernel_ms = float(fused_detail["avg_ms"]) if fused_detail else 0.0
  return {
      "fused_representative": fused_summary,
      "fused_kernel": fused_detail,
      "staged_total_ms": staged_total_ms,
      "staged_overhead_ms": staged_total_ms - fused_kernel_ms,
      "staged_overhead_pct": ((staged_total_ms / fused_kernel_ms) - 1.0) * 100.0 if fused_kernel_ms else 0.0,
      "stages": stages,
  }


def write_comparison(output: Path, comparison: dict[str, Any]) -> None:
  (output / "comparison.json").write_text(json.dumps(comparison, indent=2) + "\n", encoding="utf-8")
  fused = comparison.get("fused_kernel") or {}
  representative = comparison["fused_representative"]
  lines = [
      "# Final Core Profile Comparison",
      "",
      f"- Representative fused frame average: {representative.get('avg_wall_ms', 0.0):.3f} ms",
      f"- Representative fused frame P95: {representative.get('wall_stats', {}).get('p95_ms', 0.0):.3f} ms",
      f"- Representative fused frame CoV: {representative.get('wall_stats', {}).get('cov', 0.0):.4f}",
      f"- Fused final-core kernel average: {float(fused.get('avg_ms', 0.0)):.3f} ms",
      f"- Staged final-core total: {comparison['staged_total_ms']:.3f} ms",
      f"- Staging overhead: {comparison['staged_overhead_ms']:.3f} ms ({comparison['staged_overhead_pct']:.2f}%)",
      "",
      "| Stage | Avg ms | P95 ms | % staged total |",
      "| --- | ---: | ---: | ---: |",
  ]
  for row in comparison["stages"]:
    lines.append(
        f"| `{row['name']}` | {float(row['avg_ms']):.3f} | {float(row['p95_ms']):.3f} | "
        f"{float(row['percent_of_staged_total']):.2f} |"
    )
  (output / "comparison.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def run(command: list[str], cwd: Path, log_path: Path, env: dict[str, str] | None = None) -> None:
  completed = subprocess.run(
      command,
      cwd=str(cwd),
      env=env,
      text=True,
      stdout=subprocess.PIPE,
      stderr=subprocess.PIPE,
      check=False,
  )
  log_path.with_suffix(".stdout.log").write_text(completed.stdout or "", encoding="utf-8")
  log_path.with_suffix(".stderr.log").write_text(completed.stderr or "", encoding="utf-8")
  if completed.returncode != 0:
    raise SystemExit(f"Command failed ({completed.returncode}): {' '.join(command)}")


def harness_command(
    harness: Path,
    report_dir: Path,
    width: int,
    height: int,
    warmup: int,
    iterations: int,
    mode: str,
    pass_timing: str,
    threadgroup: str = "auto",
) -> list[str]:
  return [
      str(harness),
      "--case", "standard-core",
      "--width", str(width),
      "--height", str(height),
      "--warmup", str(warmup),
      "--iterations", str(iterations),
      "--final-core-mode", mode,
      "--pass-timing", pass_timing,
      "--threadgroup", threadgroup,
      "--profile-report", str(report_dir),
  ]


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument("--build-dir", type=Path, default=Path("build-profile"))
  parser.add_argument("--output", type=Path, required=True)
  parser.add_argument("--width", type=int, default=3840)
  parser.add_argument("--height", type=int, default=2160)
  parser.add_argument("--warmup", type=int, default=10)
  parser.add_argument("--iterations", type=int, default=120)
  parser.add_argument("--detail-warmup", type=int, default=3)
  parser.add_argument("--detail-iterations", type=int, default=10)
  parser.add_argument("--capture-gputrace", action="store_true")
  parser.add_argument("--skip-runs", action="store_true", help="Only rebuild comparison files from existing reports.")
  return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
  args = parse_args(argv)
  root = Path(__file__).resolve().parents[1]
  harness = args.build_dir / "SpektraFilmPerfHarness"
  args.output.mkdir(parents=True, exist_ok=True)
  fused_dir = args.output / "fused-representative"
  fused_detail_dir = args.output / "fused-detail"
  staged_dir = args.output / "staged-detail"
  if not args.skip_runs:
    runs = [
        ("fused-representative", harness_command(harness, fused_dir, args.width, args.height, args.warmup, args.iterations, "fused", "off")),
        ("fused-detail", harness_command(harness, fused_detail_dir, args.width, args.height, args.detail_warmup, args.detail_iterations, "fused", "auto")),
        ("staged-detail", harness_command(harness, staged_dir, args.width, args.height, args.detail_warmup, args.detail_iterations, "staged", "auto")),
    ]
    for name, command in runs:
      run(command, root, args.output / name)
    for threadgroup in THREADGROUPS:
      report = args.output / "threadgroups" / threadgroup
      run(
          harness_command(harness, report, args.width, args.height, args.detail_warmup, args.detail_iterations, "fused", "auto", threadgroup),
          root,
          args.output / f"threadgroup-{threadgroup}",
      )
    if args.capture_gputrace:
      trace = args.output / "fused-final-core.gputrace"
      command = harness_command(harness, args.output / "capture-report", args.width, args.height, 3, 1, "fused", "off")
      command.extend(["--capture-gputrace", str(trace), "--capture-iteration", "0"])
      env = dict(os.environ)
      env["MTL_CAPTURE_ENABLED"] = "1"
      run(command, root, args.output / "capture", env)
  comparison = build_comparison(fused_dir, fused_detail_dir, staged_dir)
  write_comparison(args.output, comparison)
  print(f"Wrote final-core profiling report to {args.output}")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
