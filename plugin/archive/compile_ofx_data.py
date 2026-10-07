#!/usr/bin/env python3
"""Compile SpektraFilm Python profile resources into native OFX data.

The output format is intentionally simple for the first native plugin stage:

    8 bytes   magic: SPKOFX1\0
    8 bytes   little-endian manifest JSON byte length
    N bytes   UTF-8 manifest JSON
    rest      NumPy NPZ payload with profile arrays and LUTs

The C++ loader currently validates the magic header only; the deterministic
Metal core will consume the manifest and NPZ payload once the spectral kernels
are ported.
"""

from __future__ import annotations

import argparse
import io
import json
import os
import struct
import sys
from pathlib import Path
from typing import Any

import numpy as np


REPO_ROOT = Path(__file__).resolve().parents[3]
OFX_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = Path(os.environ.get("SPEKTRAFILM_DATA_DIR", OFX_ROOT / "Resources" / "data"))
os.environ.setdefault("SPEKTRAFILM_DATA_DIR", str(DATA_DIR))
SRC_DIR = REPO_ROOT / "src"
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))
TOOLS_DIR = Path(__file__).resolve().parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))
os.environ.setdefault("MPLCONFIGDIR", "/private/tmp/spektrafilm-mpl-cache")
os.environ.setdefault("XDG_CACHE_HOME", "/private/tmp/spektrafilm-xdg-cache")

from spektrafilm.profiles.io import Profile, load_profile
from spektrafilm.utils.io import read_neutral_print_filters
from spektrafilm.utils.spectral_upsampling import HANATOS2025_SPECTRA_LUT
from ofx_stock_lists import FILMS, PAPERS


MAGIC = b"SPKOFX1\0"


def _json_safe(value: Any) -> Any:
    if isinstance(value, np.ndarray):
        return value.tolist()
    if isinstance(value, np.generic):
        return value.item()
    if isinstance(value, dict):
        return {str(k): _json_safe(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_json_safe(v) for v in value]
    return value


def _profile_manifest(profile: Profile, index: int) -> dict[str, Any]:
    data = profile.data
    return {
        "index": index,
        "stock": profile.info.stock,
        "name": profile.info.name,
        "type": profile.info.type,
        "support": profile.info.support,
        "stage": profile.info.stage,
        "use": profile.info.use,
        "antihalation": profile.info.antihalation,
        "reference_illuminant": profile.info.reference_illuminant,
        "viewing_illuminant": profile.info.viewing_illuminant,
        "wavelength_count": int(data.wavelengths.shape[0]),
        "exposure_count": int(data.log_exposure.shape[0]),
        "has_layer_curves": bool(data.density_curves_layers.size),
    }


def _profile_arrays(prefix: str, profile: Profile) -> dict[str, np.ndarray]:
    data = profile.data
    return {
        f"{prefix}.wavelengths": np.asarray(data.wavelengths, dtype=np.float32),
        f"{prefix}.log_sensitivity": np.asarray(data.log_sensitivity, dtype=np.float32),
        f"{prefix}.bandpass_hanatos2025": np.asarray(data.bandpass_hanatos2025, dtype=np.float32),
        f"{prefix}.channel_density": np.asarray(data.channel_density, dtype=np.float32),
        f"{prefix}.base_density": np.asarray(data.base_density, dtype=np.float32),
        f"{prefix}.midscale_neutral_density": np.asarray(data.midscale_neutral_density, dtype=np.float32),
        f"{prefix}.log_exposure": np.asarray(data.log_exposure, dtype=np.float32),
        f"{prefix}.density_curves": np.asarray(data.density_curves, dtype=np.float32),
        f"{prefix}.density_curves_layers": np.asarray(data.density_curves_layers, dtype=np.float32),
    }


def build_payload() -> tuple[dict[str, Any], bytes]:
    film_profiles = [load_profile(stock) for stock in FILMS]
    paper_profiles = [load_profile(stock) for stock in PAPERS]

    arrays: dict[str, np.ndarray] = {
        "spectral_upsampling.hanatos2025": np.asarray(HANATOS2025_SPECTRA_LUT, dtype=np.float32),
    }
    manifest: dict[str, Any] = {
        "format": "SPKOFX1",
        "version": 1,
        "films": [],
        "papers": [],
        "neutral_print_filters": _json_safe(read_neutral_print_filters()),
    }

    for index, profile in enumerate(film_profiles):
        key = f"film.{index}.{profile.info.stock}"
        manifest["films"].append(_profile_manifest(profile, index))
        arrays.update(_profile_arrays(key, profile))

    for index, profile in enumerate(paper_profiles):
        key = f"paper.{index}.{profile.info.stock}"
        manifest["papers"].append(_profile_manifest(profile, index))
        arrays.update(_profile_arrays(key, profile))

    npz_buffer = io.BytesIO()
    np.savez_compressed(npz_buffer, **arrays)
    return manifest, npz_buffer.getvalue()


def write_compiled_data(output: Path) -> Path:
    manifest, npz_payload = build_payload()
    manifest_bytes = json.dumps(manifest, indent=2, sort_keys=True).encode("utf-8")
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("wb") as file:
        file.write(MAGIC)
        file.write(struct.pack("<Q", len(manifest_bytes)))
        file.write(manifest_bytes)
        file.write(npz_payload)

    manifest_path = output.with_suffix(".manifest.json")
    manifest_path.write_text(manifest_bytes.decode("utf-8") + "\n", encoding="utf-8")
    return manifest_path


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=OFX_ROOT / "Resources" / "SpektraFilmData.spkdata",
        help="Compiled data output path.",
    )
    args = parser.parse_args(argv)

    manifest_path = write_compiled_data(args.output)
    print(f"Wrote {args.output}")
    print(f"Wrote {manifest_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
