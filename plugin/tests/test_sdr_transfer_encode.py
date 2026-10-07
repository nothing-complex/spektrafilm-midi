from __future__ import annotations

import re
from pathlib import Path

import numpy as np
import pytest


OFX_DIR = Path(__file__).resolve().parents[1]
COLOR_ENCODE_MIN = -0.25
COLOR_ENCODE_MAX = 64.0
COLOR_LUT_SIZE = 4096


def _signed_gamma_encode(values: np.ndarray, gamma: float) -> np.ndarray:
    return np.sign(values) * (np.abs(values) ** (1.0 / gamma))


def _signed_srgb_encode(values: np.ndarray) -> np.ndarray:
    x = np.abs(values)
    encoded = np.where(x <= 0.0031308, 12.92 * x, 1.055 * (x ** (1.0 / 2.4)) - 0.055)
    return np.sign(values) * encoded


def _signed_prophoto_encode(values: np.ndarray) -> np.ndarray:
    x = np.abs(values)
    encoded = np.where(x < (1.0 / 512.0), 16.0 * x, x ** (1.0 / 1.8))
    return np.sign(values) * encoded


def _old_uniform_encode_lut_sample(encode, values: np.ndarray) -> np.ndarray:
    grid = np.linspace(COLOR_ENCODE_MIN, COLOR_ENCODE_MAX, COLOR_LUT_SIZE, dtype=np.float64)
    lut = encode(grid)
    return np.interp(values, grid, lut)


def _relative_derivative_jump(samples: np.ndarray, values: np.ndarray) -> float:
    derivative = np.diff(samples) / np.diff(values)
    return float(abs(derivative[1] - derivative[0]) / max(abs(derivative[0]), abs(derivative[1]), 1.0e-12))


@pytest.mark.parametrize(
    ("name", "encode"),
    (
        ("Rec.709 Gamma 2.4", lambda x: _signed_gamma_encode(x, 2.4)),
        ("Rec.709 Gamma 2.2", lambda x: _signed_gamma_encode(x, 2.2)),
        ("DCI-P3", lambda x: _signed_gamma_encode(x, 2.6)),
        ("sRGB", _signed_srgb_encode),
        ("Display P3", _signed_srgb_encode),
    ),
)
def test_analytic_sdr_encode_removes_uniform_lut_derivative_break(name, encode):
    del name
    grid = np.linspace(COLOR_ENCODE_MIN, COLOR_ENCODE_MAX, COLOR_LUT_SIZE, dtype=np.float64)
    former_artifact_index = int(np.searchsorted(grid, 0.016))
    former_artifact_value = grid[former_artifact_index]
    assert 0.15 <= _signed_gamma_encode(np.asarray([former_artifact_value]), 2.4)[0] <= 0.25

    lut_region = grid[former_artifact_index - 1 : former_artifact_index + 2]
    old_samples = _old_uniform_encode_lut_sample(encode, lut_region)
    assert _relative_derivative_jump(old_samples, lut_region) > 0.25

    h = 1.0e-4
    dense_region = former_artifact_value + np.asarray([-h, 0.0, h])
    analytic_samples = encode(dense_region)
    assert _relative_derivative_jump(analytic_samples, dense_region) < 0.02

    former_artifact_points = np.asarray([0.001, 0.016, 0.032, 0.048], dtype=np.float64)
    assert np.max(np.abs(_old_uniform_encode_lut_sample(encode, former_artifact_points) - encode(former_artifact_points))) > 1.0e-3


def test_prophoto_analytic_encode_matches_expected_piecewise_curve():
    values = np.asarray([-0.01, -1.0 / 512.0, -0.001, 0.0, 0.001, 1.0 / 512.0, 0.18], dtype=np.float64)
    encoded = _signed_prophoto_encode(values)

    assert encoded[3] == 0.0
    assert encoded[4] == pytest.approx(16.0 * 0.001)
    assert encoded[6] == pytest.approx(0.18 ** (1.0 / 1.8))
    assert encoded[0] < 0.0
    assert encoded[5] == pytest.approx((1.0 / 512.0) ** (1.0 / 1.8))


