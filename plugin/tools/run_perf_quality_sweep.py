#!/usr/bin/env python3
"""Sweep SpektraFilm Metal performance configs while enforcing parity quality."""

from __future__ import annotations

import argparse
import csv
import datetime as _datetime
import json
import os
import platform
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


OFX_ROOT = Path(__file__).resolve().parents[1]
TOOLS_DIR = OFX_ROOT / "tools"
DEFAULT_BUILD_DIR = OFX_ROOT / "build"
DEFAULT_PERF_HARNESS = DEFAULT_BUILD_DIR / "SpektraFilmPerfHarness"
DEFAULT_PARITY_HARNESS = DEFAULT_BUILD_DIR / "SpektraFilmParityHarness"
DEFAULT_PARITY_RUNNER = TOOLS_DIR / "run_parity_harness.py"

INT_FIELDS = {"width", "height", "iterations", "diffusion_group_size"}
TEXT_FIELDS = {
    "case",
    "candidate",
    "perf_status",
    "quality_status",
    "quality_policy",
    "pass_timing_mode",
    "threadgroup",
    "scanner_image_storage",
    "blur_backend",
    "blur_downsample",
    "intermediate_precision",
    "diffusion_cluster_sigma",
    "dir_tail_backend",
    "density_curve_lookup",
    "spectral_transmittance",
    "final_core_mode",
    "source_format",
    "destination_format",
    "host_layout",
    "grain_synthesis_sampler",
    "grain_synthesis_radius_lut",
    "grain_synthesis_target_storage",
    "grain_synthesis_cell_mode",
}
QUALITY_OK_STATUSES = {"PASSED", "SKIPPED"}
QUALITY_POLICIES = {"exact", "report_only"}


@dataclass(frozen=True)
class CandidateConfig:
  name: str
  env: dict[str, str] = field(default_factory=dict)
  perf_args: tuple[str, ...] = ()
  quality_args: tuple[str, ...] = ()
  quality_required: bool = True
  quality_policy: str = "exact"
  tags: tuple[str, ...] = ()


def _candidate(
  name: str,
  env: dict[str, str] | None = None,
  perf_args: tuple[str, ...] = (),
  quality_args: tuple[str, ...] = (),
  quality_required: bool = True,
  quality_policy: str = "exact",
  tags: tuple[str, ...] = (),
) -> CandidateConfig:
  if quality_policy not in QUALITY_POLICIES:
    raise ValueError(f"Unknown quality policy {quality_policy!r}.")
  return CandidateConfig(
      name=name,
      env=env or {},
      perf_args=perf_args,
      quality_args=quality_args,
      quality_required=quality_required,
      quality_policy=quality_policy,
      tags=tags,
  )


