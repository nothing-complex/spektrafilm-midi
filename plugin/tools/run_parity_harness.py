#!/usr/bin/env python3
"""Run Python-vs-Metal image parity cases for the SpektraFilm OFX renderer."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

import numpy as np


REPO_ROOT = Path(__file__).resolve().parents[3]
OFX_ROOT = Path(__file__).resolve().parents[1]
TOOLS_DIR = OFX_ROOT / "tools"
DEFAULT_BUILD_DIR = OFX_ROOT / "build"
DEFAULT_DATA_DIR = OFX_ROOT / "Resources" / "data"
DEFAULT_ARCHIVE_PROFILE_DIR = DEFAULT_DATA_DIR / "profiles" / "archive"
SRC_DIR = REPO_ROOT / "src"

STAGES = (
    "film_log_raw",
    "film_density_cmy",
    "film_density_cmy_grain",
    "print_log_raw",
    "print_density_cmy",
    "final_linear_rgb",
)

NON_SPATIAL_STAGES = {
    "film_log_raw",
    "film_density_cmy",
    "print_log_raw",
    "print_density_cmy",
    "final_linear_rgb",
}

FILMS = (
    "kodak_ektar_100",
    "kodak_portra_160",
    "kodak_portra_400",
    "kodak_portra_800",
    "kodak_portra_800_push1",
    "kodak_portra_800_push2",
    "kodak_gold_200",
    "kodak_ultramax_400",
    "kodak_vision3_50d",
    "kodak_vision3_250d",
    "kodak_verita_200d",
    "kodak_vision3_200t",
    "kodak_vision3_500t",
    "fujifilm_pro_400h",
    "fujifilm_c200",
    "fujifilm_xtra_400",
    "kodak_ektachrome_100",
    "kodak_kodachrome_64",
    "fujifilm_velvia_100",
    "fujifilm_provia_100f",
)

PAPERS = (
    "kodak_endura_premier",
    "kodak_ultra_endura",
    "kodak_ektacolor_edge",
    "kodak_supra_endura",
    "kodak_portra_endura",
    "fujifilm_crystal_archive_typeii",
    "kodak_2383",
    "kodak_2393",
)


@dataclass(frozen=True)
class Pattern:
  name: str
  image: np.ndarray


@dataclass
class ParityParams:
  film: str = "kodak_portra_400"
  paper: str = "kodak_portra_endura"
  process: str = "print_simulation"
  rgb_to_raw_method: str = "hanatos2025"
  input_color_space: str = "linear_rec2020"
  output_color_space: str = "linear_rec2020"
  film_exposure_ev: float = 0.0
  print_exposure_ev: float = 0.0
  film_gamma: float = 1.0
  print_gamma: float = 1.0
  filter_c: float = 0.0
  filter_m_shift: float = 0.0
  filter_y_shift: float = 0.0
  preflash_exposure: float = 0.0
  preflash_m_filter_shift: float = 0.0
  preflash_y_filter_shift: float = 0.0
  dir_amount: float = 0.0
  dir_diffusion_um: float = 20.0
  dir_diffusion_tail_um: float = 200.0
  dir_diffusion_tail_weight: float = 0.06
  grain_enabled: bool = False
  grain_model: str = "production"
  grain_particle_area_um2: float = 0.1
  grain_particle_scale_rgb: tuple[float, float, float] = (1.2, 1.0, 2.5)
  grain_particle_scale_layers: tuple[float, float, float] = (6.0, 1.0, 0.4)
  grain_density_min_rgb: tuple[float, float, float] = (0.04, 0.05, 0.06)
  grain_uniformity_rgb: tuple[float, float, float] = (0.99, 0.97, 0.98)
  grain_final_blur_um: float = 0.0
  grain_blur_dye_clouds_um: float = 1.0
  grain_seed: int = 1
  halation_enabled: bool = False
  scatter_amount: float = 1.0
  scatter_scale: float = 1.0
  halation_amount: float = 1.0
  halation_scale: float = 1.0
  halation_strength_rgb: tuple[float, float, float] = (0.05, 0.015, 0.0)
  halation_boost_ev: float = 0.0
  halation_boost_range: float = 0.3
  halation_protect_ev: float = 4.0
  camera_diffusion_enabled: bool = False
  camera_diffusion_strength: float = 0.5
  camera_diffusion_spatial_scale: float = 1.0
  print_diffusion_enabled: bool = False
  print_diffusion_strength: float = 0.5
  print_diffusion_spatial_scale: float = 1.0
  scanner_enabled: bool = False
  scanner_white_correction: bool = False
  scanner_black_correction: bool = False
  scanner_white_level: float = 0.98
  scanner_black_level: float = 0.01
  glare_percent: float = 0.0
  glare_roughness: float = 0.7
  glare_blur: float = 0.0
  scanner_mtf50_lp_mm: float = 0.0
  scanner_unsharp_radius_um: float = 0.0
  scanner_unsharp_amount: float = 0.0
  deactivate_spatial_effects: bool = True
  deactivate_stochastic_effects: bool = True
  unsupported: list[str] = field(default_factory=list)


@dataclass(frozen=True)
class Case:
  case_id: str
  suite: str
  pattern: Pattern
  stage: str
  params: ParityParams


def _grid(width: int, height: int) -> tuple[np.ndarray, np.ndarray]:
  x = np.linspace(0.0, 1.0, width, dtype=np.float64)
  y = np.linspace(0.0, 1.0, height, dtype=np.float64)
  return np.meshgrid(x, y, indexing="xy")


def make_patterns(width: int = 96, height: int = 64) -> list[Pattern]:
  x, y = _grid(width, height)
  patterns: list[Pattern] = []

  gray = np.repeat(np.linspace(0.0, 1.0, width, dtype=np.float64)[None, :, None], height, axis=0).repeat(3, axis=2)
  patterns.append(Pattern("gray_ramp", np.clip(gray, 0.0, None)))

  log_values = 0.184 * np.power(10.0, np.linspace(-2.0, 2.0, width, dtype=np.float64))
  log_ramp = np.repeat(log_values[None, :, None], height, axis=0).repeat(3, axis=2)
  patterns.append(Pattern("log_gray_ramp", log_ramp))

  rgb_ramps = np.stack((x, y, 1.0 - x), axis=-1)
  patterns.append(Pattern("rgb_channel_ramps", rgb_ramps))

  plane = np.stack((x, y, np.full_like(x, 0.184)), axis=-1)
  patterns.append(Pattern("rg_color_plane", plane))

  hue = np.zeros((height, width, 3), dtype=np.float64)
  angle = 2.0 * np.pi * x
  saturation = y
  hue[..., 0] = np.clip(0.5 + 0.5 * np.cos(angle) * saturation, 0.0, 1.0)
  hue[..., 1] = np.clip(0.5 + 0.5 * np.cos(angle - 2.0 * np.pi / 3.0) * saturation, 0.0, 1.0)
  hue[..., 2] = np.clip(0.5 + 0.5 * np.cos(angle + 2.0 * np.pi / 3.0) * saturation, 0.0, 1.0)
  patterns.append(Pattern("hue_saturation_sweep", hue))

  colors = np.array(
      [
          [0.184, 0.184, 0.184], [0.9, 0.1, 0.1], [0.1, 0.9, 0.1], [0.1, 0.1, 0.9],
          [0.9, 0.9, 0.1], [0.1, 0.9, 0.9], [0.9, 0.1, 0.9], [0.02, 0.02, 0.02],
          [1.8, 1.8, 1.8], [0.75, 0.48, 0.34], [0.18, 0.30, 0.12], [0.03, 0.05, 0.09],
      ],
      dtype=np.float64,
  )
  patches = np.zeros((height, width, 3), dtype=np.float64)
  rows, cols = 3, 4
  for index, color in enumerate(colors):
    y0 = (index // cols) * height // rows
    y1 = (index // cols + 1) * height // rows
    x0 = (index % cols) * width // cols
    x1 = (index % cols + 1) * width // cols
    patches[y0:y1, x0:x1, :] = color
  patterns.append(Pattern("primary_secondary_skin_foliage_patches", patches))

  near_black = np.repeat(np.linspace(0.0, 0.08, width, dtype=np.float64)[None, :, None], height, axis=0).repeat(3, axis=2)
  patterns.append(Pattern("near_black_ramp", near_black))

  hdr = np.repeat(np.linspace(0.0, 8.0, width, dtype=np.float64)[None, :, None], height, axis=0).repeat(3, axis=2)
  patterns.append(Pattern("hdr_overrange_ramp", hdr))

  checker = ((((np.arange(height)[:, None] // 8) + (np.arange(width)[None, :] // 8)) % 2) * 0.8 + 0.05).astype(np.float64)
  patterns.append(Pattern("checkerboard", np.repeat(checker[:, :, None], 3, axis=2)))

  impulse = np.full((height, width, 3), 0.02, dtype=np.float64)
  impulse[height // 2 - 2:height // 2 + 2, width // 2 - 2:width // 2 + 2, :] = 8.0
  patterns.append(Pattern("impulse_highlight", impulse))

  edge = np.full((height, width, 3), 0.04, dtype=np.float64)
  edge[:, width // 2:, :] = 0.7
  patterns.append(Pattern("hard_edge", edge))

  slanted = np.full((height, width, 3), 0.04, dtype=np.float64)
  slanted[x + 0.35 * y > 0.55, :] = 0.7
  patterns.append(Pattern("slanted_edge", slanted))

  rng = np.random.default_rng(2025)
  noise = np.clip(rng.normal(loc=0.35, scale=0.18, size=(height, width, 3)), 0.0, 1.5)
  patterns.append(Pattern("seeded_noise", noise))

  stress = np.stack(
      (
          0.06 + 0.9 * x + 0.15 * checker,
          0.04 + 0.7 * y,
          0.03 + 0.6 * (1.0 - x) + 0.15 * np.sin(30.0 * x) ** 2,
      ),
      axis=-1,
  )
  stress[height // 2 - 1:height // 2 + 2, width // 2 - 1:width // 2 + 2, :] = 6.0
  patterns.append(Pattern("spatial_stress", stress))

  return patterns


def select_patterns(patterns: Iterable[Pattern], names: set[str] | None) -> list[Pattern]:
  selected = list(patterns)
  if names is None:
    return selected
  return [pattern for pattern in selected if pattern.name in names]


def params_to_key_values(params: ParityParams, stage: str) -> str:
  def value_to_text(value):
    if isinstance(value, bool):
      return "true" if value else "false"
    if isinstance(value, tuple):
      return ",".join(str(item) for item in value)
    return str(value)

  keys = [
      "film", "paper", "process", "rgb_to_raw_method", "input_color_space", "output_color_space",
      "film_exposure_ev", "print_exposure_ev", "film_gamma", "print_gamma",
      "filter_c", "filter_m_shift", "filter_y_shift", "preflash_exposure",
      "preflash_m_filter_shift", "preflash_y_filter_shift", "dir_amount",
      "dir_diffusion_um", "dir_diffusion_tail_um", "dir_diffusion_tail_weight",
      "grain_enabled", "grain_model", "grain_particle_area_um2",
      "grain_particle_scale_rgb", "grain_particle_scale_layers", "grain_density_min_rgb",
      "grain_uniformity_rgb", "grain_final_blur_um", "grain_blur_dye_clouds_um",
      "grain_seed", "halation_enabled", "scatter_amount", "scatter_scale",
      "halation_amount", "halation_scale", "halation_strength_rgb", "halation_boost_ev",
      "halation_boost_range", "halation_protect_ev", "camera_diffusion_enabled",
      "camera_diffusion_strength", "camera_diffusion_spatial_scale", "print_diffusion_enabled",
      "print_diffusion_strength", "print_diffusion_spatial_scale", "scanner_enabled",
      "scanner_white_correction", "scanner_black_correction", "scanner_white_level",
      "scanner_black_level", "glare_percent", "glare_roughness", "glare_blur",
      "scanner_mtf50_lp_mm", "scanner_unsharp_radius_um", "scanner_unsharp_amount",
      "deactivate_spatial_effects", "deactivate_stochastic_effects",
  ]
  lines = [f"stage={stage}"]
  for key in keys:
    lines.append(f"{key}={value_to_text(getattr(params, key))}")
  return "\n".join(lines) + "\n"


def _python_color_space(tag: str) -> str:
  mapping = {
      "linear_rec2020": "ITU-R BT.2020",
      "linear_rec709": "ITU-R BT.709",
      "srgb": "sRGB",
      "prophoto_rgb": "ProPhoto RGB",
      "display_p3": "Display P3",
  }
  return mapping.get(tag, "ITU-R BT.2020")


def _replace_link_or_copy(source: Path, target: Path) -> None:
  if target.is_symlink() or target.exists():
    try:
      if target.resolve() == source.resolve():
        return
    except OSError:
      pass
    if target.is_dir() and not target.is_symlink():
      shutil.rmtree(target)
    else:
      target.unlink()
  try:
    target.symlink_to(source, target_is_directory=source.is_dir())
  except OSError:
    if source.is_dir():
      shutil.copytree(source, target)
    else:
      shutil.copy2(source, target)


def prepare_python_data_dir(
  output_dir: Path,
  profile_dir: Path = DEFAULT_ARCHIVE_PROFILE_DIR,
  data_dir: Path | None = None,
) -> Path:
  if not profile_dir.is_dir():
    raise FileNotFoundError(f"Python parity profile directory not found: {profile_dir}")
  data_dir = data_dir or (output_dir / "python_data")
  data_dir.mkdir(parents=True, exist_ok=True)
  for name in ("filters", "luts", "standards"):
    _replace_link_or_copy(DEFAULT_DATA_DIR / name, data_dir / name)

  profiles_dir = data_dir / "profiles"
  profiles_dir.mkdir(parents=True, exist_ok=True)
  expected = {source.name for source in profile_dir.glob("*.json")}
  for stale in profiles_dir.glob("*.json"):
    if stale.name not in expected:
      stale.unlink()
  for source in profile_dir.glob("*.json"):
    _replace_link_or_copy(source, profiles_dir / source.name)
  return data_dir


def install_python_profile_compatibility() -> None:
  """Let the local Hanatos 2025 Python package read newer OFX profile JSON."""
  from spektrafilm.profiles import io as profile_io

  if getattr(profile_io, "_spektra_parity_compat_installed", False):
    return

  original_profile_from_dict = profile_io.profile_from_dict
  info_fields = set(profile_io.ProfileInfo.__dataclass_fields__)
  data_fields = set(profile_io.ProfileData.__dataclass_fields__)

  def profile_from_dict_compat(payload):
    if isinstance(payload, dict):
      payload = dict(payload)
      info_payload = payload.get("info", {})
      data_payload = payload.get("data", {})
      if isinstance(info_payload, dict):
        payload["info"] = {key: value for key, value in info_payload.items() if key in info_fields}
      if isinstance(data_payload, dict):
        payload["data"] = {key: value for key, value in data_payload.items() if key in data_fields}
    return original_profile_from_dict(payload)

  profile_io.profile_from_dict = profile_from_dict_compat
  profile_io._spektra_parity_compat_installed = True


def build_python_params(parity: ParityParams):
  if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))
  os.environ.setdefault("SPEKTRAFILM_DATA_DIR", str(DEFAULT_DATA_DIR))
  install_python_profile_compatibility()
  from spektrafilm.runtime.params_builder import digest_params, init_params

  params = init_params(parity.film, parity.paper)
  params.settings.rgb_to_raw_method = "hanatos2025"
  params.settings.bandpass_hanatos2025 = True
  params.settings.use_enlarger_lut = False
  params.settings.use_scanner_lut = False
  params.settings.use_fast_stats = False
  params.camera.auto_exposure = False
  params.camera.exposure_compensation_ev = parity.film_exposure_ev
  params.io.input_color_space = _python_color_space(parity.input_color_space)
  params.io.input_cctf_decoding = False
  params.io.output_color_space = _python_color_space(parity.output_color_space)
  params.io.output_cctf_encoding = False
  params.io.scan_film = parity.process == "scan_negative"
  params.enlarger.print_exposure = 2.0 ** parity.print_exposure_ev
  params.film_render.density_curve_gamma = parity.film_gamma
  params.print_render.density_curve_gamma = parity.print_gamma
  params.enlarger.c_filter_neutral += parity.filter_c
  params.enlarger.m_filter_shift = parity.filter_m_shift
  params.enlarger.y_filter_shift = parity.filter_y_shift
  params.enlarger.preflash_exposure = parity.preflash_exposure
  params.enlarger.preflash_m_filter_shift = parity.preflash_m_filter_shift
  params.enlarger.preflash_y_filter_shift = parity.preflash_y_filter_shift

  params.film_render.dir_couplers.amount = parity.dir_amount
  params.film_render.dir_couplers.diffusion_size_um = parity.dir_diffusion_um
  params.film_render.grain.active = parity.grain_enabled
  params.film_render.grain.agx_particle_area_um2 = parity.grain_particle_area_um2
  params.film_render.grain.agx_particle_scale = parity.grain_particle_scale_rgb
  params.film_render.grain.agx_particle_scale_layers = parity.grain_particle_scale_layers
  params.film_render.grain.density_min = parity.grain_density_min_rgb
  params.film_render.grain.uniformity = parity.grain_uniformity_rgb
  params.film_render.grain.blur = parity.grain_final_blur_um
  params.film_render.grain.blur_dye_clouds_um = parity.grain_blur_dye_clouds_um

  params.film_render.halation.active = parity.halation_enabled
  params.film_render.halation.scatter_amount = parity.scatter_amount
  params.film_render.halation.scatter_spatial_scale = parity.scatter_scale
  params.film_render.halation.halation_amount = parity.halation_amount
  params.film_render.halation.halation_spatial_scale = parity.halation_scale
  params.film_render.halation.halation_strength = parity.halation_strength_rgb
  params.film_render.halation.boost_ev = parity.halation_boost_ev
  params.film_render.halation.boost_range = parity.halation_boost_range
  params.film_render.halation.protect_ev = parity.halation_protect_ev

  params.camera.diffusion_filter.active = parity.camera_diffusion_enabled
  params.camera.diffusion_filter.strength = parity.camera_diffusion_strength
  params.camera.diffusion_filter.spatial_scale = parity.camera_diffusion_spatial_scale
  params.enlarger.diffusion_filter.active = parity.print_diffusion_enabled
  params.enlarger.diffusion_filter.strength = parity.print_diffusion_strength
  params.enlarger.diffusion_filter.spatial_scale = parity.print_diffusion_spatial_scale

  params.scanner.white_correction = parity.scanner_white_correction
  params.scanner.black_correction = parity.scanner_black_correction
  params.scanner.white_level = parity.scanner_white_level
  params.scanner.black_level = parity.scanner_black_level
  params.print_render.glare.active = parity.glare_percent > 0.0
  params.print_render.glare.percent = parity.glare_percent
  params.print_render.glare.roughness = parity.glare_roughness
  params.print_render.glare.blur = parity.glare_blur
  params.scanner.unsharp_mask = (parity.scanner_unsharp_radius_um, parity.scanner_unsharp_amount)

  params.debug.deactivate_spatial_effects = parity.deactivate_spatial_effects
  params.debug.deactivate_stochastic_effects = parity.deactivate_stochastic_effects
  return digest_params(params)


def run_python_stage(image: np.ndarray, stage: str, parity: ParityParams) -> np.ndarray:
  if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))
  from spektrafilm.runtime.pipeline import SimulationPipeline

  np.random.seed(parity.grain_seed)
  params = build_python_params(parity)
  pipeline = SimulationPipeline(params)
  preprocessed = pipeline._preprocess(image)
  film_log_raw = pipeline._filming_stage.expose(preprocessed)
  if stage == "film_log_raw":
    return film_log_raw
  film_density_cmy = pipeline._filming_stage.develop(film_log_raw)
  if stage in {"film_density_cmy", "film_density_cmy_grain"}:
    return film_density_cmy
  print_log_raw = pipeline._printing_stage.expose(film_density_cmy)
  if stage == "print_log_raw":
    return print_log_raw
  print_density_cmy = pipeline._printing_stage.develop(print_log_raw)
  if stage == "print_density_cmy":
    return print_density_cmy
  return pipeline._scanning_stage.scan(print_density_cmy)


def to_rgba(image: np.ndarray) -> np.ndarray:
  rgb = np.asarray(image, dtype=np.float32)
  alpha = np.ones((*rgb.shape[:2], 1), dtype=np.float32)
  return np.concatenate([rgb, alpha], axis=2)


def from_rgba(image: np.ndarray) -> np.ndarray:
  return np.asarray(image[..., :3], dtype=np.float64)


def write_raw_rgba(path: Path, image: np.ndarray) -> None:
  path.parent.mkdir(parents=True, exist_ok=True)
  to_rgba(image).astype(np.float32).tofile(path)


def read_raw_rgba(path: Path, width: int, height: int) -> np.ndarray:
  data = np.fromfile(path, dtype=np.float32)
  expected = width * height * 4
  if data.size != expected:
    raise RuntimeError(f"{path} has {data.size} floats, expected {expected}")
  return data.reshape(height, width, 4)


def safe_cache_name(value: str) -> str:
  return "".join(ch if ch.isalnum() or ch in ("-", "_", ".") else "_" for ch in value)


def case_reference_signature(case: Case) -> str:
  image = np.ascontiguousarray(case.pattern.image, dtype=np.float32)
  digest = hashlib.sha256()
  digest.update(b"spektrafilm-parity-reference-v1")
  digest.update(case.case_id.encode("utf-8"))
  digest.update(case.suite.encode("utf-8"))
  digest.update(case.pattern.name.encode("utf-8"))
  digest.update(case.stage.encode("utf-8"))
  digest.update(params_to_key_values(case.params, case.stage).encode("utf-8"))
  digest.update(str(image.shape).encode("utf-8"))
  digest.update(image.tobytes())
  return digest.hexdigest()


def load_or_generate_python_reference(
  case: Case,
  reference_cache_dir: Path | None,
  refresh_reference_cache: bool,
) -> tuple[np.ndarray, str]:
  if reference_cache_dir is None:
    return run_python_stage(case.pattern.image, case.stage, case.params), "generated"

  reference_cache_dir.mkdir(parents=True, exist_ok=True)
  signature = case_reference_signature(case)
  cache_stem = f"{safe_cache_name(case.case_id)}.{signature[:16]}"
  cache_path = reference_cache_dir / f"{cache_stem}.npy"
  metadata_path = reference_cache_dir / f"{cache_stem}.json"
  if cache_path.is_file() and not refresh_reference_cache:
    try:
      return np.asarray(np.load(cache_path), dtype=np.float64), "cached"
    except Exception:
      pass

  reference = run_python_stage(case.pattern.image, case.stage, case.params)
  temp_path = reference_cache_dir / f"{cache_stem}.{os.getpid()}.tmp.npy"
  np.save(temp_path, np.asarray(reference, dtype=np.float32), allow_pickle=False)
  temp_path.replace(cache_path)
  metadata_path.write_text(
      json.dumps(
          {
              "case_id": case.case_id,
              "suite": case.suite,
              "pattern": case.pattern.name,
              "stage": case.stage,
              "film": case.params.film,
              "paper": case.params.paper,
              "signature": signature,
              "shape": list(reference.shape),
          },
          indent=2,
          allow_nan=True,
      ) + "\n",
      encoding="utf-8",
  )
  return reference, "generated"


def run_metal_stage(
  harness: Path,
  build_dir: Path,
  case_dir: Path,
  image: np.ndarray,
  stage: str,
  parity: ParityParams,
  source_format: str = "float",
  destination_format: str = "float",
  host_layout: str = "contiguous",
) -> tuple[np.ndarray | None, str]:
  height, width = image.shape[:2]
  input_path = case_dir / "input.f32"
  output_path = case_dir / "metal.f32"
  params_path = case_dir / "params.txt"
  write_raw_rgba(input_path, image)
  params_path.write_text(params_to_key_values(parity, stage), encoding="utf-8")
  command = [
      str(harness),
      "--input", str(input_path),
      "--output", str(output_path),
      "--width", str(width),
      "--height", str(height),
      "--stage", stage,
      "--params", str(params_path),
      "--resource-dir", str(build_dir),
      "--source-format", source_format,
      "--destination-format", destination_format,
      "--host-layout", host_layout,
  ]
  result = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
  (case_dir / "metal_stdout.txt").write_text(result.stdout, encoding="utf-8")
  (case_dir / "metal_stderr.txt").write_text(result.stderr, encoding="utf-8")
  if result.returncode != 0:
    return None, f"INFRASTRUCTURE_FAILED: Metal harness exited {result.returncode}: {result.stderr.strip()}"
  return from_rgba(read_raw_rgba(output_path, width, height)), "OK"


def percentile_abs(diff: np.ndarray, percentile: float) -> float:
  return float(np.percentile(np.abs(diff), percentile))


def safe_psnr(reference: np.ndarray, rmse: float) -> float:
  data_range = max(float(np.nanmax(reference) - np.nanmin(reference)), 1.0e-6)
  if rmse <= 0.0:
    return float("inf")
  return float(20.0 * math.log10(data_range / rmse))


def safe_ssim(reference: np.ndarray, actual: np.ndarray) -> float:
  try:
    from skimage.metrics import structural_similarity
  except Exception:
    return float("nan")
  min_dim = min(reference.shape[0], reference.shape[1])
  if min_dim < 3:
    return float("nan")
  win_size = min(7, min_dim if min_dim % 2 == 1 else min_dim - 1)
  data_range = max(float(np.nanmax([reference, actual]) - np.nanmin([reference, actual])), 1.0e-6)
  return float(structural_similarity(reference, actual, channel_axis=2, data_range=data_range, win_size=win_size))


def radial_power_similarity(reference: np.ndarray, actual: np.ndarray) -> float:
  ref = reference - np.mean(reference, axis=(0, 1), keepdims=True)
  act = actual - np.mean(actual, axis=(0, 1), keepdims=True)
  ref_power = np.mean(np.abs(np.fft.rfft2(ref, axes=(0, 1))) ** 2, axis=2).ravel()
  act_power = np.mean(np.abs(np.fft.rfft2(act, axes=(0, 1))) ** 2, axis=2).ravel()
  denom = np.linalg.norm(ref_power) * np.linalg.norm(act_power)
  if denom <= 1.0e-12:
    return float("nan")
  return float(np.dot(ref_power, act_power) / denom)


def _scaled_min_similarity(default_threshold: float, threshold_scale: float) -> float:
  return 1.0 - (1.0 - default_threshold) * threshold_scale


def _uses_grain_statistics(suite: str, stage: str) -> bool:
  return suite in {"grain", "combined_stochastic"} or stage == "film_density_cmy_grain"


def classify_metrics(metrics: dict[str, float], suite: str, stage: str, threshold_scale: float = 1.0) -> str:
  scale = max(float(threshold_scale), 1.0e-6)
  if suite == "grain" or stage == "film_density_cmy_grain":
    min_power_similarity = _scaled_min_similarity(0.75, scale)
    failed = (
        metrics["mean_abs"] > 0.08 * scale
        or metrics["std_abs_delta"] > 0.08 * scale
        or (not math.isnan(metrics["power_similarity"]) and metrics["power_similarity"] < min_power_similarity)
    )
  elif suite == "combined_stochastic":
    min_power_similarity = _scaled_min_similarity(0.75, scale)
    failed = (
        metrics["nrmse"] > 0.08 * scale
        or metrics["p95_abs"] > 0.08 * scale
        or metrics["mean_abs"] > 0.08 * scale
        or metrics["std_abs_delta"] > 0.08 * scale
        or (not math.isnan(metrics["power_similarity"]) and metrics["power_similarity"] < min_power_similarity)
    )
  elif suite == "non_spatial":
    failed = metrics["max_abs"] > 0.015 * scale or metrics["p99_abs"] > 0.006 * scale or metrics["rmse"] > 0.003 * scale
  else:
    min_ssim = _scaled_min_similarity(0.94, scale)
    failed = (
        metrics["nrmse"] > 0.08 * scale
        or metrics["p95_abs"] > 0.08 * scale
        or (not math.isnan(metrics["ssim"]) and metrics["ssim"] < min_ssim)
    )
  return "FAILED TEST" if failed else "PASSED"


def compute_metrics(
  reference: np.ndarray,
  actual: np.ndarray,
  suite: str,
  stage: str,
  threshold_scale: float = 1.0,
) -> dict[str, float | str]:
  diff = np.asarray(actual, dtype=np.float64) - np.asarray(reference, dtype=np.float64)
  rmse = float(np.sqrt(np.mean(diff * diff)))
  ref_range = max(float(np.nanmax(reference) - np.nanmin(reference)), 1.0e-6)
  metrics: dict[str, float | str] = {
      "max_abs": float(np.max(np.abs(diff))),
      "p99_abs": percentile_abs(diff, 99.0),
      "p95_abs": percentile_abs(diff, 95.0),
      "mean_abs": float(np.mean(np.abs(diff))),
      "rmse": rmse,
      "nrmse": rmse / ref_range,
      "psnr": safe_psnr(reference, rmse),
      "ssim": safe_ssim(reference, actual),
      "mean_ref": float(np.mean(reference)),
      "mean_actual": float(np.mean(actual)),
      "std_ref": float(np.std(reference)),
      "std_actual": float(np.std(actual)),
      "mean_abs_delta": float(abs(np.mean(actual) - np.mean(reference))),
      "std_abs_delta": float(abs(np.std(actual) - np.std(reference))),
      "power_similarity": radial_power_similarity(reference, actual) if _uses_grain_statistics(suite, stage) else float("nan"),
  }
  metrics["threshold_scale"] = float(threshold_scale)
  metrics["status"] = classify_metrics(metrics, suite, stage, threshold_scale)
  return metrics


def _setup_matplotlib(output_dir: Path):
  os.environ.setdefault("MPLCONFIGDIR", str(output_dir / ".matplotlib"))
  import matplotlib

  matplotlib.use("Agg", force=True)
  import matplotlib.pyplot as plt

  return plt


def display_image(image: np.ndarray) -> np.ndarray:
  data = np.asarray(image[..., :3], dtype=np.float64)
  lo = float(np.nanpercentile(data, 1.0))
  hi = float(np.nanpercentile(data, 99.0))
  if not np.isfinite(lo) or not np.isfinite(hi) or hi <= lo:
    lo, hi = float(np.nanmin(data)), float(np.nanmax(data))
  if hi <= lo:
    hi = lo + 1.0
  return np.clip((data - lo) / (hi - lo), 0.0, 1.0)


def diff_preview_images(diff: np.ndarray) -> tuple[np.ndarray, np.ndarray, float]:
  abs_diff = np.abs(np.asarray(diff, dtype=np.float64))
  signed_scale = max(float(np.nanpercentile(abs_diff, 99.0)), 1.0e-6)
  abs_preview = display_image(abs_diff)
  signed_preview = np.clip(diff / (2.0 * signed_scale) + 0.5, 0.0, 1.0)
  return abs_preview, signed_preview, signed_scale


def write_visuals(case_dir: Path, case: Case, reference: np.ndarray, actual: np.ndarray, output_root: Path) -> None:
  plt = _setup_matplotlib(output_root)
  diff = actual - reference
  abs_preview, signed_preview, signed_scale = diff_preview_images(diff)

  panels = [
      ("input", display_image(case.pattern.image)),
      ("python", display_image(reference)),
      ("metal", display_image(actual)),
      ("abs diff stretched", abs_preview),
      (f"signed diff +/-{signed_scale:.4g}", signed_preview),
  ]
  fig, axes = plt.subplots(1, len(panels), figsize=(16, 4), constrained_layout=True)
  for axis, (title, image) in zip(axes, panels):
    axis.imshow(image)
    axis.set_title(title)
    axis.axis("off")
  fig.suptitle(f"{case.case_id} / {case.stage}")
  fig.savefig(case_dir / "contact_sheet.png", dpi=140)
  plt.close(fig)

  center = reference.shape[0] // 2
  fig, axis = plt.subplots(figsize=(9, 4), constrained_layout=True)
  for channel, label in enumerate(("R", "G", "B")):
    axis.plot(reference[center, :, channel], label=f"py {label}", linewidth=1.2)
    axis.plot(actual[center, :, channel], label=f"metal {label}", linestyle="--", linewidth=1.0)
  axis.set_title("Center-row channel profile")
  axis.set_xlabel("x")
  axis.legend(ncol=3, fontsize=8)
  fig.savefig(case_dir / "line_profile.png", dpi=140)
  plt.close(fig)

  fig, axis = plt.subplots(figsize=(7, 4), constrained_layout=True)
  axis.hist(reference.ravel(), bins=80, alpha=0.5, label="python")
  axis.hist(actual.ravel(), bins=80, alpha=0.5, label="metal")
  axis.set_title("Value histogram")
  axis.legend()
  fig.savefig(case_dir / "histogram.png", dpi=140)
  plt.close(fig)


def write_optional_exr(path: Path, image: np.ndarray) -> bool:
  try:
    import OpenImageIO as oiio
  except Exception:
    return False
  height, width, channels = image.shape
  out = oiio.ImageOutput.create(str(path))
  if out is None:
    return False
  spec = oiio.ImageSpec(width, height, channels, oiio.TypeDesc("float"))
  try:
    out.open(str(path), spec)
    out.write_image(np.asarray(image, dtype=np.float32))
  finally:
    out.close()
  return True


def write_case_arrays(case_dir: Path, case: Case, reference: np.ndarray, actual: np.ndarray | None) -> None:
  payload = {
      "input_rgb": np.asarray(case.pattern.image, dtype=np.float32),
      "python_rgb": np.asarray(reference, dtype=np.float32),
  }
  if actual is not None:
    payload["metal_rgb"] = np.asarray(actual, dtype=np.float32)
    payload["diff_rgb"] = np.asarray(actual - reference, dtype=np.float32)
  np.savez_compressed(case_dir / "outputs.npz", **payload)
  write_optional_exr(case_dir / "python.exr", reference)
  if actual is not None:
    diff = actual - reference
    abs_preview, signed_preview, signed_scale = diff_preview_images(diff)
    write_optional_exr(case_dir / "metal.exr", actual)
    write_optional_exr(case_dir / "diff.exr", diff)
    write_optional_exr(case_dir / "abs_diff.exr", np.abs(diff))
    write_optional_exr(case_dir / "abs_diff_preview.exr", abs_preview)
    write_optional_exr(case_dir / "signed_diff_preview.exr", signed_preview)
    (case_dir / "diff_exr_notes.json").write_text(
        json.dumps(
            {
                "diff.exr": "Raw signed float difference: Metal - Python. This often looks black in viewers because values are tiny and negative values clip.",
                "abs_diff.exr": "Raw absolute float difference. This can also look black when errors are small.",
                "abs_diff_preview.exr": "Viewable contrast-stretched absolute difference using the same display normalization as the contact sheet.",
                "signed_diff_preview.exr": "Viewable signed difference. 0.5 is no difference; above 0.5 means Metal is higher; below 0.5 means Metal is lower.",
                "signed_preview_scale": signed_scale,
                "signed_preview_formula": "clip((Metal - Python) / (2 * signed_preview_scale) + 0.5, 0, 1)",
            },
            indent=2,
            allow_nan=True,
        ) + "\n",
        encoding="utf-8",
    )


def apply_quality_fail_sentinel(actual: np.ndarray) -> np.ndarray:
  """Deterministically perturb Metal output so metric classification must fail."""
  perturbed = np.asarray(actual, dtype=np.float64).copy()
  perturbed[..., :3] += 0.25
  return perturbed


def combined_stress_params(*, stochastic: bool) -> ParityParams:
  params = ParityParams(
      deactivate_spatial_effects=False,
      deactivate_stochastic_effects=not stochastic,
      grain_enabled=stochastic,
  )
  params.halation_enabled = True
  params.camera_diffusion_enabled = True
  params.camera_diffusion_strength = 0.5
  params.print_diffusion_enabled = True
  params.print_diffusion_strength = 0.45
  params.dir_amount = 0.25
  if stochastic:
    params.glare_percent = 0.015
    params.glare_blur = 1.0
  params.scanner_unsharp_radius_um = 0.7
  params.scanner_unsharp_amount = 0.45
  return params


def quick_cases(patterns: list[Pattern]) -> list[Case]:
  selected = {pattern.name: pattern for pattern in patterns}
  cases: list[Case] = []
  for pattern_name in ("gray_ramp", "log_gray_ramp", "rgb_channel_ramps", "primary_secondary_skin_foliage_patches", "hard_edge"):
    pattern = selected.get(pattern_name)
    if pattern is None:
      continue
    for stage in ("film_log_raw", "film_density_cmy", "print_log_raw", "print_density_cmy", "final_linear_rgb"):
      cases.append(Case(f"quick__{pattern_name}__{stage}", "non_spatial", pattern, stage, ParityParams()))

  impulse = selected.get("impulse_highlight")
  if impulse is not None:
    spatial = ParityParams(deactivate_spatial_effects=False)
    spatial.halation_enabled = True
    cases.append(Case("quick__impulse_highlight__halation_final", "spatial", impulse, "final_linear_rgb", spatial))

  hard_edge = selected.get("hard_edge")
  if hard_edge is not None:
    camera_diffusion = ParityParams(deactivate_spatial_effects=False)
    camera_diffusion.camera_diffusion_enabled = True
    camera_diffusion.camera_diffusion_strength = 0.75
    cases.append(Case("quick__hard_edge__camera_diffusion_final", "spatial", hard_edge, "final_linear_rgb", camera_diffusion))

    print_diffusion = ParityParams(deactivate_spatial_effects=False)
    print_diffusion.print_diffusion_enabled = True
    print_diffusion.print_diffusion_strength = 0.75
    cases.append(Case("quick__hard_edge__print_diffusion_final", "spatial", hard_edge, "final_linear_rgb", print_diffusion))

  slanted_edge = selected.get("slanted_edge")
  if slanted_edge is not None:
    scanner = ParityParams(deactivate_spatial_effects=False)
    scanner.scanner_enabled = True
    scanner.glare_percent = 0.02
    scanner.glare_blur = 1.2
    scanner.scanner_unsharp_radius_um = 0.8
    scanner.scanner_unsharp_amount = 0.5
    cases.append(Case("quick__slanted_edge__scanner_glare_final", "spatial", slanted_edge, "final_linear_rgb", scanner))

  stress = selected.get("spatial_stress")
  if stress is not None:
    dir_params = ParityParams(deactivate_spatial_effects=False)
    dir_params.dir_amount = 0.35
    dir_params.dir_diffusion_um = 25.0
    dir_params.dir_diffusion_tail_um = 180.0
    cases.append(Case("quick__spatial_stress__dir_final", "spatial", stress, "final_linear_rgb", dir_params))

    cases.append(Case(
        "quick__spatial_stress__combined_no_grain_final",
        "combined",
        stress,
        "final_linear_rgb",
        combined_stress_params(stochastic=False),
    ))
    cases.append(Case(
        "quick__spatial_stress__combined_pipeline_final",
        "combined_stochastic",
        stress,
        "final_linear_rgb",
        combined_stress_params(stochastic=True),
    ))

  log_ramp = selected.get("log_gray_ramp")
  if log_ramp is not None:
    grain = ParityParams(deactivate_spatial_effects=False, deactivate_stochastic_effects=False, grain_enabled=True)
    cases.append(Case("quick__log_gray_ramp__production_grain_density", "grain", log_ramp, "film_density_cmy_grain", grain))
  return cases


def full_cases(patterns: list[Pattern]) -> list[Case]:
  cases = quick_cases(patterns)
  for film in FILMS:
    for paper in PAPERS:
      params = ParityParams(film=film, paper=paper)
      for pattern in patterns:
        for stage in STAGES:
          suite = "non_spatial" if stage in NON_SPATIAL_STAGES else "grain"
          cases.append(Case(f"full__{film}__{paper}__{pattern.name}__{stage}", suite, pattern, stage, params))
  return cases


def filter_cases(cases: list[Case], stage_names: set[str] | None) -> list[Case]:
  if stage_names is None:
    return cases
  return [case for case in cases if case.stage in stage_names]


def run_cases(
  cases: list[Case],
  harness: Path,
  build_dir: Path,
  output_dir: Path,
  *,
  skip_metal: bool = False,
  source_format: str = "float",
  destination_format: str = "float",
  host_layout: str = "contiguous",
  reference_cache_dir: Path | None = None,
  refresh_reference_cache: bool = False,
  quality_threshold_scale: float = 1.0,
  force_quality_fail: bool = False,
) -> tuple[list[dict], list[dict]]:
  metrics_rows: list[dict] = []
  manifest_cases: list[dict] = []
  for index, case in enumerate(cases, start=1):
    case_dir = output_dir / "cases" / case.case_id
    case_dir.mkdir(parents=True, exist_ok=True)
    print(f"[{index}/{len(cases)}] {case.case_id}")
    reference, reference_status = load_or_generate_python_reference(
        case,
        reference_cache_dir,
        refresh_reference_cache,
    )
    actual = None
    metal_status = "SKIPPED"
    if not skip_metal:
      actual, metal_status = run_metal_stage(
          harness,
          build_dir,
          case_dir,
          case.pattern.image,
          case.stage,
          case.params,
          source_format=source_format,
          destination_format=destination_format,
          host_layout=host_layout,
      )
    if actual is not None and force_quality_fail:
      actual = apply_quality_fail_sentinel(actual)
    write_case_arrays(case_dir, case, reference, actual)
    if actual is not None:
      metrics = compute_metrics(reference, actual, case.suite, case.stage, quality_threshold_scale)
      write_visuals(case_dir, case, reference, actual, output_dir)
    else:
      metrics = {
          "status": metal_status,
          "max_abs": float("nan"),
          "p99_abs": float("nan"),
          "p95_abs": float("nan"),
          "mean_abs": float("nan"),
          "rmse": float("nan"),
          "nrmse": float("nan"),
          "psnr": float("nan"),
          "ssim": float("nan"),
          "mean_ref": float(np.mean(reference)),
          "mean_actual": float("nan"),
          "std_ref": float(np.std(reference)),
          "std_actual": float("nan"),
          "mean_abs_delta": float("nan"),
          "std_abs_delta": float("nan"),
          "power_similarity": float("nan"),
      }
    row = {
        "case_id": case.case_id,
        "suite": case.suite,
        "pattern": case.pattern.name,
        "stage": case.stage,
        "film": case.params.film,
        "paper": case.params.paper,
        "reference_status": reference_status,
        "metal_status": metal_status,
        **metrics,
    }
    metrics_rows.append(row)
    manifest_cases.append({
        "case_id": case.case_id,
        "suite": case.suite,
        "pattern": case.pattern.name,
        "stage": case.stage,
        "film": case.params.film,
        "paper": case.params.paper,
        "path": str(case_dir.relative_to(output_dir)),
        "reference_status": reference_status,
        "status": metrics["status"],
        "unsupported": case.params.unsupported,
    })
  return metrics_rows, manifest_cases


def write_reports(output_dir: Path, metrics_rows: list[dict], manifest_cases: list[dict], args: argparse.Namespace) -> None:
  output_dir.mkdir(parents=True, exist_ok=True)
  metrics_path = output_dir / "metrics.json"
  metrics_path.write_text(json.dumps(metrics_rows, indent=2, allow_nan=True) + "\n", encoding="utf-8")
  if metrics_rows:
    with (output_dir / "summary.csv").open("w", newline="", encoding="utf-8") as file:
      writer = csv.DictWriter(file, fieldnames=list(metrics_rows[0].keys()))
      writer.writeheader()
      writer.writerows(metrics_rows)
  manifest = {
      "runtime": "spektrafilm-python-vs-metal",
      "harness": str(args.harness),
      "build_dir": str(args.build_dir),
      "python_data_dir": str(getattr(args, "python_data_dir", "")),
      "python_profile_dir": str(getattr(args, "python_profile_dir", "")),
      "reference_cache_dir": str(getattr(args, "reference_cache_dir", "") or ""),
      "refresh_reference_cache": bool(getattr(args, "refresh_reference_cache", False)),
      "mode": args.mode,
      "source_format": getattr(args, "source_format", "float"),
      "destination_format": getattr(args, "destination_format", "float"),
      "host_layout": getattr(args, "host_layout", "contiguous"),
      "quality_threshold_scale": float(getattr(args, "quality_threshold_scale", 1.0)),
      "force_quality_fail": bool(getattr(args, "force_quality_fail", False)),
      "cases": manifest_cases,
  }
  (output_dir / "manifest.json").write_text(json.dumps(manifest, indent=2, allow_nan=True) + "\n", encoding="utf-8")

  plt = _setup_matplotlib(output_dir)
  labels = [row["case_id"] for row in metrics_rows]
  rmse = [row.get("rmse", float("nan")) for row in metrics_rows]
  status_colors = ["#b42318" if row.get("status") == "FAILED TEST" else "#1a7f37" for row in metrics_rows]
  if labels:
    fig, axis = plt.subplots(figsize=(max(8, min(28, len(labels) * 0.28)), 4), constrained_layout=True)
    axis.bar(np.arange(len(labels)), rmse, color=status_colors)
    axis.set_title("RMSE by case")
    axis.set_ylabel("RMSE")
    axis.set_xticks(np.arange(len(labels)))
    axis.set_xticklabels(labels, rotation=90, fontsize=6)
    fig.savefig(output_dir / "failure_summary.png", dpi=140)
    plt.close(fig)


def parse_csv_set(value: str | None) -> set[str] | None:
  if not value:
    return None
  return {item.strip() for item in value.split(",") if item.strip()}


def main(argv: list[str] | None = None) -> int:
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument("--output", type=Path, required=True, help="Directory for parity reports.")
  parser.add_argument("--build-dir", type=Path, default=DEFAULT_BUILD_DIR, help="OFX build directory containing the Metal harness resources.")
  parser.add_argument("--harness", type=Path, default=None, help="Path to SpektraFilmParityHarness. Defaults to BUILD_DIR/SpektraFilmParityHarness.")
  parser.add_argument("--mode", choices=("quick", "full"), default="quick")
  parser.add_argument("--width", type=int, default=96)
  parser.add_argument("--height", type=int, default=64)
  parser.add_argument("--patterns", help="Comma-separated pattern names to include.")
  parser.add_argument("--stages", help="Comma-separated stage names to include.")
  parser.add_argument("--source-format", choices=("float", "half"), default="float", help="Host source format passed to the Metal parity harness.")
  parser.add_argument("--destination-format", choices=("float", "half"), default="float", help="Host destination format passed to the Metal parity harness.")
  parser.add_argument("--host-layout", choices=("contiguous", "strided", "offset"), default="contiguous", help="Host memory layout passed to the Metal parity harness.")
  parser.add_argument("--quality-threshold-scale", type=float, default=1.0, help="Scale metric failure thresholds. Values below 1.0 are stricter; default is 1.0.")
  parser.add_argument("--force-quality-fail", action="store_true", help="Perturb Metal output before metric classification. Used as a report-only sentinel to verify quality failures are surfaced.")
  parser.add_argument("--skip-metal", action="store_true", help="Generate Python references and reports without running Metal.")
  parser.add_argument("--python-profile-dir", type=Path, default=DEFAULT_ARCHIVE_PROFILE_DIR, help="Profile JSON directory for the local Python reference. Defaults to Resources/data/profiles/archive.")
  parser.add_argument("--python-data-dir", type=Path, help="Prepared SpektraFilm Python data directory. Defaults to OUTPUT/python_data.")
  parser.add_argument("--reference-cache-dir", type=Path, help="Directory for cached Python reference arrays reused across Metal candidate runs.")
  parser.add_argument("--refresh-reference-cache", action="store_true", help="Regenerate Python references even when cache entries exist.")
  args = parser.parse_args(argv)
  if args.quality_threshold_scale <= 0.0:
    raise SystemExit("--quality-threshold-scale must be positive.")

  args.output.mkdir(parents=True, exist_ok=True)
  os.environ.setdefault("MPLCONFIGDIR", str(args.output / ".matplotlib"))
  os.environ.setdefault("XDG_CACHE_HOME", str(args.output / ".cache"))
  args.python_data_dir = prepare_python_data_dir(args.output, args.python_profile_dir, args.python_data_dir)
  os.environ["SPEKTRAFILM_DATA_DIR"] = str(args.python_data_dir)
  args.harness = args.harness or (args.build_dir / "SpektraFilmParityHarness")
  patterns = select_patterns(make_patterns(args.width, args.height), parse_csv_set(args.patterns))
  cases = quick_cases(patterns) if args.mode == "quick" else full_cases(patterns)
  cases = filter_cases(cases, parse_csv_set(args.stages))
  if not cases:
    raise SystemExit("No parity cases selected.")
  metrics_rows, manifest_cases = run_cases(
      cases,
      args.harness,
      args.build_dir,
      args.output,
      skip_metal=args.skip_metal,
      source_format=args.source_format,
      destination_format=args.destination_format,
      host_layout=args.host_layout,
      reference_cache_dir=args.reference_cache_dir,
      refresh_reference_cache=args.refresh_reference_cache,
      quality_threshold_scale=args.quality_threshold_scale,
      force_quality_fail=args.force_quality_fail,
  )
  write_reports(args.output, metrics_rows, manifest_cases, args)
  failed = sum(1 for row in metrics_rows if row.get("status") == "FAILED TEST")
  infra = sum(1 for row in metrics_rows if str(row.get("status", "")).startswith("INFRASTRUCTURE_FAILED"))
  print(f"Wrote parity report to {args.output} ({failed} failed metric checks, {infra} infrastructure failures).")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
