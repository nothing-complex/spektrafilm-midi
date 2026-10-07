#!/usr/bin/env python3
"""Build macOS optimization variants and run the perf/quality sweep for each."""

from __future__ import annotations

import argparse
import datetime as _datetime
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


OFX_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_BUILD_ROOT = OFX_ROOT / "build_perf_variants"
DEFAULT_SWEEP_RUNNER = OFX_ROOT / "tools" / "run_perf_quality_sweep.py"

VARIANTS: dict[str, dict[str, str]] = {
    "release": {},
    "native-fast-math": {"SPEKTRAFILM_NATIVE_FAST_MATH": "ON"},
    "metal-fast-math": {"SPEKTRAFILM_METAL_FAST_MATH": "ON"},
    "all-fast-math": {
        "SPEKTRAFILM_NATIVE_FAST_MATH": "ON",
        "SPEKTRAFILM_METAL_FAST_MATH": "ON",
    },
}

DEFAULT_SWEEP_ARGS = [
    "--case", "all",
    "--sizes", "1920x1080,3840x2160",
    "--iterations", "3",
    "--warmup", "1",
    "--parity-mode", "quick",
]


def parse_csv(value: str | None) -> list[str]:
  if not value:
    return []
  return [item.strip() for item in value.split(",") if item.strip()]


def run_command(command: list[str], cwd: Path, log_dir: Path, name: str) -> subprocess.CompletedProcess[str]:
  log_dir.mkdir(parents=True, exist_ok=True)
  completed = subprocess.run(
      command,
      cwd=str(cwd),
      text=True,
      stdout=subprocess.PIPE,
      stderr=subprocess.PIPE,
      check=False,
  )
  (log_dir / f"{name}.stdout.log").write_text(completed.stdout or "", encoding="utf-8")
  (log_dir / f"{name}.stderr.log").write_text(completed.stderr or "", encoding="utf-8")
  return completed


def variant_cmake_args(name: str, build_type: str) -> list[str]:
  args = [f"-DCMAKE_BUILD_TYPE={build_type}"]
  for key, value in VARIANTS[name].items():
    args.append(f"-D{key}={value}")
  return args


def parse_args(argv: list[str] | None = None) -> tuple[argparse.Namespace, list[str]]:
  parser = argparse.ArgumentParser(
      description=__doc__,
      epilog="Arguments after -- are passed through to run_perf_quality_sweep.py.",
  )
  parser.add_argument("--output", type=Path, required=True, help="Directory for compile-variant reports.")
  parser.add_argument("--build-root", type=Path, default=DEFAULT_BUILD_ROOT, help="Parent directory for generated build dirs.")
  parser.add_argument("--sweep-runner", type=Path, default=DEFAULT_SWEEP_RUNNER)
  parser.add_argument("--variants", default="release,native-fast-math,metal-fast-math,all-fast-math")
  parser.add_argument("--build-type", default="Release")
  parser.add_argument("--parallel", default="", help="Optional CMake --parallel value. Empty lets CMake choose.")
  parser.add_argument("--skip-build", action="store_true", help="Reuse existing build dirs and only run sweeps.")
  parser.add_argument("--stop-on-failure", action="store_true")
  args, sweep_args = parser.parse_known_args(argv)
  if sweep_args and sweep_args[0] == "--":
    sweep_args = sweep_args[1:]
  unknown = sorted(set(parse_csv(args.variants)) - set(VARIANTS))
  if unknown:
    raise SystemExit(f"Unknown variant(s): {', '.join(unknown)}")
  return args, sweep_args or DEFAULT_SWEEP_ARGS


def write_json(path: Path, payload: Any) -> None:
  path.write_text(json.dumps(payload, indent=2, allow_nan=True) + "\n", encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
  args, sweep_args = parse_args(argv)
  args.output.mkdir(parents=True, exist_ok=True)
  args.build_root.mkdir(parents=True, exist_ok=True)
  selected_variants = parse_csv(args.variants)
  manifest = {
      "schema_version": 1,
      "created_at_utc": _datetime.datetime.now(_datetime.timezone.utc).isoformat(),
      "build_root": str(args.build_root),
      "sweep_runner": str(args.sweep_runner),
      "build_type": args.build_type,
      "variants": {name: VARIANTS[name] for name in selected_variants},
      "sweep_args": sweep_args,
  }
  write_json(args.output / "compile_sweep_manifest.json", manifest)

  summary: list[dict[str, Any]] = []
  for variant in selected_variants:
    variant_output = args.output / variant
    variant_logs = variant_output / "logs"
    build_dir = args.build_root / variant
    variant_output.mkdir(parents=True, exist_ok=True)
    status = {
        "variant": variant,
        "build_dir": str(build_dir),
        "output_dir": str(variant_output),
        "configure_returncode": 0,
        "build_returncode": 0,
        "sweep_returncode": 0,
        "status": "PASSED",
    }

    if not args.skip_build:
      configure = run_command(
          ["cmake", "-S", str(OFX_ROOT), "-B", str(build_dir), *variant_cmake_args(variant, args.build_type)],
          OFX_ROOT,
          variant_logs,
          "configure",
      )
      status["configure_returncode"] = configure.returncode
      if configure.returncode != 0:
        status["status"] = "CONFIGURE_FAILED"
        summary.append(status)
        if args.stop_on_failure:
          break
        continue

      build_command = [
          "cmake", "--build", str(build_dir),
          "--target", "SpektraFilmPerfHarness", "SpektraFilmParityHarness",
          "--parallel",
      ]
      if args.parallel:
        build_command.append(args.parallel)
      build = run_command(build_command, OFX_ROOT, variant_logs, "build")
      status["build_returncode"] = build.returncode
      if build.returncode != 0:
        status["status"] = "BUILD_FAILED"
        summary.append(status)
        if args.stop_on_failure:
          break
        continue

    sweep = run_command(
        [
            sys.executable,
            str(args.sweep_runner),
            "--output", str(variant_output / "sweep"),
            "--build-dir", str(build_dir),
            *sweep_args,
        ],
        OFX_ROOT,
        variant_logs,
        "sweep",
    )
    status["sweep_returncode"] = sweep.returncode
    if sweep.returncode != 0:
      status["status"] = "SWEEP_FAILED"
    summary.append(status)
    write_json(args.output / "compile_sweep_summary.json", summary)
    if sweep.returncode != 0 and args.stop_on_failure:
      break

  write_json(args.output / "compile_sweep_summary.json", summary)
  failed = sum(1 for row in summary if row["status"] != "PASSED")
  print(f"Wrote compile sweep report to {args.output} ({failed} variant failures).")
  return 1 if failed else 0


if __name__ == "__main__":
  raise SystemExit(main())