def default_candidate_configs() -> list[CandidateConfig]:
  baseline_env = {
      "SPEKTRAFILM_SCRATCH_STORAGE": "private",
      "SPEKTRAFILM_THREADGROUP": "auto",
      "SPEKTRAFILM_SCANNER_IMAGE_STORAGE": "buffer",
      "SPEKTRAFILM_DIFFUSION_GROUP_SIZE": "1",
      "SPEKTRAFILM_DIR_TAIL_BACKEND": "fused",
      "SPEKTRAFILM_BLUR_BACKEND": "custom",
      "SPEKTRAFILM_BLUR_DOWNSAMPLE": "off",
      "SPEKTRAFILM_INTERMEDIATE_PRECISION": "float",
      "SPEKTRAFILM_DIFFUSION_CLUSTER_SIGMA": "off",
      "SPEKTRAFILM_HALATION_GROUPED_TAIL": "0",
      "SPEKTRAFILM_SCANNER_MPS": "0",
      "SPEKTRAFILM_GRAIN_BLUR_RECURRENCE": "0",
      "SPEKTRAFILM_DENSITY_CURVE_LOOKUP": "binary",
      "SPEKTRAFILM_SPECTRAL_TRANSMITTANCE": "pow",
      "SPEKTRAFILM_GRAIN_SYNTHESIS_SAMPLER": "r2",
      "SPEKTRAFILM_GRAIN_SYNTHESIS_RADIUS_LUT": "512",
      "SPEKTRAFILM_GRAIN_SYNTHESIS_TARGET_STORAGE": "float-buffer",
      "SPEKTRAFILM_GRAIN_SYNTHESIS_CELL_MODE": "offset-list",
  }
  baseline_options = {
      "scratch_storage": "private",
      "threadgroup": "auto",
      "scanner_image_storage": "buffer",
      "diffusion_group_size": "1",
      "grain_synthesis_sampler": "r2",
      "grain_synthesis_radius_lut": "512",
      "grain_synthesis_target_storage": "float-buffer",
      "grain_synthesis_cell_mode": "offset-list",
      "blur_backend": "custom",
      "blur_downsample": "off",
      "intermediate_precision": "float",
      "diffusion_cluster_sigma": "off",
      "halation_grouped_tail": "0",
      "scanner_mps": "0",
      "grain_blur_recurrence": "0",
      "dir_tail_backend": "fused",
      "density_curve_lookup": "binary",
      "spectral_transmittance": "pow",
      "source_format": "float",
      "destination_format": "float",
      "host_layout": "contiguous",
  }

  def perf_args(**overrides: str) -> tuple[str, ...]:
    values = {**baseline_options, **overrides}
    return (
        "--scratch-storage", values["scratch_storage"],
        "--threadgroup", values["threadgroup"],
        "--scanner-image-storage", values["scanner_image_storage"],
        "--diffusion-group-size", values["diffusion_group_size"],
        "--blur-backend", values["blur_backend"],
        "--blur-downsample", values["blur_downsample"],
        "--intermediate-precision", values["intermediate_precision"],
        "--diffusion-cluster-sigma", values["diffusion_cluster_sigma"],
        "--halation-grouped-tail", values["halation_grouped_tail"],
        "--scanner-mps", values["scanner_mps"],
        "--grain-blur-recurrence", values["grain_blur_recurrence"],
        "--dir-tail-backend", values["dir_tail_backend"],
        "--density-curve-lookup", values["density_curve_lookup"],
        "--spectral-transmittance", values["spectral_transmittance"],
        "--source-format", values["source_format"],
        "--destination-format", values["destination_format"],
        "--host-layout", values["host_layout"],
        "--grain-synthesis-sampler", values["grain_synthesis_sampler"],
        "--grain-synthesis-radius-lut", values["grain_synthesis_radius_lut"],
        "--grain-synthesis-target-storage", values["grain_synthesis_target_storage"],
        "--grain-synthesis-cell-mode", values["grain_synthesis_cell_mode"],
    )

  def quality_args(**overrides: str) -> tuple[str, ...]:
    values = {**baseline_options, **overrides}
    return (
        "--source-format", values["source_format"],
        "--destination-format", values["destination_format"],
        "--host-layout", values["host_layout"],
    )

  return [
      _candidate("baseline", baseline_env, perf_args(), quality_args(), tags=("baseline", "exact")),
      _candidate(
          "shared-scratch",
          {**baseline_env, "SPEKTRAFILM_SCRATCH_STORAGE": "shared"},
          perf_args(scratch_storage="shared"),
          quality_args(),
          tags=("scratch", "exact"),
      ),
      _candidate(
          "threadgroup-16x16",
          {**baseline_env, "SPEKTRAFILM_THREADGROUP": "16x16"},
          perf_args(threadgroup="16x16"),
          quality_args(),
          tags=("threadgroup", "exact"),
      ),
      _candidate(
          "threadgroup-32x8",
          {**baseline_env, "SPEKTRAFILM_THREADGROUP": "32x8"},
          perf_args(threadgroup="32x8"),
          quality_args(),
          tags=("threadgroup", "exact"),
      ),
      _candidate(
          "threadgroup-8x32",
          {**baseline_env, "SPEKTRAFILM_THREADGROUP": "8x32"},
          perf_args(threadgroup="8x32"),
          quality_args(),
          tags=("threadgroup", "exact"),
      ),
      _candidate(
          "threadgroup-64x4",
          {**baseline_env, "SPEKTRAFILM_THREADGROUP": "64x4"},
          perf_args(threadgroup="64x4"),
          quality_args(),
          tags=("threadgroup", "exact"),
      ),
      _candidate(
          "diffusion-group-2",
          {**baseline_env, "SPEKTRAFILM_DIFFUSION_GROUP_SIZE": "2"},
          perf_args(diffusion_group_size="2"),
          quality_args(),
          tags=("diffusion", "exact", "promotable"),
      ),
      _candidate(
          "diffusion-group-4",
          {**baseline_env, "SPEKTRAFILM_DIFFUSION_GROUP_SIZE": "4"},
          perf_args(diffusion_group_size="4"),
          quality_args(),
          tags=("diffusion", "exact"),
      ),
      _candidate(
          "scanner-texture",
          {**baseline_env, "SPEKTRAFILM_SCANNER_IMAGE_STORAGE": "texture"},
          perf_args(scanner_image_storage="texture"),
          quality_args(),
          tags=("scanner", "texture", "exact"),
      ),
      _candidate(
          "dir-tail-mps",
          {**baseline_env, "SPEKTRAFILM_DIR_TAIL_BACKEND": "mps"},
          perf_args(dir_tail_backend="mps"),
          quality_args(),
          tags=("dir", "mps"),
          quality_policy="report_only",
      ),
      _candidate(
          "host-half-source",
          baseline_env,
          perf_args(source_format="half"),
          quality_args(source_format="half"),
          tags=("host-io", "half", "exact"),
      ),
      _candidate(
          "host-half-destination",
          baseline_env,
          perf_args(destination_format="half"),
          quality_args(destination_format="half"),
          tags=("host-io", "half", "exact"),
      ),
      _candidate(
          "host-half-io",
          baseline_env,
          perf_args(source_format="half", destination_format="half"),
          quality_args(source_format="half", destination_format="half"),
          tags=("host-io", "half", "exact"),
      ),
      _candidate(
          "host-strided-float",
          baseline_env,
          perf_args(host_layout="strided"),
          quality_args(host_layout="strided"),
          tags=("host-io", "layout", "exact"),
      ),
      _candidate(
          "host-offset-float",
          baseline_env,
          perf_args(host_layout="offset"),
          quality_args(host_layout="offset"),
          tags=("host-io", "layout", "exact"),
      ),
  ]


