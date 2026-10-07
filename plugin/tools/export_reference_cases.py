#!/usr/bin/env python3
"""Export Python SpektraFilm reference cases for OFX parity testing."""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

import numpy as np


REPO_ROOT = Path(__file__).resolve().parents[3]
OFX_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = Path(os.environ.get("SPEKTRAFILM_DATA_DIR", OFX_ROOT / "Resources" / "data"))
os.environ.setdefault("SPEKTRAFILM_DATA_DIR", str(DATA_DIR))
SRC_DIR = REPO_ROOT / "src"
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from spektrafilm.runtime.params_builder import digest_params, init_params
from spektrafilm.runtime.pipeline import SimulationPipeline


def gray_ramp(width: int = 32, height: int = 16) -> np.ndarray:
    ramp = np.linspace(0.01, 1.0, width, dtype=np.float64)
    return np.repeat(ramp[None, :, None], height, axis=0).repeat(3, axis=2)


def color_patches() -> np.ndarray:
    colors = np.array(
        [
            [0.184, 0.184, 0.184],
            [0.5, 0.05, 0.05],
            [0.05, 0.5, 0.05],
            [0.05, 0.05, 0.5],
            [0.8, 0.7, 0.45],
            [0.02, 0.02, 0.02],
            [2.0, 2.0, 2.0],
            [0.9, 0.4, 0.1],
        ],
        dtype=np.float64,
    )
    patch = np.zeros((16, 32, 3), dtype=np.float64)
    for index, color in enumerate(colors):
        y0 = 0 if index < 4 else 8
        x0 = (index % 4) * 8
        patch[y0 : y0 + 8, x0 : x0 + 8, :] = color
    return patch


def highlight_edge(size: int = 32) -> np.ndarray:
    image = np.zeros((size, size, 3), dtype=np.float64) + 0.02
    image[:, size // 2 :, :] = 0.7
    image[size // 2 - 2 : size // 2 + 2, size // 2 - 2 : size // 2 + 2, :] = 8.0
    return image


def make_params(*, enlarged_production_grain: bool = False):
    params = init_params("kodak_portra_400", "kodak_portra_endura")
    params.camera.auto_exposure = False
    params.debug.deactivate_spatial_effects = False
    params.debug.deactivate_stochastic_effects = not enlarged_production_grain
    params.settings.use_enlarger_lut = False
    params.settings.use_scanner_lut = False
    params.io.input_color_space = "ITU-R BT.2020"
    params.io.input_cctf_decoding = False
    params.io.output_color_space = "ITU-R BT.2020"
    params.io.output_cctf_encoding = False
    if enlarged_production_grain:
        params.io.crop = True
        params.io.crop_center = (0.5, 0.5)
        params.io.crop_size = (0.25, 0.25)
        params.io.upscale_factor = 4.0
    return digest_params(params)


def run_stage_reference(image: np.ndarray, *, enlarged_production_grain: bool = False) -> dict[str, np.ndarray]:
    params = make_params(enlarged_production_grain=enlarged_production_grain)
    pipeline = SimulationPipeline(params)
    preprocessed = pipeline._preprocess(image)
    film_log_raw = pipeline._filming_stage.expose(preprocessed)
    film_density_cmy = pipeline._filming_stage.develop(film_log_raw)
    print_log_raw = pipeline._printing_stage.expose(film_density_cmy)
    print_density_cmy = pipeline._printing_stage.develop(print_log_raw)
    output_rgb = pipeline._scanning_stage.scan(print_density_cmy)
    return {
        "input_rgb": image,
        "preprocessed_rgb": preprocessed,
        "film_log_raw": film_log_raw,
        "film_density_cmy": film_density_cmy,
        "print_log_raw": print_log_raw,
        "print_density_cmy": print_density_cmy,
        "output_rgb": output_rgb,
    }


def export_references(output: Path) -> None:
    output.mkdir(parents=True, exist_ok=True)
    cases = {
        "gray_ramp": gray_ramp(),
        "color_patches": color_patches(),
        "highlight_edge": highlight_edge(),
    }
    manifest = {
        "runtime": "spektrafilm",
        "film": "kodak_portra_400",
        "paper": "kodak_portra_endura",
        "input_color_space": "ITU-R BT.2020",
        "output_color_space": "ITU-R BT.2020",
        "cases": [],
    }
    for name, image in cases.items():
        stages = run_stage_reference(image)
        case_path = output / f"{name}.npz"
        np.savez_compressed(case_path, **stages)
        manifest["cases"].append({"name": name, "path": case_path.name})

    stages = run_stage_reference(highlight_edge(32), enlarged_production_grain=True)
    case_path = output / "enlarged_production_grain.npz"
    np.savez_compressed(case_path, **stages)
    manifest["cases"].append(
        {
            "name": "enlarged_production_grain",
            "path": case_path.name,
            "enlarger_scale": 4.0,
            "enlarger_offset_x_percent": 0.0,
            "enlarger_offset_y_percent": 0.0,
            "production_grain": True,
        }
    )

    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True, help="Output directory for reference .npz files.")
    args = parser.parse_args(argv)
    export_references(args.output)
    print(f"Wrote reference cases to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