def test_generator_marks_simple_sdr_output_transfers_as_analytic():
    source = (OFX_DIR / "tools" / "generate_profile_curves.py").read_text(encoding="utf-8")

    for token in (
        "TRANSFER_LINEAR = 0",
        "TRANSFER_LUT = 1",
        "TRANSFER_SRGB = 2",
        "TRANSFER_GAMMA = 3",
        "TRANSFER_PROPHOTO = 4",
        "_array(\"color_transfer_params\", transfer_params)",
        "const float *colorTransferParams()",
    ):
        assert token in source

    for key in ("srgb", "display_p3"):
        entry = re.search(rf'"key": "{key}",[\s\S]*?"transfer": TRANSFER_SRGB', source)
        assert entry, key
    assert re.search(r'"key": "prophoto_rgb",[\s\S]*?"transfer": TRANSFER_PROPHOTO', source)
    for key, gamma in (
        ("adobe_rgb_1998", "2.19921875"),
        ("dci_p3", "2.6"),
        ("p3d65_gamma22", "2.2"),
        ("p3d65_gamma26", "2.6"),
        ("rec709_gamma22", "2.2"),
        ("rec709_gamma24", "2.4"),
    ):
        entry = re.search(rf'"key": "{key}",[\s\S]*?"transfer": TRANSFER_GAMMA,[\s\S]*?"transfer_param": {gamma}', source)
        assert entry, key


def test_metal_analytic_sdr_encode_branches_do_not_sample_encode_lut():
    source = (OFX_DIR / "shaders" / "SpektraFilm.metal").read_text(encoding="utf-8")

    srgb_branch = source.index("if (transferKind == kSpektraTransferSrgb)")
    gamma_branch = source.index("if (transferKind == kSpektraTransferGamma)")
    prophoto_branch = source.index("if (transferKind == kSpektraTransferProPhoto)")
    fallback_lut = source.index("spektra_sample_lut_range", prophoto_branch)

    assert srgb_branch < fallback_lut
    assert gamma_branch < fallback_lut
    assert prophoto_branch < fallback_lut
    assert "return spektra_signed_srgb_encode(rgb);" in source[srgb_branch:gamma_branch]
    assert "return spektra_signed_gamma_encode(rgb, transferParams[colorSpace]);" in source[gamma_branch:prophoto_branch]
    assert "return spektra_signed_prophoto_encode(rgb);" in source[prophoto_branch:fallback_lut]


@pytest.mark.parametrize(
    "shader_path",
    (
        OFX_DIR / "shaders" / "vulkan" / "SpektraPrintScan.comp",
        OFX_DIR / "shaders" / "vulkan" / "SpektraScannerPost.comp",
    ),
)
def test_vulkan_analytic_sdr_encode_branches_do_not_sample_encode_lut(shader_path):
    source = shader_path.read_text(encoding="utf-8")

    for token in (
        "const uint kTransferLinear = 0u;",
        "const uint kTransferSrgb = 2u;",
        "const uint kTransferGamma = 3u;",
        "const uint kTransferProPhoto = 4u;",
        "params.colorSpaceCount * (params.transferLutSize + kOutputGamutCompressionStride)",
    ):
        assert token in source

    srgb_branch = source.index("if (transferKind == kTransferSrgb)")
    gamma_branch = source.index("if (transferKind == kTransferGamma)")
    prophoto_branch = source.index("if (transferKind == kTransferProPhoto)")
    fallback_lut = source.index("sampleColorEncodeLutRange", prophoto_branch)

    assert srgb_branch < fallback_lut
    assert gamma_branch < fallback_lut
    assert prophoto_branch < fallback_lut
    assert "return signedSrgbEncode(rgb);" in source[srgb_branch:gamma_branch]
    assert "return signedGammaEncode(rgb, colorTransferParam(colorSpace));" in source[gamma_branch:prophoto_branch]
    assert "return signedProPhotoEncode(rgb);" in source[prophoto_branch:fallback_lut]


def test_vulkan_renderer_appends_transfer_params_to_encode_buffer():
    source = (OFX_DIR / "src" / "SpektraVulkanRenderer.cpp").read_text(encoding="utf-8")

    assert "includePrintScanResources && (!colorEncodeLuts() || !colorTransferParams())" in source
    append_block = re.search(
        r"colorEncodeAndGamutData\.insert\(\s*colorEncodeAndGamutData\.end\(\),\s*colorTransferParams\(\),\s*colorTransferParams\(\) \+ static_cast<size_t>\(kSpektraColorSpaceCount\)\s*\);",
        source,
        re.MULTILINE,
    )
    assert append_block