def parse_size(text: str) -> tuple[int, int]:
  if "x" not in text.lower():
    raise argparse.ArgumentTypeError(f"Invalid size {text!r}; expected WIDTHxHEIGHT.")
  width_text, height_text = text.lower().split("x", 1)
  try:
    width = int(width_text)
    height = int(height_text)
  except ValueError as exc:
    raise argparse.ArgumentTypeError(f"Invalid size {text!r}; expected integer WIDTHxHEIGHT.") from exc
  if width <= 0 or height <= 0:
    raise argparse.ArgumentTypeError(f"Invalid size {text!r}; dimensions must be positive.")
  return width, height


def parse_size_list(text: str) -> list[tuple[int, int]]:
  sizes = [parse_size(item.strip()) for item in text.split(",") if item.strip()]
  if not sizes:
    raise argparse.ArgumentTypeError("At least one size is required.")
  return sizes


def parse_csv_set(value: str | None) -> set[str] | None:
  if not value:
    return None
  return {item.strip() for item in value.split(",") if item.strip()}


def parse_csv_tuple(value: str | None) -> tuple[str, ...]:
  parsed = parse_csv_set(value)
  return tuple(sorted(parsed)) if parsed else ()


def parse_case_tuple(value: str) -> tuple[str, ...]:
  cases = tuple(item.strip() for item in value.split(",") if item.strip())
  return cases if cases else ("all",)


def safe_log_name(value: str) -> str:
  return "".join(ch if ch.isalnum() or ch in ("-", "_", ".") else "_" for ch in value)


def _string_dict(value: Any, field_name: str) -> dict[str, str]:
  if value is None:
    return {}
  if not isinstance(value, dict):
    raise SystemExit(f"{field_name} must be an object.")
  return {str(key): str(item) for key, item in value.items()}


def _string_tuple(value: Any, field_name: str) -> tuple[str, ...]:
  if value is None:
    return ()
  if not isinstance(value, list):
    raise SystemExit(f"{field_name} must be a list.")
  return tuple(str(item) for item in value)


def _candidate_from_manifest(row: dict[str, Any], manifest_path: Path) -> CandidateConfig:
  if not isinstance(row, dict):
    raise SystemExit(f"Candidate entries in {manifest_path} must be objects.")
  name = str(row.get("name", "")).strip()
  if not name:
    raise SystemExit(f"Candidate in {manifest_path} is missing a non-empty name.")
  quality_policy = str(row.get("quality_policy", "exact"))
  if quality_policy not in QUALITY_POLICIES:
    raise SystemExit(f"Candidate {name!r} has unknown quality_policy {quality_policy!r}.")
  quality_required = bool(row.get("quality_required", True))
  return _candidate(
      name,
      _string_dict(row.get("env"), f"{name}.env"),
      _string_tuple(row.get("perf_args"), f"{name}.perf_args"),
      _string_tuple(row.get("quality_args"), f"{name}.quality_args"),
      quality_required=quality_required,
      quality_policy=quality_policy,
      tags=_string_tuple(row.get("tags"), f"{name}.tags"),
  )


def load_candidate_manifest(path: Path) -> tuple[bool, list[CandidateConfig]]:
  try:
    payload = json.loads(path.read_text(encoding="utf-8"))
  except FileNotFoundError as exc:
    raise SystemExit(f"Candidate manifest not found: {path}") from exc
  except json.JSONDecodeError as exc:
    raise SystemExit(f"Unable to parse candidate manifest {path}: {exc}") from exc
  if not isinstance(payload, dict):
    raise SystemExit(f"Candidate manifest {path} must be a JSON object.")
  include_defaults = bool(payload.get("include_defaults", True))
  rows = payload.get("candidates", [])
  if not isinstance(rows, list):
    raise SystemExit(f"Candidate manifest {path} field candidates must be a list.")
  return include_defaults, [_candidate_from_manifest(row, path) for row in rows]


def merge_candidate_configs(base: list[CandidateConfig], additions: list[CandidateConfig]) -> list[CandidateConfig]:
  merged: list[CandidateConfig] = []
  index_by_name: dict[str, int] = {}
  for candidate in [*base, *additions]:
    existing = index_by_name.get(candidate.name)
    if existing is None:
      index_by_name[candidate.name] = len(merged)
      merged.append(candidate)
    else:
      merged[existing] = candidate
  return merged


def load_candidate_configs(manifest_paths: list[Path] | None) -> list[CandidateConfig]:
  candidates = default_candidate_configs()
  if not manifest_paths:
    return candidates
  include_defaults = True
  manifest_candidates: list[CandidateConfig] = []
  for manifest_path in manifest_paths:
    current_include_defaults, current_candidates = load_candidate_manifest(manifest_path)
    include_defaults = include_defaults and current_include_defaults
    manifest_candidates.extend(current_candidates)
  return merge_candidate_configs(candidates if include_defaults else [], manifest_candidates)


def _convert_csv_value(key: str, value: str | None) -> Any:
  if value is None:
    return None
  value = value.strip()
  if value == "":
    return ""
  if key in TEXT_FIELDS:
    return value
  if key in INT_FIELDS:
    try:
      return int(float(value))
    except ValueError:
      return value
  try:
    return float(value)
  except ValueError:
    return value


def parse_perf_stdout(text: str) -> list[dict[str, Any]]:
  csv_lines: list[str] = []
  in_csv = False
  for line in text.splitlines():
    if line.startswith("# pass_detail"):
      break
    if not line.strip():
      continue
    if line.startswith("case,"):
      in_csv = True
    if in_csv:
      csv_lines.append(line)
  if not csv_lines:
    return []

  rows: list[dict[str, Any]] = []
  for row in csv.DictReader(csv_lines):
    rows.append({key: _convert_csv_value(key, value) for key, value in row.items()})
  return rows


