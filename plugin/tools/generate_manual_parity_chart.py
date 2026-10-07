#!/usr/bin/env python3
"""Generate a deterministic scene-linear Rec.2020 chart for manual parity checks."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import OpenImageIO as oiio


def _grid(width: int, height: int) -> tuple[np.ndarray, np.ndarray]:
    x = np.linspace(0.0, 1.0, width, dtype=np.float64)
    y = np.linspace(0.0, 1.0, height, dtype=np.float64)
    return np.meshgrid(x, y, indexing="xy")


def _hue_sweep(width: int, height: int) -> np.ndarray:
    x, y = _grid(width, height)
    angle = 2.0 * np.pi * x
    saturation = y
    image = np.zeros((height, width, 3), dtype=np.float64)
    image[..., 0] = np.clip(0.5 + 0.5 * np.cos(angle) * saturation, 0.0, 1.0)
    image[..., 1] = np.clip(0.5 + 0.5 * np.cos(angle - 2.0 * np.pi / 3.0) * saturation, 0.0, 1.0)
    image[..., 2] = np.clip(0.5 + 0.5 * np.cos(angle + 2.0 * np.pi / 3.0) * saturation, 0.0, 1.0)
    return image


def _patches(width: int, height: int) -> np.ndarray:
    colors = np.array(
        [
            [0.000, 0.000, 0.000],
            [0.010, 0.010, 0.010],
            [0.040, 0.040, 0.040],
            [0.184, 0.184, 0.184],
            [0.500, 0.500, 0.500],
            [1.000, 1.000, 1.000],
            [2.000, 2.000, 2.000],
            [4.000, 4.000, 4.000],
            [0.900, 0.100, 0.100],
            [0.100, 0.900, 0.100],
            [0.100, 0.100, 0.900],
            [0.900, 0.900, 0.100],
            [0.100, 0.900, 0.900],
            [0.900, 0.100, 0.900],
            [0.750, 0.480, 0.340],
            [0.180, 0.300, 0.120],
        ],
        dtype=np.float64,
    )
    image = np.zeros((height, width, 3), dtype=np.float64)
    rows, cols = 4, 4
    for index, color in enumerate(colors):
        y0 = (index // cols) * height // rows
        y1 = (index // cols + 1) * height // rows
        x0 = (index % cols) * width // cols
        x1 = (index % cols + 1) * width // cols
        image[y0:y1, x0:x1, :] = color
    return image


def _zone_plate(width: int, height: int) -> np.ndarray:
    x, y = _grid(width, height)
    radius = np.sqrt((x - 0.5) ** 2 + (y - 0.5) ** 2)
    rings = 0.5 + 0.5 * np.sin(360.0 * radius * radius)
    slanted = np.full_like(rings, 0.04)
    slanted[x + 0.35 * y > 0.55] = 0.8
    checker = ((((np.arange(height)[:, None] // 16) + (np.arange(width)[None, :] // 16)) % 2) * 0.7 + 0.08).astype(np.float64)
    return np.stack((slanted, rings, checker), axis=-1)


def make_chart(width: int, height: int) -> np.ndarray:
    chart = np.full((height, width, 3), 0.184, dtype=np.float64)
    row_h = height // 4
    col_w = width // 3

    x = np.linspace(0.0, 1.0, width, dtype=np.float64)
    gray = np.repeat(x[None, :, None], row_h, axis=0).repeat(3, axis=2)
    chart[:row_h, :, :] = gray

    log_values = 0.184 * np.power(2.0, np.linspace(-8.0, 5.0, width, dtype=np.float64))
    log_ramp = np.repeat(log_values[None, :, None], row_h, axis=0).repeat(3, axis=2)
    chart[row_h:2 * row_h, :, :] = log_ramp

    x2, y2 = _grid(col_w, row_h)
    chart[2 * row_h:3 * row_h, :col_w, :] = np.stack((x2, y2, 1.0 - x2), axis=-1)
    chart[2 * row_h:3 * row_h, col_w:2 * col_w, :] = _hue_sweep(col_w, row_h)
    chart[2 * row_h:3 * row_h, 2 * col_w:, :] = _patches(width - 2 * col_w, row_h)

    chart[3 * row_h:, :col_w, :] = _zone_plate(col_w, height - 3 * row_h)
    near_black = np.repeat(np.linspace(0.0, 0.08, col_w, dtype=np.float64)[None, :, None], height - 3 * row_h, axis=0).repeat(3, axis=2)
    chart[3 * row_h:, col_w:2 * col_w, :] = near_black
    hdr = np.repeat(np.linspace(0.0, 8.0, width - 2 * col_w, dtype=np.float64)[None, :, None], height - 3 * row_h, axis=0).repeat(3, axis=2)
    chart[3 * row_h:, 2 * col_w:, :] = hdr

    impulse_size = max(4, min(width, height) // 96)
    cy, cx = height // 2, width // 2
    chart[cy - impulse_size:cy + impulse_size, cx - impulse_size:cx + impulse_size, :] = 8.0
    return chart


def write_exr(path: Path, image: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    height, width, channels = image.shape
    spec = oiio.ImageSpec(width, height, channels, oiio.TypeDesc("float"))
    spec.channelnames = ["R", "G", "B"]
    spec.attribute("oiio:ColorSpace", "Linear Rec.2020")
    out = oiio.ImageOutput.create(str(path))
    if out is None:
        raise RuntimeError(f"Could not create {path}")
    try:
        out.open(str(path), spec)
        out.write_image(np.asarray(image, dtype=np.float32))
    finally:
        out.close()


def write_preview_png(path: Path, image: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    preview = np.clip(image, 0.0, 1.0)
    preview = np.where(preview <= 0.0031308, 12.92 * preview, 1.055 * np.power(preview, 1.0 / 2.4) - 0.055)
    preview_u8 = np.asarray(np.clip(preview, 0.0, 1.0) * 255.0 + 0.5, dtype=np.uint8)
    height, width, channels = preview_u8.shape
    spec = oiio.ImageSpec(width, height, channels, oiio.TypeDesc("uint8"))
    spec.channelnames = ["R", "G", "B"]
    spec.attribute("oiio:ColorSpace", "sRGB")
    out = oiio.ImageOutput.create(str(path))
    if out is None:
        raise RuntimeError(f"Could not create {path}")
    try:
        out.open(str(path), spec)
        out.write_image(preview_u8)
    finally:
        out.close()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=Path("manual_parity_chart"))
    parser.add_argument("--width", type=int, default=1920)
    parser.add_argument("--height", type=int, default=1080)
    args = parser.parse_args()

    chart = make_chart(args.width, args.height)
    write_exr(args.output_dir / "spektrafilm_manual_parity_linear_rec2020.exr", chart)
    write_preview_png(args.output_dir / "spektrafilm_manual_parity_preview_srgb.png", chart)
    print(args.output_dir / "spektrafilm_manual_parity_linear_rec2020.exr")
    print(args.output_dir / "spektrafilm_manual_parity_preview_srgb.png")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