def candidate_env(config: CandidateConfig) -> dict[str, str]:
  env = os.environ.copy()
  env.update(config.env)
  return env


def run_command(
  command: list[str],
  cwd: Path,
  env: dict[str, str],
  stdout_path: Path,
  stderr_path: Path,
) -> subprocess.CompletedProcess[str]:
  try:
    completed = subprocess.run(
        command,
        cwd=str(cwd),
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
  except FileNotFoundError as exc:
    completed = subprocess.CompletedProcess(command, 127, "", f"{exc}\n")
  stdout_path.write_text(completed.stdout or "", encoding="utf-8")
  stderr_path.write_text(completed.stderr or "", encoding="utf-8")
  return completed


def sanitize_name(name: str) -> str:
  return "".join(char if char.isalnum() or char in "-_." else "_" for char in name)


def load_quality_metrics(metrics_path: Path) -> list[dict[str, Any]]:
  if not metrics_path.is_file():
    return []
  try:
    metrics = json.loads(metrics_path.read_text(encoding="utf-8"))
  except json.JSONDecodeError:
    return []
  return metrics if isinstance(metrics, list) else []


def summarize_quality(metrics_rows: list[dict[str, Any]], returncode: int) -> dict[str, Any]:
  failed = sum(1 for row in metrics_rows if row.get("status") == "FAILED TEST")
  infra = sum(1 for row in metrics_rows if str(row.get("status", "")).startswith("INFRASTRUCTURE_FAILED"))
  if returncode != 0 or infra > 0:
    status = "INFRASTRUCTURE_FAILED"
  elif failed > 0:
    status = "FAILED TEST"
  elif metrics_rows:
    status = "PASSED"
  else:
    status = "INFRASTRUCTURE_FAILED"
    infra = max(infra, 1)
  return {
      "status": status,
      "failed": failed,
      "infrastructure_failures": infra,
      "case_count": len(metrics_rows),
  }


def run_quality_candidate(config: CandidateConfig, args: argparse.Namespace, candidate_dir: Path) -> dict[str, Any]:
  if args.skip_quality or not config.quality_required:
    return {
        "candidate": config.name,
        "quality_policy": config.quality_policy,
        "tags": list(config.tags),
        "status": "SKIPPED",
        "failed": 0,
        "infrastructure_failures": 0,
        "case_count": 0,
    }

  quality_dir = candidate_dir / "quality"
  quality_dir.mkdir(parents=True, exist_ok=True)
  command = [
      sys.executable,
      str(args.parity_runner),
      "--output", str(quality_dir),
      "--build-dir", str(args.build_dir),
      "--harness", str(args.parity_harness),
      "--mode", args.parity_mode,
      "--width", str(args.parity_width),
      "--height", str(args.parity_height),
      "--quality-threshold-scale", str(args.quality_threshold_scale),
      *config.quality_args,
  ]
  if args.reference_cache_dir:
    command.extend(["--reference-cache-dir", str(args.reference_cache_dir)])
  if args.refresh_reference_cache:
    command.append("--refresh-reference-cache")
  if args.python_data_dir:
    command.extend(["--python-data-dir", str(args.python_data_dir)])
  if args.patterns:
    command.extend(["--patterns", args.patterns])
  if args.stages:
    command.extend(["--stages", args.stages])

  env = candidate_env(config)
  if args.python_runtime_cache_dir:
    env.setdefault("MPLCONFIGDIR", str(args.python_runtime_cache_dir / "matplotlib"))
    env.setdefault("XDG_CACHE_HOME", str(args.python_runtime_cache_dir / "xdg"))

  completed = run_command(
      command,
      OFX_ROOT,
      env,
      candidate_dir / "quality.stdout.log",
      candidate_dir / "quality.stderr.log",
  )
  metrics_rows = load_quality_metrics(quality_dir / "metrics.json")
  summary = summarize_quality(metrics_rows, completed.returncode)
  summary.update({
      "candidate": config.name,
      "quality_policy": config.quality_policy,
      "tags": list(config.tags),
      "returncode": completed.returncode,
      "output_dir": str(quality_dir),
      "stdout_log": str(candidate_dir / "quality.stdout.log"),
      "stderr_log": str(candidate_dir / "quality.stderr.log"),
  })
  return summary


def run_perf_candidate(
  config: CandidateConfig,
  args: argparse.Namespace,
  candidate_dir: Path,
  quality_status: str,
) -> list[dict[str, Any]]:
  rows: list[dict[str, Any]] = []
  for case_name in args.cases:
    case_log_name = safe_log_name(case_name)
    for width, height in args.sizes:
      size_name = f"{width}x{height}"
      log_name = f"perf_{case_log_name}_{size_name}"
      command = [
          str(args.perf_harness),
          "--resource-dir", str(args.build_dir),
          "--case", case_name,
          "--width", str(width),
          "--height", str(height),
          "--iterations", str(args.iterations),
          "--warmup", str(args.warmup),
          *config.perf_args,
      ]
      if args.pass_timing != "off":
        command.extend(["--pass-timing", args.pass_timing])
      if args.detail:
        command.append("--detail")

      completed = run_command(
          command,
          OFX_ROOT,
          candidate_env(config),
          candidate_dir / f"{log_name}.stdout.log",
          candidate_dir / f"{log_name}.stderr.log",
      )
      parsed_rows = parse_perf_stdout(completed.stdout)
      if completed.returncode != 0 or not parsed_rows:
        rows.append({
            "candidate": config.name,
            "quality_policy": config.quality_policy,
            "quality_status": quality_status,
            "perf_status": "INFRASTRUCTURE_FAILED",
            "case": case_name,
            "width": width,
            "height": height,
            "iterations": args.iterations,
            "avg_wall_ms": "",
            "returncode": completed.returncode,
            "stdout_log": str(candidate_dir / f"{log_name}.stdout.log"),
            "stderr_log": str(candidate_dir / f"{log_name}.stderr.log"),
        })
        continue

      for row in parsed_rows:
        row.update({
            "candidate": config.name,
            "quality_policy": config.quality_policy,
            "quality_status": quality_status,
            "perf_status": "OK",
            "returncode": completed.returncode,
            "stdout_log": str(candidate_dir / f"{log_name}.stdout.log"),
            "stderr_log": str(candidate_dir / f"{log_name}.stderr.log"),
        })
        rows.append(row)
  return rows


def select_best_configs(
  rows: list[dict[str, Any]],
  quality_by_candidate: dict[str, dict[str, Any]],
  config_by_candidate: dict[str, CandidateConfig],
) -> list[dict[str, Any]]:
  best_by_case: dict[tuple[str, int, int, str, str, str], dict[str, Any]] = {}
  for row in rows:
    if row.get("perf_status") != "OK":
      continue
    candidate = str(row.get("candidate", ""))
    config = config_by_candidate.get(candidate)
    if config is None or config.quality_policy != "exact":
      continue
    quality_status = str(quality_by_candidate.get(candidate, {}).get("status", "UNKNOWN"))
    if quality_status not in QUALITY_OK_STATUSES:
      continue
    avg_wall_ms = row.get("avg_wall_ms")
    if not isinstance(avg_wall_ms, (int, float)):
      continue
    key = (
        str(row.get("case", "")),
        int(row.get("width", 0)),
        int(row.get("height", 0)),
        str(row.get("source_format", "float")),
        str(row.get("destination_format", "float")),
        str(row.get("host_layout", "contiguous")),
    )
    current = best_by_case.get(key)
    if current is None or float(avg_wall_ms) < float(current["avg_wall_ms"]):
      best_by_case[key] = row
  return [best_by_case[key] for key in sorted(best_by_case)]


def _perf_key(row: dict[str, Any]) -> tuple[str, int, int, str, str, str]:
  return (
      str(row.get("case", "")),
      int(row.get("width", 0) or 0),
      int(row.get("height", 0) or 0),
      str(row.get("source_format", "float")),
      str(row.get("destination_format", "float")),
      str(row.get("host_layout", "contiguous")),
  )


def _numeric(row: dict[str, Any], key: str) -> float | None:
  value = row.get(key)
  return float(value) if isinstance(value, (int, float)) else None


def build_candidate_comparison(
  rows: list[dict[str, Any]],
  quality_by_candidate: dict[str, dict[str, Any]],
  config_by_candidate: dict[str, CandidateConfig],
) -> list[dict[str, Any]]:
  baseline_by_key: dict[tuple[str, int, int, str, str, str], dict[str, Any]] = {
      _perf_key(row): row
      for row in rows
      if row.get("perf_status") == "OK" and row.get("candidate") == "baseline"
  }
  comparison_rows: list[dict[str, Any]] = []
  for row in rows:
    candidate = str(row.get("candidate", ""))
    config = config_by_candidate.get(candidate)
    quality_status = str(quality_by_candidate.get(candidate, {}).get("status", row.get("quality_status", "UNKNOWN")))
    policy = config.quality_policy if config else str(row.get("quality_policy", "exact"))
    avg_wall_ms = _numeric(row, "avg_wall_ms")
    avg_pass_count = _numeric(row, "avg_pass_count")
    baseline = baseline_by_key.get(_perf_key(row))
    baseline_ms = _numeric(baseline, "avg_wall_ms") if baseline else None
    baseline_pass_count = _numeric(baseline, "avg_pass_count") if baseline else None
    speedup = baseline_ms / avg_wall_ms if baseline_ms and avg_wall_ms and avg_wall_ms > 0.0 else ""
    wall_delta_pct = ((avg_wall_ms - baseline_ms) / baseline_ms * 100.0) if baseline_ms and avg_wall_ms is not None else ""
    pass_count_delta = (avg_pass_count - baseline_pass_count) if baseline_pass_count is not None and avg_pass_count is not None else ""
    promotable = (
        row.get("perf_status") == "OK"
        and policy == "exact"
        and quality_status in QUALITY_OK_STATUSES
    )
    comparison_rows.append({
        "candidate": candidate,
        "quality_policy": policy,
        "promotable": int(promotable),
        "perf_status": row.get("perf_status", ""),
        "quality_status": quality_status,
        "case": row.get("case", ""),
        "width": row.get("width", ""),
        "height": row.get("height", ""),
        "source_format": row.get("source_format", "float"),
        "destination_format": row.get("destination_format", "float"),
        "host_layout": row.get("host_layout", "contiguous"),
        "threadgroup": row.get("threadgroup", ""),
        "diffusion_group_size": row.get("diffusion_group_size", ""),
        "scanner_image_storage": row.get("scanner_image_storage", ""),
        "blur_backend": row.get("blur_backend", ""),
        "blur_downsample": row.get("blur_downsample", ""),
        "intermediate_precision": row.get("intermediate_precision", ""),
        "diffusion_cluster_sigma": row.get("diffusion_cluster_sigma", ""),
        "halation_grouped_tail": row.get("halation_grouped_tail", ""),
        "scanner_mps": row.get("scanner_mps", ""),
        "grain_blur_recurrence": row.get("grain_blur_recurrence", ""),
        "dir_tail_backend": row.get("dir_tail_backend", ""),
        "density_curve_lookup": row.get("density_curve_lookup", ""),
        "spectral_transmittance": row.get("spectral_transmittance", ""),
        "final_core_mode": row.get("final_core_mode", ""),
        "avg_wall_ms": row.get("avg_wall_ms", ""),
        "baseline_avg_wall_ms": baseline_ms if baseline_ms is not None else "",
        "wall_delta_pct": wall_delta_pct,
        "speedup": speedup,
        "avg_pass_count": row.get("avg_pass_count", ""),
        "baseline_avg_pass_count": baseline_pass_count if baseline_pass_count is not None else "",
        "pass_count_delta": pass_count_delta,
    })
  return comparison_rows


def _git_text(args: list[str]) -> str:
  try:
    completed = subprocess.run(
        ["git", *args],
        cwd=str(OFX_ROOT),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=False,
    )
  except FileNotFoundError:
    return ""
  return completed.stdout.strip() if completed.returncode == 0 else ""


def cmake_cache_values(build_dir: Path) -> dict[str, str]:
  cache_path = build_dir / "CMakeCache.txt"
  if not cache_path.is_file():
    return {}
  wanted = {
      "CMAKE_BUILD_TYPE",
      "SPEKTRAFILM_NATIVE_FAST_MATH",
      "SPEKTRAFILM_METAL_FAST_MATH",
      "SPEKTRAFILM_METAL_EXTRA_FLAGS",
  }
  values: dict[str, str] = {}
  for line in cache_path.read_text(encoding="utf-8", errors="replace").splitlines():
    if line.startswith("//") or line.startswith("#") or "=" not in line:
      continue
    key_with_type, value = line.split("=", 1)
    key = key_with_type.split(":", 1)[0]
    if key in wanted:
      values[key] = value
  return values


def build_manifest(args: argparse.Namespace, candidates: list[CandidateConfig]) -> dict[str, Any]:
  return {
      "schema_version": 1,
      "created_at_utc": _datetime.datetime.now(_datetime.timezone.utc).isoformat(),
      "platform": {
          "platform": platform.platform(),
          "machine": platform.machine(),
          "processor": platform.processor(),
          "python": sys.version,
      },
      "git": {
          "head": _git_text(["rev-parse", "HEAD"]),
          "status_short": _git_text(["status", "--short"]),
      },
      "build": {
          "build_dir": str(args.build_dir),
          "perf_harness": str(args.perf_harness),
          "parity_harness": str(args.parity_harness),
          "parity_runner": str(args.parity_runner),
          "cmake_cache": cmake_cache_values(args.build_dir),
      },
      "run": {
          "case": args.case,
          "cases": list(args.cases),
          "sizes": [f"{width}x{height}" for width, height in args.sizes],
          "iterations": args.iterations,
          "warmup": args.warmup,
          "parity_mode": args.parity_mode,
          "parity_width": args.parity_width,
          "parity_height": args.parity_height,
          "quality_threshold_scale": args.quality_threshold_scale,
          "patterns": args.patterns,
          "stages": args.stages,
          "skip_quality": args.skip_quality,
          "pass_timing": args.pass_timing,
          "detail": args.detail,
          "reference_cache_dir": str(args.reference_cache_dir),
          "refresh_reference_cache": args.refresh_reference_cache,
          "python_data_dir": str(args.python_data_dir),
          "python_runtime_cache_dir": str(args.python_runtime_cache_dir),
          "candidate_manifest": [str(path) for path in (args.candidate_manifest or [])],
          "candidate_tags": args.candidate_tags,
      },
      "candidates": [
          {
              "name": candidate.name,
              "env": candidate.env,
              "perf_args": list(candidate.perf_args),
              "quality_args": list(candidate.quality_args),
              "quality_required": candidate.quality_required,
              "quality_policy": candidate.quality_policy,
              "tags": list(candidate.tags),
          }
          for candidate in candidates
      ],
  }


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
  preferred = [
      "candidate",
      "perf_status",
      "quality_status",
      "quality_policy",
      "promotable",
      "case",
      "width",
      "height",
      "iterations",
      "avg_wall_ms",
      "baseline_avg_wall_ms",
      "wall_delta_pct",
      "speedup",
      "avg_fps",
      "avg_cpu_setup_ms",
      "avg_source_copy_ms",
      "avg_command_buffer_ms",
      "avg_output_copy_ms",
      "avg_pass_count",
      "baseline_avg_pass_count",
      "pass_count_delta",
      "threadgroup",
      "diffusion_group_size",
      "scanner_image_storage",
      "blur_backend",
      "blur_downsample",
      "intermediate_precision",
      "diffusion_cluster_sigma",
      "halation_grouped_tail",
      "scanner_mps",
      "grain_blur_recurrence",
      "dir_tail_backend",
      "density_curve_lookup",
      "spectral_transmittance",
      "source_format",
      "destination_format",
      "host_layout",
      "grain_synthesis_sampler",
      "grain_synthesis_radius_lut",
      "grain_synthesis_target_storage",
      "grain_synthesis_cell_mode",
  ]
  keys = set().union(*(row.keys() for row in rows)) if rows else set(preferred)
  fieldnames = [key for key in preferred if key in keys] + sorted(keys - set(preferred))
  with path.open("w", encoding="utf-8", newline="") as handle:
    writer = csv.DictWriter(handle, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)


def write_reports(
  output_dir: Path,
  manifest: dict[str, Any],
  quality_rows: list[dict[str, Any]],
  perf_rows: list[dict[str, Any]],
  best_rows: list[dict[str, Any]],
  comparison_rows: list[dict[str, Any]],
) -> None:
  (output_dir / "manifest.json").write_text(json.dumps(manifest, indent=2, allow_nan=True) + "\n", encoding="utf-8")
  (output_dir / "quality_results.json").write_text(json.dumps(quality_rows, indent=2, allow_nan=True) + "\n", encoding="utf-8")
  (output_dir / "perf_results.json").write_text(json.dumps(perf_rows, indent=2, allow_nan=True) + "\n", encoding="utf-8")
  (output_dir / "best_configs.json").write_text(json.dumps(best_rows, indent=2, allow_nan=True) + "\n", encoding="utf-8")
  (output_dir / "candidate_comparison.json").write_text(json.dumps(comparison_rows, indent=2, allow_nan=True) + "\n", encoding="utf-8")
  write_csv(output_dir / "perf_results.csv", perf_rows)
  write_csv(output_dir / "best_configs.csv", best_rows)
  write_csv(output_dir / "candidate_comparison.csv", comparison_rows)


def select_candidates(
  candidates: list[CandidateConfig],
  wanted_text: str | None,
  tag_text: str | None = None,
) -> list[CandidateConfig]:
  wanted = parse_csv_set(wanted_text)
  wanted_tags = parse_csv_set(tag_text)
  selected = candidates
  if not wanted:
    selected = candidates
  else:
    by_name = {candidate.name: candidate for candidate in candidates}
    unknown = sorted(wanted - set(by_name))
    if unknown:
      raise SystemExit(f"Unknown candidate(s): {', '.join(unknown)}")
    selected = [candidate for candidate in candidates if candidate.name in wanted]

  if wanted_tags:
    available_tags = set().union(*(candidate.tags for candidate in candidates)) if candidates else set()
    unknown_tags = sorted(wanted_tags - available_tags)
    if unknown_tags:
      raise SystemExit(f"Unknown candidate tag(s): {', '.join(unknown_tags)}")
    selected = [candidate for candidate in selected if wanted_tags.intersection(candidate.tags)]
    if not wanted:
      baseline = next((candidate for candidate in candidates if candidate.name == "baseline"), None)
      if baseline and all(candidate.name != "baseline" for candidate in selected):
        selected = [baseline, *selected]

  return selected


def print_candidate_list(candidates: list[CandidateConfig]) -> None:
  print("name,quality_policy,tags")
  for candidate in candidates:
    print(f"{candidate.name},{candidate.quality_policy},{'|'.join(candidate.tags)}")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument("--output", type=Path, help="Directory for sweep reports.")
  parser.add_argument("--build-dir", type=Path, default=DEFAULT_BUILD_DIR, help="Build directory containing Metal harness resources.")
  parser.add_argument("--perf-harness", type=Path, default=None, help="Path to SpektraFilmPerfHarness. Defaults to BUILD_DIR/SpektraFilmPerfHarness.")
  parser.add_argument("--parity-harness", type=Path, default=None, help="Path to SpektraFilmParityHarness. Defaults to BUILD_DIR/SpektraFilmParityHarness.")
  parser.add_argument("--parity-runner", type=Path, default=DEFAULT_PARITY_RUNNER, help="Path to run_parity_harness.py.")
  parser.add_argument("--case", default="all", help="Perf harness case or comma-separated case list, for example all, all-effects, halation-only, camera-diffusion-only, print-diffusion-only, dir-only, production-grain, auto-exposure, scanner-only.")
  parser.add_argument("--sizes", type=parse_size_list, default=parse_size_list("1920x1080,3840x2160"), help="Comma-separated WIDTHxHEIGHT list.")
  parser.add_argument("--iterations", type=int, default=3)
  parser.add_argument("--warmup", type=int, default=1)
  parser.add_argument("--parity-mode", choices=("quick", "full"), default="quick")
  parser.add_argument("--parity-width", type=int, default=96)
  parser.add_argument("--parity-height", type=int, default=64)
  parser.add_argument("--quality-threshold-scale", type=float, default=1.0, help="Scale parity metric failure thresholds. Values below 1.0 are stricter.")
  parser.add_argument("--patterns", help="Comma-separated parity pattern names to include.")
  parser.add_argument("--stages", help="Comma-separated parity stage names to include.")
  parser.add_argument("--candidates", help="Comma-separated candidate names. Defaults to the full matrix.")
  parser.add_argument("--candidate-manifest", type=Path, action="append", help="JSON file adding or replacing sweep candidates.")
  parser.add_argument("--candidate-tags", help="Comma-separated candidate tags to include. Baseline is included automatically for tagged sweeps.")
  parser.add_argument("--list-candidates", action="store_true", help="Print selected candidates and exit without running a sweep.")
  parser.add_argument("--skip-quality", action="store_true", help="Run perf only and mark quality as SKIPPED.")
  parser.add_argument("--reference-cache-dir", type=Path, help="Shared Python parity reference cache. Defaults to OUTPUT/python_reference_cache.")
  parser.add_argument("--refresh-reference-cache", action="store_true", help="Regenerate Python parity references instead of reusing the shared cache.")
  parser.add_argument("--python-data-dir", type=Path, help="Shared prepared Python data directory for parity runs. Defaults to OUTPUT/python_data.")
  parser.add_argument("--python-runtime-cache-dir", type=Path, help="Shared Python runtime cache directory for parity runs. Defaults to OUTPUT/python_runtime_cache.")
  parser.add_argument("--detail", action="store_true", help="Ask the perf harness to include pass detail logs.")
  parser.add_argument("--pass-timing", choices=("off", "auto", "counter", "split"), default="off")
  args = parser.parse_args(argv)
  if not args.list_candidates and args.output is None:
    raise SystemExit("--output is required unless --list-candidates is used.")
  if args.iterations <= 0 or args.warmup < 0:
    raise SystemExit("--iterations must be positive and --warmup must be non-negative.")
  if args.parity_width <= 0 or args.parity_height <= 0:
    raise SystemExit("--parity-width and --parity-height must be positive.")
  if args.quality_threshold_scale <= 0.0:
    raise SystemExit("--quality-threshold-scale must be positive.")
  args.cases = parse_case_tuple(args.case)
  if args.output is not None and args.reference_cache_dir is None:
    args.reference_cache_dir = args.output / "python_reference_cache"
  if args.output is not None and args.python_data_dir is None:
    args.python_data_dir = args.output / "python_data"
  if args.output is not None and args.python_runtime_cache_dir is None:
    args.python_runtime_cache_dir = args.output / "python_runtime_cache"
  args.perf_harness = args.perf_harness or (args.build_dir / "SpektraFilmPerfHarness")
  args.parity_harness = args.parity_harness or (args.build_dir / "SpektraFilmParityHarness")
  return args


def main(argv: list[str] | None = None) -> int:
  args = parse_args(argv)
  candidates = select_candidates(load_candidate_configs(args.candidate_manifest), args.candidates, args.candidate_tags)
  if args.list_candidates:
    print_candidate_list(candidates)
    return 0

  args.output.mkdir(parents=True, exist_ok=True)
  manifest = build_manifest(args, candidates)
  config_by_candidate = {candidate.name: candidate for candidate in candidates}

  quality_rows: list[dict[str, Any]] = []
  quality_by_candidate: dict[str, dict[str, Any]] = {}
  perf_rows: list[dict[str, Any]] = []
  for candidate in candidates:
    candidate_dir = args.output / sanitize_name(candidate.name)
    candidate_dir.mkdir(parents=True, exist_ok=True)
    quality = run_quality_candidate(candidate, args, candidate_dir)
    quality_rows.append(quality)
    quality_by_candidate[candidate.name] = quality
    perf_rows.extend(run_perf_candidate(candidate, args, candidate_dir, str(quality["status"])))
    print(
        f"{candidate.name}: quality={quality['status']} "
        f"perf_rows={sum(1 for row in perf_rows if row.get('candidate') == candidate.name)}"
    )

  best_rows = select_best_configs(perf_rows, quality_by_candidate, config_by_candidate)
  comparison_rows = build_candidate_comparison(perf_rows, quality_by_candidate, config_by_candidate)
  write_reports(args.output, manifest, quality_rows, perf_rows, best_rows, comparison_rows)
  def quality_policy_for(row: dict[str, Any]) -> str:
    config = config_by_candidate.get(str(row["candidate"]))
    return config.quality_policy if config else "exact"

  failed_quality = sum(
      1 for row in quality_rows
      if row["status"] == "FAILED TEST" and quality_policy_for(row) == "exact"
  )
  infra_quality = sum(
      1 for row in quality_rows
      if row["status"] == "INFRASTRUCTURE_FAILED" and quality_policy_for(row) == "exact"
  )
  report_only_failed_quality = sum(
      1 for row in quality_rows
      if row["status"] == "FAILED TEST" and quality_policy_for(row) == "report_only"
  )
  report_only_infra_quality = sum(
      1 for row in quality_rows
      if row["status"] == "INFRASTRUCTURE_FAILED" and quality_policy_for(row) == "report_only"
  )
  infra_perf = sum(1 for row in perf_rows if row.get("perf_status") == "INFRASTRUCTURE_FAILED")
  print(
      f"Wrote sweep report to {args.output} "
      f"({len(best_rows)} best rows, {failed_quality} exact quality failures, "
      f"{infra_quality} exact quality infrastructure failures, "
      f"{report_only_failed_quality} report-only quality failures, "
      f"{report_only_infra_quality} report-only quality infrastructure failures, "
      f"{infra_perf} perf infrastructure failures)."
  )
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
