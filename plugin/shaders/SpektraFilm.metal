#include <metal_stdlib>
using namespace metal;

constant int kSpektraOutputRoleDisplayHdr = 1;
constant int kSpektraOutputRoleRcm = 2;
constant int kSpektraColorSpaceBmdFilmWideGamutGen5 = 2;
constant int kSpektraColorSpaceDavinciIntermediateWideGamut = 3;
constant int kSpektraColorSpaceAces2065_1 = 10;
constant int kSpektraColorSpaceAcesCg = 11;
constant int kSpektraColorSpaceAcesCct = 12;
constant int kSpektraColorSpaceAcesCc = 13;
constant int kSpektraColorSpaceLinearRec2020 = 14;
constant int kSpektraColorSpaceLinearRec709 = 15;
constant int kSpektraColorSpaceLinearP3D65 = 16;
constant int kSpektraColorSpaceSrgb = 17;
constant int kSpektraColorSpaceDisplayP3 = 18;
constant int kSpektraColorSpaceDciP3 = 21;
constant int kSpektraColorSpaceP3D65Gamma22 = 22;
constant int kSpektraColorSpaceP3D65Gamma26 = 23;
constant int kSpektraColorSpaceRec709Gamma22 = 24;
constant int kSpektraColorSpaceRec709Gamma24 = 25;
constant uint kSpektraColorAdaptationInputCompression = 1u << 0u;
constant uint kSpektraColorAdaptationCurveSmoothing = 1u << 1u;
constant uint kSpektraColorAdaptationOutputLightnessCompression = 1u << 2u;
constant uint kSpektraColorAdaptationOutputChromaCompression = 1u << 3u;

struct SpektraKernelParams {
  int process;
  int rgbToRawMethod;
  int inputColorSpace;
  int outputColorSpace;
  int outputRole;
  int hdrPreset;
  int hdrTransfer;
  float hdrReferenceWhiteNits;
  float hdrPeakNits;
  float hdrExposureEv;
  int hdrToneMapping;
  uint colorAdaptationFlags;
  int film;
  int paper;
  int printTiming;
  float filmExposureEv;
  uint autoExposureEnabled;
  int autoExposureMethod;
  float autoExposureEv;
  float _padAutoExposure0;
  float printExposureEv;
  float filmGamma;
  float printGamma;
  float printShadowShape;
  float printHighlightShape;
  int filmPushPullMode;
  float filmPushPullStops;
  int printPushPullMode;
  float printPushPullStops;
  float negativeBleachBypassAmount;
  float negativeLeucoCyanCoupling;
  float printBleachBypassAmount;
  uint scanNegativeInvert;
  float filterC;
  float filterMShift;
  float filterYShift;
  float enlargerScale;
  float enlargerOffsetXPercent;
  float enlargerOffsetYPercent;
  float _padEnlarger0;
  float preflashExposure;
  float preflashMFilterShift;
  float preflashYFilterShift;
  float printerLightsR;
  float printerLightsG;
  float printerLightsB;
  uint printerLightsGang;
  uint printerLightCalibration;
  float dirCouplersAmount;
  float dirCouplersDiffusionUm;
  float dirCouplersDiffusionTailUm;
  float dirCouplersDiffusionTailWeight;
  uint grainEnabled;
  int grainModel;
  int filmFormat;
  float grainAmount;
  float grainSaturation;
  uint grainSublayersEnabled;
  int grainSubLayerCount;
  float grainParticleAreaUm2;
  float grainParticleScaleR;
  float grainParticleScaleG;
  float grainParticleScaleB;
  float grainParticleScaleLayer0;
  float grainParticleScaleLayer1;
  float grainParticleScaleLayer2;
  float grainDensityMinR;
  float grainDensityMinG;
  float grainDensityMinB;
  float grainUniformityR;
  float grainUniformityG;
  float grainUniformityB;
  float grainFinalBlurUm;
  float grainBlurDyeCloudsUm;
  float grainMicroStructureScale;
  float grainMicroStructureSigmaNm;
  uint grainSeed;
  uint grainAnimate;
  float filmPixelSizeUm;
  float _padGrain0;
  int grainSynthesisSamples;
  float grainSynthesisAmount;
  float grainSynthesisMeanRadiusUm;
  float grainSynthesisRadiusStdDevRatio;
  float grainSynthesisObservationSigmaUm;
  float grainSynthesisCellSizeRatio;
  float grainSynthesisMaxRadiusQuantile;
  float grainSynthesisCoverageEpsilon;
  int grainSynthesisMaxGrainsPerCell;
  float grainSynthesisRadiusScaleR;
  float grainSynthesisRadiusScaleG;
  float grainSynthesisRadiusScaleB;
  float grainSynthesisLayerScale0;
  float grainSynthesisLayerScale1;
  float grainSynthesisLayerScale2;
  uint grainSynthesisLayered;
  uint _padGrainSynthesis0;
  uint halationEnabled;
  float scatterAmount;
  float scatterScale;
  float halationAmount;
  float halationScale;
  float halationStrengthR;
  float halationStrengthG;
  float halationStrengthB;
  float halationFirstSigmaUmR;
  float halationFirstSigmaUmG;
  float halationFirstSigmaUmB;
  float halationBoostEv;
  float halationBoostRange;
  float halationProtectEv;
  float _padHalation0;
  uint cameraDiffusionEnabled;
  int cameraDiffusionFamily;
  float cameraDiffusionStrength;
  float cameraDiffusionSpatialScale;
  float cameraDiffusionHaloWarmth;
  float cameraDiffusionCoreIntensity;
  float cameraDiffusionCoreSize;
  float cameraDiffusionHaloIntensity;
  float cameraDiffusionHaloSize;
  float cameraDiffusionBloomIntensity;
  float cameraDiffusionBloomSize;
  uint printDiffusionEnabled;
  int printDiffusionFamily;
  float printDiffusionStrength;
  float printDiffusionSpatialScale;
  float printDiffusionHaloWarmth;
  float printDiffusionCoreIntensity;
  float printDiffusionCoreSize;
  float printDiffusionHaloIntensity;
  float printDiffusionHaloSize;
  float printDiffusionBloomIntensity;
  float printDiffusionBloomSize;
  uint scannerEnabled;
  uint scannerWhiteCorrection;
  uint scannerBlackCorrection;
  float scannerWhiteLevel;
  float scannerBlackLevel;
  float glarePercent;
  float glareRoughness;
  float glareBlur;
  float scannerBlurSigmaPx;
  float scannerUnsharpSigmaPx;
  float scannerUnsharpAmount;
  uint densityCurveLookupMode;
  uint spectralTransmittanceMode;
  uint _padPerf0;
  float time;
};

static bool spektra_color_adaptation_enabled(constant SpektraKernelParams &params, uint flag) {
  return (params.colorAdaptationFlags & flag) != 0u;
}

constant uint kSpektraGrainSynthesisMaxSamples = 1024u;

struct SpektraGrainSynthesisComponentInfo {
  float scaledMeanRadius;
  float maxRadius;
  float maxRadiusSquared;
  float cellSize;
  float invCellSize;
  float meanArea;
  float cellArea;
  float densityToLambda;
  float logMean;
  float logSigma;
  uint grainCap;
  uint cellScanRadius;
  uint sampleCount;
  uint active;
  uint radiusLutOffset;
  uint radiusLutSize;
  uint cellOffsetStart;
  uint cellOffsetCount;
  uint samplerMode;
  uint _pad0;
};

struct SpektraCurveInfo {
  uint exposureCount;
  uint _pad0;
  uint _pad1;
  uint _pad2;
};

struct SpektraSpectralInfo {
  uint filmWavelengthCount;
  uint hanatosWidth;
  uint hanatosHeight;
  uint hanatosWavelengthCount;
  uint filmCount;
  uint paperCount;
  uint filmPositive;
  uint _padCount1;
  float mallettRawMidgrayGreen;
  float filmDensityCurveMinimum0;
  float filmDensityCurveMinimum1;
  float filmDensityCurveMinimum2;
  float filmDensityCurveMaximum0;
  float filmDensityCurveMaximum1;
  float filmDensityCurveMaximum2;
  float _padDensityCurveMaximum0;
  float paperDensityCurveMaximum0;
  float paperDensityCurveMaximum1;
  float paperDensityCurveMaximum2;
  float _padPaperDensityCurveMaximum0;
};

struct SpektraColorInfo {
  uint colorSpaceCount;
  uint transferLutSize;
  float decodeMin;
  float decodeMax;
  float encodeMin;
  float encodeMax;
  float _pad0;
  float _pad1;
};

struct SpektraDirInfo {
  float matrix00;
  float matrix01;
  float matrix02;
  float matrix10;
  float matrix11;
  float matrix12;
  float matrix20;
  float matrix21;
  float matrix22;
  float densityMax0;
  float densityMax1;
  float densityMax2;
};

struct SpektraDiffusionInfo {
  uint componentCount;
  float scatterFraction;
  uint _pad0;
  uint _pad1;
};

struct SpektraDiffusionComponent {
  float sigmaPx;
  float weightR;
  float weightG;
  float weightB;
};

struct SpektraGaussianBlurInfo {
  float firstWeight;
  float firstRatio;
  float ratioStep;
  float invWeightSum;
  uint radius;
  uint active;
  uint _pad0;
  uint _pad1;
};

struct SpektraFrameConstants {
  float4 print; // x: exposure factor, y: reference black Y, z: reference white Y
  float4 film;  // x: reference black Y, y: reference white Y
  float4 glare; // rgb: print scan illuminant in output RGB
  float4 preflash; // rgb: constant paper raw preflash exposure
  float4 filmDmaxScan; // rgb: film D-max scan in output RGB, a: scan Y
  float4 filmDminScan; // rgb: clear-film scan in output RGB, a: scan Y
};

struct SpektraScanResult {
  float3 rgb;
  float y;
};

static uint spektra_hash(uint x) {
  x ^= x >> 16;
  x *= 0x7feb352du;
  x ^= x >> 15;
  x *= 0x846ca68bu;
  x ^= x >> 16;
  return x;
}

static float spektra_rand01(uint seed) {
  return (float(spektra_hash(seed) & 0x00ffffffu) + 0.5) / 16777216.0;
}

static float2 spektra_output_pixel_film_um(
  uint2 gid,
  constant SpektraKernelParams &params,
  constant uint2 &dims
) {
  const float scale = max(params.enlargerScale, 1.0);
  const float2 safeDims = float2(max(dims.x, 1u), max(dims.y, 1u));
  const float2 outputUv = (float2(gid) + 0.5) / safeDims;
  const float2 sourceUv = float2(0.5) +
    (outputUv - float2(0.5)) / scale +
    float2(params.enlargerOffsetXPercent, params.enlargerOffsetYPercent) * (0.01 / scale);
  const float framePixelSizeUm = max(params.filmPixelSizeUm * scale, 1.0e-6);
  return sourceUv * safeDims * framePixelSizeUm;
}

static uint spektra_film_cell_seed(float2 filmUm, float cellSizeUm, uint seed) {
  const float safeCellSize = max(cellSizeUm, 1.0e-4);
  const int2 cell = int2(floor(filmUm / safeCellSize));
  return spektra_hash(seed ^ (uint(cell.x) * 0x1f123bb5u) ^ (uint(cell.y) * 0x5f356495u));
}

static int2 spektra_film_um_to_output_pixel(
  float2 filmUm,
  constant SpektraKernelParams &params,
  constant uint2 &dims
) {
  const float scale = max(params.enlargerScale, 1.0);
  const float2 safeDims = float2(max(dims.x, 1u), max(dims.y, 1u));
  const float framePixelSizeUm = max(params.filmPixelSizeUm * scale, 1.0e-6);
  const float2 sourceUv = filmUm / (safeDims * framePixelSizeUm);
  const float2 outputUv = float2(0.5) +
    (sourceUv - float2(0.5)) * scale -
    float2(params.enlargerOffsetXPercent, params.enlargerOffsetYPercent) * 0.01;
  return int2(floor(outputUv * safeDims));
}

static float spektra_film_format_mm(int format) {
  switch (format) {
    case 0:
      return 4.8;
    case 1:
      return 5.79;
    case 2:
      return 10.26;
    case 3:
      return 12.52;
    case 5:
      return 24.89;
    case 6:
      return 52.48;
    case 7:
      return 70.41;
    case 4:
    default:
      return 35.0;
  }
}

static float spektra_grain_final_blur_um(constant SpektraKernelParams &params) {
  const float formatScale = pow(max(spektra_film_format_mm(params.filmFormat) / 35.0, 1.0e-6), 0.62);
  return max(params.grainFinalBlurUm, 0.0) * formatScale;
}

static float spektra_gaussian(uint seed) {
  const float u1 = max(spektra_rand01(seed), 1.0e-6);
  const float u2 = spektra_rand01(seed ^ 0x9e3779b9u);
  return sqrt(-2.0 * log(u1)) * cos(6.28318530718 * u2);
}

static float spektra_mitchell_weight(float t) {
  constexpr float B = 1.0 / 3.0;
  constexpr float C = 1.0 / 3.0;
  const float x = abs(t);
  if (x < 1.0) {
    return (1.0 / 6.0) * ((12.0 - 9.0 * B - 6.0 * C) * x * x * x +
                          (-18.0 + 12.0 * B + 6.0 * C) * x * x +
                          (6.0 - 2.0 * B));
  }
  if (x < 2.0) {
    return (1.0 / 6.0) * ((-B - 6.0 * C) * x * x * x +
                          (6.0 * B + 30.0 * C) * x * x +
                          (-12.0 * B - 48.0 * C) * x +
                          (8.0 * B + 24.0 * C));
  }
  return 0.0;
}

static uint spektra_safe_index(int index, uint size) {
  if (size <= 1u) {
    return 0u;
  }
  const int period = int(size) * 2 - 2;
  int mirrored = index % period;
  if (mirrored < 0) {
    mirrored += period;
  }
  if (mirrored >= int(size)) {
    mirrored = period - mirrored;
  }
  return uint(mirrored);
}

static uint spektra_color_space_index(int colorSpace, constant SpektraColorInfo &colorInfo) {
  if (colorSpace < 0 || colorSpace >= int(colorInfo.colorSpaceCount)) {
    return 0u;
  }
  return uint(colorSpace);
}

static bool spektra_rcm_enabled(constant SpektraKernelParams &params) {
  return params.outputRole == kSpektraOutputRoleRcm;
}

static uint spektra_final_output_color_space(constant SpektraKernelParams &params, constant SpektraColorInfo &colorInfo) {
  constexpr int kLinearRec2020ColorSpace = 14;
  if (params.outputRole == kSpektraOutputRoleDisplayHdr) {
    return spektra_color_space_index(kLinearRec2020ColorSpace, colorInfo);
  }
  return spektra_color_space_index(params.outputColorSpace, colorInfo);
}

static float spektra_sample_transfer_lut(
  float value,
  uint colorSpace,
  constant SpektraColorInfo &colorInfo,
  device const float *luts
) {
  const uint lutSize = colorInfo.transferLutSize;
  if (lutSize <= 1u) {
    return value;
  }
  const uint offset = colorSpace * lutSize;
  const float range = max(colorInfo.decodeMax - colorInfo.decodeMin, 1.0e-6);
  const float step = range / float(lutSize - 1u);
  if (value <= colorInfo.decodeMin) {
    const float y0 = luts[offset];
    const float y1 = luts[offset + 1u];
    return y0 + (value - colorInfo.decodeMin) * ((y1 - y0) / max(step, 1.0e-12));
  }
  if (value >= colorInfo.decodeMax) {
    const float y0 = luts[offset + lutSize - 2u];
    const float y1 = luts[offset + lutSize - 1u];
    return y1 + (value - colorInfo.decodeMax) * ((y1 - y0) / max(step, 1.0e-12));
  }
  const float t = (value - colorInfo.decodeMin) / range;
  const float position = t * float(lutSize - 1u);
  const uint lo = uint(floor(position));
  const uint hi = min(lo + 1u, lutSize - 1u);
  const float f = position - float(lo);
  return mix(luts[offset + lo], luts[offset + hi], f);
}

static float spektra_sample_lut_range(
  float value,
  uint colorSpace,
  float minimum,
  float maximum,
  constant SpektraColorInfo &colorInfo,
  device const float *luts
) {
  const uint lutSize = colorInfo.transferLutSize;
  if (lutSize <= 1u) {
    return value;
  }
  const float range = max(maximum - minimum, 1.0e-6);
  const float step = range / float(lutSize - 1u);
  const uint offset = colorSpace * lutSize;
  if (value <= minimum) {
    const float y0 = luts[offset];
    const float y1 = luts[offset + 1u];
    return y0 + (value - minimum) * ((y1 - y0) / max(step, 1.0e-12));
  }
  if (value >= maximum) {
    const float y0 = luts[offset + lutSize - 2u];
    const float y1 = luts[offset + lutSize - 1u];
    return y1 + (value - maximum) * ((y1 - y0) / max(step, 1.0e-12));
  }
  const float t = (value - minimum) / range;
  const float position = t * float(lutSize - 1u);
  const uint lo = uint(floor(position));
  const uint hi = min(lo + 1u, lutSize - 1u);
  const float f = position - float(lo);
  return mix(luts[offset + lo], luts[offset + hi], f);
}

constant uint kSpektraTransferLinear = 0u;
constant uint kSpektraTransferSrgb = 2u;
constant uint kSpektraTransferGamma = 3u;
constant uint kSpektraTransferProPhoto = 4u;

static float spektra_signed_srgb_encode(float value) {
  const float x = abs(value);
  const float y = x <= 0.0031308
    ? 12.92 * x
    : 1.055 * pow(x, 1.0 / 2.4) - 0.055;
  return value < 0.0 ? -y : y;
}

static float spektra_signed_gamma_encode(float value, float gamma) {
  const float y = pow(abs(value), 1.0 / max(gamma, 1.0e-6));
  return value < 0.0 ? -y : y;
}

static float spektra_signed_prophoto_encode(float value) {
  const float x = abs(value);
  const float y = x < (1.0 / 512.0) ? 16.0 * x : pow(x, 1.0 / 1.8);
  return value < 0.0 ? -y : y;
}

static float3 spektra_signed_srgb_encode(float3 rgb) {
  return float3(
    spektra_signed_srgb_encode(rgb.r),
    spektra_signed_srgb_encode(rgb.g),
    spektra_signed_srgb_encode(rgb.b)
  );
}

static float3 spektra_signed_gamma_encode(float3 rgb, float gamma) {
  return float3(
    spektra_signed_gamma_encode(rgb.r, gamma),
    spektra_signed_gamma_encode(rgb.g, gamma),
    spektra_signed_gamma_encode(rgb.b, gamma)
  );
}

static float3 spektra_signed_prophoto_encode(float3 rgb) {
  return float3(
    spektra_signed_prophoto_encode(rgb.r),
    spektra_signed_prophoto_encode(rgb.g),
    spektra_signed_prophoto_encode(rgb.b)
  );
}

static float3 spektra_encode_output_rgb(
  float3 rgb,
  uint colorSpace,
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  device const float *encodeLuts,
  device const uint *transferKinds,
  device const float *transferParams
) {
  (void)params;
  const uint transferKind = transferKinds[colorSpace];
  if (transferKind == kSpektraTransferLinear) {
    return rgb;
  }
  if (transferKind == kSpektraTransferSrgb) {
    return spektra_signed_srgb_encode(rgb);
  }
  if (transferKind == kSpektraTransferGamma) {
    return spektra_signed_gamma_encode(rgb, transferParams[colorSpace]);
  }
  if (transferKind == kSpektraTransferProPhoto) {
    return spektra_signed_prophoto_encode(rgb);
  }
  return float3(
    spektra_sample_lut_range(rgb.r, colorSpace, colorInfo.encodeMin, colorInfo.encodeMax, colorInfo, encodeLuts),
    spektra_sample_lut_range(rgb.g, colorSpace, colorInfo.encodeMin, colorInfo.encodeMax, colorInfo, encodeLuts),
    spektra_sample_lut_range(rgb.b, colorSpace, colorInfo.encodeMin, colorInfo.encodeMax, colorInfo, encodeLuts)
  );
}

static float3 spektra_encode_output_rgb(
  float3 rgb,
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  device const float *encodeLuts,
  device const uint *transferKinds,
  device const float *transferParams
) {
  const uint colorSpace = spektra_color_space_index(params.outputColorSpace, colorInfo);
  return spektra_encode_output_rgb(rgb, colorSpace, params, colorInfo, encodeLuts, transferKinds, transferParams);
}

static float spektra_rec2020_luminance(float3 rgb) {
  return dot(rgb, float3(0.2627, 0.6780, 0.0593));
}

static bool spektra_rcm_inverse_ootf_enabled(uint colorSpace) {
  switch (int(colorSpace)) {
    case kSpektraColorSpaceBmdFilmWideGamutGen5:
    case kSpektraColorSpaceDavinciIntermediateWideGamut:
    case kSpektraColorSpaceAces2065_1:
    case kSpektraColorSpaceAcesCg:
    case kSpektraColorSpaceAcesCct:
    case kSpektraColorSpaceAcesCc:
    case kSpektraColorSpaceLinearRec2020:
    case kSpektraColorSpaceLinearRec709:
    case kSpektraColorSpaceLinearP3D65:
    case kSpektraColorSpaceSrgb:
    case kSpektraColorSpaceDisplayP3:
    case kSpektraColorSpaceDciP3:
    case kSpektraColorSpaceP3D65Gamma22:
    case kSpektraColorSpaceP3D65Gamma26:
    case kSpektraColorSpaceRec709Gamma22:
    case kSpektraColorSpaceRec709Gamma24:
      return true;
    default:
      return false;
  }
}

static float spektra_apply_inverse_rcm_ootf_channel(float value) {
  // Resolve CST inverse OOTF: inverse BT.1886 EOTF, then inverse BT.709 OETF.
  const float x = abs(value);
  const float signal = pow(x, 1.0 / 2.4);
  const float sceneLinear = signal < 0.081
    ? signal / 4.5
    : pow((signal + 0.099) / 1.099, 1.0 / 0.45);
  return value < 0.0 ? -sceneLinear : sceneLinear;
}

static float3 spektra_apply_inverse_rcm_ootf(float3 displayLinear) {
  return float3(
    spektra_apply_inverse_rcm_ootf_channel(displayLinear.r),
    spektra_apply_inverse_rcm_ootf_channel(displayLinear.g),
    spektra_apply_inverse_rcm_ootf_channel(displayLinear.b)
  );
}

static float3 spektra_hdr_apply_luminance_tone_map(float3 rgb, constant SpektraKernelParams &params) {
  const float referenceWhite = max(params.hdrReferenceWhiteNits, 1.0);
  const float peak = max(params.hdrPeakNits, referenceWhite + 1.0);
  float3 nits = rgb * (referenceWhite * exp2(params.hdrExposureEv));
  const float sourceY = spektra_rec2020_luminance(nits);
  if (!(sourceY > 1.0e-6) || !isfinite(sourceY)) {
    return float3(0.0);
  }
  float mappedY = sourceY;
  if (params.hdrToneMapping == 1) {
    mappedY = min(sourceY, peak);
  } else if (sourceY > referenceWhite) {
    const float shoulder = max(peak - referenceWhite, 1.0);
    mappedY = referenceWhite + shoulder * (1.0 - exp(-(sourceY - referenceWhite) / shoulder));
  }
  return nits * (mappedY / sourceY);
}

static float spektra_encode_pq(float nits) {
  constexpr float m1 = 2610.0 / 16384.0;
  constexpr float m2 = 2523.0 / 32.0;
  constexpr float c1 = 3424.0 / 4096.0;
  constexpr float c2 = 2413.0 / 128.0;
  constexpr float c3 = 2392.0 / 128.0;
  const float y = pow(max(nits, 0.0) / 10000.0, m1);
  return pow((c1 + c2 * y) / (1.0 + c3 * y), m2);
}

static float spektra_encode_hlg(float sceneLinear) {
  constexpr float a = 0.17883277;
  constexpr float b = 1.0 - 4.0 * a;
  constexpr float c = 0.55991073;
  const float e = max(sceneLinear, 0.0);
  return e <= (1.0 / 12.0) ? sqrt(3.0 * e) : a * log(12.0 * e - b) + c;
}

static float spektra_hlg_system_gamma(float peakNits) {
  return max(1.0 + 0.42 * log10(max(peakNits, 1.0) / 1000.0), 1.0e-6);
}

static float spektra_hlg_channel_to_signal(float nits, float peakNits, bool clampToPeak) {
  const float normalized = max(nits, 0.0) / peakNits;
  return clampToPeak ? clamp(normalized, 0.0, 1.0) : normalized;
}

static float3 spektra_hlg_display_nits_to_signal(float3 nits, float peakNits, bool clampToPeak) {
  const float gamma = spektra_hlg_system_gamma(peakNits);
  return float3(
    spektra_encode_hlg(pow(spektra_hlg_channel_to_signal(nits.r, peakNits, clampToPeak), 1.0 / gamma)),
    spektra_encode_hlg(pow(spektra_hlg_channel_to_signal(nits.g, peakNits, clampToPeak), 1.0 / gamma)),
    spektra_encode_hlg(pow(spektra_hlg_channel_to_signal(nits.b, peakNits, clampToPeak), 1.0 / gamma))
  );
}

constant uint kSpektraOutputGamutCompressionStride = 18u;

static float spektra_reinhard_knee(float value, float threshold, float limit, float power) {
  if (!isfinite(value) || value <= threshold) {
    return value;
  }
  const float scale = max(limit - threshold, 1.0e-12);
  const float x = (value - threshold) / scale;
  const float y = x / pow(1.0 + pow(x, power), 1.0 / power);
  return threshold + scale * y;
}

static float spektra_signed_cuberoot(float value) {
  return value < 0.0 ? -pow(-value, 1.0 / 3.0) : pow(value, 1.0 / 3.0);
}

static float3 spektra_mul_packed_matrix(device const float *data, uint offset, float3 value) {
  return float3(
    data[offset] * value.r + data[offset + 1u] * value.g + data[offset + 2u] * value.b,
    data[offset + 3u] * value.r + data[offset + 4u] * value.g + data[offset + 5u] * value.b,
    data[offset + 6u] * value.r + data[offset + 7u] * value.g + data[offset + 8u] * value.b
  );
}

static float3 spektra_oklab_from_output_rgb(float3 rgb, device const float *outputGamutCompressionData, uint dataOffset) {
  const float3 lms = spektra_mul_packed_matrix(outputGamutCompressionData, dataOffset, rgb);
  const float3 lmsPrime = float3(
    spektra_signed_cuberoot(lms.r),
    spektra_signed_cuberoot(lms.g),
    spektra_signed_cuberoot(lms.b)
  );
  const float3 row0 = float3(0.2104542553, 0.7936177850, -0.0040720468);
  const float3 row1 = float3(1.9779984951, -2.4285922050, 0.4505937099);
  const float3 row2 = float3(0.0259040371, 0.7827717662, -0.8086757660);
  return float3(dot(row0, lmsPrime), dot(row1, lmsPrime), dot(row2, lmsPrime));
}

static float3 spektra_output_rgb_from_oklab(float3 lab, device const float *outputGamutCompressionData, uint dataOffset) {
  const float3 invRow0 = float3(1.0, 0.3963377774, 0.2158037573);
  const float3 invRow1 = float3(1.0, -0.1055613458, -0.0638541728);
  const float3 invRow2 = float3(1.0, -0.0894841775, -1.2914855480);
  const float3 lmsPrime = float3(dot(invRow0, lab), dot(invRow1, lab), dot(invRow2, lab));
  const float3 lms = lmsPrime * lmsPrime * lmsPrime;
  return spektra_mul_packed_matrix(outputGamutCompressionData, dataOffset + 9u, lms);
}

static bool spektra_rgb_in_bounds(float3 rgb, float lowerBound, float upperBound) {
  constexpr float epsilon = 1.0e-6;
  return all(isfinite(rgb)) &&
    all(rgb >= float3(lowerBound - epsilon)) &&
    all(rgb <= float3(upperBound + epsilon));
}

static float spektra_solve_oklch_cmax(
  float3 lab,
  float chroma,
  float2 hueUnit,
  device const float *outputGamutCompressionData,
  uint dataOffset,
  float lowerBound,
  float upperBound
) {
  float lo = 0.0;
  float hi = max(chroma, 1.0e-6);
  const float maxHi = 4.0 * max(upperBound, 1.0);
  for (uint expansion = 0u; expansion < 12u; ++expansion) {
    const float3 candidate = spektra_output_rgb_from_oklab(
      float3(lab.x, hueUnit.x * hi, hueUnit.y * hi),
      outputGamutCompressionData,
      dataOffset
    );
    if (!spektra_rgb_in_bounds(candidate, lowerBound, upperBound)) {
      break;
    }
    lo = hi;
    hi = min(hi * 2.0, maxHi);
    if (hi >= maxHi) {
      break;
    }
  }
  for (uint iteration = 0u; iteration < 16u; ++iteration) {
    const float mid = 0.5 * (lo + hi);
    const float3 candidate = spektra_output_rgb_from_oklab(
      float3(lab.x, hueUnit.x * mid, hueUnit.y * mid),
      outputGamutCompressionData,
      dataOffset
    );
    if (spektra_rgb_in_bounds(candidate, lowerBound, upperBound)) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return lo;
}

static float3 spektra_output_gamut_compress_oklch(
  float3 rgb,
  uint colorSpace,
  device const float *outputGamutCompressionData,
  float lowerBound,
  float upperBound,
  bool softenInGamut,
  bool compressLightness,
  bool compressChroma
) {
  if (outputGamutCompressionData == nullptr) {
    return rgb;
  }
  if (!all(isfinite(rgb))) {
    return float3(lowerBound);
  }
  const bool inBounds = spektra_rgb_in_bounds(rgb, lowerBound, upperBound);
  if (inBounds && !softenInGamut) {
    return rgb;
  }
  const uint dataOffset = colorSpace * kSpektraOutputGamutCompressionStride;
  float3 lab = spektra_oklab_from_output_rgb(rgb, outputGamutCompressionData, dataOffset);
  if (compressLightness) {
    lab.x = softenInGamut
      ? spektra_reinhard_knee(max(lab.x, 0.0), 0.7, 1.0, 2.2)
      : clamp(lab.x, 0.0, pow(max(upperBound, 0.0), 1.0 / 3.0));
  }
  const float chroma = length(lab.yz);
  if (!(chroma > 1.0e-10) || !isfinite(chroma)) {
    if (inBounds) {
      return rgb;
    }
    const float3 neutral = spektra_output_rgb_from_oklab(float3(lab.x, 0.0, 0.0), outputGamutCompressionData, dataOffset);
    return clamp(neutral, float3(lowerBound), float3(upperBound));
  }
  if (!compressChroma) {
    const float3 lightnessCompressed = spektra_output_rgb_from_oklab(lab, outputGamutCompressionData, dataOffset);
    return spektra_rgb_in_bounds(lightnessCompressed, lowerBound, upperBound)
      ? lightnessCompressed
      : clamp(lightnessCompressed, float3(lowerBound), float3(upperBound));
  }
  const float2 hueUnit = lab.yz / chroma;
  const float cmax = max(
    spektra_solve_oklch_cmax(lab, chroma, hueUnit, outputGamutCompressionData, dataOffset, lowerBound, upperBound),
    1.0e-9
  );
  const float normalizedChroma = chroma / cmax;
  const float compressedNormalized = softenInGamut
    ? spektra_reinhard_knee(normalizedChroma, 0.0, 1.0, 6.0)
    : (normalizedChroma <= 1.0 ? normalizedChroma : spektra_reinhard_knee(normalizedChroma, 0.85, 1.0, 4.0));
  const float compressedChroma = min(compressedNormalized * cmax, cmax);
  const float3 compressed = spektra_output_rgb_from_oklab(
    float3(lab.x, hueUnit.x * compressedChroma, hueUnit.y * compressedChroma),
    outputGamutCompressionData,
    dataOffset
  );
  return spektra_rgb_in_bounds(compressed, lowerBound, upperBound)
    ? compressed
    : clamp(compressed, float3(lowerBound), float3(upperBound));
}

static float3 spektra_finalize_display_hdr_rgb(
  float3 rgb,
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  device const float *encodeLuts
) {
  const float peak = max(params.hdrPeakNits, max(params.hdrReferenceWhiteNits, 1.0) + 1.0);
  device const float *outputGamutCompressionData =
    encodeLuts + colorInfo.colorSpaceCount * colorInfo.transferLutSize;
  const uint colorSpace = spektra_final_output_color_space(params, colorInfo);
  const bool compressLightness =
    spektra_color_adaptation_enabled(params, kSpektraColorAdaptationOutputLightnessCompression);
  const bool compressChroma =
    spektra_color_adaptation_enabled(params, kSpektraColorAdaptationOutputChromaCompression);
  const bool compressOutputGamut = compressLightness || compressChroma;
  float3 nits = spektra_hdr_apply_luminance_tone_map(compressOutputGamut ? rgb : max(rgb, float3(0.0)), params);
  if (compressOutputGamut) {
    nits = spektra_output_gamut_compress_oklch(
      nits / peak,
      colorSpace,
      outputGamutCompressionData,
      0.0,
      1.0,
      false,
      compressLightness,
      compressChroma
    ) * peak;
    nits = clamp(nits, float3(0.0), float3(peak));
  } else {
    nits = max(nits, float3(0.0));
  }
  return params.hdrTransfer == 1
    ? spektra_hlg_display_nits_to_signal(nits, peak, compressOutputGamut)
    : float3(
        spektra_encode_pq(nits.r),
        spektra_encode_pq(nits.g),
        spektra_encode_pq(nits.b)
      );
}

static float3 spektra_finalize_display_sdr_rgb(
  float3 rgb,
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  device const float *encodeLuts,
  device const uint *transferKinds
) {
  device const float *outputGamutCompressionData =
    encodeLuts + colorInfo.colorSpaceCount * colorInfo.transferLutSize;
  device const float *transferParams =
    encodeLuts + colorInfo.colorSpaceCount * (colorInfo.transferLutSize + kSpektraOutputGamutCompressionStride);
  const bool compressLightness =
    spektra_color_adaptation_enabled(params, kSpektraColorAdaptationOutputLightnessCompression);
  const bool compressChroma =
    spektra_color_adaptation_enabled(params, kSpektraColorAdaptationOutputChromaCompression);
  if (compressLightness || compressChroma) {
    const uint colorSpace = spektra_final_output_color_space(params, colorInfo);
    rgb = spektra_output_gamut_compress_oklch(
      rgb,
      colorSpace,
      outputGamutCompressionData,
      0.0,
      1.0,
      true,
      compressLightness,
      compressChroma
    );
  }
  return spektra_encode_output_rgb(rgb, params, colorInfo, encodeLuts, transferKinds, transferParams);
}

static float3 spektra_finalize_rcm_rgb(
  float3 timelineLinear,
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  device const float *encodeLuts,
  device const uint *transferKinds
) {
  device const float *transferParams =
    encodeLuts + colorInfo.colorSpaceCount * (colorInfo.transferLutSize + kSpektraOutputGamutCompressionStride);
  const uint colorSpace = spektra_color_space_index(params.outputColorSpace, colorInfo);
  if (spektra_rcm_inverse_ootf_enabled(colorSpace)) {
    timelineLinear = spektra_apply_inverse_rcm_ootf(timelineLinear);
  }
  return spektra_encode_output_rgb(timelineLinear, colorSpace, params, colorInfo, encodeLuts, transferKinds, transferParams);
}

static float3 spektra_finalize_output_rgb(
  float3 rgb,
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  device const float *encodeLuts,
  device const uint *transferKinds
) {
  if (params.outputRole == kSpektraOutputRoleDisplayHdr) {
    return spektra_finalize_display_hdr_rgb(rgb, params, colorInfo, encodeLuts);
  }
  if (params.outputRole == kSpektraOutputRoleRcm) {
    // RCM returns the selected timeline color space with the same inverse
    // OOTF the user would otherwise apply in a matching CST before Resolve's
    // normal timeline-to-display transform.
    return spektra_finalize_rcm_rgb(rgb, params, colorInfo, encodeLuts, transferKinds);
  }
  return spektra_finalize_display_sdr_rgb(rgb, params, colorInfo, encodeLuts, transferKinds);
}

static float spektra_decode_srgb_scalar(float value) {
  value = clamp(value, 0.0, 1.0);
  return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4);
}

static float3 spektra_decode_input_rgb(
  float3 rgb,
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  device const float *decodeLuts,
  device const uint *transferKinds
) {
  const uint colorSpace = spektra_color_space_index(params.inputColorSpace, colorInfo);
  if (transferKinds[colorSpace] == 0u) {
    return rgb;
  }
  return float3(
    spektra_sample_transfer_lut(rgb.r, colorSpace, colorInfo, decodeLuts),
    spektra_sample_transfer_lut(rgb.g, colorSpace, colorInfo, decodeLuts),
    spektra_sample_transfer_lut(rgb.b, colorSpace, colorInfo, decodeLuts)
  );
}

static float3 spektra_mul_color_matrix(float3 rgb, int colorSpace, constant SpektraColorInfo &colorInfo, device const float *matrices) {
  const uint matrixOffset = spektra_color_space_index(colorSpace, colorInfo) * 9u;
  return float3(
    matrices[matrixOffset] * rgb.r + matrices[matrixOffset + 1u] * rgb.g + matrices[matrixOffset + 2u] * rgb.b,
    matrices[matrixOffset + 3u] * rgb.r + matrices[matrixOffset + 4u] * rgb.g + matrices[matrixOffset + 5u] * rgb.b,
    matrices[matrixOffset + 6u] * rgb.r + matrices[matrixOffset + 7u] * rgb.g + matrices[matrixOffset + 8u] * rgb.b
  );
}

static float3 spektra_sensitivity(uint wavelengthIndex, device const float *linearSensitivity) {
  const uint offset = wavelengthIndex * 3u;
  float3 sensitivity = float3(linearSensitivity[offset], linearSensitivity[offset + 1u], linearSensitivity[offset + 2u]);
  return select(float3(0.0), sensitivity, isfinite(sensitivity));
}

static float spektra_channel_component(float3 value, uint channel) {
  return channel == 0u ? value.r : (channel == 1u ? value.g : value.b);
}

static float spektra_channel_density_min(uint channel, constant SpektraKernelParams &params) {
  return max(channel == 0u ? params.grainDensityMinR : (channel == 1u ? params.grainDensityMinG : params.grainDensityMinB), 0.0);
}

static float spektra_channel_particle_scale(uint channel, constant SpektraKernelParams &params) {
  return max(channel == 0u ? params.grainParticleScaleR : (channel == 1u ? params.grainParticleScaleG : params.grainParticleScaleB), 1.0e-3);
}

static float spektra_channel_uniformity(uint channel, constant SpektraKernelParams &params) {
  return clamp(channel == 0u ? params.grainUniformityR : (channel == 1u ? params.grainUniformityG : params.grainUniformityB), 0.0, 1.0);
}

static float spektra_layer_particle_scale(uint layer, constant SpektraKernelParams &params) {
  return max(layer == 0u ? params.grainParticleScaleLayer0 : (layer == 1u ? params.grainParticleScaleLayer1 : params.grainParticleScaleLayer2), 1.0e-3);
}

static float3 spektra_apply_grain_controls(
  float3 baseDensity,
  float3 grainedDensity,
  constant SpektraKernelParams &params
) {
  const float amount = max(params.grainAmount, 0.0);
  const float saturation = clamp(params.grainSaturation, 0.0, 1.0);
  if (amount == 1.0 && saturation == 1.0) {
    return grainedDensity;
  }
  float3 delta = (grainedDensity - baseDensity) * amount;
  const float neutral = (delta.r + delta.g + delta.b) / 3.0;
  delta = mix(float3(neutral), delta, saturation);
  return max(baseDensity + delta, float3(0.0));
}

static float spektra_particle_developed_density(
  float density,
  float densityMax,
  float particles,
  float uniformity,
  float blurDamping,
  uint seed
) {
  const float safeDensityMax = max(densityMax, 1.0e-6);
  const float safeParticles = max(particles, 1.0e-3);
  const float probability = clamp(density / safeDensityMax, 1.0e-6, 1.0 - 1.0e-6);
  const float saturation = max(1.0 - probability * uniformity * (1.0 - 1.0e-6), 1.0e-6);
  const float expectedSeeds = safeParticles / saturation;
  const float expectedDeveloped = expectedSeeds * probability;
  const float variance = max(expectedSeeds * probability, 1.0e-6);
  const float developed = clamp(expectedDeveloped + sqrt(variance) * spektra_gaussian(seed) * blurDamping, 0.0, expectedSeeds);
  return developed * (safeDensityMax / safeParticles) * saturation;
}

static float spektra_density_curve_max(
  uint channel,
  constant SpektraCurveInfo &curveInfo,
  device const float *densityCurves
) {
  float maximum = 0.0;
  for (uint i = 0u; i < curveInfo.exposureCount; ++i) {
    maximum = max(maximum, densityCurves[i * 3u + channel]);
  }
  return max(maximum, 1.0e-6);
}

static float3 spektra_preview_grain_density(
  float3 densityCmy,
  constant SpektraKernelParams &params,
  constant SpektraCurveInfo &curveInfo,
  device const float *densityCurves,
  float2 filmUm,
  uint baseSeed
) {
  float3 outDensity = densityCmy;
  const float pixelArea = max(params.filmPixelSizeUm * params.filmPixelSizeUm, 1.0e-6);
  const float finalBlurPx = spektra_grain_final_blur_um(params) / max(params.filmPixelSizeUm, 1.0e-6);
  const float blurDamping = rsqrt(1.0 + 0.35 * finalBlurPx + 0.12 * max(params.grainBlurDyeCloudsUm, 0.0));
  const uint layerCount = params.grainSublayersEnabled != 0 ? 3u : uint(clamp(params.grainSubLayerCount, 1, 8));

  for (uint channel = 0u; channel < 3u; ++channel) {
    const float densityMin = spektra_channel_density_min(channel, params);
    const float densityMax = spektra_density_curve_max(channel, curveInfo, densityCurves) + densityMin;
    const float particleArea = max(params.grainParticleAreaUm2 * spektra_channel_particle_scale(channel, params), 1.0e-4);
    const float particles = max(pixelArea / particleArea / max(float(layerCount), 1.0), 1.0e-3);
    const float sourceDensity = max(spektra_channel_component(densityCmy, channel) + densityMin, 0.0);
    float accumulated = 0.0;
    for (uint layer = 0u; layer < layerCount; ++layer) {
      const uint particleSeed = spektra_film_cell_seed(
        filmUm,
        sqrt(particleArea),
        baseSeed ^ (channel * 0x85ebca6bu) ^ (layer * 0xc2b2ae35u)
      );
      accumulated += spektra_particle_developed_density(
        sourceDensity,
        densityMax,
        particles,
        spektra_channel_uniformity(channel, params),
        blurDamping,
        particleSeed
      );
    }
    accumulated /= max(float(layerCount), 1.0);
    outDensity[channel] = max(accumulated - densityMin, 0.0);
  }
  return outDensity;
}

static float spektra_interp_density_layer(
  float density,
  uint channel,
  uint layer,
  constant SpektraCurveInfo &curveInfo,
  constant SpektraSpectralInfo &info,
  device const float *densityCurves,
  device const float *densityCurveLayers
) {
  const uint count = curveInfo.exposureCount;
  if (count == 0u) {
    return 0.0;
  }
  const float target = info.filmPositive != 0u ? -density : density;
  const float firstX = info.filmPositive != 0u ? -densityCurves[channel] : densityCurves[channel];
  const float lastX = info.filmPositive != 0u ? -densityCurves[(count - 1u) * 3u + channel] : densityCurves[(count - 1u) * 3u + channel];
  const bool ascending = lastX >= firstX;
  if ((ascending && target <= firstX) || (!ascending && target >= firstX)) {
    return densityCurveLayers[layer * 3u + channel];
  }
  if ((ascending && target >= lastX) || (!ascending && target <= lastX)) {
    return densityCurveLayers[(count - 1u) * 9u + layer * 3u + channel];
  }

  uint lo = 0u;
  uint hi = count - 1u;
  while (hi - lo > 1u) {
    const uint mid = (lo + hi) >> 1u;
    const float x = info.filmPositive != 0u ? -densityCurves[mid * 3u + channel] : densityCurves[mid * 3u + channel];
    if ((ascending && x <= target) || (!ascending && x >= target)) {
      lo = mid;
    } else {
      hi = mid;
    }
  }

  const float x0 = info.filmPositive != 0u ? -densityCurves[lo * 3u + channel] : densityCurves[lo * 3u + channel];
  const float x1 = info.filmPositive != 0u ? -densityCurves[hi * 3u + channel] : densityCurves[hi * 3u + channel];
  const float y0 = densityCurveLayers[lo * 9u + layer * 3u + channel];
  const float y1 = densityCurveLayers[hi * 9u + layer * 3u + channel];
  const float t = clamp((target - x0) / max(x1 - x0, 1.0e-9), 0.0, 1.0);
  return max(mix(y0, y1, t), 0.0);
}

static float3 spektra_production_grain_density(
  float3 densityCmy,
  constant SpektraKernelParams &params,
  constant SpektraCurveInfo &curveInfo,
  constant SpektraSpectralInfo &info,
  device const float *densityCurves,
  device const float *densityCurveLayers,
  device const float *densityCurveLayerMaxima,
  float2 filmUm,
  uint baseSeed
) {
  if (params.grainSublayersEnabled == 0u) {
    return spektra_preview_grain_density(densityCmy, params, curveInfo, densityCurves, filmUm, baseSeed);
  }

  float3 outDensity = float3(0.0);
  const float pixelArea = max(params.filmPixelSizeUm * params.filmPixelSizeUm, 1.0e-6);
  const float finalBlurPx = spektra_grain_final_blur_um(params) / max(params.filmPixelSizeUm, 1.0e-6);
  const float blurDamping = rsqrt(1.0 + 0.12 * max(params.grainBlurDyeCloudsUm, 0.0) + 0.35 * finalBlurPx);

  for (uint channel = 0u; channel < 3u; ++channel) {
    const float densityMin = spektra_channel_density_min(channel, params);
    const float uniformity = spektra_channel_uniformity(channel, params);
    float densityMaxTotal = 0.0;
    for (uint layer = 0u; layer < 3u; ++layer) {
      densityMaxTotal += max(densityCurveLayerMaxima[layer * 3u + channel], 0.0);
    }
    densityMaxTotal = max(densityMaxTotal, 1.0e-6);

    float channelDensity = 0.0;
    for (uint layer = 0u; layer < 3u; ++layer) {
      const float layerMax = max(densityCurveLayerMaxima[layer * 3u + channel], 0.0);
      const float layerFraction = layerMax / densityMaxTotal;
      const float layerDensityMin = layerFraction * densityMin;
      const float layerDensityMax = max(layerMax + layerDensityMin, 1.0e-6);
      const float layerDensity = spektra_interp_density_layer(
        spektra_channel_component(densityCmy, channel),
        channel,
        layer,
        curveInfo,
        info,
        densityCurves,
        densityCurveLayers
      ) + layerDensityMin;
      const float particleArea = max(
        params.grainParticleAreaUm2 *
          spektra_channel_particle_scale(channel, params) *
          spektra_layer_particle_scale(layer, params),
        1.0e-4
      );
      const float particles = max(pixelArea * layerFraction / particleArea, 1.0e-3);
      const uint particleSeed = spektra_film_cell_seed(
        filmUm,
        sqrt(particleArea),
        baseSeed ^ (channel * 0x85ebca6bu) ^ (layer * 0xc2b2ae35u)
      );
      channelDensity += spektra_particle_developed_density(
        max(layerDensity, 0.0),
        layerDensityMax,
        particles,
        uniformity,
        blurDamping,
        particleSeed
      );
    }

    const float microSigma = params.grainMicroStructureSigmaNm * 0.001 / max(params.filmPixelSizeUm, 1.0e-6);
    if (microSigma > 0.05 && params.grainMicroStructureScale > 0.0) {
      const float sigma = microSigma * params.grainMicroStructureScale;
      const uint clumpSeed = spektra_film_cell_seed(
        filmUm,
        max(params.grainMicroStructureScale, 1.0e-4),
        baseSeed ^ (channel * 0x27d4eb2du) ^ 0x165667b1u
      );
      const float clump = exp(spektra_gaussian(clumpSeed) * sigma - 0.5 * sigma * sigma);
      channelDensity *= clump;
    }
    outDensity[channel] = max(channelDensity - densityMin, 0.0);
  }
  return outDensity;
}

static float3 spektra_apply_grain_to_density(
  float3 densityCmy,
  constant SpektraKernelParams &params,
  constant SpektraCurveInfo &curveInfo,
  constant SpektraSpectralInfo &info,
  device const float *densityCurves,
  device const float *densityCurveLayers,
  device const float *densityCurveLayerMaxima,
  float2 filmUm,
  uint baseSeed
) {
  if (params.grainEnabled == 0u) {
    return densityCmy;
  }
  float3 grainedDensity;
  if (params.grainModel == 1) {
    grainedDensity = spektra_production_grain_density(
      densityCmy,
      params,
      curveInfo,
      info,
      densityCurves,
      densityCurveLayers,
      densityCurveLayerMaxima,
      filmUm,
      baseSeed
    );
  } else {
    grainedDensity = spektra_preview_grain_density(densityCmy, params, curveInfo, densityCurves, filmUm, baseSeed);
  }
  return spektra_apply_grain_controls(densityCmy, grainedDensity, params);
}

static float spektra_development_activity(float stops) {
  const float clampedStops = clamp(stops, -2.0, 2.0);
  float developmentSeconds = 180.0;
  if (clampedStops < 0.0) {
    developmentSeconds = mix(180.0, 150.0, min(-clampedStops, 1.0));
  } else if (clampedStops <= 1.0) {
    developmentSeconds = mix(180.0, 220.0, clampedStops);
  } else {
    developmentSeconds = mix(220.0, 280.0, clampedStops - 1.0);
  }
  return log(developmentSeconds / 180.0);
}

static float spektra_push_pull_speed_gain(float stops) {
  if (stops > 0.0) {
    const float pushOne = mix(0.0, 0.33, min(stops, 1.0));
    return stops <= 1.0 ? pushOne : mix(0.33, 0.5, min(stops - 1.0, 1.0));
  }
  if (stops < 0.0) {
    return mix(0.0, -0.2, min(-stops, 1.0));
  }
  return 0.0;
}

static float spektra_sigmoid(float u) {
  return 1.0 / (1.0 + exp(-u));
}

static float spektra_push_pull_warp_log_raw(float logRaw, uint channel, float stops) {
  const float activity = spektra_development_activity(stops);
  const float signedActivitySquared = activity * abs(activity);

  const float3 toeLinear = float3(0.0, 0.0, 0.0);
  const float3 midLinear = float3(0.25, 0.28, 0.31);
  const float3 shoulderLinear = float3(0.32, 0.38, 0.45);
  const float3 toeQuadratic = float3(0.0, 0.0, 0.0);
  const float3 midQuadratic = float3(0.04, 0.06, 0.08);
  const float3 shoulderQuadratic = float3(0.08, 0.12, 0.16);

  const float toeMask = 1.0 - spektra_sigmoid((logRaw + 2.0) / 0.5);
  const float shoulderMask = spektra_sigmoid(logRaw / 0.5);
  const float midMask = max(1.0 - toeMask - shoulderMask, 0.0);

  const float toeShift = toeLinear[channel] * activity + toeQuadratic[channel] * signedActivitySquared;
  const float midShift = midLinear[channel] * activity + midQuadratic[channel] * signedActivitySquared;
  const float shoulderShift = shoulderLinear[channel] * activity + shoulderQuadratic[channel] * signedActivitySquared;
  return logRaw + toeShift * toeMask + midShift * midMask + shoulderShift * shoulderMask;
}

static float3 spektra_experimental_push_pull_log_raw(float3 logRaw, float stops) {
  float3 shifted = logRaw - (stops - spektra_push_pull_speed_gain(stops)) * log10(2.0);
  const float activity = spektra_development_activity(stops);
  const float meanLogRaw = (shifted.x + shifted.y + shifted.z) / 3.0;
  const float3x3 coupling = float3x3(
    float3(0.0, -0.015, 0.015),
    float3(0.015, 0.0, -0.015),
    float3(-0.015, 0.015, 0.0)
  );
  shifted += activity * (coupling * (shifted - float3(meanLogRaw)));
  return float3(
    spektra_push_pull_warp_log_raw(shifted.r, 0u, stops),
    spektra_push_pull_warp_log_raw(shifted.g, 1u, stops),
    spektra_push_pull_warp_log_raw(shifted.b, 2u, stops)
  );
}

static float spektra_experimental_push_pull_density_gain(float logRaw, uint channel, float stops) {
  const float activity = spektra_development_activity(stops);
  const float signedActivitySquared = activity * abs(activity);
  const float3 buildLinear = float3(1.05, 0.95, 1.00);
  const float3 buildQuadratic = float3(-0.90, -0.82, -0.86);

  const float toeMask = 1.0 - spektra_sigmoid((logRaw + 2.0) / 0.5);
  const float shoulderMask = spektra_sigmoid(logRaw / 0.5);
  const float midMask = max(1.0 - toeMask - shoulderMask, 0.0);
  const float regionWeight = 0.12 * toeMask + midMask + shoulderMask;
  const float build = buildLinear[channel] * activity + buildQuadratic[channel] * signedActivitySquared;
  return clamp(1.0 + build * regionWeight, 0.35, 2.0);
}

static float spektra_interp_density_curve(
  float logRaw,
  uint channel,
  float gammaFactor,
  constant SpektraCurveInfo &curveInfo,
  device const float *logExposure,
  device const float *densityCurves,
  uint lookupMode,
  uint smoothInterpolation
) {
  const uint count = curveInfo.exposureCount;
  if (count == 0u) {
    return 0.0;
  }

  device const float2 *curveExposure = (device const float2 *)logExposure;
  const float gamma = max(gammaFactor, 1.0e-6);
  const float lookupRaw = gammaFactor == 1.0 ? logRaw : logRaw * gamma;
  const float firstX = curveExposure[0].x;
  const float lastX = curveExposure[count - 1u].x;
  if (lookupRaw <= firstX) {
    return densityCurves[channel];
  }
  if (lookupRaw >= lastX) {
    return densityCurves[(count - 1u) * 3u + channel];
  }

  if (smoothInterpolation == 0u && lookupMode != 0u && count > 1u) {
    const float indexF = clamp(
      (lookupRaw - firstX) * float(count - 1u) / max(lastX - firstX, 1.0e-9),
      0.0,
      float(count - 1u)
    );
    if (lookupMode == 2u) {
      const uint idx = uint(clamp(floor(indexF + 0.5), 0.0, float(count - 1u)));
      return densityCurves[idx * 3u + channel];
    }
    const uint loUniform = uint(floor(indexF));
    const uint hiUniform = min(loUniform + 1u, count - 1u);
    const float y0Uniform = densityCurves[loUniform * 3u + channel];
    const float y1Uniform = densityCurves[hiUniform * 3u + channel];
    return mix(y0Uniform, y1Uniform, indexF - float(loUniform));
  }

  uint lo = 0u;
  uint hi = count - 1u;
  while (hi - lo > 1u) {
    const uint mid = (lo + hi) >> 1u;
    if (curveExposure[mid].x <= lookupRaw) {
      lo = mid;
    } else {
      hi = mid;
    }
  }

  const float x0 = curveExposure[lo].x;
  const float x1 = curveExposure[hi].x;
  const float inverseDx0 = curveExposure[lo].y;
  const float y0 = densityCurves[lo * 3u + channel];
  const float y1 = densityCurves[hi * 3u + channel];
  const float t = clamp((lookupRaw - x0) * inverseDx0, 0.0, 1.0);
  if (smoothInterpolation != 0u && count > 2u) {
    const float dx0 = max(x1 - x0, 1.0e-9);
    const float d0 = (y1 - y0) * inverseDx0;
    float m0 = d0;
    float m1 = d0;
    if (lo > 0u) {
      const float yPrev = densityCurves[(lo - 1u) * 3u + channel];
      const float dPrev = (y0 - yPrev) * curveExposure[lo - 1u].y;
      m0 = dPrev * d0 > 0.0 ? 0.5 * (dPrev + d0) : 0.0;
    }
    if (hi + 1u < count) {
      const float yNext = densityCurves[(hi + 1u) * 3u + channel];
      const float dNext = (yNext - y1) * curveExposure[hi].y;
      m1 = dNext * d0 > 0.0 ? 0.5 * (dNext + d0) : 0.0;
    }
    if (abs(d0) <= 1.0e-9) {
      m0 = 0.0;
      m1 = 0.0;
    } else {
      const float limit = 3.0 * abs(d0);
      m0 = d0 * m0 > 0.0 ? clamp(m0, -limit, limit) : 0.0;
      m1 = d0 * m1 > 0.0 ? clamp(m1, -limit, limit) : 0.0;
    }
    const float t2 = t * t;
    const float t3 = t2 * t;
    return (2.0 * t3 - 3.0 * t2 + 1.0) * y0 +
      (t3 - 2.0 * t2 + t) * dx0 * m0 +
      (-2.0 * t3 + 3.0 * t2) * y1 +
      (t3 - t2) * dx0 * m1;
  }
  return mix(y0, y1, t);
}

static float3 spektra_hanatos_raw(
  float3 xyz,
  constant SpektraSpectralInfo &info,
  device const float4 *hanatosRawResponseLut
) {
  const float b = xyz.x + xyz.y + xyz.z;
  const float2 xy = clamp(xyz.xy / max(b, 1.0e-10), float2(0.0), float2(1.0));
  const float tx = clamp((1.0 - xy.x) * (1.0 - xy.x), 0.0, 1.0);
  const float ty = clamp(xy.y / max(1.0 - xy.x, 1.0e-10), 0.0, 1.0);
  const float xCoord = tx * float(info.hanatosWidth - 1u);
  const float yCoord = ty * float(info.hanatosHeight - 1u);
  const int xBase = xCoord >= float(info.hanatosWidth - 1u) ? int(info.hanatosWidth - 2u) : int(floor(xCoord));
  const int yBase = yCoord >= float(info.hanatosHeight - 1u) ? int(info.hanatosHeight - 2u) : int(floor(yCoord));
  const float xFrac = xCoord >= float(info.hanatosWidth - 1u) ? 1.0 : xCoord - float(xBase);
  const float yFrac = yCoord >= float(info.hanatosHeight - 1u) ? 1.0 : yCoord - float(yBase);
  float wx[4] = {
    spektra_mitchell_weight(xFrac + 1.0),
    spektra_mitchell_weight(xFrac),
    spektra_mitchell_weight(xFrac - 1.0),
    spektra_mitchell_weight(xFrac - 2.0)
  };
  float wy[4] = {
    spektra_mitchell_weight(yFrac + 1.0),
    spektra_mitchell_weight(yFrac),
    spektra_mitchell_weight(yFrac - 1.0),
    spektra_mitchell_weight(yFrac - 2.0)
  };

  float3 raw = float3(0.0);
  float weightSum = 0.0;
  for (uint i = 0u; i < 4u; ++i) {
    const uint xi = spektra_safe_index(xBase - 1 + int(i), info.hanatosWidth);
    for (uint j = 0u; j < 4u; ++j) {
      const uint yj = spektra_safe_index(yBase - 1 + int(j), info.hanatosHeight);
      const float weight = wx[i] * wy[j];
      weightSum += weight;
      raw += weight * hanatosRawResponseLut[xi * info.hanatosHeight + yj].xyz;
    }
  }
  if (weightSum != 0.0) {
    raw /= weightSum;
  }
  return raw * max(b, 0.0);
}

static float3 spektra_mallett_raw(
  float3 linearSrgb,
  device const float *mallettRawMatrix
) {
  const float3 srgb = max(linearSrgb, float3(0.0));
  return float3(
    mallettRawMatrix[0u] * srgb.r + mallettRawMatrix[1u] * srgb.g + mallettRawMatrix[2u] * srgb.b,
    mallettRawMatrix[3u] * srgb.r + mallettRawMatrix[4u] * srgb.g + mallettRawMatrix[5u] * srgb.b,
    mallettRawMatrix[6u] * srgb.r + mallettRawMatrix[7u] * srgb.g + mallettRawMatrix[8u] * srgb.b
  );
}

static float3 spektra_film_raw_from_decoded(
  float3 decoded,
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  constant SpektraSpectralInfo &info,
  device const float *hanatosSpectraLut,
  device const float *mallettBasisIlluminant,
  device const float *inputToReferenceXyz,
  device const float *inputToSrgb
) {
  float3 raw;
  if (params.rgbToRawMethod == 1) {
    const float3 srgb = spektra_mul_color_matrix(decoded, params.inputColorSpace, colorInfo, inputToSrgb);
    raw = spektra_mallett_raw(srgb, mallettBasisIlluminant);
  } else {
    const float3 xyz = spektra_mul_color_matrix(decoded, params.inputColorSpace, colorInfo, inputToReferenceXyz);
    device const float4 *packedHanatosSpectraLut = (device const float4 *)hanatosSpectraLut;
    const uint compressedOffset = spektra_color_adaptation_enabled(params, kSpektraColorAdaptationInputCompression)
      ? info.hanatosWidth * info.hanatosHeight
      : 0u;
    raw = spektra_hanatos_raw(xyz, info, packedHanatosSpectraLut + compressedOffset);
  }
  return max(raw * exp2(params.filmExposureEv + params.autoExposureEv), float3(0.0));
}

static float3 spektra_film_raw(
  float3 rgb,
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  constant SpektraSpectralInfo &info,
  device const float *logSensitivity,
  device const float *bandpassHanatos2025,
  device const float *hanatosSpectraLut,
  device const float *mallettBasisIlluminant,
  device const float *inputToReferenceXyz,
  device const float *inputToSrgb,
  device const float *decodeLuts,
  device const uint *transferKinds
) {
  (void)logSensitivity;
  (void)bandpassHanatos2025;
  const float3 decoded = spektra_decode_input_rgb(rgb, params, colorInfo, decodeLuts, transferKinds);
  return spektra_film_raw_from_decoded(
    decoded,
    params,
    colorInfo,
    info,
    hanatosSpectraLut,
    mallettBasisIlluminant,
    inputToReferenceXyz,
    inputToSrgb
  );
}

static float3 spektra_film_log_raw(
  float3 rgb,
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  constant SpektraSpectralInfo &info,
  device const float *logSensitivity,
  device const float *bandpassHanatos2025,
  device const float *hanatosSpectraLut,
  device const float *mallettBasisIlluminant,
  device const float *inputToReferenceXyz,
  device const float *inputToSrgb,
  device const float *decodeLuts,
  device const uint *transferKinds
) {
  const float3 raw = spektra_film_raw(
    rgb,
    params,
    colorInfo,
    info,
    logSensitivity,
    bandpassHanatos2025,
    hanatosSpectraLut,
    mallettBasisIlluminant,
    inputToReferenceXyz,
    inputToSrgb,
    decodeLuts,
    transferKinds
  );
  return log10(raw + float3(1.0e-10));
}

static float3 spektra_film_log_raw_linear_srgb(
  float3 linearSrgb,
  int rgbToRawMethod,
  constant SpektraColorInfo &colorInfo,
  constant SpektraSpectralInfo &info,
  device const float *logSensitivity,
  device const float *bandpassHanatos2025,
  device const float *hanatosSpectraLut,
  device const float *mallettBasisIlluminant,
  device const float *inputToReferenceXyz
) {
  constexpr int kLinearSrgbColorSpace = 17;
  const float3 rgb = max(linearSrgb, float3(0.0));
  (void)logSensitivity;
  (void)bandpassHanatos2025;
  float3 raw;
  if (rgbToRawMethod == 1) {
    raw = spektra_mallett_raw(rgb, mallettBasisIlluminant);
  } else {
    const float3 xyz = spektra_mul_color_matrix(rgb, kLinearSrgbColorSpace, colorInfo, inputToReferenceXyz);
    raw = spektra_hanatos_raw(xyz, info, (device const float4 *)hanatosSpectraLut);
  }
  return log10(max(raw, float3(0.0)) + float3(1.0e-10));
}

static float3 spektra_develop_film_density(
  float3 logRaw,
  constant SpektraKernelParams &params,
  constant SpektraCurveInfo &curveInfo,
  device const float *logExposure,
  device const float *densityCurves
) {
  const uint smoothInterpolation =
    spektra_color_adaptation_enabled(params, kSpektraColorAdaptationCurveSmoothing) ? 1u : 0u;
  if (params.filmPushPullMode == 1) {
    const float3 lookupRaw = spektra_experimental_push_pull_log_raw(logRaw, params.filmPushPullStops);
    const float3 density = float3(
      spektra_interp_density_curve(lookupRaw.r, 0u, params.filmGamma, curveInfo, logExposure, densityCurves, params.densityCurveLookupMode, smoothInterpolation),
      spektra_interp_density_curve(lookupRaw.g, 1u, params.filmGamma, curveInfo, logExposure, densityCurves, params.densityCurveLookupMode, smoothInterpolation),
      spektra_interp_density_curve(lookupRaw.b, 2u, params.filmGamma, curveInfo, logExposure, densityCurves, params.densityCurveLookupMode, smoothInterpolation)
    );
    return density * float3(
      spektra_experimental_push_pull_density_gain(lookupRaw.r, 0u, params.filmPushPullStops),
      spektra_experimental_push_pull_density_gain(lookupRaw.g, 1u, params.filmPushPullStops),
      spektra_experimental_push_pull_density_gain(lookupRaw.b, 2u, params.filmPushPullStops)
    );
  }
  return float3(
    spektra_interp_density_curve(logRaw.r, 0u, params.filmGamma, curveInfo, logExposure, densityCurves, params.densityCurveLookupMode, smoothInterpolation),
    spektra_interp_density_curve(logRaw.g, 1u, params.filmGamma, curveInfo, logExposure, densityCurves, params.densityCurveLookupMode, smoothInterpolation),
    spektra_interp_density_curve(logRaw.b, 2u, params.filmGamma, curveInfo, logExposure, densityCurves, params.densityCurveLookupMode, smoothInterpolation)
  );
}

static float spektra_filtered_enlarger_illuminant_with_filters(
  uint wavelength,
  constant SpektraKernelParams &params,
  constant SpektraSpectralInfo &info,
  device const float *thKg3Illuminant,
  device const float *customEnlargerFilters,
  device const float *neutralPrintFilters,
  float cFilter,
  float mFilterShift,
  float yFilterShift
) {
  const uint film = uint(clamp(params.film, 0, int(max(info.filmCount, 1u) - 1u)));
  const uint paper = uint(clamp(params.paper, 0, int(max(info.paperCount, 1u) - 1u)));
  const uint neutralOffset = (paper * info.filmCount + film) * 3u;
  const float3 neutral = float3(
    neutralPrintFilters[neutralOffset],
    neutralPrintFilters[neutralOffset + 1u],
    neutralPrintFilters[neutralOffset + 2u]
  );
  const float3 cc = max(
    neutral + float3(cFilter, mFilterShift, yFilterShift),
    float3(0.0)
  );
  const float3 wheelTransmittance = pow(float3(10.0), -cc / 100.0);
  const uint filterOffset = wavelength * 3u;
  const float3 filters = clamp(float3(
    customEnlargerFilters[filterOffset],
    customEnlargerFilters[filterOffset + 1u],
    customEnlargerFilters[filterOffset + 2u]
  ), float3(0.0), float3(1.0));
  const float3 dimmed = 1.0 - (1.0 - filters) * (1.0 - wheelTransmittance);
  return thKg3Illuminant[wavelength] * dimmed.r * dimmed.g * dimmed.b;
}

static float spektra_filtered_enlarger_illuminant(
  uint wavelength,
  constant SpektraKernelParams &params,
  constant SpektraSpectralInfo &info,
  device const float *thKg3Illuminant,
  device const float *customEnlargerFilters,
  device const float *neutralPrintFilters
) {
  return spektra_filtered_enlarger_illuminant_with_filters(
    wavelength,
    params,
    info,
    thKg3Illuminant,
    customEnlargerFilters,
    neutralPrintFilters,
    params.filterC,
    params.filterMShift,
    params.filterYShift
  );
}

static float spektra_spectral_transmittance(float density, constant SpektraKernelParams &params) {
  constexpr float kLog2Ten = 3.3219280948873623;
  constexpr float kLnTen = 2.302585092994046;
  if (params.spectralTransmittanceMode == 1u) {
    return exp2(-density * kLog2Ten);
  }
  if (params.spectralTransmittanceMode == 2u) {
    return fast::exp(-density * kLnTen);
  }
  return pow(10.0, -density);
}

static float spektra_spectral_transmittance_pow(float density) {
  const float transmittance = pow(10.0, -density);
  return isfinite(transmittance) ? transmittance : 0.0;
}

static float spektra_preflash_filtered_enlarger_illuminant(
  uint wavelength,
  constant SpektraKernelParams &params,
  constant SpektraSpectralInfo &info,
  device const float *thKg3Illuminant,
  device const float *customEnlargerFilters,
  device const float *neutralPrintFilters
) {
  return spektra_filtered_enlarger_illuminant_with_filters(
    wavelength,
    params,
    info,
    thKg3Illuminant,
    customEnlargerFilters,
    neutralPrintFilters,
    0.0,
    params.preflashMFilterShift,
    params.preflashYFilterShift
  );
}

static float3 spektra_film_silver_density(float3 densityCmy, constant SpektraSpectralInfo &info) {
  if (info.filmPositive != 0u) {
    return max(
      float3(
        info.filmDensityCurveMaximum0,
        info.filmDensityCurveMaximum1,
        info.filmDensityCurveMaximum2
      ) - densityCmy,
      float3(0.0)
    );
  }
  return max(densityCmy, float3(0.0));
}

static float3 spektra_bleach_bypass_silver_layers(
  float3 densityCmy,
  bool printStage,
  constant SpektraSpectralInfo &info
) {
  return printStage ? max(densityCmy, float3(0.0)) : spektra_film_silver_density(densityCmy, info);
}

static float spektra_bleach_bypass_retained_silver_image(
  float3 densityCmy,
  bool printStage,
  constant SpektraSpectralInfo &info
) {
  const float3 silverLayers = spektra_bleach_bypass_silver_layers(densityCmy, printStage, info);
  const float layerShoulder = printStage ? 0.65 : 0.85;
  const float3 retainedSilverByLayer = silverLayers / (silverLayers + float3(layerShoulder));
  return (retainedSilverByLayer.r + retainedSilverByLayer.g + retainedSilverByLayer.b) / 3.0;
}

static float spektra_bleach_bypass_retained_silver_density(
  float3 densityCmy,
  float amount,
  bool printStage,
  constant SpektraSpectralInfo &info
) {
  const float retainedSilverImage = spektra_bleach_bypass_retained_silver_image(densityCmy, printStage, info);
  const float silverDensityScale = printStage ? 0.36 : 0.22;
  return clamp(amount, 0.0, 1.0) * silverDensityScale * retainedSilverImage;
}

static float3 spektra_bleach_bypass_dye_density(
  float3 densityCmy,
  float amount,
  bool printStage,
  constant SpektraSpectralInfo &info
) {
  const float retainedSilverImage = spektra_bleach_bypass_retained_silver_image(densityCmy, printStage, info);
  const float blackImageAmount = clamp(clamp(amount, 0.0, 1.0) * retainedSilverImage, 0.0, 1.0);
  const float blackDensity = max(densityCmy.r, max(densityCmy.g, densityCmy.b));
  return mix(densityCmy, float3(blackDensity), blackImageAmount);
}

static float spektra_negative_leuco_cyan_density_loss(
  float3 densityCmy,
  float amount,
  constant SpektraKernelParams &params,
  constant SpektraSpectralInfo &info
) {
  if (info.filmPositive != 0u) {
    return 0.0;
  }
  const float cyanDensityMax = max(info.filmDensityCurveMaximum0, 1.0e-6);
  const float cyanDensityDrive = clamp(max(densityCmy.r, 0.0) / cyanDensityMax, 0.0, 1.0);
  const float coupling = clamp(params.negativeLeucoCyanCoupling, 0.0, 2.0);
  const float documentedLeucoCyanMaxLoss = 0.30;
  return min(
    clamp(amount, 0.0, 1.0) * coupling * documentedLeucoCyanMaxLoss * cyanDensityDrive,
    documentedLeucoCyanMaxLoss * coupling
  );
}

static float3 spektra_negative_bleach_bypass_dye_density(
  float3 densityCmy,
  float amount,
  constant SpektraKernelParams &params,
  constant SpektraSpectralInfo &info
) {
  float3 bypassedDensityCmy = spektra_bleach_bypass_dye_density(densityCmy, amount, false, info);
  bypassedDensityCmy.r = max(
    bypassedDensityCmy.r - spektra_negative_leuco_cyan_density_loss(densityCmy, amount, params, info),
    0.0
  );
  return bypassedDensityCmy;
}

static float spektra_bleach_bypass_silver_spectral_density(
  float retainedSilverDensity
) {
  return retainedSilverDensity;
}

static float3 spektra_print_raw_from_film_density(
  float3 filmDensityCmy,
  constant SpektraKernelParams &params,
  constant SpektraSpectralInfo &info,
  device const float *filmChannelDensity,
  device const float *filmBaseDensity,
  device const float *paperLogSensitivity,
  device const float *thKg3Illuminant,
  device const float *customEnlargerFilters,
  device const float *neutralPrintFilters,
  device const float *academyPrinterDensityData
) {
  float3 raw = float3(0.0);
  const float3 bypassedFilmDensityCmy = spektra_negative_bleach_bypass_dye_density(
    filmDensityCmy,
    params.negativeBleachBypassAmount,
    params,
    info
  );
  const float retainedSilverDensity = spektra_bleach_bypass_retained_silver_density(
    filmDensityCmy,
    params.negativeBleachBypassAmount,
    false,
    info
  );
  if (params.printTiming == 1) {
    float3 normalization = float3(0.0);
    for (uint wavelength = 0u; wavelength < info.filmWavelengthCount; ++wavelength) {
      const uint channelOffset = wavelength * 3u;
      const float densitySpectral =
        bypassedFilmDensityCmy.r * filmChannelDensity[channelOffset] +
        bypassedFilmDensityCmy.g * filmChannelDensity[channelOffset + 1u] +
        bypassedFilmDensityCmy.b * filmChannelDensity[channelOffset + 2u] +
        filmBaseDensity[wavelength] +
        spektra_bleach_bypass_silver_spectral_density(retainedSilverDensity);
      const float transmittance = spektra_spectral_transmittance(densitySpectral, params);
      const float3 apd = max(float3(
        academyPrinterDensityData[channelOffset],
        academyPrinterDensityData[channelOffset + 1u],
        academyPrinterDensityData[channelOffset + 2u]
      ), float3(0.0));
      raw += (isfinite(transmittance) ? transmittance : 0.0) * apd;
      normalization += apd;
    }
    return raw / max(normalization, float3(1.0e-10));
  }
  for (uint wavelength = 0u; wavelength < info.filmWavelengthCount; ++wavelength) {
    const uint channelOffset = wavelength * 3u;
    const float densitySpectral =
      bypassedFilmDensityCmy.r * filmChannelDensity[channelOffset] +
      bypassedFilmDensityCmy.g * filmChannelDensity[channelOffset + 1u] +
      bypassedFilmDensityCmy.b * filmChannelDensity[channelOffset + 2u] +
      filmBaseDensity[wavelength] +
      spektra_bleach_bypass_silver_spectral_density(retainedSilverDensity);
    const float lightRaw = spektra_spectral_transmittance(densitySpectral, params) *
      spektra_filtered_enlarger_illuminant(wavelength, params, info, thKg3Illuminant, customEnlargerFilters, neutralPrintFilters);
    const float light = isfinite(lightRaw) ? lightRaw : 0.0;
    raw += light * spektra_sensitivity(wavelength, paperLogSensitivity);
  }
  return raw;
}

static float3 spektra_print_raw_from_film_density_cached(
  float3 filmDensityCmy,
  constant SpektraKernelParams &params,
  constant SpektraSpectralInfo &info,
  device const float *filmChannelDensity,
  device const float4 *filmSpectralDensity,
  device const float4 *filteredEnlargerResponse,
  device const float *academyPrinterDensityData
) {
  if (params.printTiming != 1 &&
      params.spectralTransmittanceMode == 0u &&
      params.negativeBleachBypassAmount == 0.0 &&
      info.filmWavelengthCount == 81u) {
    float3 raw0 = float3(0.0);
    float3 raw1 = float3(0.0);
    float3 raw2 = float3(0.0);
    for (uint wavelength = 0u; wavelength < 81u; wavelength += 3u) {
      const float4 spectral0 = filmSpectralDensity[wavelength];
      const float4 spectral1 = filmSpectralDensity[wavelength + 1u];
      const float4 spectral2 = filmSpectralDensity[wavelength + 2u];
      raw0 += spektra_spectral_transmittance_pow(dot(filmDensityCmy, spectral0.xyz)) *
        filteredEnlargerResponse[wavelength].xyz;
      raw1 += spektra_spectral_transmittance_pow(dot(filmDensityCmy, spectral1.xyz)) *
        filteredEnlargerResponse[wavelength + 1u].xyz;
      raw2 += spektra_spectral_transmittance_pow(dot(filmDensityCmy, spectral2.xyz)) *
        filteredEnlargerResponse[wavelength + 2u].xyz;
    }
    return raw0 + raw1 + raw2;
  }
  float3 raw = float3(0.0);
  const float3 bypassedFilmDensityCmy = spektra_negative_bleach_bypass_dye_density(
    filmDensityCmy,
    params.negativeBleachBypassAmount,
    params,
    info
  );
  const float retainedSilverDensity = spektra_bleach_bypass_retained_silver_density(
    filmDensityCmy,
    params.negativeBleachBypassAmount,
    false,
    info
  );
  if (params.printTiming == 1) {
    float3 normalization = float3(0.0);
    for (uint wavelength = 0u; wavelength < info.filmWavelengthCount; ++wavelength) {
      const uint channelOffset = wavelength * 3u;
      const float4 spectral = filmSpectralDensity[wavelength];
      const float densitySpectral =
        dot(bypassedFilmDensityCmy, spectral.xyz) +
        spectral.w +
        spektra_bleach_bypass_silver_spectral_density(retainedSilverDensity);
      const float transmittance = spektra_spectral_transmittance(densitySpectral, params);
      const float3 apd = max(float3(
        academyPrinterDensityData[channelOffset],
        academyPrinterDensityData[channelOffset + 1u],
        academyPrinterDensityData[channelOffset + 2u]
      ), float3(0.0));
      raw += (isfinite(transmittance) ? transmittance : 0.0) * apd;
      normalization += apd;
    }
    return raw / max(normalization, float3(1.0e-10));
  }
  for (uint wavelength = 0u; wavelength < info.filmWavelengthCount; ++wavelength) {
    const float4 spectral = filmSpectralDensity[wavelength];
    const float densitySpectral =
      dot(bypassedFilmDensityCmy, spectral.xyz) +
      spectral.w +
      spektra_bleach_bypass_silver_spectral_density(retainedSilverDensity);
    const float transmittance = spektra_spectral_transmittance(densitySpectral, params);
    const float3 response = filteredEnlargerResponse[info.filmWavelengthCount + wavelength].xyz;
    raw += (isfinite(transmittance) ? transmittance : 0.0) * response;
  }
  return raw;
}

static float3 spektra_printer_light_exposure_scale(
  constant SpektraKernelParams &params,
  constant SpektraSpectralInfo &info,
  device const float *academyPrinterDensityData
) {
  const float3 points = float3(
    params.printerLightsR,
    params.printerLightsG,
    params.printerLightsB
  );
  const float linkedPoint = (params.printerLightsR + params.printerLightsG + params.printerLightsB) / 3.0;
  const float3 resolvedPoints = params.printerLightsGang != 0u
    ? float3(linkedPoint)
    : points;
  float3 internalPoints = float3(0.0);
  if (params.printTiming == 1 && params.printerLightCalibration != 0u) {
    const uint film = uint(clamp(params.film, 0, int(max(info.filmCount, 1u) - 1u)));
    const uint paper = uint(clamp(params.paper, 0, int(max(info.paperCount, 1u) - 1u)));
    const uint offset = info.filmWavelengthCount * 3u + (paper * info.filmCount + film) * 3u;
    internalPoints = float3(
      academyPrinterDensityData[offset],
      academyPrinterDensityData[offset + 1u],
      academyPrinterDensityData[offset + 2u]
    );
  }
  return exp2((internalPoints + resolvedPoints) / 12.0);
}

static float3 spektra_apd_printer_timing_exposure_scale(
  constant SpektraKernelParams &params,
  constant SpektraSpectralInfo &info,
  device const float *academyPrinterDensityData
) {
  if (params.printTiming != 1) {
    return float3(1.0);
  }
  return spektra_printer_light_exposure_scale(params, info, academyPrinterDensityData);
}

static float3 spektra_apd_neutral_exposure_scale(
  constant SpektraKernelParams &params,
  constant SpektraSpectralInfo &info,
  device const float *academyPrinterDensityData
) {
  if (params.printTiming != 1 || params.printerLightCalibration == 0u) {
    return float3(1.0);
  }
  const uint film = uint(clamp(params.film, 0, int(max(info.filmCount, 1u) - 1u)));
  const uint paper = uint(clamp(params.paper, 0, int(max(info.paperCount, 1u) - 1u)));
  const uint offset = info.filmWavelengthCount * 3u + (paper * info.filmCount + film) * 3u;
  return exp2(float3(
    academyPrinterDensityData[offset],
    academyPrinterDensityData[offset + 1u],
    academyPrinterDensityData[offset + 2u]
  ) / 12.0);
}

static float3 spektra_print_raw_preflash(
  constant SpektraKernelParams &params,
  constant SpektraSpectralInfo &info,
  device const float *filmBaseDensity,
  device const float *paperLogSensitivity,
  device const float *thKg3Illuminant,
  device const float *customEnlargerFilters,
  device const float *neutralPrintFilters,
  device const float *academyPrinterDensityData
) {
  if (params.preflashExposure <= 0.0) {
    return float3(0.0);
  }
  float3 raw = float3(0.0);
  if (params.printTiming == 1) {
    float3 normalization = float3(0.0);
    for (uint wavelength = 0u; wavelength < info.filmWavelengthCount; ++wavelength) {
      const uint channelOffset = wavelength * 3u;
      const float transmittance = spektra_spectral_transmittance(filmBaseDensity[wavelength], params);
      const float3 apd = max(float3(
        academyPrinterDensityData[channelOffset],
        academyPrinterDensityData[channelOffset + 1u],
        academyPrinterDensityData[channelOffset + 2u]
      ), float3(0.0));
      raw += (isfinite(transmittance) ? transmittance : 0.0) * apd;
      normalization += apd;
    }
    return (raw / max(normalization, float3(1.0e-10))) *
      spektra_apd_neutral_exposure_scale(params, info, academyPrinterDensityData) *
      max(params.preflashExposure, 0.0);
  }
  for (uint wavelength = 0u; wavelength < info.filmWavelengthCount; ++wavelength) {
    const float densityBase = filmBaseDensity[wavelength];
    const float lightRaw = spektra_spectral_transmittance(densityBase, params) *
      spektra_preflash_filtered_enlarger_illuminant(wavelength, params, info, thKg3Illuminant, customEnlargerFilters, neutralPrintFilters);
    const float light = isfinite(lightRaw) ? lightRaw : 0.0;
    raw += light * spektra_sensitivity(wavelength, paperLogSensitivity);
  }
  return raw * max(params.preflashExposure, 0.0);
}

static float spektra_print_midgray_exposure_factor(
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  constant SpektraCurveInfo &filmCurveInfo,
  constant SpektraSpectralInfo &info,
  device const float *filmLogExposure,
  device const float *filmDensityCurves,
  device const float *filmLogSensitivity,
  device const float *bandpassHanatos2025,
  device const float *hanatosSpectraLut,
  device const float *mallettBasisIlluminant,
  device const float *inputToReferenceXyz,
  device const float *filmChannelDensity,
  device const float *filmBaseDensity,
  device const float *paperLogSensitivity,
  device const float *thKg3Illuminant,
  device const float *customEnlargerFilters,
  device const float *neutralPrintFilters,
  device const float *academyPrinterDensityData
) {
  const float3 midgrayLogRaw = spektra_film_log_raw_linear_srgb(
    float3(0.184),
    params.rgbToRawMethod,
    colorInfo,
    info,
    filmLogSensitivity,
    bandpassHanatos2025,
    hanatosSpectraLut,
    mallettBasisIlluminant,
    inputToReferenceXyz
  );
  const float3 midgrayDensityCmy = spektra_develop_film_density(
    midgrayLogRaw,
    params,
    filmCurveInfo,
    filmLogExposure,
    filmDensityCurves
  ) + float3(
    info.filmDensityCurveMinimum0,
    info.filmDensityCurveMinimum1,
    info.filmDensityCurveMinimum2
  );
  const float3 rawMidgray = max(
    spektra_print_raw_from_film_density(
      midgrayDensityCmy,
      params,
      info,
      filmChannelDensity,
      filmBaseDensity,
      paperLogSensitivity,
      thKg3Illuminant,
      customEnlargerFilters,
      neutralPrintFilters,
      academyPrinterDensityData
    ),
    float3(1.0e-10)
  );
  const float rawMidgrayGeomean = exp((log(rawMidgray.r) + log(rawMidgray.g) + log(rawMidgray.b)) / 3.0);
  return 1.0 / max(rawMidgrayGeomean, 1.0e-10);
}

static float3 spektra_print_log_raw_with_preflash_and_exposure_factor(
  float3 filmDensityCmy,
  constant SpektraKernelParams &params,
  constant SpektraSpectralInfo &info,
  device const float *filmChannelDensity,
  device const float *filmBaseDensity,
  device const float *paperLogSensitivity,
  device const float *thKg3Illuminant,
  device const float *customEnlargerFilters,
  device const float *neutralPrintFilters,
  device const float *academyPrinterDensityData,
  float exposureFactor,
  float3 rawPreflash
) {
  const float3 raw = spektra_print_raw_from_film_density(
    filmDensityCmy,
    params,
    info,
    filmChannelDensity,
    filmBaseDensity,
    paperLogSensitivity,
    thKg3Illuminant,
    customEnlargerFilters,
    neutralPrintFilters,
    academyPrinterDensityData
  );
  const float3 rawTimed = raw * spektra_apd_printer_timing_exposure_scale(params, info, academyPrinterDensityData) *
    exposureFactor + rawPreflash;
  return log10(max(rawTimed * exp2(params.printExposureEv), float3(0.0)) + float3(1.0e-10));
}

static float3 spektra_print_log_raw_with_cached_response(
  float3 filmDensityCmy,
  constant SpektraKernelParams &params,
  constant SpektraSpectralInfo &info,
  device const float *filmChannelDensity,
  device const float4 *filmSpectralDensity,
  device const float4 *filteredEnlargerResponse,
  device const float *academyPrinterDensityData,
  float exposureFactor,
  float3 rawPreflash
) {
  const float3 raw = spektra_print_raw_from_film_density_cached(
    filmDensityCmy,
    params,
    info,
    filmChannelDensity,
    filmSpectralDensity,
    filteredEnlargerResponse,
    academyPrinterDensityData
  );
  const float3 rawTimed = raw * spektra_apd_printer_timing_exposure_scale(params, info, academyPrinterDensityData) *
    exposureFactor + rawPreflash;
  return log10(max(rawTimed * exp2(params.printExposureEv), float3(0.0)) + float3(1.0e-10));
}

static float3 spektra_print_log_raw_with_exposure_factor(
  float3 filmDensityCmy,
  constant SpektraKernelParams &params,
  constant SpektraSpectralInfo &info,
  device const float *filmChannelDensity,
  device const float *filmBaseDensity,
  device const float *paperLogSensitivity,
  device const float *thKg3Illuminant,
  device const float *customEnlargerFilters,
  device const float *neutralPrintFilters,
  device const float *academyPrinterDensityData,
  float exposureFactor
) {
  const float3 rawPreflash = spektra_print_raw_preflash(
    params,
    info,
    filmBaseDensity,
    paperLogSensitivity,
    thKg3Illuminant,
    customEnlargerFilters,
    neutralPrintFilters,
    academyPrinterDensityData
  );
  return spektra_print_log_raw_with_preflash_and_exposure_factor(
    filmDensityCmy,
    params,
    info,
    filmChannelDensity,
    filmBaseDensity,
    paperLogSensitivity,
    thKg3Illuminant,
    customEnlargerFilters,
    neutralPrintFilters,
    academyPrinterDensityData,
    exposureFactor,
    rawPreflash
  );
}

static float3 spektra_print_log_raw(
  float3 filmDensityCmy,
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  constant SpektraCurveInfo &filmCurveInfo,
  constant SpektraSpectralInfo &info,
  device const float *filmLogExposure,
  device const float *filmDensityCurves,
  device const float *filmLogSensitivity,
  device const float *bandpassHanatos2025,
  device const float *hanatosSpectraLut,
  device const float *mallettBasisIlluminant,
  device const float *inputToReferenceXyz,
  device const float *filmChannelDensity,
  device const float *filmBaseDensity,
  device const float *paperLogSensitivity,
  device const float *thKg3Illuminant,
  device const float *customEnlargerFilters,
  device const float *neutralPrintFilters,
  device const float *academyPrinterDensityData
) {
  const float exposureFactor = spektra_print_midgray_exposure_factor(
    params,
    colorInfo,
    filmCurveInfo,
    info,
    filmLogExposure,
    filmDensityCurves,
    filmLogSensitivity,
    bandpassHanatos2025,
    hanatosSpectraLut,
    mallettBasisIlluminant,
    inputToReferenceXyz,
    filmChannelDensity,
    filmBaseDensity,
    paperLogSensitivity,
    thKg3Illuminant,
    customEnlargerFilters,
    neutralPrintFilters,
    academyPrinterDensityData
  );
  return spektra_print_log_raw_with_exposure_factor(
    filmDensityCmy,
    params,
    info,
    filmChannelDensity,
    filmBaseDensity,
    paperLogSensitivity,
    thKg3Illuminant,
    customEnlargerFilters,
    neutralPrintFilters,
    academyPrinterDensityData,
    exposureFactor
  );
}

static float3 spektra_develop_print_density(
  float3 logRaw,
  constant SpektraKernelParams &params,
  constant SpektraSpectralInfo &info,
  constant SpektraCurveInfo &paperCurveInfo,
  device const float *paperLogExposure,
  device const float *paperDensityCurves
) {
  const uint smoothInterpolation =
    spektra_color_adaptation_enabled(params, kSpektraColorAdaptationCurveSmoothing) ? 1u : 0u;
  const float3 density = float3(
    spektra_interp_density_curve(logRaw.r, 0u, params.printGamma, paperCurveInfo, paperLogExposure, paperDensityCurves, params.densityCurveLookupMode, smoothInterpolation),
    spektra_interp_density_curve(logRaw.g, 1u, params.printGamma, paperCurveInfo, paperLogExposure, paperDensityCurves, params.densityCurveLookupMode, smoothInterpolation),
    spektra_interp_density_curve(logRaw.b, 2u, params.printGamma, paperCurveInfo, paperLogExposure, paperDensityCurves, params.densityCurveLookupMode, smoothInterpolation)
  );
  if (params.printShadowShape == 0.0 && params.printHighlightShape == 0.0) {
    return density;
  }
  const float3 densityMaximum = max(
    float3(
      info.paperDensityCurveMaximum0,
      info.paperDensityCurveMaximum1,
      info.paperDensityCurveMaximum2
    ),
    float3(1.0e-6)
  );
  const float3 normalizedDensity = clamp(density / densityMaximum, float3(0.0), float3(1.0));
  const float3 shadowBasis = normalizedDensity * normalizedDensity * (1.0 - normalizedDensity);
  const float3 highlightBasis = normalizedDensity * (1.0 - normalizedDensity) * (1.0 - normalizedDensity);
  constexpr float kPrintCurveShapeStrength = 0.5;
  const float3 shapedNormalizedDensity = clamp(
    normalizedDensity -
      kPrintCurveShapeStrength * clamp(params.printShadowShape, -1.0, 1.0) * shadowBasis -
      kPrintCurveShapeStrength * clamp(params.printHighlightShape, -1.0, 1.0) * highlightBasis,
    float3(0.0),
    float3(1.0)
  );
  return shapedNormalizedDensity * densityMaximum;
}

static SpektraScanResult spektra_scan_density_to_output_rgb_linear_y(
  float3 densityCmy,
  float retainedSilverDensity,
  bool printStage,
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  constant SpektraSpectralInfo &info,
  device const float *channelDensity,
  device const float *baseDensity,
  device const float *scanIlluminant,
  device const float *standardObserverCmfs,
  device const float *scanToOutputRgb
) {
  float3 xyz = float3(0.0);
  float normalization = 0.0;
  for (uint wavelength = 0u; wavelength < info.filmWavelengthCount; ++wavelength) {
    const uint channelOffset = wavelength * 3u;
    const float densitySpectral =
      densityCmy.r * channelDensity[channelOffset] +
      densityCmy.g * channelDensity[channelOffset + 1u] +
      densityCmy.b * channelDensity[channelOffset + 2u] +
      baseDensity[wavelength] +
      spektra_bleach_bypass_silver_spectral_density(retainedSilverDensity);
    const float lightRaw = spektra_spectral_transmittance(densitySpectral, params) * scanIlluminant[wavelength];
    const float light = isfinite(lightRaw) ? lightRaw : 0.0;
    const float3 cmf = float3(
      standardObserverCmfs[channelOffset],
      standardObserverCmfs[channelOffset + 1u],
      standardObserverCmfs[channelOffset + 2u]
    );
    xyz += light * cmf;
    normalization += scanIlluminant[wavelength] * cmf.y;
  }
  xyz /= max(normalization, 1.0e-10);
  return {spektra_mul_color_matrix(xyz, int(spektra_final_output_color_space(params, colorInfo)), colorInfo, scanToOutputRgb), xyz.y};
}

static SpektraScanResult spektra_scan_density_to_output_rgb_linear_y_cached(
  float3 densityCmy,
  float retainedSilverDensity,
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  constant SpektraSpectralInfo &info,
  device const float4 *spectralDensity,
  device const float *scanCmfProducts,
  float inverseNormalization,
  device const float *scanToOutputRgb
) {
  float3 xyz0 = float3(0.0);
  float3 xyz1 = float3(0.0);
  float3 xyz2 = float3(0.0);
  uint wavelength = 0u;
  for (; wavelength + 2u < info.filmWavelengthCount; wavelength += 3u) {
    const uint offset0 = wavelength * 3u;
    const uint offset1 = offset0 + 3u;
    const uint offset2 = offset0 + 6u;
    const float4 spectral0 = spectralDensity[wavelength];
    const float4 spectral1 = spectralDensity[wavelength + 1u];
    const float4 spectral2 = spectralDensity[wavelength + 2u];
    const float density0 = dot(densityCmy, spectral0.xyz) + spectral0.w + retainedSilverDensity;
    const float density1 = dot(densityCmy, spectral1.xyz) + spectral1.w + retainedSilverDensity;
    const float density2 = dot(densityCmy, spectral2.xyz) + spectral2.w + retainedSilverDensity;
    const float transmittance0 = spektra_spectral_transmittance(density0, params);
    const float transmittance1 = spektra_spectral_transmittance(density1, params);
    const float transmittance2 = spektra_spectral_transmittance(density2, params);
    xyz0 += (isfinite(transmittance0) ? transmittance0 : 0.0) * float3(
      scanCmfProducts[offset0],
      scanCmfProducts[offset0 + 1u],
      scanCmfProducts[offset0 + 2u]
    );
    xyz1 += (isfinite(transmittance1) ? transmittance1 : 0.0) * float3(
      scanCmfProducts[offset1],
      scanCmfProducts[offset1 + 1u],
      scanCmfProducts[offset1 + 2u]
    );
    xyz2 += (isfinite(transmittance2) ? transmittance2 : 0.0) * float3(
      scanCmfProducts[offset2],
      scanCmfProducts[offset2 + 1u],
      scanCmfProducts[offset2 + 2u]
    );
  }
  float3 xyz = xyz0 + xyz1 + xyz2;
  for (; wavelength < info.filmWavelengthCount; ++wavelength) {
    const uint offset = wavelength * 3u;
    const float4 spectral = spectralDensity[wavelength];
    const float density = dot(densityCmy, spectral.xyz) + spectral.w + retainedSilverDensity;
    const float transmittance = spektra_spectral_transmittance(density, params);
    xyz += (isfinite(transmittance) ? transmittance : 0.0) * float3(
      scanCmfProducts[offset],
      scanCmfProducts[offset + 1u],
      scanCmfProducts[offset + 2u]
    );
  }
  xyz *= inverseNormalization;
  return {spektra_mul_color_matrix(xyz, int(spektra_final_output_color_space(params, colorInfo)), colorInfo, scanToOutputRgb), xyz.y};
}

static SpektraScanResult spektra_scan_density_to_output_rgb_linear_y_cached_common(
  float3 densityCmy,
  bool printStage,
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  constant SpektraSpectralInfo &info,
  device const float4 *spectralDensity,
  device const float4 *packedScanCmfProducts,
  device const float *legacyScanCmfProducts,
  float inverseNormalization,
  device const float *scanToOutputRgb
) {
  const float bleachBypassAmount = printStage
    ? params.printBleachBypassAmount
    : params.negativeBleachBypassAmount;
  if (bleachBypassAmount == 0.0 &&
      params.spectralTransmittanceMode == 0u &&
      info.filmWavelengthCount == 81u) {
    float3 xyz0 = float3(0.0);
    float3 xyz1 = float3(0.0);
    float3 xyz2 = float3(0.0);
    for (uint wavelength = 0u; wavelength < 81u; wavelength += 3u) {
      const float4 spectral0 = spectralDensity[wavelength];
      const float4 spectral1 = spectralDensity[wavelength + 1u];
      const float4 spectral2 = spectralDensity[wavelength + 2u];
      xyz0 += spektra_spectral_transmittance_pow(dot(densityCmy, spectral0.xyz)) *
        packedScanCmfProducts[wavelength].xyz;
      xyz1 += spektra_spectral_transmittance_pow(dot(densityCmy, spectral1.xyz)) *
        packedScanCmfProducts[wavelength + 1u].xyz;
      xyz2 += spektra_spectral_transmittance_pow(dot(densityCmy, spectral2.xyz)) *
        packedScanCmfProducts[wavelength + 2u].xyz;
    }
    const float3 xyz = (xyz0 + xyz1 + xyz2) * inverseNormalization;
    return {spektra_mul_color_matrix(xyz, int(spektra_final_output_color_space(params, colorInfo)), colorInfo, scanToOutputRgb), xyz.y};
  }
  const float3 bypassedDensityCmy = printStage
    ? spektra_bleach_bypass_dye_density(densityCmy, bleachBypassAmount, true, info)
    : spektra_negative_bleach_bypass_dye_density(densityCmy, bleachBypassAmount, params, info);
  return spektra_scan_density_to_output_rgb_linear_y_cached(
    bypassedDensityCmy,
    spektra_bleach_bypass_retained_silver_density(densityCmy, bleachBypassAmount, printStage, info),
    params,
    colorInfo,
    info,
    spectralDensity,
    legacyScanCmfProducts,
    inverseNormalization,
    scanToOutputRgb
  );
}

static float3 spektra_scan_density_to_output_rgb_linear(
  float3 densityCmy,
  float retainedSilverDensity,
  bool printStage,
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  constant SpektraSpectralInfo &info,
  device const float *channelDensity,
  device const float *baseDensity,
  device const float *scanIlluminant,
  device const float *standardObserverCmfs,
  device const float *scanToOutputRgb
) {
  return spektra_scan_density_to_output_rgb_linear_y(
    densityCmy,
    retainedSilverDensity,
    printStage,
    params,
    colorInfo,
    info,
    channelDensity,
    baseDensity,
    scanIlluminant,
    standardObserverCmfs,
    scanToOutputRgb
  ).rgb;
}

static float3 spektra_scan_illuminant_to_output_rgb(
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  constant SpektraSpectralInfo &info,
  device const float *scanIlluminant,
  device const float *standardObserverCmfs,
  device const float *scanToOutputRgb
) {
  float3 xyz = float3(0.0);
  float normalization = 0.0;
  for (uint wavelength = 0u; wavelength < info.filmWavelengthCount; ++wavelength) {
    const uint channelOffset = wavelength * 3u;
    const float3 cmf = float3(
      standardObserverCmfs[channelOffset],
      standardObserverCmfs[channelOffset + 1u],
      standardObserverCmfs[channelOffset + 2u]
    );
    xyz += scanIlluminant[wavelength] * cmf;
    normalization += scanIlluminant[wavelength] * cmf.y;
  }
  xyz /= max(normalization, 1.0e-10);
  return spektra_mul_color_matrix(xyz, int(spektra_final_output_color_space(params, colorInfo)), colorInfo, scanToOutputRgb);
}

static float3 spektra_scan_density_to_output_rgb(
  float3 densityCmy,
  float retainedSilverDensity,
  bool printStage,
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  constant SpektraSpectralInfo &info,
  device const float *channelDensity,
  device const float *baseDensity,
  device const float *scanIlluminant,
  device const float *standardObserverCmfs,
  device const float *scanToOutputRgb,
  device const float *encodeLuts,
  device const uint *transferKinds
) {
  const float3 rgb = spektra_scan_density_to_output_rgb_linear(
    densityCmy,
    retainedSilverDensity,
    printStage,
    params,
    colorInfo,
    info,
    channelDensity,
    baseDensity,
    scanIlluminant,
    standardObserverCmfs,
    scanToOutputRgb
  );
  return spektra_finalize_output_rgb(rgb, params, colorInfo, encodeLuts, transferKinds);
}

static float3 spektra_density_curve_max_cmy(
  constant SpektraCurveInfo &curveInfo,
  device const float *densityCurves
) {
  return float3(
    spektra_density_curve_max(0u, curveInfo, densityCurves),
    spektra_density_curve_max(1u, curveInfo, densityCurves),
    spektra_density_curve_max(2u, curveInfo, densityCurves)
  );
}

static float spektra_scanner_target_level(bool correctionEnabled, float level, float referenceY) {
  return correctionEnabled ? spektra_decode_srgb_scalar(level) : referenceY;
}

static float3 spektra_apply_scanner_black_white_correction(
  float3 rgb,
  float sourceY,
  float referenceBlackY,
  float referenceWhiteY,
  constant SpektraKernelParams &params
) {
  if (params.scannerEnabled == 0u || (params.scannerBlackCorrection == 0u && params.scannerWhiteCorrection == 0u)) {
    return rgb;
  }
  const float blackLevel = spektra_scanner_target_level(params.scannerBlackCorrection != 0u, params.scannerBlackLevel, referenceBlackY);
  const float whiteLevel = spektra_scanner_target_level(params.scannerWhiteCorrection != 0u, params.scannerWhiteLevel, referenceWhiteY);
  const float m = (whiteLevel - blackLevel) / max(referenceWhiteY - referenceBlackY, 1.0e-10);
  const float q = blackLevel - m * referenceBlackY;
  const float correctedY = clamp(m * sourceY + q, 0.0, 1.0);
  return rgb * (correctedY / max(sourceY, 1.0e-10));
}

static float3 spektra_apply_print_scan_output_contract(
  SpektraScanResult scan,
  constant SpektraFrameConstants &frameConstants,
  constant SpektraKernelParams &params
) {
  if (spektra_rcm_enabled(params)) {
    return scan.rgb;
  }
  return spektra_apply_scanner_black_white_correction(
    scan.rgb,
    scan.y,
    frameConstants.print.y,
    frameConstants.print.z,
    params
  );
}

static float4 spektra_normalize_film_scan_rgb_y(
  SpektraScanResult scan,
  SpektraScanResult filmDmaxScan,
  SpektraScanResult filmDminScan,
  bool positiveFilm
) {
  const float3 rawScanRange = filmDminScan.rgb - filmDmaxScan.rgb;
  const float3 scanRangeSign = select(float3(-1.0), float3(1.0), rawScanRange >= float3(0.0));
  const float3 scanRange = scanRangeSign * max(abs(rawScanRange), float3(1.0e-6));
  const float yRange = max(filmDminScan.y - filmDmaxScan.y, 1.0e-10);
  const float3 normalizedRgb = positiveFilm
    ? (scan.rgb - filmDmaxScan.rgb) / scanRange
    : (filmDminScan.rgb - scan.rgb) / scanRange;
  const float normalizedY = positiveFilm
    ? (scan.y - filmDmaxScan.y) / yRange
    : (filmDminScan.y - scan.y) / yRange;
  return float4(normalizedRgb, normalizedY);
}

static float3 spektra_apply_film_scan_output_contract(
  SpektraScanResult scan,
  constant SpektraFrameConstants &frameConstants,
  constant SpektraKernelParams &params,
  constant SpektraSpectralInfo &info
) {
  if (params.scanNegativeInvert == 0u) {
    return scan.rgb;
  }
  const SpektraScanResult filmDmaxScan = {frameConstants.filmDmaxScan.rgb, frameConstants.filmDmaxScan.a};
  const SpektraScanResult filmDminScan = {frameConstants.filmDminScan.rgb, frameConstants.filmDminScan.a};
  const float4 normalized = spektra_normalize_film_scan_rgb_y(
    scan,
    filmDmaxScan,
    filmDminScan,
    info.filmPositive != 0u
  );
  if (spektra_rcm_enabled(params)) {
    return normalized.rgb;
  }
  return spektra_apply_scanner_black_white_correction(
    normalized.rgb,
    normalized.a,
    0.0,
    1.0,
    params
  );
}

static float spektra_scan_density_to_y(
  float3 densityCmy,
  float retainedSilverDensity,
  bool printStage,
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  constant SpektraSpectralInfo &info,
  device const float *channelDensity,
  device const float *baseDensity,
  device const float *scanIlluminant,
  device const float *standardObserverCmfs,
  device const float *scanToOutputRgb
) {
  return spektra_scan_density_to_output_rgb_linear_y(
    densityCmy,
    retainedSilverDensity,
    printStage,
    params,
    colorInfo,
    info,
    channelDensity,
    baseDensity,
    scanIlluminant,
    standardObserverCmfs,
    scanToOutputRgb
  ).y;
}

static float spektra_print_reference_y(
  bool blackReference,
  constant SpektraKernelParams &params,
  constant SpektraColorInfo &colorInfo,
  constant SpektraCurveInfo &filmCurveInfo,
  constant SpektraSpectralInfo &info,
  device const float *filmLogExposure,
  device const float *filmDensityCurves,
  constant SpektraCurveInfo &paperCurveInfo,
  device const float *paperLogExposure,
  device const float *paperDensityCurves,
  device const float *filmLogSensitivity,
  device const float *bandpassHanatos2025,
  device const float *hanatosSpectraLut,
  device const float *mallettBasisIlluminant,
  device const float *inputToReferenceXyz,
  device const float *filmChannelDensity,
  device const float *filmBaseDensity,
  device const float *paperLogSensitivity,
  device const float *thKg3Illuminant,
  device const float *customEnlargerFilters,
  device const float *neutralPrintFilters,
  device const float *academyPrinterDensityData,
  device const float *paperChannelDensity,
  device const float *paperBaseDensity,
  device const float *paperScanIlluminant,
  device const float *standardObserverCmfs,
  device const float *paperScanToOutputRgb
) {
  const float3 filmBlack = -float3(params.grainDensityMinR, params.grainDensityMinG, params.grainDensityMinB);
  const float3 filmWhite = spektra_density_curve_max_cmy(filmCurveInfo, filmDensityCurves);
  const float3 filmDensity = blackReference ? filmBlack : filmWhite;
  const float3 printLogRaw = spektra_print_log_raw(
    filmDensity,
    params,
    colorInfo,
    filmCurveInfo,
    info,
    filmLogExposure,
    filmDensityCurves,
    filmLogSensitivity,
    bandpassHanatos2025,
    hanatosSpectraLut,
    mallettBasisIlluminant,
    inputToReferenceXyz,
    filmChannelDensity,
    filmBaseDensity,
    paperLogSensitivity,
    thKg3Illuminant,
    customEnlargerFilters,
    neutralPrintFilters,
    academyPrinterDensityData
  );
  const float3 printDensity = spektra_develop_print_density(
    printLogRaw,
    params,
    info,
    paperCurveInfo,
    paperLogExposure,
    paperDensityCurves
  );
  return spektra_scan_density_to_y(
    printDensity,
    0.0,
    true,
    params,
    colorInfo,
    info,
    paperChannelDensity,
    paperBaseDensity,
    paperScanIlluminant,
    standardObserverCmfs,
    paperScanToOutputRgb
  );
}

kernel void spektrafilm_filtered_enlarger_response(
  device float4 *responseOut [[buffer(0)]],
  constant SpektraKernelParams &params [[buffer(1)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(2)]],
  device const float *paperLogSensitivity [[buffer(3)]],
  device const float *thKg3Illuminant [[buffer(4)]],
  device const float *customEnlargerFilters [[buffer(5)]],
  device const float *neutralPrintFilters [[buffer(6)]],
  device const float4 *filmSpectralDensity [[buffer(7)]],
  uint tid [[thread_position_in_grid]]
) {
  if (tid >= spectralInfo.filmWavelengthCount) {
    return;
  }
  const float illuminant = spektra_filtered_enlarger_illuminant(
    tid,
    params,
    spectralInfo,
    thKg3Illuminant,
    customEnlargerFilters,
    neutralPrintFilters
  );
  const float baseTransmittanceRaw = spektra_spectral_transmittance(filmSpectralDensity[tid].w, params);
  const float baseTransmittance = isfinite(baseTransmittanceRaw) ? baseTransmittanceRaw : 0.0;
  const float3 response = illuminant * spektra_sensitivity(tid, paperLogSensitivity);
  responseOut[tid] = float4(baseTransmittance * response, 0.0);
  responseOut[spectralInfo.filmWavelengthCount + tid] = float4(response, 0.0);
}

kernel void spektrafilm_frame_constants(
  device SpektraFrameConstants *constantsOut [[buffer(0)]],
  constant SpektraKernelParams &params [[buffer(1)]],
  constant SpektraCurveInfo &filmCurveInfo [[buffer(2)]],
  device const float *filmLogExposure [[buffer(3)]],
  device const float *filmDensityCurves [[buffer(4)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(5)]],
  constant SpektraColorInfo &colorInfo [[buffer(6)]],
  constant SpektraCurveInfo &paperCurveInfo [[buffer(7)]],
  device const float *paperLogExposure [[buffer(8)]],
  device const float *paperDensityCurves [[buffer(9)]],
  device const float *filmLogSensitivity [[buffer(10)]],
  device const float *bandpassHanatos2025 [[buffer(11)]],
  device const float *hanatosSpectraLut [[buffer(12)]],
  device const float *mallettBasisIlluminant [[buffer(13)]],
  device const float *inputToReferenceXyz [[buffer(14)]],
  device const float *filmChannelDensity [[buffer(15)]],
  device const float *filmBaseDensity [[buffer(16)]],
  device const float *paperLogSensitivity [[buffer(17)]],
  device const float *thKg3Illuminant [[buffer(18)]],
  device const float *customEnlargerFilters [[buffer(19)]],
  device const float *neutralPrintFilters [[buffer(20)]],
  device const float *academyPrinterDensityData [[buffer(21)]],
  device const float *paperScanDensityData [[buffer(22)]],
  device const float *scanIlluminantsAndCmfs [[buffer(23)]],
  device const float *scanToOutputRgbData [[buffer(24)]],
  uint tid [[thread_position_in_grid]]
) {
  if (tid > 0u) {
    return;
  }
  device const float *paperChannelDensity = paperScanDensityData;
  device const float *paperBaseDensity = paperScanDensityData + spectralInfo.filmWavelengthCount * 3u;
  device const float *filmScanIlluminant = scanIlluminantsAndCmfs;
  device const float *paperScanIlluminant = scanIlluminantsAndCmfs + spectralInfo.filmWavelengthCount;
  device const float *standardObserverCmfs = scanIlluminantsAndCmfs + spectralInfo.filmWavelengthCount * 2u;
  device const float *filmScanToOutputRgb = scanToOutputRgbData;
  device const float *paperScanToOutputRgb = scanToOutputRgbData + colorInfo.colorSpaceCount * 9u;

  const float printExposureFactor = spektra_print_midgray_exposure_factor(
    params,
    colorInfo,
    filmCurveInfo,
    spectralInfo,
    filmLogExposure,
    filmDensityCurves,
    filmLogSensitivity,
    bandpassHanatos2025,
    hanatosSpectraLut,
    mallettBasisIlluminant,
    inputToReferenceXyz,
    filmChannelDensity,
    filmBaseDensity,
    paperLogSensitivity,
    thKg3Illuminant,
    customEnlargerFilters,
    neutralPrintFilters,
    academyPrinterDensityData
  );
  const float3 printRawPreflash = spektra_print_raw_preflash(
    params,
    spectralInfo,
    filmBaseDensity,
    paperLogSensitivity,
    thKg3Illuminant,
    customEnlargerFilters,
    neutralPrintFilters,
    academyPrinterDensityData
  );
  const float printReferenceBlackY = spektra_print_reference_y(
    true,
    params,
    colorInfo,
    filmCurveInfo,
    spectralInfo,
    filmLogExposure,
    filmDensityCurves,
    paperCurveInfo,
    paperLogExposure,
    paperDensityCurves,
    filmLogSensitivity,
    bandpassHanatos2025,
    hanatosSpectraLut,
    mallettBasisIlluminant,
    inputToReferenceXyz,
    filmChannelDensity,
    filmBaseDensity,
    paperLogSensitivity,
    thKg3Illuminant,
    customEnlargerFilters,
    neutralPrintFilters,
    academyPrinterDensityData,
    paperChannelDensity,
    paperBaseDensity,
    paperScanIlluminant,
    standardObserverCmfs,
    paperScanToOutputRgb
  );
  const float printReferenceWhiteY = spektra_print_reference_y(
    false,
    params,
    colorInfo,
    filmCurveInfo,
    spectralInfo,
    filmLogExposure,
    filmDensityCurves,
    paperCurveInfo,
    paperLogExposure,
    paperDensityCurves,
    filmLogSensitivity,
    bandpassHanatos2025,
    hanatosSpectraLut,
    mallettBasisIlluminant,
    inputToReferenceXyz,
    filmChannelDensity,
    filmBaseDensity,
    paperLogSensitivity,
    thKg3Illuminant,
    customEnlargerFilters,
    neutralPrintFilters,
    academyPrinterDensityData,
    paperChannelDensity,
    paperBaseDensity,
    paperScanIlluminant,
    standardObserverCmfs,
    paperScanToOutputRgb
  );
  const float3 filmBlack = spektra_density_curve_max_cmy(filmCurveInfo, filmDensityCurves);
  const float3 filmWhite = float3(0.0);
  SpektraScanResult filmDmaxScan = {float3(0.0), 0.0};
  SpektraScanResult filmDminScan = {float3(0.0), 0.0};
  if (params.scanNegativeInvert != 0u) {
    filmDmaxScan = spektra_scan_density_to_output_rgb_linear_y(
      filmBlack,
      0.0,
      false,
      params,
      colorInfo,
      spectralInfo,
      filmChannelDensity,
      filmBaseDensity,
      filmScanIlluminant,
      standardObserverCmfs,
      filmScanToOutputRgb
    );
    filmDminScan = spektra_scan_density_to_output_rgb_linear_y(
      filmWhite,
      0.0,
      false,
      params,
      colorInfo,
      spectralInfo,
      filmChannelDensity,
      filmBaseDensity,
      filmScanIlluminant,
      standardObserverCmfs,
      filmScanToOutputRgb
    );
  }
  const float3 printGlareRgb = spektra_scan_illuminant_to_output_rgb(
    params,
    colorInfo,
    spectralInfo,
    paperScanIlluminant,
    standardObserverCmfs,
    paperScanToOutputRgb
  );
  constantsOut[0].print = float4(printExposureFactor, printReferenceBlackY, printReferenceWhiteY, 0.0);
  constantsOut[0].film = float4(filmDmaxScan.y, filmDminScan.y, 0.0, 0.0);
  constantsOut[0].glare = float4(printGlareRgb, 0.0);
  constantsOut[0].preflash = float4(printRawPreflash, 0.0);
  constantsOut[0].filmDmaxScan = float4(filmDmaxScan.rgb, filmDmaxScan.y);
  constantsOut[0].filmDminScan = float4(filmDminScan.rgb, filmDminScan.y);
}

static float spektra_layer_density_max_total(
  uint channel,
  device const float *densityCurveLayerMaxima
) {
  float total = 0.0;
  for (uint layer = 0u; layer < 3u; ++layer) {
    total += max(densityCurveLayerMaxima[layer * 3u + channel], 0.0);
  }
  return max(total, 1.0e-6);
}

static float spektra_production_layer_particle_density(
  float3 filmDensityCmy,
  uint layer,
  uint channel,
  constant SpektraKernelParams &params,
  constant SpektraCurveInfo &curveInfo,
  constant SpektraSpectralInfo &info,
  device const float *densityCurves,
  device const float *densityCurveLayers,
  device const float *densityCurveLayerMaxima,
  float2 filmUm,
  uint baseSeed
) {
  const float pixelArea = max(params.filmPixelSizeUm * params.filmPixelSizeUm, 1.0e-6);
  const float densityMin = spektra_channel_density_min(channel, params);
  const float uniformity = spektra_channel_uniformity(channel, params);

  if (params.grainSublayersEnabled == 0u) {
    if (layer != 0u) {
      return 0.0;
    }
    const uint subLayerCount = uint(clamp(params.grainSubLayerCount, 1, 8));
    const float densityMax = spektra_density_curve_max(channel, curveInfo, densityCurves) + densityMin;
    const float particleArea = max(params.grainParticleAreaUm2 * spektra_channel_particle_scale(channel, params), 1.0e-4);
    const float particles = max(pixelArea / particleArea / max(float(subLayerCount), 1.0), 1.0e-3);
    const float sourceDensity = max(spektra_channel_component(filmDensityCmy, channel) + densityMin, 0.0);
    float accumulated = 0.0;
    for (uint subLayer = 0u; subLayer < subLayerCount; ++subLayer) {
      const uint particleSeed = spektra_film_cell_seed(
        filmUm,
        sqrt(particleArea),
        baseSeed ^ (channel * 0x85ebca6bu) ^ (subLayer * 0x9e3779b9u)
      );
      accumulated += spektra_particle_developed_density(
        sourceDensity,
        densityMax,
        particles,
        uniformity,
        1.0,
        particleSeed
      );
    }
    return max(accumulated / max(float(subLayerCount), 1.0) - densityMin, 0.0);
  }

  const float densityMaxTotal = spektra_layer_density_max_total(channel, densityCurveLayerMaxima);
  const float layerMax = max(densityCurveLayerMaxima[layer * 3u + channel], 0.0);
  const float layerFraction = layerMax / densityMaxTotal;
  const float layerDensityMin = layerFraction * densityMin;
  const float layerDensityMax = max(layerMax + layerDensityMin, 1.0e-6);
  const float layerDensity = spektra_interp_density_layer(
    spektra_channel_component(filmDensityCmy, channel),
    channel,
    layer,
    curveInfo,
    info,
    densityCurves,
    densityCurveLayers
  ) + layerDensityMin;
  const float particleArea = max(
    params.grainParticleAreaUm2 *
      spektra_channel_particle_scale(channel, params) *
      spektra_layer_particle_scale(layer, params),
    1.0e-4
  );
  const float particles = max(pixelArea * layerFraction / particleArea, 1.0e-3);
  const uint particleSeed = spektra_film_cell_seed(
    filmUm,
    sqrt(particleArea),
    baseSeed ^ (channel * 0x85ebca6bu) ^ (layer * 0xc2b2ae35u)
  );
  return spektra_particle_developed_density(
    max(layerDensity, 0.0),
    layerDensityMax,
    particles,
    uniformity,
    1.0,
    particleSeed
  );
}

static float spektra_grain_layer_blur_sigma(
  uint layer,
  uint channel,
  constant SpektraKernelParams &params,
  device const float *densityCurveLayerMaxima
) {
  if (params.grainSublayersEnabled == 0u || params.grainBlurDyeCloudsUm <= 0.0) {
    return 0.0;
  }
  const float densityMin = spektra_channel_density_min(channel, params);
  const float densityMaxTotal = spektra_layer_density_max_total(channel, densityCurveLayerMaxima);
  const float layerMax = max(densityCurveLayerMaxima[layer * 3u + channel], 0.0);
  const float layerFraction = layerMax / densityMaxTotal;
  const float layerDensityMax = max(layerMax + layerFraction * densityMin, 1.0e-6);
  const float particleArea = max(
    params.grainParticleAreaUm2 *
      spektra_channel_particle_scale(channel, params) *
      spektra_layer_particle_scale(layer, params),
    1.0e-4
  );
  const float pixelArea = max(params.filmPixelSizeUm * params.filmPixelSizeUm, 1.0e-6);
  const float particles = max(pixelArea * layerFraction / particleArea, 1.0e-3);
  const float odParticle = layerDensityMax / particles;
  // Match the Python layer-particle model: particle count already carries the
  // film-pixel-size dependence, so dividing by filmPixelSizeUm again would
  // double-convert the dye-cloud blur and make the control effectively vanish.
  return max(params.grainBlurDyeCloudsUm, 0.0) * sqrt(max(odParticle, 0.0));
}

static float spektra_gaussian_weight(float offset, float sigma) {
  return exp(-0.5 * (offset * offset) / max(sigma * sigma, 1.0e-8));
}

static float spektra_layer_buffer_sample(
  device const float *buffer,
  uint width,
  uint height,
  int x,
  int y,
  uint component
) {
  const uint sx = spektra_safe_index(x, width);
  const uint sy = spektra_safe_index(y, height);
  return buffer[(sy * width + sx) * 9u + component];
}

static float4 spektra_float4_buffer_sample(
  device const float4 *buffer,
  uint width,
  uint height,
  int x,
  int y
) {
  const uint sx = spektra_safe_index(x, width);
  const uint sy = spektra_safe_index(y, height);
  return buffer[sy * width + sx];
}

static float4 spektra_source_sample_black_outside(
  device const float4 *source,
  constant SpektraKernelParams &params,
  constant uint2 &dims,
  uint2 gid
) {
  const float scale = max(params.enlargerScale, 1.0);
  const float2 safeDims = float2(max(dims.x, 1u), max(dims.y, 1u));
  const float2 outputUv = (float2(gid) + 0.5) / safeDims;
  const float2 sourceUv = float2(0.5) +
    (outputUv - float2(0.5)) / scale +
    float2(params.enlargerOffsetXPercent, params.enlargerOffsetYPercent) * (0.01 / scale);

  if (sourceUv.x < 0.0 || sourceUv.x > 1.0 || sourceUv.y < 0.0 || sourceUv.y > 1.0) {
    return float4(0.0, 0.0, 0.0, 1.0);
  }

  const float2 sourcePx = sourceUv * safeDims - 0.5;
  const int x0 = int(floor(sourcePx.x));
  const int y0 = int(floor(sourcePx.y));
  const int x1 = x0 + 1;
  const int y1 = y0 + 1;
  const float tx = fract(sourcePx.x);
  const float ty = fract(sourcePx.y);
  const float4 p00 = spektra_float4_buffer_sample(source, dims.x, dims.y, x0, y0);
  const float4 p10 = spektra_float4_buffer_sample(source, dims.x, dims.y, x1, y0);
  const float4 p01 = spektra_float4_buffer_sample(source, dims.x, dims.y, x0, y1);
  const float4 p11 = spektra_float4_buffer_sample(source, dims.x, dims.y, x1, y1);
  return mix(mix(p00, p10, tx), mix(p01, p11, tx), ty);
}

kernel void spektrafilm_enlarger_resample(
  device const float4 *source [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  destination[gid.y * dims.x + gid.x] = spektra_source_sample_black_outside(source, params, dims, gid);
}

static float spektra_normal_quantile(float p) {
  p = clamp(p, 1.0e-6, 1.0 - 1.0e-6);
  constexpr float a1 = -3.969683028665376e+01;
  constexpr float a2 = 2.209460984245205e+02;
  constexpr float a3 = -2.759285104469687e+02;
  constexpr float a4 = 1.383577518672690e+02;
  constexpr float a5 = -3.066479806614716e+01;
  constexpr float a6 = 2.506628277459239e+00;
  constexpr float b1 = -5.447609879822406e+01;
  constexpr float b2 = 1.615858368580409e+02;
  constexpr float b3 = -1.556989798598866e+02;
  constexpr float b4 = 6.680131188771972e+01;
  constexpr float b5 = -1.328068155288572e+01;
  constexpr float c1 = -7.784894002430293e-03;
  constexpr float c2 = -3.223964580411365e-01;
  constexpr float c3 = -2.400758277161838e+00;
  constexpr float c4 = -2.549732539343734e+00;
  constexpr float c5 = 4.374664141464968e+00;
  constexpr float c6 = 2.938163982698783e+00;
  constexpr float d1 = 7.784695709041462e-03;
  constexpr float d2 = 3.224671290700398e-01;
  constexpr float d3 = 2.445134137142996e+00;
  constexpr float d4 = 3.754408661907416e+00;
  constexpr float pLow = 0.02425;
  constexpr float pHigh = 1.0 - pLow;
  if (p < pLow) {
    const float q = sqrt(-2.0 * log(p));
    return (((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
      ((((d1 * q + d2) * q + d3) * q + d4) * q + 1.0);
  }
  if (p > pHigh) {
    const float q = sqrt(-2.0 * log(1.0 - p));
    return -(((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
      ((((d1 * q + d2) * q + d3) * q + d4) * q + 1.0);
  }
  const float q = p - 0.5;
  const float r = q * q;
  return (((((a1 * r + a2) * r + a3) * r + a4) * r + a5) * r + a6) * q /
    (((((b1 * r + b2) * r + b3) * r + b4) * r + b5) * r + 1.0);
}

static float spektra_grain_synthesis_channel_scale(uint channel, constant SpektraKernelParams &params) {
  return max(channel == 0u ? params.grainSynthesisRadiusScaleR : (channel == 1u ? params.grainSynthesisRadiusScaleG : params.grainSynthesisRadiusScaleB), 1.0e-6);
}

static float spektra_grain_synthesis_layer_scale(uint layer, constant SpektraKernelParams &params) {
  if (params.grainSynthesisLayered == 0u) {
    return 1.0;
  }
  return max(layer == 0u ? params.grainSynthesisLayerScale0 : (layer == 1u ? params.grainSynthesisLayerScale1 : params.grainSynthesisLayerScale2), 1.0e-6);
}

struct SpektraGrainSynthesisEval {
  float scaledMeanRadius;
  float maxRadius;
  float maxRadiusSquared;
  float cellSize;
  float meanArea;
  float cellArea;
  float densityToLambda;
  uint grainCap;
};

static uint spektra_mix_seed(uint seed, uint value) {
  return spektra_hash(seed ^ (value + 0x9e3779b9u + (seed << 6u) + (seed >> 2u)));
}

static uint spektra_cell_seed(int2 cell, uint channel, uint layer, constant SpektraKernelParams &params) {
  uint seed = spektra_mix_seed(params.grainSeed, uint(cell.x));
  seed = spektra_mix_seed(seed, uint(cell.y));
  seed = spektra_mix_seed(seed, channel * 0x85ebca6bu);
  seed = spektra_mix_seed(seed, layer * 0xc2b2ae35u);
  const uint frameSeed = params.grainAnimate != 0u ? uint(floor(params.time * 24.0 + 0.5)) : 0u;
  return spektra_mix_seed(seed, frameSeed);
}

static uint spektra_poisson_sample(float lambda, uint seed, uint cap) {
  if (lambda <= 0.0 || cap == 0u) {
    return 0u;
  }
  if (lambda < 1.0e-5) {
    return spektra_rand01(seed ^ 0x4cf5ad43u) < lambda ? 1u : 0u;
  }
  if (lambda < 8.0) {
    const float threshold = exp(-lambda);
    float product = 1.0;
    uint k = 0u;
    while (k < cap) {
      product *= spektra_rand01(seed ^ (k * 0x27d4eb2du));
      if (product <= threshold) {
        break;
      }
      ++k;
    }
    return min(k, cap);
  }
  const float sample = floor(lambda + sqrt(lambda) * spektra_gaussian(seed ^ 0x165667b1u) + 0.5);
  return uint(clamp(sample, 0.0, float(cap)));
}

static uint spektra_poisson_sample_cdf(float lambda, uint seed, uint cap) {
  if (lambda <= 0.0 || cap == 0u) {
    return 0u;
  }
  const float u = spektra_rand01(seed ^ 0x4cf5ad43u);
  if (lambda < 1.0e-5) {
    return u < lambda ? 1u : 0u;
  }
  if (lambda < 16.0) {
    float probability = fast::exp(-lambda);
    float cdf = probability;
    uint k = 0u;
    while (u > cdf && k < cap) {
      ++k;
      probability *= lambda / float(k);
      cdf += probability;
    }
    return min(k, cap);
  }
  const float sample = floor(lambda + sqrt(lambda) * spektra_gaussian(seed ^ 0x165667b1u) + 0.5);
  return uint(clamp(sample, 0.0, float(cap)));
}

static float spektra_grain_synthesis_radius(
  float meanRadius,
  float maxRadius,
  constant SpektraKernelParams &params,
  uint seed
) {
  const float ratio = max(params.grainSynthesisRadiusStdDevRatio, 0.0);
  if (ratio <= 1.0e-6) {
    return meanRadius;
  }
  const float logSigma = sqrt(log(1.0 + ratio * ratio));
  const float logMean = log(max(meanRadius, 1.0e-6)) - 0.5 * logSigma * logSigma;
  return min(exp(logMean + logSigma * spektra_gaussian(seed)), maxRadius);
}

static float spektra_grain_synthesis_max_radius(float meanRadius, constant SpektraKernelParams &params) {
  const float ratio = max(params.grainSynthesisRadiusStdDevRatio, 0.0);
  if (ratio <= 1.0e-6) {
    return meanRadius;
  }
  const float logSigma = sqrt(log(1.0 + ratio * ratio));
  const float logMean = log(max(meanRadius, 1.0e-6)) - 0.5 * logSigma * logSigma;
  return exp(logMean + logSigma * spektra_normal_quantile(params.grainSynthesisMaxRadiusQuantile));
}

static SpektraGrainSynthesisEval spektra_grain_synthesis_make_eval(
  uint layer,
  uint channel,
  constant SpektraKernelParams &params,
  bool fixedRadius
) {
  SpektraGrainSynthesisEval eval;
  eval.scaledMeanRadius = max(
    params.grainSynthesisMeanRadiusUm *
      spektra_grain_synthesis_channel_scale(channel, params) *
      spektra_grain_synthesis_layer_scale(layer, params),
    1.0e-6
  );
  const float ratio = fixedRadius ? 0.0 : max(params.grainSynthesisRadiusStdDevRatio, 0.0);
  eval.maxRadius = fixedRadius
    ? eval.scaledMeanRadius
    : max(spektra_grain_synthesis_max_radius(eval.scaledMeanRadius, params), eval.scaledMeanRadius);
  eval.maxRadiusSquared = eval.maxRadius * eval.maxRadius;
  eval.cellSize = max(params.grainSynthesisMeanRadiusUm * max(params.grainSynthesisCellSizeRatio, 0.05), 1.0e-4);
  eval.meanArea = 3.14159265359 * eval.scaledMeanRadius * eval.scaledMeanRadius * (1.0 + ratio * ratio);
  eval.cellArea = eval.cellSize * eval.cellSize;
  eval.densityToLambda = 2.302585093 / max(eval.meanArea, 1.0e-12);
  eval.grainCap = uint(clamp(params.grainSynthesisMaxGrainsPerCell, 1, 128));
  return eval;
}

static float spektra_grain_synthesis_cell_distance_squared(
  float2 pointUm,
  float2 cellOrigin,
  float cellSize
) {
  const float2 cellMax = cellOrigin + cellSize;
  const float2 closest = clamp(pointUm, cellOrigin, cellMax);
  const half2 delta = half2(pointUm - closest);
  return float(dot(delta, delta));
}

static uint spektra_grain_synthesis_adaptive_sample_count(float targetDensity, uint requestedSamples) {
  if (requestedSamples <= 4u) {
    return requestedSamples;
  }
  const float coverage = clamp(1.0 - exp(-max(targetDensity, 0.0) * 2.302585093), 0.0, 1.0);
  const float varianceWeight = sqrt(clamp((coverage * (1.0 - coverage)) * 4.0, 0.0, 1.0));
  const float sampleScale = mix(0.25, 1.0, varianceWeight);
  const uint minimumSamples = min(requestedSamples, max(4u, requestedSamples / 16u));
  const uint adaptiveSamples = uint(ceil(float(requestedSamples) * sampleScale));
  return min(max(adaptiveSamples, minimumSamples), requestedSamples);
}

static float spektra_grain_synthesis_density_at_um(
  device const float4 *densityIn,
  float2 filmUm,
  uint layer,
  uint channel,
  constant SpektraKernelParams &params,
  constant uint2 &dims,
  constant SpektraCurveInfo &curveInfo,
  constant SpektraSpectralInfo &info,
  device const float *densityCurves,
  device const float *densityCurveLayers
) {
  const int2 pixel = spektra_film_um_to_output_pixel(filmUm, params, dims);
  const int x = pixel.x;
  const int y = pixel.y;
  const float3 density = spektra_float4_buffer_sample(densityIn, dims.x, dims.y, x, y).rgb;
  if (params.grainSynthesisLayered == 0u) {
    return layer == 0u ? max(spektra_channel_component(density, channel), 0.0) : 0.0;
  }
  return spektra_interp_density_layer(
    spektra_channel_component(density, channel),
    channel,
    layer,
    curveInfo,
    info,
    densityCurves,
    densityCurveLayers
  );
}

static float spektra_grain_synthesis_target_at_um(
  device const float *targetDensities,
  float2 filmUm,
  uint component,
  constant SpektraKernelParams &params,
  constant uint2 &dims
) {
  const int2 pixel = spektra_film_um_to_output_pixel(filmUm, params, dims);
  const int x = pixel.x;
  const int y = pixel.y;
  return max(spektra_layer_buffer_sample(targetDensities, dims.x, dims.y, x, y, component), 0.0);
}

static float spektra_layer_half_buffer_sample(
  device const half *data,
  uint width,
  uint height,
  int x,
  int y,
  uint component
) {
  const uint sx = uint(clamp(x, 0, int(width) - 1));
  const uint sy = uint(clamp(y, 0, int(height) - 1));
  return float(data[(sy * width + sx) * 9u + component]);
}

static float spektra_grain_synthesis_target_at_um_half(
  device const half *targetDensities,
  float2 filmUm,
  uint component,
  constant SpektraKernelParams &params,
  constant uint2 &dims
) {
  const int2 pixel = spektra_film_um_to_output_pixel(filmUm, params, dims);
  const int x = pixel.x;
  const int y = pixel.y;
  return max(spektra_layer_half_buffer_sample(targetDensities, dims.x, dims.y, x, y, component), 0.0);
}

static float spektra_layer_r16_texture_array_sample(
  texture2d_array<half, access::read> data,
  uint width,
  uint height,
  int x,
  int y,
  uint component
) {
  const uint sx = uint(clamp(x, 0, int(width) - 1));
  const uint sy = uint(clamp(y, 0, int(height) - 1));
  return float(data.read(uint2(sx, sy), component).r);
}

static float spektra_grain_synthesis_target_at_um_texture(
  texture2d_array<half, access::read> targetDensities,
  float2 filmUm,
  uint component,
  constant SpektraKernelParams &params,
  constant uint2 &dims
) {
  const int2 pixel = spektra_film_um_to_output_pixel(filmUm, params, dims);
  const int x = pixel.x;
  const int y = pixel.y;
  return max(spektra_layer_r16_texture_array_sample(targetDensities, dims.x, dims.y, x, y, component), 0.0);
}

static bool spektra_grain_synthesis_indicator(
  device const float4 *densityIn,
  float2 pointUm,
  uint layer,
  uint channel,
  SpektraGrainSynthesisEval eval,
  bool fixedRadius,
  constant SpektraKernelParams &params,
  constant uint2 &dims,
  constant SpektraCurveInfo &curveInfo,
  constant SpektraSpectralInfo &info,
  device const float *densityCurves,
  device const float *densityCurveLayers
) {
  const float2 minCellFloat = floor((pointUm - eval.maxRadius) / eval.cellSize);
  const float2 maxCellFloat = floor((pointUm + eval.maxRadius) / eval.cellSize);
  const int2 cellMin = int2(int(minCellFloat.x), int(minCellFloat.y));
  const int2 cellMax = int2(int(maxCellFloat.x), int(maxCellFloat.y));

  for (int cy = cellMin.y; cy <= cellMax.y; ++cy) {
    for (int cx = cellMin.x; cx <= cellMax.x; ++cx) {
      const int2 cell = int2(cx, cy);
      const float2 cellOrigin = float2(float(cell.x), float(cell.y)) * eval.cellSize;
      if (spektra_grain_synthesis_cell_distance_squared(pointUm, cellOrigin, eval.cellSize) > eval.maxRadiusSquared) {
        continue;
      }
      const float2 cellCenter = cellOrigin + 0.5 * eval.cellSize;
      const float targetDensity = spektra_grain_synthesis_density_at_um(
        densityIn,
        cellCenter,
        layer,
        channel,
        params,
        dims,
        curveInfo,
        info,
        densityCurves,
        densityCurveLayers
      );
      if (targetDensity <= 0.0) {
        continue;
      }
      const float expectedGrains = max(targetDensity, 0.0) * eval.densityToLambda * eval.cellArea;
      if (expectedGrains <= 1.0e-7) {
        continue;
      }
      const uint baseSeed = spektra_cell_seed(cell, channel, layer, params);
      const uint grainCount = spektra_poisson_sample(expectedGrains, baseSeed, eval.grainCap);
      for (uint grain = 0u; grain < grainCount; ++grain) {
        const uint grainSeed = spektra_mix_seed(baseSeed, grain * 0x9e3779b9u);
        const float2 center = cellOrigin + float2(
          spektra_rand01(grainSeed ^ 0x68bc21ebu),
          spektra_rand01(grainSeed ^ 0x02e5be93u)
        ) * eval.cellSize;
        const float radius = fixedRadius
          ? eval.scaledMeanRadius
          : spektra_grain_synthesis_radius(eval.scaledMeanRadius, eval.maxRadius, params, grainSeed ^ 0x85ebca6bu);
        const half2 delta = half2(pointUm - center);
        const half radiusH = half(radius);
        if (dot(delta, delta) <= radiusH * radiusH) {
          return true;
        }
      }
    }
  }
  return false;
}

static float spektra_grain_synthesis_radius_fast(
  SpektraGrainSynthesisComponentInfo eval,
  bool fixedRadius,
  device const float *radiusLut,
  uint seed
) {
  if (fixedRadius || eval.logSigma <= 1.0e-6) {
    return eval.scaledMeanRadius;
  }
  if (eval.radiusLutSize > 0u) {
    const uint lutIndex = spektra_hash(seed ^ 0x6d2b79f5u) % eval.radiusLutSize;
    return radiusLut[eval.radiusLutOffset + lutIndex];
  }
  return min(fast::exp(eval.logMean + eval.logSigma * spektra_gaussian(seed)), eval.maxRadius);
}

static float spektra_exp_neg_unit(float lambda) {
  const float l2 = lambda * lambda;
  const float l3 = l2 * lambda;
  const float l4 = l2 * l2;
  const float l5 = l4 * lambda;
  return max(1.0f - lambda + 0.5f * l2 - 0.1666666667f * l3 + 0.0416666667f * l4 - 0.0083333333f * l5, 0.0f);
}

static uint spektra_poisson_sample_cdf_fast(float lambda, uint seed, uint cap) {
  if (lambda <= 0.0 || cap == 0u) {
    return 0u;
  }
  const float u = spektra_rand01(seed ^ 0x4cf5ad43u);
  if (lambda < 1.0e-5) {
    return u < lambda ? 1u : 0u;
  }
  if (lambda < 1.0) {
    float probability = spektra_exp_neg_unit(lambda);
    float cdf = probability;
    uint k = 0u;
    while (u > cdf && k < cap) {
      ++k;
      probability *= lambda / float(k);
      cdf += probability;
    }
    return min(k, cap);
  }
  return spektra_poisson_sample_cdf(lambda, seed, cap);
}

static float2 spektra_grain_synthesis_sample_offset(
  device const float2 *sampleOffsets,
  SpektraGrainSynthesisComponentInfo eval,
  uint component,
  uint sample,
  uint activeSampleCount,
  uint index
) {
  uint sampleIndex = sample;
  if (eval.samplerMode == 2u && activeSampleCount > 1u) {
    const uint key = spektra_hash(index ^ (component * 0x9e3779b9u) ^ 0x51ed270bu);
    if ((activeSampleCount & (activeSampleCount - 1u)) == 0u) {
      sampleIndex = (sample ^ key) & (activeSampleCount - 1u);
    } else {
      sampleIndex = (sample + (key % activeSampleCount)) % activeSampleCount;
    }
  }
  return sampleOffsets[component * kSpektraGrainSynthesisMaxSamples + sampleIndex];
}

static bool spektra_grain_synthesis_indicator_fast(
  device const float *targetDensities,
  float2 pointUm,
  uint component,
  SpektraGrainSynthesisComponentInfo eval,
  bool fixedRadius,
  constant SpektraKernelParams &params,
  constant uint2 &dims,
  device const float *radiusLut,
  device const int2 *cellOffsets
) {
  const int2 centerCell = int2(floor(pointUm * eval.invCellSize));
  const int scanRadius = int(eval.cellScanRadius);
  const uint offsetTotal = eval.cellOffsetCount > 0u
    ? eval.cellOffsetCount
    : uint((scanRadius * 2 + 1) * (scanRadius * 2 + 1));

  for (uint offsetIndex = 0u; offsetIndex < offsetTotal; ++offsetIndex) {
    int dx = 0;
    int dy = 0;
    if (eval.cellOffsetCount > 0u) {
      const int2 offset = cellOffsets[eval.cellOffsetStart + offsetIndex];
      dx = offset.x;
      dy = offset.y;
    } else {
      const int side = scanRadius * 2 + 1;
      const int linear = int(offsetIndex);
      dx = (linear % side) - scanRadius;
      dy = (linear / side) - scanRadius;
    }
    const int2 cell = centerCell + int2(dx, dy);
    const float2 cellOrigin = float2(float(cell.x), float(cell.y)) * eval.cellSize;
    if (spektra_grain_synthesis_cell_distance_squared(pointUm, cellOrigin, eval.cellSize) > eval.maxRadiusSquared) {
      continue;
    }
    const float2 cellCenter = cellOrigin + 0.5f * eval.cellSize;
    const float targetDensity = spektra_grain_synthesis_target_at_um(
      targetDensities,
      cellCenter,
      component,
      params,
      dims
    );
    if (targetDensity <= 0.0f) {
      continue;
    }
    const float expectedGrains = targetDensity * eval.densityToLambda * eval.cellArea;
    if (expectedGrains <= 1.0e-7f) {
      continue;
    }
    const uint layer = component / 3u;
    const uint channel = component - layer * 3u;
    const uint baseSeed = spektra_cell_seed(cell, channel, layer, params);
    const uint grainCount = spektra_poisson_sample_cdf_fast(expectedGrains, baseSeed, eval.grainCap);
    for (uint grain = 0u; grain < grainCount; ++grain) {
      const uint grainSeed = spektra_mix_seed(baseSeed, grain * 0x9e3779b9u);
      const float2 center = cellOrigin + float2(
        spektra_rand01(grainSeed ^ 0x68bc21ebu),
        spektra_rand01(grainSeed ^ 0x02e5be93u)
      ) * eval.cellSize;
      const float radius = spektra_grain_synthesis_radius_fast(eval, fixedRadius, radiusLut, grainSeed ^ 0x85ebca6bu);
      const half2 delta = half2(pointUm - center);
      const half radiusH = half(radius);
      if (dot(delta, delta) <= radiusH * radiusH) {
        return true;
      }
    }
  }
  return false;
}

static bool spektra_grain_synthesis_indicator_fast(
  device const half *targetDensities,
  float2 pointUm,
  uint component,
  SpektraGrainSynthesisComponentInfo eval,
  bool fixedRadius,
  constant SpektraKernelParams &params,
  constant uint2 &dims,
  device const float *radiusLut,
  device const int2 *cellOffsets
) {
  const int2 centerCell = int2(floor(pointUm * eval.invCellSize));
  const int scanRadius = int(eval.cellScanRadius);
  const uint offsetTotal = eval.cellOffsetCount > 0u
    ? eval.cellOffsetCount
    : uint((scanRadius * 2 + 1) * (scanRadius * 2 + 1));

  for (uint offsetIndex = 0u; offsetIndex < offsetTotal; ++offsetIndex) {
    int dx = 0;
    int dy = 0;
    if (eval.cellOffsetCount > 0u) {
      const int2 offset = cellOffsets[eval.cellOffsetStart + offsetIndex];
      dx = offset.x;
      dy = offset.y;
    } else {
      const int side = scanRadius * 2 + 1;
      const int linear = int(offsetIndex);
      dx = (linear % side) - scanRadius;
      dy = (linear / side) - scanRadius;
    }
    const int2 cell = centerCell + int2(dx, dy);
    const float2 cellOrigin = float2(float(cell.x), float(cell.y)) * eval.cellSize;
    if (spektra_grain_synthesis_cell_distance_squared(pointUm, cellOrigin, eval.cellSize) > eval.maxRadiusSquared) {
      continue;
    }
    const float2 cellCenter = cellOrigin + 0.5 * eval.cellSize;
    const float targetDensity = spektra_grain_synthesis_target_at_um_half(
      targetDensities,
      cellCenter,
      component,
      params,
      dims
    );
    if (targetDensity <= 0.0) {
      continue;
    }
    const float expectedGrains = targetDensity * eval.densityToLambda * eval.cellArea;
    if (expectedGrains <= 1.0e-7) {
      continue;
    }
    const uint layer = component / 3u;
    const uint channel = component - layer * 3u;
    const uint baseSeed = spektra_cell_seed(cell, channel, layer, params);
    const uint grainCount = spektra_poisson_sample_cdf_fast(expectedGrains, baseSeed, eval.grainCap);
    for (uint grain = 0u; grain < grainCount; ++grain) {
      const uint grainSeed = spektra_mix_seed(baseSeed, grain * 0x9e3779b9u);
      const float2 center = cellOrigin + float2(
        spektra_rand01(grainSeed ^ 0x68bc21ebu),
        spektra_rand01(grainSeed ^ 0x02e5be93u)
      ) * eval.cellSize;
      const float radius = spektra_grain_synthesis_radius_fast(eval, fixedRadius, radiusLut, grainSeed ^ 0x85ebca6bu);
      const half2 delta = half2(pointUm - center);
      const half radiusH = half(radius);
      if (dot(delta, delta) <= radiusH * radiusH) {
        return true;
      }
    }
  }
  return false;
}

static bool spektra_grain_synthesis_indicator_fast(
  texture2d_array<half, access::read> targetDensities,
  float2 pointUm,
  uint component,
  SpektraGrainSynthesisComponentInfo eval,
  bool fixedRadius,
  constant SpektraKernelParams &params,
  constant uint2 &dims,
  device const float *radiusLut,
  device const int2 *cellOffsets
) {
  const int2 centerCell = int2(floor(pointUm * eval.invCellSize));
  const int scanRadius = int(eval.cellScanRadius);
  const uint offsetTotal = eval.cellOffsetCount > 0u
    ? eval.cellOffsetCount
    : uint((scanRadius * 2 + 1) * (scanRadius * 2 + 1));

  for (uint offsetIndex = 0u; offsetIndex < offsetTotal; ++offsetIndex) {
    int dx = 0;
    int dy = 0;
    if (eval.cellOffsetCount > 0u) {
      const int2 offset = cellOffsets[eval.cellOffsetStart + offsetIndex];
      dx = offset.x;
      dy = offset.y;
    } else {
      const int side = scanRadius * 2 + 1;
      const int linear = int(offsetIndex);
      dx = (linear % side) - scanRadius;
      dy = (linear / side) - scanRadius;
    }
    const int2 cell = centerCell + int2(dx, dy);
    const float2 cellOrigin = float2(float(cell.x), float(cell.y)) * eval.cellSize;
    if (spektra_grain_synthesis_cell_distance_squared(pointUm, cellOrigin, eval.cellSize) > eval.maxRadiusSquared) {
      continue;
    }
    const float2 cellCenter = cellOrigin + 0.5f * eval.cellSize;
    const float targetDensity = spektra_grain_synthesis_target_at_um_texture(
      targetDensities,
      cellCenter,
      component,
      params,
      dims
    );
    if (targetDensity <= 0.0f) {
      continue;
    }
    const float expectedGrains = targetDensity * eval.densityToLambda * eval.cellArea;
    if (expectedGrains <= 1.0e-7f) {
      continue;
    }
    const uint layer = component / 3u;
    const uint channel = component - layer * 3u;
    const uint baseSeed = spektra_cell_seed(cell, channel, layer, params);
    const uint grainCount = spektra_poisson_sample_cdf_fast(expectedGrains, baseSeed, eval.grainCap);
    for (uint grain = 0u; grain < grainCount; ++grain) {
      const uint grainSeed = spektra_mix_seed(baseSeed, grain * 0x9e3779b9u);
      const float2 center = cellOrigin + float2(
        spektra_rand01(grainSeed ^ 0x68bc21ebu),
        spektra_rand01(grainSeed ^ 0x02e5be93u)
      ) * eval.cellSize;
      const float radius = spektra_grain_synthesis_radius_fast(eval, fixedRadius, radiusLut, grainSeed ^ 0x85ebca6bu);
      const half2 delta = half2(pointUm - center);
      const half radiusH = half(radius);
      if (dot(delta, delta) <= radiusH * radiusH) {
        return true;
      }
    }
  }
  return false;
}

static float spektra_microstructure_sigma(constant SpektraKernelParams &params) {
  return params.grainMicroStructureSigmaNm * 0.001 / max(params.filmPixelSizeUm, 1.0e-6);
}

static float spektra_microstructure_blur_sigma(constant SpektraKernelParams &params) {
  return max(params.grainMicroStructureScale, 0.0) / max(params.filmPixelSizeUm, 1.0e-6);
}

static float3 spektra_dir_silver_density(
  float3 densityCmy,
  constant SpektraSpectralInfo &info
) {
  return spektra_film_silver_density(densityCmy, info);
}

static float3 spektra_dir_correction_from_density(
  float3 densityCmy,
  constant SpektraSpectralInfo &info,
  constant SpektraDirInfo &dirInfo
) {
  const float3 silver = spektra_dir_silver_density(densityCmy, info);
  return float3(
    silver.r * dirInfo.matrix00 + silver.g * dirInfo.matrix10 + silver.b * dirInfo.matrix20,
    silver.r * dirInfo.matrix01 + silver.g * dirInfo.matrix11 + silver.b * dirInfo.matrix21,
    silver.r * dirInfo.matrix02 + silver.g * dirInfo.matrix12 + silver.b * dirInfo.matrix22
  );
}

static float spektra_dir_tail_amplitude(uint component) {
  constexpr float3 kExpGaussianFitAmplitude = float3(0.1633, 0.6496, 0.1870);
  return kExpGaussianFitAmplitude[component];
}

static float3 spektra_halation_scatter_core_sigma(constant SpektraKernelParams &params) {
  constexpr float3 kScatterCoreUm = float3(2.2, 2.0, 1.6);
  return kScatterCoreUm * max(params.scatterScale, 0.0) / max(params.filmPixelSizeUm, 1.0e-6);
}

static float3 spektra_halation_scatter_tail_sigma(constant SpektraKernelParams &params, uint component) {
  constexpr float3 kScatterTailUm = float3(9.3, 9.7, 9.1);
  const float ratio = component == 0u ? 0.5360 : (component == 1u ? 1.5236 : 2.7684);
  return kScatterTailUm * ratio * max(params.scatterScale, 0.0) / max(params.filmPixelSizeUm, 1.0e-6);
}

static float spektra_halation_scatter_tail_weight(uint component) {
  return component == 0u ? 0.1633 : (component == 1u ? 0.6496 : 0.1870);
}

static float3 spektra_halation_first_sigma(constant SpektraKernelParams &params, uint bounce) {
  const float3 kHalationFirstSigmaUm = max(
    float3(params.halationFirstSigmaUmR, params.halationFirstSigmaUmG, params.halationFirstSigmaUmB),
    float3(1.0e-6)
  );
  return kHalationFirstSigmaUm * max(params.halationScale, 0.0) * sqrt(float(bounce + 1u)) /
    max(params.filmPixelSizeUm, 1.0e-6);
}

static float spektra_max3(float3 value) {
  return max(max(value.r, value.g), value.b);
}

static float4 spektra_channel_gaussian_sample_x(
  device const float4 *source,
  uint width,
  uint height,
  uint2 gid,
  float3 sigma
) {
  const float maxSigma = spektra_max3(sigma);
  if (maxSigma <= 1.0e-4) {
    return spektra_float4_buffer_sample(source, width, height, int(gid.x), int(gid.y));
  }
  const int radius = min(int(ceil(3.0 * maxSigma)), 256);
  const int x = int(gid.x);
  const int y = int(gid.y);
  const float3 safeSigma = max(sigma, float3(1.0e-6));
  const float3 invSigma2 = 1.0 / max(safeSigma * safeSigma, float3(1.0e-8));
  float3 weight = exp(-0.5 * invSigma2);
  float3 ratio = exp(-1.5 * invSigma2);
  const float3 ratioStep = exp(-invSigma2);
  float4 value = spektra_float4_buffer_sample(source, width, height, x, y);
  float3 weightSum = float3(1.0);
  for (int offset = 1; offset <= radius; ++offset) {
    const float4 samplePair =
      spektra_float4_buffer_sample(source, width, height, x - offset, y) +
      spektra_float4_buffer_sample(source, width, height, x + offset, y);
    value.rgb += samplePair.rgb * weight;
    value.a += samplePair.a;
    weightSum += 2.0 * weight;
    weight *= ratio;
    ratio *= ratioStep;
  }
  value.rgb /= max(weightSum, float3(1.0e-8));
  value.a /= float(radius * 2 + 1);
  return value;
}

static float4 spektra_channel_gaussian_sample_y(
  device const float4 *source,
  uint width,
  uint height,
  uint2 gid,
  float3 sigma
) {
  const float maxSigma = spektra_max3(sigma);
  if (maxSigma <= 1.0e-4) {
    return spektra_float4_buffer_sample(source, width, height, int(gid.x), int(gid.y));
  }
  const int radius = min(int(ceil(3.0 * maxSigma)), 256);
  const int x = int(gid.x);
  const int y = int(gid.y);
  const float3 safeSigma = max(sigma, float3(1.0e-6));
  const float3 invSigma2 = 1.0 / max(safeSigma * safeSigma, float3(1.0e-8));
  float3 weight = exp(-0.5 * invSigma2);
  float3 ratio = exp(-1.5 * invSigma2);
  const float3 ratioStep = exp(-invSigma2);
  float4 value = spektra_float4_buffer_sample(source, width, height, x, y);
  float3 weightSum = float3(1.0);
  for (int offset = 1; offset <= radius; ++offset) {
    const float4 samplePair =
      spektra_float4_buffer_sample(source, width, height, x, y - offset) +
      spektra_float4_buffer_sample(source, width, height, x, y + offset);
    value.rgb += samplePair.rgb * weight;
    value.a += samplePair.a;
    weightSum += 2.0 * weight;
    weight *= ratio;
    ratio *= ratioStep;
  }
  value.rgb /= max(weightSum, float3(1.0e-8));
  value.a /= float(radius * 2 + 1);
  return value;
}

kernel void spektrafilm_halation_raw_exposure(
  device const float4 *source [[buffer(0)]],
  device float4 *rawOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(4)]],
  device const float *logSensitivity [[buffer(5)]],
  device const float *bandpassHanatos2025 [[buffer(6)]],
  device const float *hanatosSpectraLut [[buffer(7)]],
  device const float *mallettBasisIlluminant [[buffer(8)]],
  device const float *inputToReferenceXyz [[buffer(9)]],
  device const float *inputToSrgb [[buffer(10)]],
  constant SpektraColorInfo &colorInfo [[buffer(11)]],
  device const float *decodeLuts [[buffer(12)]],
  device const uint *transferKinds [[buffer(13)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 sourcePixel = source[index];
  rawOut[index] = float4(
    spektra_film_raw(
      sourcePixel.rgb,
      params,
      colorInfo,
      spectralInfo,
      logSensitivity,
      bandpassHanatos2025,
      hanatosSpectraLut,
      mallettBasisIlluminant,
      inputToReferenceXyz,
      inputToSrgb,
      decodeLuts,
      transferKinds
    ),
    sourcePixel.a
  );
}

kernel void spektrafilm_halation_boost_max(
  device const float4 *rawIn [[buffer(0)]],
  device float *maxOut [[buffer(1)]],
  constant uint2 &dims [[buffer(2)]],
  constant uint &chunkPixels [[buffer(3)]],
  uint tid [[thread_position_in_grid]]
) {
  const uint count = dims.x * dims.y;
  const uint start = tid * chunkPixels;
  if (start >= count) {
    return;
  }
  const uint end = min(start + chunkPixels, count);
  float maxRaw = 0.0;
  for (uint index = start; index < end; ++index) {
    maxRaw = max(maxRaw, spektra_max3(rawIn[index].rgb));
  }
  maxOut[tid] = maxRaw;
}

kernel void spektrafilm_halation_boost_reduce_max(
  device const float *chunkMaxIn [[buffer(0)]],
  device float *boostInfoOut [[buffer(1)]],
  constant uint &chunkCount [[buffer(2)]],
  constant SpektraKernelParams &params [[buffer(3)]],
  uint tid [[thread_position_in_grid]]
) {
  if (tid != 0u) {
    return;
  }
  float maxRaw = 0.0;
  for (uint index = 0u; index < chunkCount; ++index) {
    maxRaw = max(maxRaw, chunkMaxIn[index]);
  }
  constexpr float kMidgray = 0.184;
  const float rawX0 = clamp(kMidgray * exp2(params.halationProtectEv), 0.0, maxRaw);
  const float boostRange = clamp(params.halationBoostRange, 0.0, 1.0);
  const float a = pow(28.0, 1.0 - boostRange);
  const float x0 = maxRaw > 0.0 ? rawX0 / maxRaw : 1.0;
  const float denom = exp(a * (1.0 - x0)) - a * (1.0 - x0) - 1.0;
  const float k = (maxRaw > 0.0 && rawX0 < maxRaw && denom > 1.0e-10)
    ? (exp2(max(params.halationBoostEv, 0.0)) - 1.0) / denom
    : 0.0;
  boostInfoOut[0] = maxRaw;
  boostInfoOut[1] = rawX0;
  boostInfoOut[2] = a;
  boostInfoOut[3] = k;
}

static float spektra_halation_boost_channel(
  float value,
  float rawX0,
  float maxRaw,
  float a,
  float k
) {
  if (value <= rawX0) {
    return value;
  }
  const float dx = (value - rawX0) / maxRaw;
  const float boost = k * maxRaw * (exp(a * dx) - a * dx - 1.0);
  return value + boost;
}

kernel void spektrafilm_halation_boost_apply(
  device const float4 *rawIn [[buffer(0)]],
  device float4 *rawOut [[buffer(1)]],
  device const float *boostInfo [[buffer(2)]],
  constant SpektraKernelParams &params [[buffer(3)]],
  constant uint2 &dims [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 raw = rawIn[index];
  if (params.halationEnabled == 0u || params.halationBoostEv <= 0.0) {
    rawOut[index] = raw;
    return;
  }
  const float frameMax = boostInfo[0];
  const float rawX0 = boostInfo[1];
  const float a = boostInfo[2];
  const float k = boostInfo[3];
  if (frameMax <= 0.0 || k <= 0.0) {
    rawOut[index] = raw;
    return;
  }
  if (rawX0 >= frameMax || spektra_max3(raw.rgb) <= rawX0) {
    rawOut[index] = raw;
    return;
  }
  rawOut[index] = float4(
    float3(
      spektra_halation_boost_channel(raw.r, rawX0, frameMax, a, k),
      spektra_halation_boost_channel(raw.g, rawX0, frameMax, a, k),
      spektra_halation_boost_channel(raw.b, rawX0, frameMax, a, k)
    ),
    raw.a
  );
}

kernel void spektrafilm_halation_scatter_core_blur_x(
  device const float4 *rawIn [[buffer(0)]],
  device float4 *rawOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  rawOut[gid.y * dims.x + gid.x] = spektra_channel_gaussian_sample_x(
    rawIn, dims.x, dims.y, gid, spektra_halation_scatter_core_sigma(params));
}

kernel void spektrafilm_halation_scatter_core_blur_y(
  device const float4 *rawIn [[buffer(0)]],
  device float4 *rawOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  rawOut[gid.y * dims.x + gid.x] = spektra_channel_gaussian_sample_y(
    rawIn, dims.x, dims.y, gid, spektra_halation_scatter_core_sigma(params));
}

kernel void spektrafilm_halation_scatter_tail_blur_x(
  device const float4 *rawIn [[buffer(0)]],
  device float4 *rawOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant uint &component [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  rawOut[gid.y * dims.x + gid.x] = spektra_channel_gaussian_sample_x(
    rawIn, dims.x, dims.y, gid, spektra_halation_scatter_tail_sigma(params, component));
}

kernel void spektrafilm_halation_scatter_tail_blur_y(
  device const float4 *rawIn [[buffer(0)]],
  device float4 *rawOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant uint &component [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 blurred = spektra_channel_gaussian_sample_y(
    rawIn, dims.x, dims.y, gid, spektra_halation_scatter_tail_sigma(params, component));
  rawOut[index] = float4(rawOut[index].rgb + spektra_halation_scatter_tail_weight(component) * blurred.rgb, blurred.a);
}

kernel void spektrafilm_halation_scatter_tail_group_blur_x(
  device const float4 *rawIn [[buffer(0)]],
  device float4 *tailOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const uint pixelCount = dims.x * dims.y;
  tailOut[index] = spektra_channel_gaussian_sample_x(
    rawIn, dims.x, dims.y, gid, spektra_halation_scatter_tail_sigma(params, 0u));
  tailOut[pixelCount + index] = spektra_channel_gaussian_sample_x(
    rawIn, dims.x, dims.y, gid, spektra_halation_scatter_tail_sigma(params, 1u));
  tailOut[pixelCount * 2u + index] = spektra_channel_gaussian_sample_x(
    rawIn, dims.x, dims.y, gid, spektra_halation_scatter_tail_sigma(params, 2u));
}

kernel void spektrafilm_halation_scatter_tail_group_blur_y(
  device const float4 *tailIn [[buffer(0)]],
  device float4 *accumInOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const uint pixelCount = dims.x * dims.y;
  const float4 blurred0 = spektra_channel_gaussian_sample_y(
    tailIn, dims.x, dims.y, gid, spektra_halation_scatter_tail_sigma(params, 0u));
  const float4 blurred1 = spektra_channel_gaussian_sample_y(
    tailIn + pixelCount, dims.x, dims.y, gid, spektra_halation_scatter_tail_sigma(params, 1u));
  const float4 blurred2 = spektra_channel_gaussian_sample_y(
    tailIn + pixelCount * 2u, dims.x, dims.y, gid, spektra_halation_scatter_tail_sigma(params, 2u));
  accumInOut[index] = float4(
    accumInOut[index].rgb +
      spektra_halation_scatter_tail_weight(0u) * blurred0.rgb +
      spektra_halation_scatter_tail_weight(1u) * blurred1.rgb +
      spektra_halation_scatter_tail_weight(2u) * blurred2.rgb,
    blurred0.a
  );
}

kernel void spektrafilm_halation_scatter_resolve(
  device const float4 *rawIn [[buffer(0)]],
  device const float4 *coreIn [[buffer(1)]],
  device const float4 *tailIn [[buffer(2)]],
  device float4 *rawOut [[buffer(3)]],
  constant SpektraKernelParams &params [[buffer(4)]],
  constant uint2 &dims [[buffer(5)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  constexpr float3 kScatterTailWeight = float3(0.78, 0.65, 0.67);
  const uint index = gid.y * dims.x + gid.x;
  const float4 raw = rawIn[index];
  const float3 scattered = (1.0 - kScatterTailWeight) * coreIn[index].rgb + kScatterTailWeight * tailIn[index].rgb;
  rawOut[index] = float4((1.0 - params.scatterAmount) * raw.rgb + params.scatterAmount * scattered, raw.a);
}

kernel void spektrafilm_halation_clear(
  device const float4 *rawIn [[buffer(0)]],
  device float4 *accumOut [[buffer(1)]],
  constant uint2 &dims [[buffer(2)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  accumOut[index] = float4(0.0, 0.0, 0.0, rawIn[index].a);
}

kernel void spektrafilm_halation_bounce_blur_x(
  device const float4 *rawIn [[buffer(0)]],
  device float4 *rawOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant uint &bounce [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  rawOut[gid.y * dims.x + gid.x] = spektra_channel_gaussian_sample_x(
    rawIn, dims.x, dims.y, gid, spektra_halation_first_sigma(params, bounce));
}

kernel void spektrafilm_halation_bounce_blur_y_accumulate(
  device const float4 *rawIn [[buffer(0)]],
  device float4 *accumInOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant uint &bounce [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  constexpr float kHalationBounceDecay = 0.5;
  constexpr float kHalationDecaySum3 = 1.75;
  const float weight = pow(kHalationBounceDecay, float(bounce)) / kHalationDecaySum3;
  const uint index = gid.y * dims.x + gid.x;
  const float4 blurred = spektra_channel_gaussian_sample_y(
    rawIn, dims.x, dims.y, gid, spektra_halation_first_sigma(params, bounce));
  accumInOut[index] = float4(accumInOut[index].rgb + weight * blurred.rgb, blurred.a);
}

kernel void spektrafilm_halation_resolve_log_raw(
  device const float4 *rawIn [[buffer(0)]],
  device const float4 *halationIn [[buffer(1)]],
  device float4 *logRawOut [[buffer(2)]],
  constant SpektraKernelParams &params [[buffer(3)]],
  constant uint2 &dims [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 raw = rawIn[index];
  const float3 amount = max(float3(params.halationStrengthR, params.halationStrengthG, params.halationStrengthB), float3(0.0)) *
    max(params.halationAmount, 0.0);
  const float3 resolved = (raw.rgb + amount * halationIn[index].rgb) / (1.0 + amount);
  logRawOut[index] = float4(log10(max(resolved, float3(0.0)) + float3(1.0e-10)), raw.a);
}

kernel void spektrafilm_halation_resolve_density(
  device const float4 *rawIn [[buffer(0)]],
  device const float4 *halationIn [[buffer(1)]],
  device float4 *densityOut [[buffer(2)]],
  constant SpektraKernelParams &params [[buffer(3)]],
  constant uint2 &dims [[buffer(4)]],
  constant SpektraCurveInfo &curveInfo [[buffer(5)]],
  device const float *logExposure [[buffer(6)]],
  device const float *densityCurves [[buffer(7)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 raw = rawIn[index];
  const float3 amount = max(float3(params.halationStrengthR, params.halationStrengthG, params.halationStrengthB), float3(0.0)) *
    max(params.halationAmount, 0.0);
  const float3 resolved = (raw.rgb + amount * halationIn[index].rgb) / (1.0 + amount);
  const float3 logRaw = log10(max(resolved, float3(0.0)) + float3(1.0e-10));
  densityOut[index] = float4(spektra_develop_film_density(logRaw, params, curveInfo, logExposure, densityCurves), raw.a);
}

kernel void spektrafilm_develop_from_log_raw(
  device const float4 *logRawIn [[buffer(0)]],
  device float4 *densityOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &curveInfo [[buffer(4)]],
  device const float *logExposure [[buffer(5)]],
  device const float *densityCurves [[buffer(6)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 logRaw = logRawIn[index];
  densityOut[index] = float4(spektra_develop_film_density(logRaw.rgb, params, curveInfo, logExposure, densityCurves), logRaw.a);
}

kernel void spektrafilm_develop_from_raw(
  device const float4 *rawIn [[buffer(0)]],
  device float4 *densityOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &curveInfo [[buffer(4)]],
  device const float *logExposure [[buffer(5)]],
  device const float *densityCurves [[buffer(6)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 raw = rawIn[index];
  const float3 logRaw = log10(max(raw.rgb, float3(0.0)) + float3(1.0e-10));
  densityOut[index] = float4(spektra_develop_film_density(logRaw, params, curveInfo, logExposure, densityCurves), raw.a);
}

kernel void spektrafilm_dir_correction_from_density(
  device const float4 *densityIn [[buffer(0)]],
  device float4 *correctionOut [[buffer(1)]],
  constant uint2 &dims [[buffer(2)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(3)]],
  constant SpektraDirInfo &dirInfo [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 density = densityIn[index];
  correctionOut[index] = float4(spektra_dir_correction_from_density(density.rgb, spectralInfo, dirInfo), density.a);
}

kernel void spektrafilm_copy_buffer(
  device const float4 *source [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  constant uint2 &dims [[buffer(2)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  destination[index] = source[index];
}

kernel void spektrafilm_half_to_float_buffer(
  device const half4 *source [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  constant uint2 &dims [[buffer(2)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  destination[index] = float4(source[index]);
}

static uint spektra_hash_uint(uint value) {
  value ^= value >> 16u;
  value *= 0x7feb352du;
  value ^= value >> 15u;
  value *= 0x846ca68bu;
  value ^= value >> 16u;
  return value;
}

static float spektra_hash_unit_float(uint value) {
  return float(spektra_hash_uint(value) & 0x00ffffffu) * (1.0 / 16777216.0);
}

static float spektra_half_ulp(float value) {
  const float magnitude = abs(value);
  if (!isfinite(magnitude) || magnitude >= 65504.0) {
    return 0.0;
  }
  if (magnitude < 6.103515625e-5) {
    return 5.960464477539063e-8;
  }
  return exp2(floor(log2(magnitude)) - 10.0);
}

static float spektra_dither_tpdf_for_half(uint pixelIndex) {
  const uint seed = pixelIndex * 747796405u + 0x9e3779b9u;
  return 0.5 * (spektra_hash_unit_float(seed) + spektra_hash_unit_float(seed ^ 0x85ebca6bu) - 1.0);
}

static float spektra_dither_for_half(float value, float tpdf) {
  return value + tpdf * spektra_half_ulp(value);
}

static float3 spektra_dither_rgb_for_half(float3 rgb, uint pixelIndex) {
  const float tpdf = spektra_dither_tpdf_for_half(pixelIndex);
  return float3(
    spektra_dither_for_half(rgb.r, tpdf),
    spektra_dither_for_half(rgb.g, tpdf),
    spektra_dither_for_half(rgb.b, tpdf)
  );
}
kernel void spektrafilm_float_to_half_buffer(
  device const float4 *source [[buffer(0)]],
  device half4 *destination [[buffer(1)]],
  constant uint2 &dims [[buffer(2)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 pixel = source[index];
  destination[index] = half4(float4(spektra_dither_rgb_for_half(pixel.rgb, index), pixel.a));
}

struct SpektraHostBufferLayout {
  uint width;
  uint height;
  uint rowBytes;
  uint startByteOffset;
};

kernel void spektrafilm_strided_float_to_float_buffer(
  device const uchar *source [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  constant SpektraHostBufferLayout &layout [[buffer(2)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= layout.width || gid.y >= layout.height) {
    return;
  }
  const uint index = gid.y * layout.width + gid.x;
  const uint byteOffset = layout.startByteOffset + gid.y * layout.rowBytes + gid.x * uint(sizeof(float4));
  device const float4 *pixel = reinterpret_cast<device const float4 *>(source + byteOffset);
  destination[index] = *pixel;
}

kernel void spektrafilm_strided_half_to_float_buffer(
  device const uchar *source [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  constant SpektraHostBufferLayout &layout [[buffer(2)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= layout.width || gid.y >= layout.height) {
    return;
  }
  const uint index = gid.y * layout.width + gid.x;
  const uint byteOffset = layout.startByteOffset + gid.y * layout.rowBytes + gid.x * uint(sizeof(half4));
  device const half4 *pixel = reinterpret_cast<device const half4 *>(source + byteOffset);
  destination[index] = float4(*pixel);
}

kernel void spektrafilm_float_to_strided_float_buffer(
  device const float4 *source [[buffer(0)]],
  device uchar *destination [[buffer(1)]],
  constant SpektraHostBufferLayout &layout [[buffer(2)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= layout.width || gid.y >= layout.height) {
    return;
  }
  const uint index = gid.y * layout.width + gid.x;
  const uint byteOffset = layout.startByteOffset + gid.y * layout.rowBytes + gid.x * uint(sizeof(float4));
  device float4 *pixel = reinterpret_cast<device float4 *>(destination + byteOffset);
  *pixel = source[index];
}

kernel void spektrafilm_float_to_strided_half_buffer(
  device const float4 *source [[buffer(0)]],
  device uchar *destination [[buffer(1)]],
  constant SpektraHostBufferLayout &layout [[buffer(2)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= layout.width || gid.y >= layout.height) {
    return;
  }
  const uint index = gid.y * layout.width + gid.x;
  const uint byteOffset = layout.startByteOffset + gid.y * layout.rowBytes + gid.x * uint(sizeof(half4));
  device half4 *pixel = reinterpret_cast<device half4 *>(destination + byteOffset);
  const float4 value = source[index];
  *pixel = half4(float4(spektra_dither_rgb_for_half(value.rgb, index), value.a));
}

kernel void spektrafilm_raw_to_log_raw(
  device const float4 *rawIn [[buffer(0)]],
  device float4 *logRawOut [[buffer(1)]],
  constant uint2 &dims [[buffer(2)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 raw = rawIn[index];
  logRawOut[index] = float4(log10(max(raw.rgb, float3(0.0)) + float3(1.0e-10)), raw.a);
}

static SpektraGaussianBlurInfo spektra_make_gaussian_blur_info(float sigma, int radiusLimit) {
  SpektraGaussianBlurInfo info;
  info.firstWeight = 0.0;
  info.firstRatio = 0.0;
  info.ratioStep = 0.0;
  info.invWeightSum = 1.0;
  info.radius = 0u;
  info.active = sigma > 1.0e-4 ? 1u : 0u;
  info._pad0 = 0u;
  info._pad1 = 0u;
  if (info.active == 0u) {
    return info;
  }
  const int radius = min(int(ceil(3.0 * sigma)), radiusLimit);
  info.radius = uint(max(radius, 0));
  const float invSigma2 = 1.0 / max(sigma * sigma, 1.0e-8);
  info.firstWeight = exp(-0.5 * invSigma2);
  info.firstRatio = exp(-1.5 * invSigma2);
  info.ratioStep = exp(-invSigma2);
  float weight = info.firstWeight;
  float ratio = info.firstRatio;
  float weightSum = 1.0;
  for (uint offset = 1u; offset <= info.radius; ++offset) {
    weightSum += 2.0 * weight;
    weight *= ratio;
    ratio *= info.ratioStep;
  }
  info.invWeightSum = 1.0 / max(weightSum, 1.0e-8);
  return info;
}

static float4 spektra_scalar_gaussian_sample_x_info(
  device const float4 *source,
  uint width,
  uint height,
  uint2 gid,
  SpektraGaussianBlurInfo info
) {
  const uint index = gid.y * width + gid.x;
  if (info.active == 0u || info.radius == 0u) {
    return source[index];
  }
  const int x = int(gid.x);
  const int y = int(gid.y);
  const int radius = int(info.radius);
  const bool interior = x >= radius && x + radius < int(width);
  float weight = info.firstWeight;
  float ratio = info.firstRatio;
  float4 value = source[index];
  for (int offset = 1; offset <= radius; ++offset) {
    const float4 samplePair = interior
      ? source[index - uint(offset)] + source[index + uint(offset)]
      : spektra_float4_buffer_sample(source, width, height, x - offset, y) +
        spektra_float4_buffer_sample(source, width, height, x + offset, y);
    value += weight * samplePair;
    weight *= ratio;
    ratio *= info.ratioStep;
  }
  return value * info.invWeightSum;
}

static float4 spektra_scalar_gaussian_sample_y_info(
  device const float4 *source,
  uint width,
  uint height,
  uint2 gid,
  SpektraGaussianBlurInfo info
) {
  const uint index = gid.y * width + gid.x;
  if (info.active == 0u || info.radius == 0u) {
    return source[index];
  }
  const int x = int(gid.x);
  const int y = int(gid.y);
  const int radius = int(info.radius);
  const bool interior = y >= radius && y + radius < int(height);
  float weight = info.firstWeight;
  float ratio = info.firstRatio;
  float4 value = source[index];
  for (int offset = 1; offset <= radius; ++offset) {
    const uint stride = uint(offset) * width;
    const float4 samplePair = interior
      ? source[index - stride] + source[index + stride]
      : spektra_float4_buffer_sample(source, width, height, x, y - offset) +
        spektra_float4_buffer_sample(source, width, height, x, y + offset);
    value += weight * samplePair;
    weight *= ratio;
    ratio *= info.ratioStep;
  }
  return value * info.invWeightSum;
}

static float4 spektra_scalar_gaussian_sample_x_limited(
  device const float4 *source,
  uint width,
  uint height,
  uint2 gid,
  float sigma,
  int radiusLimit
) {
  return spektra_scalar_gaussian_sample_x_info(
    source,
    width,
    height,
    gid,
    spektra_make_gaussian_blur_info(sigma, radiusLimit)
  );
}

static float4 spektra_scalar_gaussian_sample_y_limited(
  device const float4 *source,
  uint width,
  uint height,
  uint2 gid,
  float sigma,
  int radiusLimit
) {
  return spektra_scalar_gaussian_sample_y_info(
    source,
    width,
    height,
    gid,
    spektra_make_gaussian_blur_info(sigma, radiusLimit)
  );
}

static float4 spektra_scalar_gaussian_sample_x(
  device const float4 *source,
  uint width,
  uint height,
  uint2 gid,
  float sigma
) {
  return spektra_scalar_gaussian_sample_x_limited(source, width, height, gid, sigma, 256);
}

static float4 spektra_scalar_gaussian_sample_y(
  device const float4 *source,
  uint width,
  uint height,
  uint2 gid,
  float sigma
) {
  return spektra_scalar_gaussian_sample_y_limited(source, width, height, gid, sigma, 256);
}

static float spektra_layer_gaussian_sample_x_limited(
  device const float *source,
  uint width,
  uint height,
  uint2 gid,
  uint component,
  float sigma,
  int radiusLimit
) {
  const SpektraGaussianBlurInfo info = spektra_make_gaussian_blur_info(sigma, radiusLimit);
  const uint index = gid.y * width + gid.x;
  if (info.active == 0u || info.radius == 0u) {
    return source[index * 9u + component];
  }
  const int x = int(gid.x);
  const int y = int(gid.y);
  const int radius = int(info.radius);
  const bool interior = x >= radius && x + radius < int(width);
  float value = source[index * 9u + component];
  float weight = info.firstWeight;
  float ratio = info.firstRatio;
  for (int offset = 1; offset <= radius; ++offset) {
    const float samplePair = interior
      ? source[(index - uint(offset)) * 9u + component] + source[(index + uint(offset)) * 9u + component]
      : spektra_layer_buffer_sample(source, width, height, x - offset, y, component) +
        spektra_layer_buffer_sample(source, width, height, x + offset, y, component);
    value += weight * samplePair;
    weight *= ratio;
    ratio *= info.ratioStep;
  }
  return value * info.invWeightSum;
}

static float spektra_layer_gaussian_sample_y_limited(
  device const float *source,
  uint width,
  uint height,
  uint2 gid,
  uint component,
  float sigma,
  int radiusLimit
) {
  const SpektraGaussianBlurInfo info = spektra_make_gaussian_blur_info(sigma, radiusLimit);
  const uint index = gid.y * width + gid.x;
  if (info.active == 0u || info.radius == 0u) {
    return source[index * 9u + component];
  }
  const int x = int(gid.x);
  const int y = int(gid.y);
  const int radius = int(info.radius);
  const bool interior = y >= radius && y + radius < int(height);
  float value = source[index * 9u + component];
  float weight = info.firstWeight;
  float ratio = info.firstRatio;
  for (int offset = 1; offset <= radius; ++offset) {
    const uint stride = uint(offset) * width;
    const float samplePair = interior
      ? source[(index - stride) * 9u + component] + source[(index + stride) * 9u + component]
      : spektra_layer_buffer_sample(source, width, height, x, y - offset, component) +
        spektra_layer_buffer_sample(source, width, height, x, y + offset, component);
    value += weight * samplePair;
    weight *= ratio;
    ratio *= info.ratioStep;
  }
  return value * info.invWeightSum;
}

kernel void spektrafilm_diffusion_component_blur_x(
  device const float4 *source [[buffer(0)]],
  device float4 *tempOut [[buffer(1)]],
  device const SpektraDiffusionComponent *components [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant uint &componentIndex [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const SpektraDiffusionComponent component = components[componentIndex];
  tempOut[gid.y * dims.x + gid.x] = spektra_scalar_gaussian_sample_x(
    source, dims.x, dims.y, gid, max(component.sigmaPx, 1.0e-6));
}

kernel void spektrafilm_diffusion_component_blur_y_accumulate(
  device const float4 *tempIn [[buffer(0)]],
  device float4 *accumInOut [[buffer(1)]],
  device const SpektraDiffusionComponent *components [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant uint &componentIndex [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const SpektraDiffusionComponent component = components[componentIndex];
  const uint index = gid.y * dims.x + gid.x;
  const float4 blurred = spektra_scalar_gaussian_sample_y(
    tempIn, dims.x, dims.y, gid, max(component.sigmaPx, 1.0e-6));
  accumInOut[index] = float4(
    accumInOut[index].rgb + blurred.rgb * float3(component.weightR, component.weightG, component.weightB),
    blurred.a
  );
}

kernel void spektrafilm_diffusion_group_blur_x(
  device const float4 *source [[buffer(0)]],
  device float4 *tempOut [[buffer(1)]],
  device const SpektraDiffusionComponent *components [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant uint2 &componentRange [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const uint pixelCount = dims.x * dims.y;
  const uint componentStart = componentRange.x;
  const uint groupCount = min(componentRange.y, 4u);
  for (uint slot = 0u; slot < groupCount; ++slot) {
    const SpektraDiffusionComponent component = components[componentStart + slot];
    const float sigma = max(component.sigmaPx, 1.0e-6);
    if (sigma <= 1.0e-4) {
      tempOut[slot * pixelCount + index] = source[index];
      continue;
    }
    tempOut[slot * pixelCount + index] = spektra_scalar_gaussian_sample_x(source, dims.x, dims.y, gid, sigma);
  }
}

kernel void spektrafilm_diffusion_group_blur_y_accumulate(
  device const float4 *tempIn [[buffer(0)]],
  device float4 *accumInOut [[buffer(1)]],
  device const SpektraDiffusionComponent *components [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant uint2 &componentRange [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const uint pixelCount = dims.x * dims.y;
  const uint componentStart = componentRange.x;
  const uint groupCount = min(componentRange.y, 4u);
  float4 accum = accumInOut[index];
  for (uint slot = 0u; slot < groupCount; ++slot) {
    const SpektraDiffusionComponent component = components[componentStart + slot];
    const float sigma = max(component.sigmaPx, 1.0e-6);
    device const float4 *plane = tempIn + slot * pixelCount;
    float4 blurred;
    if (sigma <= 1.0e-4) {
      blurred = plane[index];
    } else {
      blurred = spektra_scalar_gaussian_sample_y(plane, dims.x, dims.y, gid, sigma);
    }
    accum = float4(
      accum.rgb + blurred.rgb * float3(component.weightR, component.weightG, component.weightB),
      blurred.a
    );
  }
  accumInOut[index] = accum;
}

kernel void spektrafilm_diffusion_downsample(
  device const float4 *source [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  constant uint2 &fullDims [[buffer(2)]],
  constant uint2 &reducedDims [[buffer(3)]],
  constant uint &scaleIn [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= reducedDims.x || gid.y >= reducedDims.y) {
    return;
  }
  const uint scale = max(scaleIn, 1u);
  float4 value = float4(0.0);
  float weightSum = 0.0;
  const int baseX = int(gid.x * scale);
  const int baseY = int(gid.y * scale);
  for (uint oy = 0u; oy < scale; ++oy) {
    for (uint ox = 0u; ox < scale; ++ox) {
      const int x = min(baseX + int(ox), int(fullDims.x) - 1);
      const int y = min(baseY + int(oy), int(fullDims.y) - 1);
      value += spektra_float4_buffer_sample(source, fullDims.x, fullDims.y, x, y);
      weightSum += 1.0;
    }
  }
  destination[gid.y * reducedDims.x + gid.x] = value / max(weightSum, 1.0e-8);
}

kernel void spektrafilm_diffusion_downsample_blur_x(
  device const float4 *source [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  device const SpektraDiffusionComponent *components [[buffer(2)]],
  constant uint2 &reducedDims [[buffer(3)]],
  constant uint &componentIndex [[buffer(4)]],
  constant float &sigmaScale [[buffer(5)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= reducedDims.x || gid.y >= reducedDims.y) {
    return;
  }
  const SpektraDiffusionComponent component = components[componentIndex];
  const float sigma = max(component.sigmaPx * sigmaScale, 1.0e-6);
  destination[gid.y * reducedDims.x + gid.x] = spektra_scalar_gaussian_sample_x(
    source, reducedDims.x, reducedDims.y, gid, sigma);
}

kernel void spektrafilm_diffusion_downsample_blur_y(
  device const float4 *source [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  device const SpektraDiffusionComponent *components [[buffer(2)]],
  constant uint2 &reducedDims [[buffer(3)]],
  constant uint &componentIndex [[buffer(4)]],
  constant float &sigmaScale [[buffer(5)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= reducedDims.x || gid.y >= reducedDims.y) {
    return;
  }
  const SpektraDiffusionComponent component = components[componentIndex];
  const float sigma = max(component.sigmaPx * sigmaScale, 1.0e-6);
  destination[gid.y * reducedDims.x + gid.x] = spektra_scalar_gaussian_sample_y(
    source, reducedDims.x, reducedDims.y, gid, sigma);
}

static float4 spektra_reduced_bilinear_sample(
  device const float4 *source,
  uint2 reducedDims,
  float2 coord
) {
  const float2 clamped = clamp(coord, float2(0.0), float2(max(float(reducedDims.x) - 1.0, 0.0), max(float(reducedDims.y) - 1.0, 0.0)));
  const int x0 = int(floor(clamped.x));
  const int y0 = int(floor(clamped.y));
  const int x1 = min(x0 + 1, int(reducedDims.x) - 1);
  const int y1 = min(y0 + 1, int(reducedDims.y) - 1);
  const float tx = clamped.x - float(x0);
  const float ty = clamped.y - float(y0);
  const float4 p00 = source[uint(y0) * reducedDims.x + uint(x0)];
  const float4 p10 = source[uint(y0) * reducedDims.x + uint(x1)];
  const float4 p01 = source[uint(y1) * reducedDims.x + uint(x0)];
  const float4 p11 = source[uint(y1) * reducedDims.x + uint(x1)];
  return mix(mix(p00, p10, tx), mix(p01, p11, tx), ty);
}

kernel void spektrafilm_diffusion_downsample_upsample_accumulate(
  device const float4 *reducedBlur [[buffer(0)]],
  device float4 *accumInOut [[buffer(1)]],
  device const SpektraDiffusionComponent *components [[buffer(2)]],
  constant uint2 &fullDims [[buffer(3)]],
  constant uint2 &reducedDims [[buffer(4)]],
  constant uint &componentIndex [[buffer(5)]],
  constant uint &scaleIn [[buffer(6)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= fullDims.x || gid.y >= fullDims.y) {
    return;
  }
  const uint index = gid.y * fullDims.x + gid.x;
  const uint scale = max(scaleIn, 1u);
  const float2 coord = (float2(float(gid.x), float(gid.y)) + 0.5) / float(scale) - 0.5;
  const SpektraDiffusionComponent component = components[componentIndex];
  const float4 blurred = spektra_reduced_bilinear_sample(reducedBlur, reducedDims, coord);
  accumInOut[index] = float4(
    accumInOut[index].rgb + blurred.rgb * float3(component.weightR, component.weightG, component.weightB),
    blurred.a
  );
}

kernel void spektrafilm_diffusion_downsample_group_blur_x(
  device const float4 *source [[buffer(0)]],
  device float4 *tempOut [[buffer(1)]],
  device const SpektraDiffusionComponent *components [[buffer(2)]],
  constant uint2 &reducedDims [[buffer(3)]],
  constant uint2 &componentRange [[buffer(4)]],
  constant float &sigmaScale [[buffer(5)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= reducedDims.x || gid.y >= reducedDims.y) {
    return;
  }
  const uint index = gid.y * reducedDims.x + gid.x;
  const uint pixelCount = reducedDims.x * reducedDims.y;
  const uint componentStart = componentRange.x;
  const uint groupCount = min(componentRange.y, 4u);
  for (uint slot = 0u; slot < groupCount; ++slot) {
    const SpektraDiffusionComponent component = components[componentStart + slot];
    const float sigma = max(component.sigmaPx * sigmaScale, 1.0e-6);
    tempOut[slot * pixelCount + index] = sigma <= 1.0e-4
      ? source[index]
      : spektra_scalar_gaussian_sample_x(source, reducedDims.x, reducedDims.y, gid, sigma);
  }
}

kernel void spektrafilm_diffusion_downsample_group_blur_y(
  device const float4 *tempIn [[buffer(0)]],
  device float4 *blurOut [[buffer(1)]],
  device const SpektraDiffusionComponent *components [[buffer(2)]],
  constant uint2 &reducedDims [[buffer(3)]],
  constant uint2 &componentRange [[buffer(4)]],
  constant float &sigmaScale [[buffer(5)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= reducedDims.x || gid.y >= reducedDims.y) {
    return;
  }
  const uint index = gid.y * reducedDims.x + gid.x;
  const uint pixelCount = reducedDims.x * reducedDims.y;
  const uint componentStart = componentRange.x;
  const uint groupCount = min(componentRange.y, 4u);
  for (uint slot = 0u; slot < groupCount; ++slot) {
    const SpektraDiffusionComponent component = components[componentStart + slot];
    const float sigma = max(component.sigmaPx * sigmaScale, 1.0e-6);
    device const float4 *plane = tempIn + slot * pixelCount;
    blurOut[slot * pixelCount + index] = sigma <= 1.0e-4
      ? plane[index]
      : spektra_scalar_gaussian_sample_y(plane, reducedDims.x, reducedDims.y, gid, sigma);
  }
}

kernel void spektrafilm_diffusion_downsample_group_upsample_accumulate(
  device const float4 *reducedBlur [[buffer(0)]],
  device float4 *accumInOut [[buffer(1)]],
  device const SpektraDiffusionComponent *components [[buffer(2)]],
  constant uint2 &fullDims [[buffer(3)]],
  constant uint2 &reducedDims [[buffer(4)]],
  constant uint2 &componentRange [[buffer(5)]],
  constant uint &scaleIn [[buffer(6)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= fullDims.x || gid.y >= fullDims.y) {
    return;
  }
  const uint index = gid.y * fullDims.x + gid.x;
  const uint reducedPixelCount = reducedDims.x * reducedDims.y;
  const uint scale = max(scaleIn, 1u);
  const float2 coord = (float2(float(gid.x), float(gid.y)) + 0.5) / float(scale) - 0.5;
  const uint componentStart = componentRange.x;
  const uint groupCount = min(componentRange.y, 4u);
  float4 accum = accumInOut[index];
  for (uint slot = 0u; slot < groupCount; ++slot) {
    const SpektraDiffusionComponent component = components[componentStart + slot];
    device const float4 *plane = reducedBlur + slot * reducedPixelCount;
    const float4 blurred = spektra_reduced_bilinear_sample(plane, reducedDims, coord);
    accum = float4(
      accum.rgb + blurred.rgb * float3(component.weightR, component.weightG, component.weightB),
      blurred.a
    );
  }
  accumInOut[index] = accum;
}

static float4 spektra_half4_buffer_sample(
  device const half4 *source,
  uint width,
  uint height,
  int x,
  int y
) {
  const uint sx = spektra_safe_index(x, width);
  const uint sy = spektra_safe_index(y, height);
  return float4(source[sy * width + sx]);
}

static float4 spektra_scalar_gaussian_sample_y_half(
  device const half4 *source,
  uint width,
  uint height,
  uint2 gid,
  float sigma
) {
  const SpektraGaussianBlurInfo info = spektra_make_gaussian_blur_info(sigma, 256);
  if (info.active == 0u || info.radius == 0u) {
    return spektra_half4_buffer_sample(source, width, height, int(gid.x), int(gid.y));
  }
  const int x = int(gid.x);
  const int y = int(gid.y);
  const int radius = int(info.radius);
  const bool interior = y >= radius && y + radius < int(height);
  const uint index = gid.y * width + gid.x;
  float4 value = float4(source[index]);
  float weight = info.firstWeight;
  float ratio = info.firstRatio;
  for (int offset = 1; offset <= radius; ++offset) {
    const float4 samplePair = interior
      ? float4(source[(gid.y - uint(offset)) * width + gid.x]) + float4(source[(gid.y + uint(offset)) * width + gid.x])
      : spektra_half4_buffer_sample(source, width, height, x, y - offset) +
        spektra_half4_buffer_sample(source, width, height, x, y + offset);
    value += weight * samplePair;
    weight *= ratio;
    ratio *= info.ratioStep;
  }
  return value * info.invWeightSum;
}

static float4 spektra_reduced_bilinear_sample_half(
  device const half4 *source,
  uint2 reducedDims,
  float2 coord
) {
  const float2 clamped = clamp(coord, float2(0.0), float2(max(float(reducedDims.x) - 1.0, 0.0), max(float(reducedDims.y) - 1.0, 0.0)));
  const int x0 = int(floor(clamped.x));
  const int y0 = int(floor(clamped.y));
  const int x1 = min(x0 + 1, int(reducedDims.x) - 1);
  const int y1 = min(y0 + 1, int(reducedDims.y) - 1);
  const float tx = clamped.x - float(x0);
  const float ty = clamped.y - float(y0);
  const float4 p00 = float4(source[uint(y0) * reducedDims.x + uint(x0)]);
  const float4 p10 = float4(source[uint(y0) * reducedDims.x + uint(x1)]);
  const float4 p01 = float4(source[uint(y1) * reducedDims.x + uint(x0)]);
  const float4 p11 = float4(source[uint(y1) * reducedDims.x + uint(x1)]);
  return mix(mix(p00, p10, tx), mix(p01, p11, tx), ty);
}

kernel void spektrafilm_diffusion_downsample_blur_x_half(
  device const float4 *source [[buffer(0)]],
  device half4 *destination [[buffer(1)]],
  device const SpektraDiffusionComponent *components [[buffer(2)]],
  constant uint2 &reducedDims [[buffer(3)]],
  constant uint &componentIndex [[buffer(4)]],
  constant float &sigmaScale [[buffer(5)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= reducedDims.x || gid.y >= reducedDims.y) {
    return;
  }
  const SpektraDiffusionComponent component = components[componentIndex];
  const float sigma = max(component.sigmaPx * sigmaScale, 1.0e-6);
  destination[gid.y * reducedDims.x + gid.x] = half4(spektra_scalar_gaussian_sample_x(
    source, reducedDims.x, reducedDims.y, gid, sigma));
}

kernel void spektrafilm_diffusion_downsample_blur_y_half(
  device const half4 *source [[buffer(0)]],
  device half4 *destination [[buffer(1)]],
  device const SpektraDiffusionComponent *components [[buffer(2)]],
  constant uint2 &reducedDims [[buffer(3)]],
  constant uint &componentIndex [[buffer(4)]],
  constant float &sigmaScale [[buffer(5)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= reducedDims.x || gid.y >= reducedDims.y) {
    return;
  }
  const SpektraDiffusionComponent component = components[componentIndex];
  const float sigma = max(component.sigmaPx * sigmaScale, 1.0e-6);
  destination[gid.y * reducedDims.x + gid.x] = half4(spektra_scalar_gaussian_sample_y_half(
    source, reducedDims.x, reducedDims.y, gid, sigma));
}

kernel void spektrafilm_diffusion_downsample_upsample_accumulate_half(
  device const half4 *reducedBlur [[buffer(0)]],
  device float4 *accumInOut [[buffer(1)]],
  device const SpektraDiffusionComponent *components [[buffer(2)]],
  constant uint2 &fullDims [[buffer(3)]],
  constant uint2 &reducedDims [[buffer(4)]],
  constant uint &componentIndex [[buffer(5)]],
  constant uint &scaleIn [[buffer(6)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= fullDims.x || gid.y >= fullDims.y) {
    return;
  }
  const uint index = gid.y * fullDims.x + gid.x;
  const uint scale = max(scaleIn, 1u);
  const float2 coord = (float2(float(gid.x), float(gid.y)) + 0.5) / float(scale) - 0.5;
  const SpektraDiffusionComponent component = components[componentIndex];
  const float4 blurred = spektra_reduced_bilinear_sample_half(reducedBlur, reducedDims, coord);
  accumInOut[index] = float4(
    accumInOut[index].rgb + blurred.rgb * float3(component.weightR, component.weightG, component.weightB),
    blurred.a
  );
}

kernel void spektrafilm_diffusion_downsample_group_blur_x_half(
  device const float4 *source [[buffer(0)]],
  device half4 *tempOut [[buffer(1)]],
  device const SpektraDiffusionComponent *components [[buffer(2)]],
  constant uint2 &reducedDims [[buffer(3)]],
  constant uint2 &componentRange [[buffer(4)]],
  constant float &sigmaScale [[buffer(5)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= reducedDims.x || gid.y >= reducedDims.y) {
    return;
  }
  const uint index = gid.y * reducedDims.x + gid.x;
  const uint pixelCount = reducedDims.x * reducedDims.y;
  const uint componentStart = componentRange.x;
  const uint groupCount = min(componentRange.y, 4u);
  for (uint slot = 0u; slot < groupCount; ++slot) {
    const SpektraDiffusionComponent component = components[componentStart + slot];
    const float sigma = max(component.sigmaPx * sigmaScale, 1.0e-6);
    tempOut[slot * pixelCount + index] = half4(sigma <= 1.0e-4
      ? source[index]
      : spektra_scalar_gaussian_sample_x(source, reducedDims.x, reducedDims.y, gid, sigma));
  }
}

kernel void spektrafilm_diffusion_downsample_group_blur_y_half(
  device const half4 *tempIn [[buffer(0)]],
  device half4 *blurOut [[buffer(1)]],
  device const SpektraDiffusionComponent *components [[buffer(2)]],
  constant uint2 &reducedDims [[buffer(3)]],
  constant uint2 &componentRange [[buffer(4)]],
  constant float &sigmaScale [[buffer(5)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= reducedDims.x || gid.y >= reducedDims.y) {
    return;
  }
  const uint index = gid.y * reducedDims.x + gid.x;
  const uint pixelCount = reducedDims.x * reducedDims.y;
  const uint componentStart = componentRange.x;
  const uint groupCount = min(componentRange.y, 4u);
  for (uint slot = 0u; slot < groupCount; ++slot) {
    const SpektraDiffusionComponent component = components[componentStart + slot];
    const float sigma = max(component.sigmaPx * sigmaScale, 1.0e-6);
    device const half4 *plane = tempIn + slot * pixelCount;
    blurOut[slot * pixelCount + index] = half4(sigma <= 1.0e-4
      ? float4(plane[index])
      : spektra_scalar_gaussian_sample_y_half(plane, reducedDims.x, reducedDims.y, gid, sigma));
  }
}

kernel void spektrafilm_diffusion_downsample_group_upsample_accumulate_half(
  device const half4 *reducedBlur [[buffer(0)]],
  device float4 *accumInOut [[buffer(1)]],
  device const SpektraDiffusionComponent *components [[buffer(2)]],
  constant uint2 &fullDims [[buffer(3)]],
  constant uint2 &reducedDims [[buffer(4)]],
  constant uint2 &componentRange [[buffer(5)]],
  constant uint &scaleIn [[buffer(6)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= fullDims.x || gid.y >= fullDims.y) {
    return;
  }
  const uint index = gid.y * fullDims.x + gid.x;
  const uint reducedPixelCount = reducedDims.x * reducedDims.y;
  const uint scale = max(scaleIn, 1u);
  const float2 coord = (float2(float(gid.x), float(gid.y)) + 0.5) / float(scale) - 0.5;
  const uint componentStart = componentRange.x;
  const uint groupCount = min(componentRange.y, 4u);
  float4 accum = accumInOut[index];
  for (uint slot = 0u; slot < groupCount; ++slot) {
    const SpektraDiffusionComponent component = components[componentStart + slot];
    device const half4 *plane = reducedBlur + slot * reducedPixelCount;
    const float4 blurred = spektra_reduced_bilinear_sample_half(plane, reducedDims, coord);
    accum = float4(
      accum.rgb + blurred.rgb * float3(component.weightR, component.weightG, component.weightB),
      blurred.a
    );
  }
  accumInOut[index] = accum;
}

kernel void spektrafilm_diffusion_resolve(
  device const float4 *source [[buffer(0)]],
  device const float4 *accumIn [[buffer(1)]],
  device float4 *destination [[buffer(2)]],
  constant SpektraDiffusionInfo &diffusionInfo [[buffer(3)]],
  constant uint2 &dims [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 raw = source[index];
  const float scatter = clamp(diffusionInfo.scatterFraction, 0.0, 0.99);
  destination[index] = float4((1.0 - scatter) * raw.rgb + scatter * accumIn[index].rgb, raw.a);
}

kernel void spektrafilm_dir_baseline(
  device const float4 *source [[buffer(0)]],
  device float4 *logRawOut [[buffer(1)]],
  device float4 *densityOut [[buffer(2)]],
  device float4 *correctionOut [[buffer(3)]],
  constant SpektraKernelParams &params [[buffer(4)]],
  constant uint2 &dims [[buffer(5)]],
  constant SpektraCurveInfo &curveInfo [[buffer(6)]],
  device const float *logExposure [[buffer(7)]],
  device const float *densityCurves [[buffer(8)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(9)]],
  device const float *logSensitivity [[buffer(10)]],
  device const float *bandpassHanatos2025 [[buffer(11)]],
  device const float *hanatosSpectraLut [[buffer(12)]],
  device const float *mallettBasisIlluminant [[buffer(13)]],
  device const float *inputToReferenceXyz [[buffer(14)]],
  device const float *inputToSrgb [[buffer(15)]],
  constant SpektraColorInfo &colorInfo [[buffer(16)]],
  device const float *decodeLuts [[buffer(17)]],
  device const uint *transferKinds [[buffer(18)]],
  constant SpektraDirInfo &dirInfo [[buffer(19)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 sourcePixel = source[index];
  const float3 logRaw = spektra_film_log_raw(
    sourcePixel.rgb,
    params,
    colorInfo,
    spectralInfo,
    logSensitivity,
    bandpassHanatos2025,
    hanatosSpectraLut,
    mallettBasisIlluminant,
    inputToReferenceXyz,
    inputToSrgb,
    decodeLuts,
    transferKinds
  );
  const float3 density = spektra_develop_film_density(logRaw, params, curveInfo, logExposure, densityCurves);
  logRawOut[index] = float4(logRaw, sourcePixel.a);
  densityOut[index] = float4(density, sourcePixel.a);
  correctionOut[index] = float4(spektra_dir_correction_from_density(density, spectralInfo, dirInfo), sourcePixel.a);
}

kernel void spektrafilm_dir_blur_x(
  device const float4 *correctionIn [[buffer(0)]],
  device float4 *correctionOut [[buffer(1)]],
  constant SpektraGaussianBlurInfo &blurInfo [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  if (blurInfo.active == 0u) {
    correctionOut[index] = correctionIn[index];
    return;
  }
  correctionOut[index] = spektra_scalar_gaussian_sample_x_info(correctionIn, dims.x, dims.y, gid, blurInfo);
}

kernel void spektrafilm_dir_blur_y(
  device const float4 *correctionIn [[buffer(0)]],
  device float4 *correctionOut [[buffer(1)]],
  constant SpektraGaussianBlurInfo &blurInfo [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  if (blurInfo.active == 0u) {
    correctionOut[index] = correctionIn[index];
    return;
  }
  correctionOut[index] = spektra_scalar_gaussian_sample_y_info(correctionIn, dims.x, dims.y, gid, blurInfo);
}

kernel void spektrafilm_dir_tail_blur_x(
  device const float4 *correctionIn [[buffer(0)]],
  device float4 *tailOut [[buffer(1)]],
  constant SpektraGaussianBlurInfo *blurInfos [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const uint pixelCount = dims.x * dims.y;
  const SpektraGaussianBlurInfo info0 = blurInfos[0];
  const SpektraGaussianBlurInfo info1 = blurInfos[1];
  const SpektraGaussianBlurInfo info2 = blurInfos[2];
  const uint maxRadius = max(info0.radius, max(info1.radius, info2.radius));
  const float4 center = correctionIn[index];
  if ((info0.active | info1.active | info2.active) == 0u || maxRadius == 0u) {
    tailOut[index] = center;
    tailOut[pixelCount + index] = center;
    tailOut[pixelCount * 2u + index] = center;
    return;
  }
  const int x = int(gid.x);
  const int y = int(gid.y);
  const bool interior = x >= int(maxRadius) && x + int(maxRadius) < int(dims.x);
  float4 value0 = center;
  float4 value1 = center;
  float4 value2 = center;
  float3 weight = float3(info0.firstWeight, info1.firstWeight, info2.firstWeight);
  float3 ratio = float3(info0.firstRatio, info1.firstRatio, info2.firstRatio);
  const float3 ratioStep = float3(info0.ratioStep, info1.ratioStep, info2.ratioStep);
  for (uint offset = 1u; offset <= maxRadius; ++offset) {
    const float4 samplePair = interior
      ? correctionIn[index - offset] + correctionIn[index + offset]
      : spektra_float4_buffer_sample(correctionIn, dims.x, dims.y, x - int(offset), y) +
        spektra_float4_buffer_sample(correctionIn, dims.x, dims.y, x + int(offset), y);
    if (offset <= info0.radius) {
      value0 += weight.x * samplePair;
      weight.x *= ratio.x;
      ratio.x *= ratioStep.x;
    }
    if (offset <= info1.radius) {
      value1 += weight.y * samplePair;
      weight.y *= ratio.y;
      ratio.y *= ratioStep.y;
    }
    if (offset <= info2.radius) {
      value2 += weight.z * samplePair;
      weight.z *= ratio.z;
      ratio.z *= ratioStep.z;
    }
  }
  tailOut[index] = value0 * info0.invWeightSum;
  tailOut[pixelCount + index] = value1 * info1.invWeightSum;
  tailOut[pixelCount * 2u + index] = value2 * info2.invWeightSum;
}

kernel void spektrafilm_dir_tail_blur_y_accumulate(
  device const float4 *tailIn [[buffer(0)]],
  device float4 *correctionInOut [[buffer(1)]],
  constant SpektraGaussianBlurInfo *blurInfos [[buffer(2)]],
  constant float &tailWeightIn [[buffer(3)]],
  constant uint2 &dims [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const uint pixelCount = dims.x * dims.y;
  const float tailWeight = clamp(tailWeightIn, 0.0, 1.0);
  float4 base = correctionInOut[index];
  const float4 blurred0 = spektra_scalar_gaussian_sample_y_info(tailIn, dims.x, dims.y, gid, blurInfos[0]);
  const float4 blurred1 = spektra_scalar_gaussian_sample_y_info(tailIn + pixelCount, dims.x, dims.y, gid, blurInfos[1]);
  const float4 blurred2 = spektra_scalar_gaussian_sample_y_info(tailIn + pixelCount * 2u, dims.x, dims.y, gid, blurInfos[2]);
  base.rgb = base.rgb * (1.0 - tailWeight) +
    tailWeight * (
      spektra_dir_tail_amplitude(0u) * blurred0.rgb +
      spektra_dir_tail_amplitude(1u) * blurred1.rgb +
      spektra_dir_tail_amplitude(2u) * blurred2.rgb
    );
  correctionInOut[index] = base;
}

kernel void spektrafilm_dir_tail_mps_accumulate(
  texture2d<float, access::read> blurredIn [[texture(0)]],
  device float4 *correctionInOut [[buffer(0)]],
  constant float &tailWeightIn [[buffer(1)]],
  constant uint &component [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float tailWeight = clamp(tailWeightIn, 0.0, 1.0);
  float4 base = correctionInOut[index];
  if (component == 0u) {
    base.rgb *= 1.0 - tailWeight;
  }
  base.rgb += tailWeight * spektra_dir_tail_amplitude(component) * blurredIn.read(gid).rgb;
  correctionInOut[index] = base;
}

kernel void spektrafilm_dir_redevelop(
  device const float4 *logRawIn [[buffer(0)]],
  device const float4 *correctionIn [[buffer(1)]],
  device float4 *densityOut [[buffer(2)]],
  constant SpektraKernelParams &params [[buffer(3)]],
  constant uint2 &dims [[buffer(4)]],
  constant SpektraCurveInfo &curveInfo [[buffer(5)]],
  device const float *logExposure [[buffer(6)]],
  device const float *dirCorrectedDensityCurves [[buffer(7)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 logRaw = logRawIn[index];
  const float3 correctedLogRaw = logRaw.rgb - correctionIn[index].rgb;
  densityOut[index] = float4(
    spektra_develop_film_density(correctedLogRaw, params, curveInfo, logExposure, dirCorrectedDensityCurves),
    logRaw.a
  );
}

kernel void spektrafilm_preview_grain_from_density(
  device const float4 *densityIn [[buffer(0)]],
  device float4 *densityOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &curveInfo [[buffer(4)]],
  device const float *densityCurves [[buffer(5)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 density = densityIn[index];
  if (params.grainEnabled == 0u) {
    densityOut[index] = density;
    return;
  }
  const uint frameSeed = params.grainAnimate != 0 ? uint(floor(params.time * 24.0 + 0.5)) : 0u;
  const uint baseSeed = params.grainSeed ^ frameSeed;
  const float2 filmUm = spektra_output_pixel_film_um(gid, params, dims);
  densityOut[index] = float4(
    spektra_apply_grain_controls(
      density.rgb,
      spektra_preview_grain_density(density.rgb, params, curveInfo, densityCurves, filmUm, baseSeed),
      params
    ),
    density.a
  );
}

kernel void spektrafilm_production_grain_layers(
  device const float4 *source [[buffer(0)]],
  device float *layerOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &curveInfo [[buffer(4)]],
  device const float *logExposure [[buffer(5)]],
  device const float *densityCurves [[buffer(6)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(7)]],
  device const float *logSensitivity [[buffer(8)]],
  device const float *bandpassHanatos2025 [[buffer(9)]],
  device const float *hanatosSpectraLut [[buffer(10)]],
  device const float *mallettBasisIlluminant [[buffer(11)]],
  device const float *inputToReferenceXyz [[buffer(12)]],
  device const float *inputToSrgb [[buffer(13)]],
  constant SpektraColorInfo &colorInfo [[buffer(14)]],
  device const float *decodeLuts [[buffer(15)]],
  device const uint *transferKinds [[buffer(16)]],
  device const float *paperScanDensityData [[buffer(17)]],
  uint3 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y || gid.z >= 9u) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const uint component = gid.z;
  const uint layer = component / 3u;
  const uint channel = component - layer * 3u;
  device const float *paperBaseDensity = paperScanDensityData + spectralInfo.filmWavelengthCount * 3u;
  device const float *filmDensityCurveLayers = paperBaseDensity + spectralInfo.filmWavelengthCount;
  device const float *filmDensityCurveLayerMaxima = filmDensityCurveLayers + curveInfo.exposureCount * 9u;
  const uint frameSeed = params.grainAnimate != 0 ? uint(floor(params.time * 24.0 + 0.5)) : 0u;
  const uint baseSeed = params.grainSeed ^ frameSeed;
  const float2 filmUm = spektra_output_pixel_film_um(gid.xy, params, dims);
  const float3 filmDensityCmy = spektra_develop_film_density(
    spektra_film_log_raw(
      source[index].rgb,
      params,
      colorInfo,
      spectralInfo,
      logSensitivity,
      bandpassHanatos2025,
      hanatosSpectraLut,
      mallettBasisIlluminant,
      inputToReferenceXyz,
      inputToSrgb,
      decodeLuts,
      transferKinds
    ),
    params,
    curveInfo,
    logExposure,
    densityCurves
  );
  layerOut[index * 9u + component] = spektra_production_layer_particle_density(
    filmDensityCmy,
    layer,
    channel,
    params,
    curveInfo,
    spectralInfo,
    densityCurves,
    filmDensityCurveLayers,
    filmDensityCurveLayerMaxima,
    filmUm,
    baseSeed
  );
}

kernel void spektrafilm_production_grain_layers_from_density(
  device const float4 *filmDensity [[buffer(0)]],
  device float *layerOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &curveInfo [[buffer(4)]],
  device const float *densityCurves [[buffer(5)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(6)]],
  device const float *paperScanDensityData [[buffer(7)]],
  uint3 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y || gid.z >= 9u) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const uint component = gid.z;
  const uint layer = component / 3u;
  const uint channel = component - layer * 3u;
  device const float *paperBaseDensity = paperScanDensityData + spectralInfo.filmWavelengthCount * 3u;
  device const float *filmDensityCurveLayers = paperBaseDensity + spectralInfo.filmWavelengthCount;
  device const float *filmDensityCurveLayerMaxima = filmDensityCurveLayers + curveInfo.exposureCount * 9u;
  const uint frameSeed = params.grainAnimate != 0 ? uint(floor(params.time * 24.0 + 0.5)) : 0u;
  const uint baseSeed = params.grainSeed ^ frameSeed;
  const float2 filmUm = spektra_output_pixel_film_um(gid.xy, params, dims);
  layerOut[index * 9u + component] = spektra_production_layer_particle_density(
    filmDensity[index].rgb,
    layer,
    channel,
    params,
    curveInfo,
    spectralInfo,
    densityCurves,
    filmDensityCurveLayers,
    filmDensityCurveLayerMaxima,
    filmUm,
    baseSeed
  );
}

static void spektra_grain_synthesis_layers_from_density_impl(
  device const float4 *filmDensity,
  device float *layerOut,
  constant SpektraKernelParams &params,
  constant uint2 &dims,
  constant SpektraCurveInfo &curveInfo,
  device const float *densityCurves,
  constant SpektraSpectralInfo &spectralInfo,
  device const float *paperScanDensityData,
  uint3 gid,
  bool fixedRadius
) {
  if (gid.x >= dims.x || gid.y >= dims.y || gid.z >= 9u) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const uint component = gid.z;
  const uint layer = component / 3u;
  const uint channel = component - layer * 3u;
  if (params.grainSynthesisLayered == 0u && layer > 0u) {
    layerOut[index * 9u + component] = 0.0;
    return;
  }

  device const float *paperBaseDensity = paperScanDensityData + spectralInfo.filmWavelengthCount * 3u;
  device const float *filmDensityCurveLayers = paperBaseDensity + spectralInfo.filmWavelengthCount;
  const uint requestedSamples = uint(clamp(params.grainSynthesisSamples, 1, 1024));
  const float sigmaUm = max(params.grainSynthesisObservationSigmaUm, 0.0);
  const float2 centerUm = spektra_output_pixel_film_um(gid.xy, params, dims);
  const float targetCenterDensity = spektra_grain_synthesis_density_at_um(
    filmDensity,
    centerUm,
    layer,
    channel,
    params,
    dims,
    curveInfo,
    spectralInfo,
    densityCurves,
    filmDensityCurveLayers
  );
  if (targetCenterDensity <= 1.0e-7 && sigmaUm <= 1.0e-6) {
    layerOut[index * 9u + component] = 0.0;
    return;
  }

  const uint sampleCount = spektra_grain_synthesis_adaptive_sample_count(targetCenterDensity, requestedSamples);
  const SpektraGrainSynthesisEval eval = spektra_grain_synthesis_make_eval(layer, channel, params, fixedRadius);
  const uint frameSeed = params.grainAnimate != 0u ? uint(floor(params.time * 24.0 + 0.5)) : 0u;
  const uint sampleSeedBase = spektra_hash(params.grainSeed ^ frameSeed ^ (channel * 0x85ebca6bu) ^ (layer * 0xc2b2ae35u));

  float covered = 0.0;
  for (uint sample = 0u; sample < sampleCount; ++sample) {
    const uint sampleSeed = spektra_mix_seed(sampleSeedBase, sample);
    const float2 sampleOffset = sigmaUm > 0.0
      ? float2(
          spektra_gaussian(sampleSeed ^ 0x23d3c1f1u),
          spektra_gaussian(sampleSeed ^ 0xa349b329u)
        ) * sigmaUm
      : float2(0.0);
    covered += spektra_grain_synthesis_indicator(
      filmDensity,
      centerUm + sampleOffset,
      layer,
      channel,
      eval,
      fixedRadius,
      params,
      dims,
      curveInfo,
      spectralInfo,
      densityCurves,
      filmDensityCurveLayers
    ) ? 1.0 : 0.0;
  }

  const float epsilon = max(params.grainSynthesisCoverageEpsilon, 1.0e-8);
  const float coverage = clamp(covered / max(float(sampleCount), 1.0), 0.0, 1.0 - epsilon);
  layerOut[index * 9u + component] = -log(max(1.0 - coverage, epsilon)) / 2.302585093;
}

kernel void spektrafilm_grain_synthesis_layers_from_density(
  device const float4 *filmDensity [[buffer(0)]],
  device float *layerOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &curveInfo [[buffer(4)]],
  device const float *densityCurves [[buffer(5)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(6)]],
  device const float *paperScanDensityData [[buffer(7)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_layers_from_density_impl(
    filmDensity,
    layerOut,
    params,
    dims,
    curveInfo,
    densityCurves,
    spectralInfo,
    paperScanDensityData,
    gid,
    false
  );
}

kernel void spektrafilm_grain_synthesis_layers_from_density_fixed_radius(
  device const float4 *filmDensity [[buffer(0)]],
  device float *layerOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &curveInfo [[buffer(4)]],
  device const float *densityCurves [[buffer(5)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(6)]],
  device const float *paperScanDensityData [[buffer(7)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_layers_from_density_impl(
    filmDensity,
    layerOut,
    params,
    dims,
    curveInfo,
    densityCurves,
    spectralInfo,
    paperScanDensityData,
    gid,
    true
  );
}

static void spektra_grain_synthesis_target_density_impl(
  device const float4 *filmDensity,
  device float *targetOut,
  constant SpektraKernelParams &params,
  constant uint2 &dims,
  constant SpektraCurveInfo &curveInfo,
  device const float *densityCurves,
  constant SpektraSpectralInfo &spectralInfo,
  device const float *paperScanDensityData,
  uint3 gid,
  uint maxComponents
) {
  if (gid.x >= dims.x || gid.y >= dims.y || gid.z >= maxComponents) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const uint component = gid.z;
  const uint layer = component / 3u;
  const uint channel = component - layer * 3u;
  if (params.grainSynthesisLayered == 0u && layer > 0u) {
    targetOut[index * 9u + component] = 0.0;
    return;
  }

  device const float *paperBaseDensity = paperScanDensityData + spectralInfo.filmWavelengthCount * 3u;
  device const float *filmDensityCurveLayers = paperBaseDensity + spectralInfo.filmWavelengthCount;
  const float2 centerUm = spektra_output_pixel_film_um(gid.xy, params, dims);
  targetOut[index * 9u + component] = spektra_grain_synthesis_density_at_um(
    filmDensity,
    centerUm,
    layer,
    channel,
    params,
    dims,
    curveInfo,
    spectralInfo,
    densityCurves,
    filmDensityCurveLayers
  );
}

kernel void spektrafilm_grain_synthesis_target_density(
  device const float4 *filmDensity [[buffer(0)]],
  device float *targetOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &curveInfo [[buffer(4)]],
  device const float *densityCurves [[buffer(5)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(6)]],
  device const float *paperScanDensityData [[buffer(7)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_target_density_impl(
    filmDensity,
    targetOut,
    params,
    dims,
    curveInfo,
    densityCurves,
    spectralInfo,
    paperScanDensityData,
    gid,
    9u
  );
}

kernel void spektrafilm_grain_synthesis_target_density_nonlayered(
  device const float4 *filmDensity [[buffer(0)]],
  device float *targetOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &curveInfo [[buffer(4)]],
  device const float *densityCurves [[buffer(5)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(6)]],
  device const float *paperScanDensityData [[buffer(7)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_target_density_impl(
    filmDensity,
    targetOut,
    params,
    dims,
    curveInfo,
    densityCurves,
    spectralInfo,
    paperScanDensityData,
    gid,
    3u
  );
}

static void spektra_grain_synthesis_target_density_half_impl(
  device const float4 *filmDensity,
  device half *targetOut,
  constant SpektraKernelParams &params,
  constant uint2 &dims,
  constant SpektraCurveInfo &curveInfo,
  device const float *densityCurves,
  constant SpektraSpectralInfo &spectralInfo,
  device const float *paperScanDensityData,
  uint3 gid,
  uint maxComponents
) {
  if (gid.x >= dims.x || gid.y >= dims.y || gid.z >= maxComponents) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const uint component = gid.z;
  const uint layer = component / 3u;
  const uint channel = component - layer * 3u;
  if (params.grainSynthesisLayered == 0u && layer > 0u) {
    targetOut[index * 9u + component] = half(0.0);
    return;
  }

  device const float *paperBaseDensity = paperScanDensityData + spectralInfo.filmWavelengthCount * 3u;
  device const float *filmDensityCurveLayers = paperBaseDensity + spectralInfo.filmWavelengthCount;
  const float2 centerUm = spektra_output_pixel_film_um(gid.xy, params, dims);
  targetOut[index * 9u + component] = half(spektra_grain_synthesis_density_at_um(
    filmDensity,
    centerUm,
    layer,
    channel,
    params,
    dims,
    curveInfo,
    spectralInfo,
    densityCurves,
    filmDensityCurveLayers
  ));
}

kernel void spektrafilm_grain_synthesis_target_density_half(
  device const float4 *filmDensity [[buffer(0)]],
  device half *targetOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &curveInfo [[buffer(4)]],
  device const float *densityCurves [[buffer(5)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(6)]],
  device const float *paperScanDensityData [[buffer(7)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_target_density_half_impl(
    filmDensity,
    targetOut,
    params,
    dims,
    curveInfo,
    densityCurves,
    spectralInfo,
    paperScanDensityData,
    gid,
    9u
  );
}

kernel void spektrafilm_grain_synthesis_target_density_nonlayered_half(
  device const float4 *filmDensity [[buffer(0)]],
  device half *targetOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &curveInfo [[buffer(4)]],
  device const float *densityCurves [[buffer(5)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(6)]],
  device const float *paperScanDensityData [[buffer(7)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_target_density_half_impl(
    filmDensity,
    targetOut,
    params,
    dims,
    curveInfo,
    densityCurves,
    spectralInfo,
    paperScanDensityData,
    gid,
    3u
  );
}

static void spektra_grain_synthesis_target_density_texture_impl(
  device const float4 *filmDensity,
  texture2d_array<half, access::write> targetOut,
  constant SpektraKernelParams &params,
  constant uint2 &dims,
  constant SpektraCurveInfo &curveInfo,
  device const float *densityCurves,
  constant SpektraSpectralInfo &spectralInfo,
  device const float *paperScanDensityData,
  uint3 gid,
  uint maxComponents
) {
  if (gid.x >= dims.x || gid.y >= dims.y || gid.z >= maxComponents) {
    return;
  }
  const uint component = gid.z;
  const uint layer = component / 3u;
  const uint channel = component - layer * 3u;
  if (params.grainSynthesisLayered == 0u && layer > 0u) {
    targetOut.write(half4(half(0.0)), gid.xy, component);
    return;
  }

  device const float *paperBaseDensity = paperScanDensityData + spectralInfo.filmWavelengthCount * 3u;
  device const float *filmDensityCurveLayers = paperBaseDensity + spectralInfo.filmWavelengthCount;
  const float2 centerUm = spektra_output_pixel_film_um(gid.xy, params, dims);
  const half targetDensity = half(spektra_grain_synthesis_density_at_um(
    filmDensity,
    centerUm,
    layer,
    channel,
    params,
    dims,
    curveInfo,
    spectralInfo,
    densityCurves,
    filmDensityCurveLayers
  ));
  targetOut.write(half4(targetDensity, half(0.0), half(0.0), half(0.0)), gid.xy, component);
}

kernel void spektrafilm_grain_synthesis_target_density_r16_texture_array(
  device const float4 *filmDensity [[buffer(0)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &curveInfo [[buffer(4)]],
  device const float *densityCurves [[buffer(5)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(6)]],
  device const float *paperScanDensityData [[buffer(7)]],
  texture2d_array<half, access::write> targetOut [[texture(0)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_target_density_texture_impl(
    filmDensity,
    targetOut,
    params,
    dims,
    curveInfo,
    densityCurves,
    spectralInfo,
    paperScanDensityData,
    gid,
    9u
  );
}

kernel void spektrafilm_grain_synthesis_target_density_nonlayered_r16_texture_array(
  device const float4 *filmDensity [[buffer(0)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &curveInfo [[buffer(4)]],
  device const float *densityCurves [[buffer(5)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(6)]],
  device const float *paperScanDensityData [[buffer(7)]],
  texture2d_array<half, access::write> targetOut [[texture(0)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_target_density_texture_impl(
    filmDensity,
    targetOut,
    params,
    dims,
    curveInfo,
    densityCurves,
    spectralInfo,
    paperScanDensityData,
    gid,
    3u
  );
}

static void spektra_grain_synthesis_layers_from_target_density_impl(
  device const float *targetDensities,
  device float *layerOut,
  constant SpektraKernelParams &params,
  constant uint2 &dims,
  device const SpektraGrainSynthesisComponentInfo *componentInfo,
  device const float2 *sampleOffsets,
  device const float *radiusLut,
  device const int2 *cellOffsets,
  uint3 gid,
  bool fixedRadius,
  uint maxComponents
) {
  if (gid.x >= dims.x || gid.y >= dims.y || gid.z >= maxComponents) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const uint component = gid.z;
  const SpektraGrainSynthesisComponentInfo eval = componentInfo[component];
  if (eval.active == 0u || eval.sampleCount == 0u) {
    layerOut[index * 9u + component] = 0.0;
    return;
  }

  const float sigmaUm = max(params.grainSynthesisObservationSigmaUm, 0.0);
  const float2 centerUm = spektra_output_pixel_film_um(gid.xy, params, dims);
  const float targetCenterDensity = max(targetDensities[index * 9u + component], 0.0);
  if (targetCenterDensity <= 1.0e-7 && sigmaUm <= 1.0e-6) {
    layerOut[index * 9u + component] = 0.0;
    return;
  }

  const uint requestedSamples = min(eval.sampleCount, kSpektraGrainSynthesisMaxSamples);
  const uint sampleCount = spektra_grain_synthesis_adaptive_sample_count(targetCenterDensity, requestedSamples);
  float covered = 0.0;
  for (uint sample = 0u; sample < sampleCount; ++sample) {
    const float2 sampleOffset = spektra_grain_synthesis_sample_offset(
      sampleOffsets,
      eval,
      component,
      sample,
      sampleCount,
      index
    );
    covered += spektra_grain_synthesis_indicator_fast(
      targetDensities,
      centerUm + sampleOffset,
      component,
      eval,
      fixedRadius,
      params,
      dims,
      radiusLut,
      cellOffsets
    ) ? 1.0 : 0.0;
  }

  const float epsilon = max(params.grainSynthesisCoverageEpsilon, 1.0e-8);
  const float coverage = clamp(covered / max(float(sampleCount), 1.0), 0.0, 1.0 - epsilon);
  layerOut[index * 9u + component] = -log(max(1.0 - coverage, epsilon)) / 2.302585093;
}

kernel void spektrafilm_grain_synthesis_layers_from_target_density(
  device const float *targetDensities [[buffer(0)]],
  device float *layerOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  device const SpektraGrainSynthesisComponentInfo *componentInfo [[buffer(4)]],
  device const float2 *sampleOffsets [[buffer(5)]],
  device const float *radiusLut [[buffer(6)]],
  device const int2 *cellOffsets [[buffer(7)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_layers_from_target_density_impl(
    targetDensities,
    layerOut,
    params,
    dims,
    componentInfo,
    sampleOffsets,
    radiusLut,
    cellOffsets,
    gid,
    false,
    9u
  );
}

kernel void spektrafilm_grain_synthesis_layers_from_target_density_fixed_radius(
  device const float *targetDensities [[buffer(0)]],
  device float *layerOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  device const SpektraGrainSynthesisComponentInfo *componentInfo [[buffer(4)]],
  device const float2 *sampleOffsets [[buffer(5)]],
  device const float *radiusLut [[buffer(6)]],
  device const int2 *cellOffsets [[buffer(7)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_layers_from_target_density_impl(
    targetDensities,
    layerOut,
    params,
    dims,
    componentInfo,
    sampleOffsets,
    radiusLut,
    cellOffsets,
    gid,
    true,
    9u
  );
}

kernel void spektrafilm_grain_synthesis_layers_from_target_density_nonlayered(
  device const float *targetDensities [[buffer(0)]],
  device float *layerOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  device const SpektraGrainSynthesisComponentInfo *componentInfo [[buffer(4)]],
  device const float2 *sampleOffsets [[buffer(5)]],
  device const float *radiusLut [[buffer(6)]],
  device const int2 *cellOffsets [[buffer(7)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_layers_from_target_density_impl(
    targetDensities,
    layerOut,
    params,
    dims,
    componentInfo,
    sampleOffsets,
    radiusLut,
    cellOffsets,
    gid,
    false,
    3u
  );
}

kernel void spektrafilm_grain_synthesis_layers_from_target_density_nonlayered_fixed_radius(
  device const float *targetDensities [[buffer(0)]],
  device float *layerOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  device const SpektraGrainSynthesisComponentInfo *componentInfo [[buffer(4)]],
  device const float2 *sampleOffsets [[buffer(5)]],
  device const float *radiusLut [[buffer(6)]],
  device const int2 *cellOffsets [[buffer(7)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_layers_from_target_density_impl(
    targetDensities,
    layerOut,
    params,
    dims,
    componentInfo,
    sampleOffsets,
    radiusLut,
    cellOffsets,
    gid,
    true,
    3u
  );
}

static void spektra_grain_synthesis_layers_from_target_density_half_impl(
  device const half *targetDensities,
  device float *layerOut,
  constant SpektraKernelParams &params,
  constant uint2 &dims,
  device const SpektraGrainSynthesisComponentInfo *componentInfo,
  device const float2 *sampleOffsets,
  device const float *radiusLut,
  device const int2 *cellOffsets,
  uint3 gid,
  bool fixedRadius,
  uint maxComponents
) {
  if (gid.x >= dims.x || gid.y >= dims.y || gid.z >= maxComponents) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const uint component = gid.z;
  const SpektraGrainSynthesisComponentInfo eval = componentInfo[component];
  if (eval.active == 0u || eval.sampleCount == 0u) {
    layerOut[index * 9u + component] = 0.0f;
    return;
  }

  const float sigmaUm = max(params.grainSynthesisObservationSigmaUm, 0.0f);
  const float2 centerUm = spektra_output_pixel_film_um(gid.xy, params, dims);
  const float targetCenterDensity = max(float(targetDensities[index * 9u + component]), 0.0f);
  if (targetCenterDensity <= 1.0e-7f && sigmaUm <= 1.0e-6f) {
    layerOut[index * 9u + component] = 0.0f;
    return;
  }

  const uint requestedSamples = min(eval.sampleCount, kSpektraGrainSynthesisMaxSamples);
  const uint sampleCount = spektra_grain_synthesis_adaptive_sample_count(targetCenterDensity, requestedSamples);
  float covered = 0.0f;
  for (uint sample = 0u; sample < sampleCount; ++sample) {
    const float2 sampleOffset = spektra_grain_synthesis_sample_offset(
      sampleOffsets,
      eval,
      component,
      sample,
      sampleCount,
      index
    );
    covered += spektra_grain_synthesis_indicator_fast(
      targetDensities,
      centerUm + sampleOffset,
      component,
      eval,
      fixedRadius,
      params,
      dims,
      radiusLut,
      cellOffsets
    ) ? 1.0f : 0.0f;
  }

  const float epsilon = max(params.grainSynthesisCoverageEpsilon, 1.0e-8f);
  const float coverage = clamp(covered / max(float(sampleCount), 1.0f), 0.0f, 1.0f - epsilon);
  layerOut[index * 9u + component] = -log(max(1.0f - coverage, epsilon)) / 2.302585093f;
}

kernel void spektrafilm_grain_synthesis_layers_from_target_density_half(
  device const half *targetDensities [[buffer(0)]],
  device float *layerOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  device const SpektraGrainSynthesisComponentInfo *componentInfo [[buffer(4)]],
  device const float2 *sampleOffsets [[buffer(5)]],
  device const float *radiusLut [[buffer(6)]],
  device const int2 *cellOffsets [[buffer(7)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_layers_from_target_density_half_impl(
    targetDensities,
    layerOut,
    params,
    dims,
    componentInfo,
    sampleOffsets,
    radiusLut,
    cellOffsets,
    gid,
    false,
    9u
  );
}

kernel void spektrafilm_grain_synthesis_layers_from_target_density_half_fixed_radius(
  device const half *targetDensities [[buffer(0)]],
  device float *layerOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  device const SpektraGrainSynthesisComponentInfo *componentInfo [[buffer(4)]],
  device const float2 *sampleOffsets [[buffer(5)]],
  device const float *radiusLut [[buffer(6)]],
  device const int2 *cellOffsets [[buffer(7)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_layers_from_target_density_half_impl(
    targetDensities,
    layerOut,
    params,
    dims,
    componentInfo,
    sampleOffsets,
    radiusLut,
    cellOffsets,
    gid,
    true,
    9u
  );
}

kernel void spektrafilm_grain_synthesis_layers_from_target_density_nonlayered_half(
  device const half *targetDensities [[buffer(0)]],
  device float *layerOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  device const SpektraGrainSynthesisComponentInfo *componentInfo [[buffer(4)]],
  device const float2 *sampleOffsets [[buffer(5)]],
  device const float *radiusLut [[buffer(6)]],
  device const int2 *cellOffsets [[buffer(7)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_layers_from_target_density_half_impl(
    targetDensities,
    layerOut,
    params,
    dims,
    componentInfo,
    sampleOffsets,
    radiusLut,
    cellOffsets,
    gid,
    false,
    3u
  );
}

kernel void spektrafilm_grain_synthesis_layers_from_target_density_nonlayered_half_fixed_radius(
  device const half *targetDensities [[buffer(0)]],
  device float *layerOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  device const SpektraGrainSynthesisComponentInfo *componentInfo [[buffer(4)]],
  device const float2 *sampleOffsets [[buffer(5)]],
  device const float *radiusLut [[buffer(6)]],
  device const int2 *cellOffsets [[buffer(7)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_layers_from_target_density_half_impl(
    targetDensities,
    layerOut,
    params,
    dims,
    componentInfo,
    sampleOffsets,
    radiusLut,
    cellOffsets,
    gid,
    true,
    3u
  );
}

static void spektra_grain_synthesis_layers_from_target_density_texture_impl(
  texture2d_array<half, access::read> targetDensities,
  device float *layerOut,
  constant SpektraKernelParams &params,
  constant uint2 &dims,
  device const SpektraGrainSynthesisComponentInfo *componentInfo,
  device const float2 *sampleOffsets,
  device const float *radiusLut,
  device const int2 *cellOffsets,
  uint3 gid,
  bool fixedRadius,
  uint maxComponents
) {
  if (gid.x >= dims.x || gid.y >= dims.y || gid.z >= maxComponents) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const uint component = gid.z;
  const SpektraGrainSynthesisComponentInfo eval = componentInfo[component];
  if (eval.active == 0u || eval.sampleCount == 0u) {
    layerOut[index * 9u + component] = 0.0f;
    return;
  }

  const float sigmaUm = max(params.grainSynthesisObservationSigmaUm, 0.0f);
  const float2 centerUm = spektra_output_pixel_film_um(gid.xy, params, dims);
  const float targetCenterDensity = max(float(targetDensities.read(gid.xy, component).r), 0.0f);
  if (targetCenterDensity <= 1.0e-7f && sigmaUm <= 1.0e-6f) {
    layerOut[index * 9u + component] = 0.0f;
    return;
  }

  const uint requestedSamples = min(eval.sampleCount, kSpektraGrainSynthesisMaxSamples);
  const uint sampleCount = spektra_grain_synthesis_adaptive_sample_count(targetCenterDensity, requestedSamples);
  float covered = 0.0f;
  for (uint sample = 0u; sample < sampleCount; ++sample) {
    const float2 sampleOffset = spektra_grain_synthesis_sample_offset(
      sampleOffsets,
      eval,
      component,
      sample,
      sampleCount,
      index
    );
    covered += spektra_grain_synthesis_indicator_fast(
      targetDensities,
      centerUm + sampleOffset,
      component,
      eval,
      fixedRadius,
      params,
      dims,
      radiusLut,
      cellOffsets
    ) ? 1.0f : 0.0f;
  }

  const float epsilon = max(params.grainSynthesisCoverageEpsilon, 1.0e-8f);
  const float coverage = clamp(covered / max(float(sampleCount), 1.0f), 0.0f, 1.0f - epsilon);
  layerOut[index * 9u + component] = -log(max(1.0f - coverage, epsilon)) / 2.302585093f;
}

kernel void spektrafilm_grain_synthesis_layers_from_target_density_r16_texture_array(
  device float *layerOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  device const SpektraGrainSynthesisComponentInfo *componentInfo [[buffer(4)]],
  device const float2 *sampleOffsets [[buffer(5)]],
  device const float *radiusLut [[buffer(6)]],
  device const int2 *cellOffsets [[buffer(7)]],
  texture2d_array<half, access::read> targetDensities [[texture(0)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_layers_from_target_density_texture_impl(
    targetDensities,
    layerOut,
    params,
    dims,
    componentInfo,
    sampleOffsets,
    radiusLut,
    cellOffsets,
    gid,
    false,
    9u
  );
}

kernel void spektrafilm_grain_synthesis_layers_from_target_density_r16_texture_array_fixed_radius(
  device float *layerOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  device const SpektraGrainSynthesisComponentInfo *componentInfo [[buffer(4)]],
  device const float2 *sampleOffsets [[buffer(5)]],
  device const float *radiusLut [[buffer(6)]],
  device const int2 *cellOffsets [[buffer(7)]],
  texture2d_array<half, access::read> targetDensities [[texture(0)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_layers_from_target_density_texture_impl(
    targetDensities,
    layerOut,
    params,
    dims,
    componentInfo,
    sampleOffsets,
    radiusLut,
    cellOffsets,
    gid,
    true,
    9u
  );
}

kernel void spektrafilm_grain_synthesis_layers_from_target_density_nonlayered_r16_texture_array(
  device float *layerOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  device const SpektraGrainSynthesisComponentInfo *componentInfo [[buffer(4)]],
  device const float2 *sampleOffsets [[buffer(5)]],
  device const float *radiusLut [[buffer(6)]],
  device const int2 *cellOffsets [[buffer(7)]],
  texture2d_array<half, access::read> targetDensities [[texture(0)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_layers_from_target_density_texture_impl(
    targetDensities,
    layerOut,
    params,
    dims,
    componentInfo,
    sampleOffsets,
    radiusLut,
    cellOffsets,
    gid,
    false,
    3u
  );
}

kernel void spektrafilm_grain_synthesis_layers_from_target_density_nonlayered_r16_texture_array_fixed_radius(
  device float *layerOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  device const SpektraGrainSynthesisComponentInfo *componentInfo [[buffer(4)]],
  device const float2 *sampleOffsets [[buffer(5)]],
  device const float *radiusLut [[buffer(6)]],
  device const int2 *cellOffsets [[buffer(7)]],
  texture2d_array<half, access::read> targetDensities [[texture(0)]],
  uint3 gid [[thread_position_in_grid]]
) {
  spektra_grain_synthesis_layers_from_target_density_texture_impl(
    targetDensities,
    layerOut,
    params,
    dims,
    componentInfo,
    sampleOffsets,
    radiusLut,
    cellOffsets,
    gid,
    true,
    3u
  );
}

kernel void spektrafilm_grain_synthesis_resolve_density(
  device const float *layerIn [[buffer(0)]],
  device const float4 *microIn [[buffer(1)]],
  device const float4 *densityIn [[buffer(2)]],
  device float4 *densityOut [[buffer(3)]],
  constant SpektraKernelParams &params [[buffer(4)]],
  constant uint2 &dims [[buffer(5)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  float3 density = float3(0.0);
  if (params.grainSynthesisLayered == 0u) {
    density = float3(
      max(layerIn[index * 9u], 0.0),
      max(layerIn[index * 9u + 1u], 0.0),
      max(layerIn[index * 9u + 2u], 0.0)
    );
  } else {
    for (uint layer = 0u; layer < 3u; ++layer) {
      density.r += max(layerIn[index * 9u + layer * 3u], 0.0);
      density.g += max(layerIn[index * 9u + layer * 3u + 1u], 0.0);
      density.b += max(layerIn[index * 9u + layer * 3u + 2u], 0.0);
    }
  }
  density *= max(microIn[index].rgb, float3(0.0));
  const float4 source = densityIn[index];
  const float amount = clamp(params.grainSynthesisAmount, 0.0, 3.0);
  densityOut[index] = float4(max(source.rgb + (density - source.rgb) * amount, float3(0.0)), source.a);
}

kernel void spektrafilm_grain_layer_blur_x(
  device const float *layerIn [[buffer(0)]],
  device float *layerOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &curveInfo [[buffer(4)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(5)]],
  device const float *paperScanDensityData [[buffer(6)]],
  constant uint &useRecurrence [[buffer(7)]],
  uint3 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y || gid.z >= 9u) {
    return;
  }
  const uint component = gid.z;
  const uint layer = component / 3u;
  const uint channel = component - layer * 3u;
  const uint index = gid.y * dims.x + gid.x;
  if (params.grainModel == 2 && params.grainSynthesisLayered == 0u && layer > 0u) {
    layerOut[index * 9u + component] = 0.0;
    return;
  }
  device const float *paperBaseDensity = paperScanDensityData + spectralInfo.filmWavelengthCount * 3u;
  device const float *filmDensityCurveLayers = paperBaseDensity + spectralInfo.filmWavelengthCount;
  device const float *filmDensityCurveLayerMaxima = filmDensityCurveLayers + curveInfo.exposureCount * 9u;
  const float sigma = spektra_grain_layer_blur_sigma(layer, channel, params, filmDensityCurveLayerMaxima);
  if (sigma <= 1.0e-4) {
    layerOut[index * 9u + component] = layerIn[index * 9u + component];
    return;
  }
  if (useRecurrence != 0u) {
    layerOut[index * 9u + component] = spektra_layer_gaussian_sample_x_limited(
      layerIn, dims.x, dims.y, gid.xy, component, sigma, 64);
    return;
  }
  const int radius = min(int(ceil(3.0 * sigma)), 64);
  float value = 0.0;
  float weightSum = 0.0;
  for (int offset = -radius; offset <= radius; ++offset) {
    const float weight = spektra_gaussian_weight(float(offset), sigma);
    value += weight * spektra_layer_buffer_sample(layerIn, dims.x, dims.y, int(gid.x) + offset, int(gid.y), component);
    weightSum += weight;
  }
  layerOut[index * 9u + component] = value / max(weightSum, 1.0e-8);
}

kernel void spektrafilm_grain_layer_blur_y(
  device const float *layerIn [[buffer(0)]],
  device float *layerOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &curveInfo [[buffer(4)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(5)]],
  device const float *paperScanDensityData [[buffer(6)]],
  constant uint &useRecurrence [[buffer(7)]],
  uint3 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y || gid.z >= 9u) {
    return;
  }
  const uint component = gid.z;
  const uint layer = component / 3u;
  const uint channel = component - layer * 3u;
  const uint index = gid.y * dims.x + gid.x;
  if (params.grainModel == 2 && params.grainSynthesisLayered == 0u && layer > 0u) {
    layerOut[index * 9u + component] = 0.0;
    return;
  }
  device const float *paperBaseDensity = paperScanDensityData + spectralInfo.filmWavelengthCount * 3u;
  device const float *filmDensityCurveLayers = paperBaseDensity + spectralInfo.filmWavelengthCount;
  device const float *filmDensityCurveLayerMaxima = filmDensityCurveLayers + curveInfo.exposureCount * 9u;
  const float sigma = spektra_grain_layer_blur_sigma(layer, channel, params, filmDensityCurveLayerMaxima);
  if (sigma <= 1.0e-4) {
    layerOut[index * 9u + component] = layerIn[index * 9u + component];
    return;
  }
  if (useRecurrence != 0u) {
    layerOut[index * 9u + component] = spektra_layer_gaussian_sample_y_limited(
      layerIn, dims.x, dims.y, gid.xy, component, sigma, 64);
    return;
  }
  const int radius = min(int(ceil(3.0 * sigma)), 64);
  float value = 0.0;
  float weightSum = 0.0;
  for (int offset = -radius; offset <= radius; ++offset) {
    const float weight = spektra_gaussian_weight(float(offset), sigma);
    value += weight * spektra_layer_buffer_sample(layerIn, dims.x, dims.y, int(gid.x), int(gid.y) + offset, component);
    weightSum += weight;
  }
  layerOut[index * 9u + component] = value / max(weightSum, 1.0e-8);
}

kernel void spektrafilm_grain_microstructure_source(
  device float4 *microOut [[buffer(0)]],
  constant SpektraKernelParams &params [[buffer(1)]],
  constant uint2 &dims [[buffer(2)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float sigma = spektra_microstructure_sigma(params);
  if (params.grainSublayersEnabled == 0u || sigma <= 0.05 || params.grainMicroStructureScale <= 0.0) {
    microOut[index] = float4(1.0);
    return;
  }
  const uint frameSeed = params.grainAnimate != 0 ? uint(floor(params.time * 24.0 + 0.5)) : 0u;
  const float2 filmUm = spektra_output_pixel_film_um(gid, params, dims);
  const uint baseSeed = spektra_film_cell_seed(
    filmUm,
    max(params.grainMicroStructureScale, 1.0e-4),
    params.grainSeed ^ frameSeed ^ 0x23d3c1f1u ^ 0xa349b329u
  );
  const float logSigma = sqrt(log(1.0 + sigma * sigma));
  const float logMean = -0.5 * logSigma * logSigma;
  microOut[index] = float4(
    exp(logMean + logSigma * spektra_gaussian(baseSeed ^ 0x165667b1u)),
    exp(logMean + logSigma * spektra_gaussian(baseSeed ^ 0x27d4eb2du)),
    exp(logMean + logSigma * spektra_gaussian(baseSeed ^ 0x85ebca6bu)),
    1.0
  );
}

kernel void spektrafilm_grain_micro_blur_x(
  device const float4 *microIn [[buffer(0)]],
  device float4 *microOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant uint &useRecurrence [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float sigma = spektra_microstructure_blur_sigma(params);
  if (params.grainSublayersEnabled == 0u || sigma <= 0.4) {
    microOut[index] = microIn[index];
    return;
  }
  if (useRecurrence != 0u) {
    microOut[index] = spektra_scalar_gaussian_sample_x_limited(microIn, dims.x, dims.y, gid, sigma, 64);
    return;
  }
  const int radius = min(int(ceil(3.0 * sigma)), 64);
  float4 value = float4(0.0);
  float weightSum = 0.0;
  for (int offset = -radius; offset <= radius; ++offset) {
    const float weight = spektra_gaussian_weight(float(offset), sigma);
    value += weight * spektra_float4_buffer_sample(microIn, dims.x, dims.y, int(gid.x) + offset, int(gid.y));
    weightSum += weight;
  }
  microOut[index] = value / max(weightSum, 1.0e-8);
}

kernel void spektrafilm_grain_micro_blur_y(
  device const float4 *microIn [[buffer(0)]],
  device float4 *microOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant uint &useRecurrence [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float sigma = spektra_microstructure_blur_sigma(params);
  if (params.grainSublayersEnabled == 0u || sigma <= 0.4) {
    microOut[index] = microIn[index];
    return;
  }
  if (useRecurrence != 0u) {
    microOut[index] = spektra_scalar_gaussian_sample_y_limited(microIn, dims.x, dims.y, gid, sigma, 64);
    return;
  }
  const int radius = min(int(ceil(3.0 * sigma)), 64);
  float4 value = float4(0.0);
  float weightSum = 0.0;
  for (int offset = -radius; offset <= radius; ++offset) {
    const float weight = spektra_gaussian_weight(float(offset), sigma);
    value += weight * spektra_float4_buffer_sample(microIn, dims.x, dims.y, int(gid.x), int(gid.y) + offset);
    weightSum += weight;
  }
  microOut[index] = value / max(weightSum, 1.0e-8);
}

kernel void spektrafilm_grain_resolve_density(
  device const float *layerIn [[buffer(0)]],
  device const float4 *microIn [[buffer(1)]],
  device const float4 *source [[buffer(2)]],
  device float4 *densityOut [[buffer(3)]],
  constant SpektraKernelParams &params [[buffer(4)]],
  constant uint2 &dims [[buffer(5)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  if (params.grainSublayersEnabled == 0u) {
    densityOut[index] = float4(
      max(layerIn[index * 9u], 0.0),
      max(layerIn[index * 9u + 1u], 0.0),
      max(layerIn[index * 9u + 2u], 0.0),
      source[index].a
    );
    return;
  }
  const float3 densityMin = float3(
    spektra_channel_density_min(0u, params),
    spektra_channel_density_min(1u, params),
    spektra_channel_density_min(2u, params)
  );
  float3 density = float3(0.0);
  for (uint layer = 0u; layer < 3u; ++layer) {
    density.r += layerIn[index * 9u + layer * 3u];
    density.g += layerIn[index * 9u + layer * 3u + 1u];
    density.b += layerIn[index * 9u + layer * 3u + 2u];
  }
  density *= microIn[index].rgb;
  densityOut[index] = float4(max(density - densityMin, float3(0.0)), source[index].a);
}

kernel void spektrafilm_grain_density_blur_x(
  device const float4 *densityIn [[buffer(0)]],
  device float4 *densityOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant uint &useRecurrence [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float sigma = spektra_grain_final_blur_um(params) / max(params.filmPixelSizeUm, 1.0e-6);
  if (sigma <= 0.0 || (params.grainSublayersEnabled == 0u && sigma <= 0.4)) {
    densityOut[index] = densityIn[index];
    return;
  }
  if (useRecurrence != 0u) {
    densityOut[index] = spektra_scalar_gaussian_sample_x_limited(densityIn, dims.x, dims.y, gid, sigma, 64);
    return;
  }
  const int radius = min(int(ceil(3.0 * sigma)), 64);
  float4 value = float4(0.0);
  float weightSum = 0.0;
  for (int offset = -radius; offset <= radius; ++offset) {
    const float weight = spektra_gaussian_weight(float(offset), sigma);
    value += weight * spektra_float4_buffer_sample(densityIn, dims.x, dims.y, int(gid.x) + offset, int(gid.y));
    weightSum += weight;
  }
  densityOut[index] = value / max(weightSum, 1.0e-8);
}

kernel void spektrafilm_grain_density_blur_y(
  device const float4 *densityIn [[buffer(0)]],
  device float4 *densityOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant uint &useRecurrence [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float sigma = spektra_grain_final_blur_um(params) / max(params.filmPixelSizeUm, 1.0e-6);
  if (sigma <= 0.0 || (params.grainSublayersEnabled == 0u && sigma <= 0.4)) {
    densityOut[index] = densityIn[index];
    return;
  }
  if (useRecurrence != 0u) {
    densityOut[index] = spektra_scalar_gaussian_sample_y_limited(densityIn, dims.x, dims.y, gid, sigma, 64);
    return;
  }
  const int radius = min(int(ceil(3.0 * sigma)), 64);
  float4 value = float4(0.0);
  float weightSum = 0.0;
  for (int offset = -radius; offset <= radius; ++offset) {
    const float weight = spektra_gaussian_weight(float(offset), sigma);
    value += weight * spektra_float4_buffer_sample(densityIn, dims.x, dims.y, int(gid.x), int(gid.y) + offset);
    weightSum += weight;
  }
  densityOut[index] = value / max(weightSum, 1.0e-8);
}

kernel void spektrafilm_grain_apply_controls(
  device const float4 *baseDensity [[buffer(0)]],
  device const float4 *grainedDensity [[buffer(1)]],
  device float4 *densityOut [[buffer(2)]],
  constant SpektraKernelParams &params [[buffer(3)]],
  constant uint2 &dims [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 base = baseDensity[index];
  const float4 grained = grainedDensity[index];
  densityOut[index] = float4(
    spektra_apply_grain_controls(base.rgb, grained.rgb, params),
    grained.a
  );
}

kernel void spektrafilm_final_from_film_density(
  device const float4 *filmDensity [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &filmCurveInfo [[buffer(4)]],
  device const float *filmLogExposure [[buffer(5)]],
  device const float *filmDensityCurves [[buffer(6)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(7)]],
  constant SpektraColorInfo &colorInfo [[buffer(8)]],
  device const uint *transferKinds [[buffer(9)]],
  constant SpektraCurveInfo &paperCurveInfo [[buffer(10)]],
  device const float *paperLogExposure [[buffer(11)]],
  device const float *paperDensityCurves [[buffer(12)]],
  device const float *filmLogSensitivity [[buffer(13)]],
  device const float *bandpassHanatos2025 [[buffer(14)]],
  device const float *hanatosSpectraLut [[buffer(15)]],
  device const float *mallettBasisIlluminant [[buffer(16)]],
  device const float *inputToReferenceXyz [[buffer(17)]],
  device const float *filmChannelDensity [[buffer(18)]],
  device const float4 *filmSpectralDensity [[buffer(19)]],
  device const float4 *filteredEnlargerResponse [[buffer(20)]],
  device const float *thKg3Illuminant [[buffer(21)]],
  device const float *customEnlargerFilters [[buffer(22)]],
  device const float *neutralPrintFilters [[buffer(23)]],
  device const float *academyPrinterDensityData [[buffer(24)]],
  device const float4 *paperSpectralDensity [[buffer(25)]],
  device const float *scanProducts [[buffer(26)]],
  device const float *scanToOutputRgbData [[buffer(27)]],
  device const float *encodeLuts [[buffer(28)]],
  constant SpektraFrameConstants &frameConstants [[buffer(29)]],
  constant uint &encodeOutput [[buffer(30)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  float4 pixel = filmDensity[index];
  device const float4 *packedScanProducts = (device const float4 *)scanProducts;
  device const float4 *filmPackedScanProducts = packedScanProducts;
  device const float4 *paperPackedScanProducts = packedScanProducts + spectralInfo.filmWavelengthCount;
  device const float *legacyScanProducts = scanProducts + spectralInfo.filmWavelengthCount * 8u;
  device const float *filmLegacyScanProducts = legacyScanProducts;
  device const float *paperLegacyScanProducts = legacyScanProducts + spectralInfo.filmWavelengthCount * 3u;
  device const float *scanInverseNormalizations = legacyScanProducts + spectralInfo.filmWavelengthCount * 6u;
  device const float *filmScanToOutputRgb = scanToOutputRgbData;
  device const float *paperScanToOutputRgb = scanToOutputRgbData + colorInfo.colorSpaceCount * 9u;

  const bool finalPrintSimulation = params.process == 0;
  const bool finalScanNegative = params.process == 1;
  if (finalPrintSimulation) {
    pixel.rgb = spektra_print_log_raw_with_cached_response(
        pixel.rgb,
        params,
        spectralInfo,
        filmChannelDensity,
        filmSpectralDensity,
        filteredEnlargerResponse,
        academyPrinterDensityData,
        frameConstants.print.x,
        frameConstants.preflash.rgb
      );
  }
  if (finalPrintSimulation) {
    pixel.rgb = spektra_develop_print_density(
      pixel.rgb,
      params,
      spectralInfo,
      paperCurveInfo,
      paperLogExposure,
      paperDensityCurves
    );
  }
  if (finalPrintSimulation) {
    const float3 printDensityCmy = pixel.rgb;
    SpektraScanResult scan = spektra_scan_density_to_output_rgb_linear_y_cached_common(
      printDensityCmy,
      true,
      params,
      colorInfo,
      spectralInfo,
      paperSpectralDensity,
      paperPackedScanProducts,
      paperLegacyScanProducts,
      scanInverseNormalizations[1],
      paperScanToOutputRgb
    );
    pixel.rgb = spektra_apply_print_scan_output_contract(scan, frameConstants, params);
  } else if (finalScanNegative) {
    const float3 filmDensityCmy = pixel.rgb;
    SpektraScanResult scan = spektra_scan_density_to_output_rgb_linear_y_cached_common(
      filmDensityCmy,
      false,
      params,
      colorInfo,
      spectralInfo,
      filmSpectralDensity,
      filmPackedScanProducts,
      filmLegacyScanProducts,
      scanInverseNormalizations[0],
      filmScanToOutputRgb
    );
    pixel.rgb = spektra_apply_film_scan_output_contract(scan, frameConstants, params, spectralInfo);
  }
  if (encodeOutput != 0u && (finalPrintSimulation || finalScanNegative)) {
    pixel.rgb = spektra_finalize_output_rgb(pixel.rgb, params, colorInfo, encodeLuts, transferKinds);
  }
  destination[index] = pixel;
}

kernel void spektrafilm_print_raw_from_film_density(
  device const float4 *filmDensity [[buffer(0)]],
  device float4 *printRawOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &filmCurveInfo [[buffer(4)]],
  device const float *filmLogExposure [[buffer(5)]],
  device const float *filmDensityCurves [[buffer(6)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(7)]],
  constant SpektraColorInfo &colorInfo [[buffer(8)]],
  device const float *filmLogSensitivity [[buffer(9)]],
  device const float *bandpassHanatos2025 [[buffer(10)]],
  device const float *hanatosSpectraLut [[buffer(11)]],
  device const float *mallettBasisIlluminant [[buffer(12)]],
  device const float *inputToReferenceXyz [[buffer(13)]],
  device const float *filmChannelDensity [[buffer(14)]],
  device const float4 *filmSpectralDensity [[buffer(15)]],
  device const float4 *filteredEnlargerResponse [[buffer(16)]],
  device const float *thKg3Illuminant [[buffer(17)]],
  device const float *customEnlargerFilters [[buffer(18)]],
  device const float *neutralPrintFilters [[buffer(19)]],
  device const float *academyPrinterDensityData [[buffer(20)]],
  constant SpektraFrameConstants &frameConstants [[buffer(21)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 density = filmDensity[index];
  const float3 raw = spektra_print_raw_from_film_density_cached(
    density.rgb,
    params,
    spectralInfo,
    filmChannelDensity,
    filmSpectralDensity,
    filteredEnlargerResponse,
    academyPrinterDensityData
  );
  const float3 rawTimed = raw * spektra_apd_printer_timing_exposure_scale(params, spectralInfo, academyPrinterDensityData) * frameConstants.print.x +
    frameConstants.preflash.rgb;
  printRawOut[index] = float4(max(rawTimed * exp2(params.printExposureEv), float3(0.0)), density.a);
}

static float3 spektra_process_negative_hanatos_raw(
  float3 referenceXyz,
  constant SpektraKernelParams &params,
  constant SpektraSpectralInfo &spectralInfo,
  device const float4 *paperHanatosResponse
) {
  const uint compressedOffset = spektra_color_adaptation_enabled(params, kSpektraColorAdaptationInputCompression)
    ? spectralInfo.hanatosWidth * spectralInfo.hanatosHeight
    : 0u;
  return max(spektra_hanatos_raw(referenceXyz, spectralInfo, paperHanatosResponse + compressedOffset), float3(0.0));
}

kernel void spektrafilm_print_raw_from_negative_light(
  device const float4 *source [[buffer(0)]],
  device float4 *printRawOut [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(4)]],
  constant SpektraColorInfo &colorInfo [[buffer(5)]],
  device const float *decodeLuts [[buffer(6)]],
  device const uint *transferKinds [[buffer(7)]],
  device const float *inputToReferenceXyz [[buffer(8)]],
  device const float4 *paperHanatosResponse [[buffer(9)]],
  device const float4 *preflashPaperHanatosResponse [[buffer(10)]],
  device const float *academyPrinterDensityData [[buffer(11)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 pixel = source[index];
  if (spectralInfo.hanatosWidth == 0u ||
      spectralInfo.hanatosHeight == 0u ||
      decodeLuts == nullptr ||
      transferKinds == nullptr ||
      inputToReferenceXyz == nullptr ||
      paperHanatosResponse == nullptr ||
      preflashPaperHanatosResponse == nullptr ||
      academyPrinterDensityData == nullptr) {
    printRawOut[index] = pixel;
    return;
  }

  const float3 decoded = spektra_decode_input_rgb(pixel.rgb, params, colorInfo, decodeLuts, transferKinds);
  const float3 referenceXyz = spektra_mul_color_matrix(decoded, params.inputColorSpace, colorInfo, inputToReferenceXyz);
  const float3 raw = spektra_process_negative_hanatos_raw(referenceXyz, params, spectralInfo, paperHanatosResponse);

  constexpr int kLinearSrgbColorSpace = 17;
  const float3 midgrayXyz = spektra_mul_color_matrix(float3(0.184), kLinearSrgbColorSpace, colorInfo, inputToReferenceXyz);
  const float3 midgrayRaw = max(
    spektra_process_negative_hanatos_raw(midgrayXyz, params, spectralInfo, paperHanatosResponse),
    float3(1.0e-10)
  );
  const float midgrayGeomean = exp((log(midgrayRaw.r) + log(midgrayRaw.g) + log(midgrayRaw.b)) / 3.0);
  const float exposureFactor = 1.0 / max(midgrayGeomean, 1.0e-10);

  const float3 preflashWhiteXyz = spektra_mul_color_matrix(float3(1.0), kLinearSrgbColorSpace, colorInfo, inputToReferenceXyz);
  const float3 preflashRaw = spektra_process_negative_hanatos_raw(
    preflashWhiteXyz,
    params,
    spectralInfo,
    preflashPaperHanatosResponse
  );
  const float3 rawTimed =
    raw *
    spektra_apd_printer_timing_exposure_scale(params, spectralInfo, academyPrinterDensityData) *
    exposureFactor *
    exp2(params.printExposureEv) +
    preflashRaw * exp2(params.printExposureEv);
  printRawOut[index] = float4(max(rawTimed, float3(0.0)), pixel.a);
}

kernel void spektrafilm_print_density_from_print_raw(
  device const float4 *printRaw [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &paperCurveInfo [[buffer(4)]],
  device const float *paperLogExposure [[buffer(5)]],
  device const float *paperDensityCurves [[buffer(6)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(7)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  float4 pixel = printRaw[index];
  pixel.rgb = log10(max(pixel.rgb, float3(0.0)) + float3(1.0e-10));
  pixel.rgb = spektra_develop_print_density(
    pixel.rgb,
    params,
    spectralInfo,
    paperCurveInfo,
    paperLogExposure,
    paperDensityCurves
  );
  destination[index] = pixel;
}

kernel void spektrafilm_profile_print_scan_from_density(
  device const float4 *printDensity [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(4)]],
  constant SpektraColorInfo &colorInfo [[buffer(5)]],
  device const float4 *paperSpectralDensity [[buffer(6)]],
  device const float *scanProducts [[buffer(7)]],
  device const float *scanToOutputRgbData [[buffer(8)]],
  constant SpektraFrameConstants &frameConstants [[buffer(9)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 pixel = printDensity[index];
  device const float4 *packedScanProducts = (device const float4 *)scanProducts;
  device const float4 *paperPackedScanProducts = packedScanProducts + spectralInfo.filmWavelengthCount;
  device const float *legacyScanProducts = scanProducts + spectralInfo.filmWavelengthCount * 8u;
  device const float *paperLegacyScanProducts = legacyScanProducts + spectralInfo.filmWavelengthCount * 3u;
  device const float *scanInverseNormalizations = legacyScanProducts + spectralInfo.filmWavelengthCount * 6u;
  device const float *paperScanToOutputRgb = scanToOutputRgbData + colorInfo.colorSpaceCount * 9u;
  const float3 printDensityCmy = pixel.rgb;
  const SpektraScanResult scan = spektra_scan_density_to_output_rgb_linear_y_cached_common(
    printDensityCmy,
    true,
    params,
    colorInfo,
    spectralInfo,
    paperSpectralDensity,
    paperPackedScanProducts,
    paperLegacyScanProducts,
    scanInverseNormalizations[1],
    paperScanToOutputRgb
  );
  destination[index] = float4(spektra_apply_print_scan_output_contract(scan, frameConstants, params), pixel.a);
}

kernel void spektrafilm_profile_finalize_output(
  device const float4 *linearRgb [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraColorInfo &colorInfo [[buffer(4)]],
  device const uint *transferKinds [[buffer(5)]],
  device const float *encodeLuts [[buffer(6)]],
  constant uint &encodeOutput [[buffer(7)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float4 pixel = linearRgb[index];
  destination[index] = encodeOutput != 0u
    ? float4(spektra_finalize_output_rgb(pixel.rgb, params, colorInfo, encodeLuts, transferKinds), pixel.a)
    : pixel;
}

kernel void spektrafilm_final_from_print_raw(
  device const float4 *printRaw [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &paperCurveInfo [[buffer(4)]],
  device const float *paperLogExposure [[buffer(5)]],
  device const float *paperDensityCurves [[buffer(6)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(7)]],
  constant SpektraColorInfo &colorInfo [[buffer(8)]],
  device const uint *transferKinds [[buffer(9)]],
  device const float4 *paperSpectralDensity [[buffer(10)]],
  device const float *scanProducts [[buffer(11)]],
  device const float *scanToOutputRgbData [[buffer(12)]],
  device const float *encodeLuts [[buffer(13)]],
  constant SpektraCurveInfo &filmCurveInfo [[buffer(14)]],
  device const float *filmLogExposure [[buffer(15)]],
  device const float *filmDensityCurves [[buffer(16)]],
  device const float *filmLogSensitivity [[buffer(17)]],
  device const float *bandpassHanatos2025 [[buffer(18)]],
  device const float *hanatosSpectraLut [[buffer(19)]],
  device const float *mallettBasisIlluminant [[buffer(20)]],
  device const float *inputToReferenceXyz [[buffer(21)]],
  device const float *filmChannelDensity [[buffer(22)]],
  device const float4 *filmSpectralDensity [[buffer(23)]],
  device const float *paperLogSensitivity [[buffer(24)]],
  device const float *thKg3Illuminant [[buffer(25)]],
  device const float *customEnlargerFilters [[buffer(26)]],
  device const float *neutralPrintFilters [[buffer(27)]],
  device const float *academyPrinterDensityData [[buffer(28)]],
  constant SpektraFrameConstants &frameConstants [[buffer(29)]],
  constant uint &encodeOutput [[buffer(30)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  float4 pixel = printRaw[index];
  pixel.rgb = log10(max(pixel.rgb, float3(0.0)) + float3(1.0e-10));
  pixel.rgb = spektra_develop_print_density(pixel.rgb, params, spectralInfo, paperCurveInfo, paperLogExposure, paperDensityCurves);
  device const float4 *packedScanProducts = (device const float4 *)scanProducts;
  device const float4 *paperPackedScanProducts = packedScanProducts + spectralInfo.filmWavelengthCount;
  device const float *legacyScanProducts = scanProducts + spectralInfo.filmWavelengthCount * 8u;
  device const float *paperLegacyScanProducts = legacyScanProducts + spectralInfo.filmWavelengthCount * 3u;
  device const float *scanInverseNormalizations = legacyScanProducts + spectralInfo.filmWavelengthCount * 6u;
  device const float *paperScanToOutputRgb = scanToOutputRgbData + colorInfo.colorSpaceCount * 9u;
  const float3 printDensityCmy = pixel.rgb;
  SpektraScanResult scan = spektra_scan_density_to_output_rgb_linear_y_cached_common(
    printDensityCmy,
    true,
    params,
    colorInfo,
    spectralInfo,
    paperSpectralDensity,
    paperPackedScanProducts,
    paperLegacyScanProducts,
    scanInverseNormalizations[1],
    paperScanToOutputRgb
  );
  pixel.rgb = spektra_apply_print_scan_output_contract(scan, frameConstants, params);
  if (encodeOutput != 0u) {
    pixel.rgb = spektra_finalize_output_rgb(pixel.rgb, params, colorInfo, encodeLuts, transferKinds);
  }
  destination[index] = pixel;
}

static float4 spektra_rgb_gaussian_sample_x(
  device const float4 *source,
  uint width,
  uint height,
  uint2 gid,
  float sigma
) {
  if (sigma <= 1.0e-4) {
    return spektra_float4_buffer_sample(source, width, height, int(gid.x), int(gid.y));
  }
  const int radius = min(int(ceil(3.0 * sigma)), 256);
  float4 value = float4(0.0);
  float weightSum = 0.0;
  for (int offset = -radius; offset <= radius; ++offset) {
    const float weight = spektra_gaussian_weight(float(offset), sigma);
    value += weight * spektra_float4_buffer_sample(source, width, height, int(gid.x) + offset, int(gid.y));
    weightSum += weight;
  }
  return value / max(weightSum, 1.0e-8);
}

static float4 spektra_rgb_gaussian_sample_y(
  device const float4 *source,
  uint width,
  uint height,
  uint2 gid,
  float sigma
) {
  if (sigma <= 1.0e-4) {
    return spektra_float4_buffer_sample(source, width, height, int(gid.x), int(gid.y));
  }
  const int radius = min(int(ceil(3.0 * sigma)), 256);
  float4 value = float4(0.0);
  float weightSum = 0.0;
  for (int offset = -radius; offset <= radius; ++offset) {
    const float weight = spektra_gaussian_weight(float(offset), sigma);
    value += weight * spektra_float4_buffer_sample(source, width, height, int(gid.x), int(gid.y) + offset);
    weightSum += weight;
  }
  return value / max(weightSum, 1.0e-8);
}

static float spektra_hash_01(uint2 p, uint seed) {
  uint x = p.x * 1664525u + p.y * 1013904223u + seed * 747796405u + 2891336453u;
  x ^= x >> 16u;
  x *= 2246822519u;
  x ^= x >> 13u;
  x *= 3266489917u;
  x ^= x >> 16u;
  return (float(x & 0x00ffffffu) + 0.5) / 16777216.0;
}

static float spektra_lognormal_from_mean_std(float mean, float stddev, uint2 gid, uint seed) {
  mean = max(mean, 0.0);
  stddev = max(stddev, 0.0);
  if (mean <= 0.0) {
    return 0.0;
  }
  if (stddev <= 1.0e-10) {
    return mean;
  }
  const float varianceRatio = (stddev * stddev) / max(mean * mean, 1.0e-20);
  const float sigma2 = log(1.0 + varianceRatio);
  const float sigma = sqrt(max(sigma2, 0.0));
  const float mu = log(mean) - 0.5 * sigma2;
  const float u1 = max(spektra_hash_01(gid, seed), 1.0e-7);
  const float u2 = spektra_hash_01(uint2(gid.y, gid.x), seed ^ 0x9e3779b9u);
  const float normal = sqrt(-2.0 * log(u1)) * cos(6.28318530718 * u2);
  return exp(mu + sigma * normal);
}

kernel void spektrafilm_print_glare_generate(
  device float4 *glareOut [[buffer(0)]],
  constant SpektraKernelParams &params [[buffer(1)]],
  constant uint2 &dims [[buffer(2)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float mean = max(params.glarePercent, 0.0);
  const float stddev = max(params.glareRoughness, 0.0) * mean;
  const float amount = spektra_lognormal_from_mean_std(mean, stddev, gid, params.grainSeed);
  glareOut[index] = float4(amount, amount, amount, 1.0);
}

kernel void spektrafilm_print_glare_blur_x(
  device const float4 *source [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant uint &useRecurrence [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float sigma = max(params.glareBlur, 0.0);
  destination[index] = useRecurrence != 0u
    ? spektra_scalar_gaussian_sample_x(source, dims.x, dims.y, gid, sigma)
    : spektra_rgb_gaussian_sample_x(source, dims.x, dims.y, gid, sigma);
}

kernel void spektrafilm_print_glare_blur_y(
  device const float4 *source [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant uint &useRecurrence [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float sigma = max(params.glareBlur, 0.0);
  destination[index] = useRecurrence != 0u
    ? spektra_scalar_gaussian_sample_y(source, dims.x, dims.y, gid, sigma)
    : spektra_rgb_gaussian_sample_y(source, dims.x, dims.y, gid, sigma);
}

kernel void spektrafilm_print_glare_apply(
  device const float4 *linearSource [[buffer(0)]],
  device const float4 *glareAmount [[buffer(1)]],
  device float4 *destination [[buffer(2)]],
  constant SpektraFrameConstants &frameConstants [[buffer(3)]],
  constant uint2 &dims [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  float4 pixel = linearSource[index];
  pixel.rgb += max(glareAmount[index].r, 0.0) * 0.01 * frameConstants.glare.rgb;
  destination[index] = pixel;
}

static float4 spektra_texture2d_sample(
  texture2d<float, access::read> source,
  uint width,
  uint height,
  int x,
  int y
) {
  const uint sx = spektra_safe_index(x, width);
  const uint sy = spektra_safe_index(y, height);
  return source.read(uint2(sx, sy));
}

static float4 spektra_rgb_gaussian_texture_sample_x(
  texture2d<float, access::read> source,
  uint width,
  uint height,
  uint2 gid,
  float sigma
) {
  if (sigma <= 1.0e-4) {
    return spektra_texture2d_sample(source, width, height, int(gid.x), int(gid.y));
  }
  const int radius = min(int(ceil(3.0 * sigma)), 256);
  float4 value = float4(0.0);
  float weightSum = 0.0;
  for (int offset = -radius; offset <= radius; ++offset) {
    const float weight = spektra_gaussian_weight(float(offset), sigma);
    value += weight * spektra_texture2d_sample(source, width, height, int(gid.x) + offset, int(gid.y));
    weightSum += weight;
  }
  return value / max(weightSum, 1.0e-8);
}

static float4 spektra_rgb_gaussian_texture_sample_y(
  texture2d<float, access::read> source,
  uint width,
  uint height,
  uint2 gid,
  float sigma
) {
  if (sigma <= 1.0e-4) {
    return spektra_texture2d_sample(source, width, height, int(gid.x), int(gid.y));
  }
  const int radius = min(int(ceil(3.0 * sigma)), 256);
  float4 value = float4(0.0);
  float weightSum = 0.0;
  for (int offset = -radius; offset <= radius; ++offset) {
    const float weight = spektra_gaussian_weight(float(offset), sigma);
    value += weight * spektra_texture2d_sample(source, width, height, int(gid.x), int(gid.y) + offset);
    weightSum += weight;
  }
  return value / max(weightSum, 1.0e-8);
}

static float4 spektra_rgb_gaussian_texture_sample_x_recurrence(
  texture2d<float, access::read> source,
  uint width,
  uint height,
  uint2 gid,
  float sigma
) {
  const SpektraGaussianBlurInfo info = spektra_make_gaussian_blur_info(sigma, 256);
  if (info.active == 0u || info.radius == 0u) {
    return spektra_texture2d_sample(source, width, height, int(gid.x), int(gid.y));
  }
  const int x = int(gid.x);
  const int y = int(gid.y);
  const int radius = int(info.radius);
  const bool interior = x >= radius && x + radius < int(width);
  float4 value = source.read(gid);
  float weight = info.firstWeight;
  float ratio = info.firstRatio;
  for (int offset = 1; offset <= radius; ++offset) {
    const float4 samplePair = interior
      ? source.read(uint2(gid.x - uint(offset), gid.y)) + source.read(uint2(gid.x + uint(offset), gid.y))
      : spektra_texture2d_sample(source, width, height, x - offset, y) +
        spektra_texture2d_sample(source, width, height, x + offset, y);
    value += weight * samplePair;
    weight *= ratio;
    ratio *= info.ratioStep;
  }
  return value * info.invWeightSum;
}

static float4 spektra_rgb_gaussian_texture_sample_y_recurrence(
  texture2d<float, access::read> source,
  uint width,
  uint height,
  uint2 gid,
  float sigma
) {
  const SpektraGaussianBlurInfo info = spektra_make_gaussian_blur_info(sigma, 256);
  if (info.active == 0u || info.radius == 0u) {
    return spektra_texture2d_sample(source, width, height, int(gid.x), int(gid.y));
  }
  const int x = int(gid.x);
  const int y = int(gid.y);
  const int radius = int(info.radius);
  const bool interior = y >= radius && y + radius < int(height);
  float4 value = source.read(gid);
  float weight = info.firstWeight;
  float ratio = info.firstRatio;
  for (int offset = 1; offset <= radius; ++offset) {
    const float4 samplePair = interior
      ? source.read(uint2(gid.x, gid.y - uint(offset))) + source.read(uint2(gid.x, gid.y + uint(offset)))
      : spektra_texture2d_sample(source, width, height, x, y - offset) +
        spektra_texture2d_sample(source, width, height, x, y + offset);
    value += weight * samplePair;
    weight *= ratio;
    ratio *= info.ratioStep;
  }
  return value * info.invWeightSum;
}

kernel void spektrafilm_buffer_to_texture(
  device const float4 *source [[buffer(0)]],
  texture2d<float, access::write> destination [[texture(0)]],
  constant uint2 &dims [[buffer(1)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  destination.write(source[index], gid);
}

kernel void spektrafilm_texture_to_buffer(
  texture2d<float, access::read> source [[texture(0)]],
  device float4 *destination [[buffer(0)]],
  constant uint2 &dims [[buffer(1)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  destination[index] = source.read(gid);
}

kernel void spektrafilm_scanner_blur_x_texture(
  texture2d<float, access::read> source [[texture(0)]],
  texture2d<float, access::write> destination [[texture(1)]],
  constant SpektraKernelParams &params [[buffer(0)]],
  constant uint2 &dims [[buffer(1)]],
  constant uint &useRecurrence [[buffer(2)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const float sigma = max(params.scannerBlurSigmaPx, 0.0);
  destination.write(useRecurrence != 0u
    ? spektra_rgb_gaussian_texture_sample_x_recurrence(source, dims.x, dims.y, gid, sigma)
    : spektra_rgb_gaussian_texture_sample_x(source, dims.x, dims.y, gid, sigma), gid);
}

kernel void spektrafilm_scanner_blur_y_texture(
  texture2d<float, access::read> source [[texture(0)]],
  texture2d<float, access::write> destination [[texture(1)]],
  constant SpektraKernelParams &params [[buffer(0)]],
  constant uint2 &dims [[buffer(1)]],
  constant uint &useRecurrence [[buffer(2)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const float sigma = max(params.scannerBlurSigmaPx, 0.0);
  destination.write(useRecurrence != 0u
    ? spektra_rgb_gaussian_texture_sample_y_recurrence(source, dims.x, dims.y, gid, sigma)
    : spektra_rgb_gaussian_texture_sample_y(source, dims.x, dims.y, gid, sigma), gid);
}

kernel void spektrafilm_unsharp_blur_x_texture(
  texture2d<float, access::read> source [[texture(0)]],
  texture2d<float, access::write> destination [[texture(1)]],
  constant SpektraKernelParams &params [[buffer(0)]],
  constant uint2 &dims [[buffer(1)]],
  constant uint &useRecurrence [[buffer(2)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const float sigma = max(params.scannerUnsharpSigmaPx, 0.0);
  destination.write(useRecurrence != 0u
    ? spektra_rgb_gaussian_texture_sample_x_recurrence(source, dims.x, dims.y, gid, sigma)
    : spektra_rgb_gaussian_texture_sample_x(source, dims.x, dims.y, gid, sigma), gid);
}

kernel void spektrafilm_unsharp_blur_y_texture(
  texture2d<float, access::read> source [[texture(0)]],
  texture2d<float, access::write> destination [[texture(1)]],
  constant SpektraKernelParams &params [[buffer(0)]],
  constant uint2 &dims [[buffer(1)]],
  constant uint &useRecurrence [[buffer(2)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const float sigma = max(params.scannerUnsharpSigmaPx, 0.0);
  destination.write(useRecurrence != 0u
    ? spektra_rgb_gaussian_texture_sample_y_recurrence(source, dims.x, dims.y, gid, sigma)
    : spektra_rgb_gaussian_texture_sample_y(source, dims.x, dims.y, gid, sigma), gid);
}

kernel void spektrafilm_scanner_blur_x(
  device const float4 *source [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant uint &useRecurrence [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float sigma = max(params.scannerBlurSigmaPx, 0.0);
  destination[index] = useRecurrence != 0u
    ? spektra_scalar_gaussian_sample_x(source, dims.x, dims.y, gid, sigma)
    : spektra_rgb_gaussian_sample_x(source, dims.x, dims.y, gid, sigma);
}

kernel void spektrafilm_scanner_blur_y(
  device const float4 *source [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant uint &useRecurrence [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float sigma = max(params.scannerBlurSigmaPx, 0.0);
  destination[index] = useRecurrence != 0u
    ? spektra_scalar_gaussian_sample_y(source, dims.x, dims.y, gid, sigma)
    : spektra_rgb_gaussian_sample_y(source, dims.x, dims.y, gid, sigma);
}

kernel void spektrafilm_unsharp_blur_x(
  device const float4 *source [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant uint &useRecurrence [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float sigma = max(params.scannerUnsharpSigmaPx, 0.0);
  destination[index] = useRecurrence != 0u
    ? spektra_scalar_gaussian_sample_x(source, dims.x, dims.y, gid, sigma)
    : spektra_rgb_gaussian_sample_x(source, dims.x, dims.y, gid, sigma);
}

kernel void spektrafilm_unsharp_blur_y(
  device const float4 *source [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant uint &useRecurrence [[buffer(4)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float sigma = max(params.scannerUnsharpSigmaPx, 0.0);
  destination[index] = useRecurrence != 0u
    ? spektra_scalar_gaussian_sample_y(source, dims.x, dims.y, gid, sigma)
    : spektra_rgb_gaussian_sample_y(source, dims.x, dims.y, gid, sigma);
}

kernel void spektrafilm_scanner_finalize(
  device const float4 *linearSource [[buffer(0)]],
  device const float4 *unsharpBlur [[buffer(1)]],
  device float4 *destination [[buffer(2)]],
  constant SpektraKernelParams &params [[buffer(3)]],
  constant uint2 &dims [[buffer(4)]],
  constant SpektraColorInfo &colorInfo [[buffer(5)]],
  device const uint *transferKinds [[buffer(6)]],
  device const float *encodeLuts [[buffer(7)]],
  constant uint &encodeOutput [[buffer(8)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  float4 pixel = linearSource[index];
  if (params.scannerEnabled != 0u && params.scannerUnsharpSigmaPx > 0.0 && params.scannerUnsharpAmount > 0.0) {
    const float3 blurred = unsharpBlur[index].rgb;
    const float3 sourceRgb = pixel.rgb;
    pixel.rgb = max(sourceRgb + params.scannerUnsharpAmount * (sourceRgb - blurred), min(sourceRgb, float3(0.0)));
  }
  if (encodeOutput != 0u) {
    pixel.rgb = spektra_finalize_output_rgb(pixel.rgb, params, colorInfo, encodeLuts, transferKinds);
  }
  destination[index] = pixel;
}

kernel void spektrafilm_scanner_finalize_texture(
  texture2d<float, access::read> linearSource [[texture(0)]],
  texture2d<float, access::read> unsharpBlur [[texture(1)]],
  device float4 *destination [[buffer(0)]],
  constant SpektraKernelParams &params [[buffer(1)]],
  constant uint2 &dims [[buffer(2)]],
  constant SpektraColorInfo &colorInfo [[buffer(3)]],
  device const uint *transferKinds [[buffer(4)]],
  device const float *encodeLuts [[buffer(5)]],
  constant uint &encodeOutput [[buffer(6)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  float4 pixel = linearSource.read(gid);
  if (params.scannerEnabled != 0u && params.scannerUnsharpSigmaPx > 0.0 && params.scannerUnsharpAmount > 0.0) {
    const float3 blurred = unsharpBlur.read(gid).rgb;
    const float3 sourceRgb = pixel.rgb;
    pixel.rgb = max(sourceRgb + params.scannerUnsharpAmount * (sourceRgb - blurred), min(sourceRgb, float3(0.0)));
  }
  if (encodeOutput != 0u) {
    pixel.rgb = spektra_finalize_output_rgb(pixel.rgb, params, colorInfo, encodeLuts, transferKinds);
  }
  destination[index] = pixel;
}

kernel void spektrafilm_grain_preview(
  device const float4 *source [[buffer(0)]],
  device float4 *destination [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  constant SpektraCurveInfo &curveInfo [[buffer(4)]],
  device const float *logExposure [[buffer(5)]],
  device const float *densityCurves [[buffer(6)]],
  constant SpektraSpectralInfo &spectralInfo [[buffer(7)]],
  device const float *logSensitivity [[buffer(8)]],
  device const float *bandpassHanatos2025 [[buffer(9)]],
  device const float *hanatosSpectraLut [[buffer(10)]],
  device const float *mallettBasisIlluminant [[buffer(11)]],
  device const float *inputToReferenceXyz [[buffer(12)]],
  device const float *inputToSrgb [[buffer(13)]],
  constant SpektraColorInfo &colorInfo [[buffer(14)]],
  device const float *decodeLuts [[buffer(15)]],
  device const uint *transferKinds [[buffer(16)]],
  constant SpektraCurveInfo &paperCurveInfo [[buffer(17)]],
  device const float *paperLogExposure [[buffer(18)]],
  device const float *paperDensityCurves [[buffer(19)]],
  device const float *filmChannelDensity [[buffer(20)]],
  device const float *filmBaseDensity [[buffer(21)]],
  device const float *paperLogSensitivity [[buffer(22)]],
  device const float *thKg3Illuminant [[buffer(23)]],
  device const float *customEnlargerFilters [[buffer(24)]],
  device const float *neutralPrintFilters [[buffer(25)]],
  device const float *academyPrinterDensityData [[buffer(26)]],
  device const float *paperScanDensityData [[buffer(27)]],
  device const float *scanIlluminantsAndCmfs [[buffer(28)]],
  device const float *scanToOutputRgbData [[buffer(29)]],
  device const float *encodeLuts [[buffer(30)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  float4 pixel = source[index];
  if (spectralInfo.filmWavelengthCount == 0u || spectralInfo.hanatosWidth == 0u ||
      logSensitivity == nullptr || bandpassHanatos2025 == nullptr ||
      hanatosSpectraLut == nullptr || mallettBasisIlluminant == nullptr ||
      inputToReferenceXyz == nullptr || inputToSrgb == nullptr ||
      decodeLuts == nullptr || transferKinds == nullptr ||
      paperLogExposure == nullptr || paperDensityCurves == nullptr ||
      filmChannelDensity == nullptr || filmBaseDensity == nullptr ||
      paperLogSensitivity == nullptr || thKg3Illuminant == nullptr ||
      customEnlargerFilters == nullptr || neutralPrintFilters == nullptr ||
      academyPrinterDensityData == nullptr ||
      paperScanDensityData == nullptr || scanIlluminantsAndCmfs == nullptr ||
      scanToOutputRgbData == nullptr || encodeLuts == nullptr) {
    destination[index] = pixel;
    return;
  }
  device const float *paperChannelDensity = paperScanDensityData;
  device const float *paperBaseDensity = paperScanDensityData + spectralInfo.filmWavelengthCount * 3u;
  device const float *filmDensityCurveLayers = paperBaseDensity + spectralInfo.filmWavelengthCount;
  device const float *filmDensityCurveLayerMaxima = filmDensityCurveLayers + curveInfo.exposureCount * 9u;
  device const float *filmScanIlluminant = scanIlluminantsAndCmfs;
  device const float *paperScanIlluminant = scanIlluminantsAndCmfs + spectralInfo.filmWavelengthCount;
  device const float *standardObserverCmfs = scanIlluminantsAndCmfs + spectralInfo.filmWavelengthCount * 2u;
  device const float *filmScanToOutputRgb = scanToOutputRgbData;
  device const float *paperScanToOutputRgb = scanToOutputRgbData + colorInfo.colorSpaceCount * 9u;
  const uint frameSeed = params.grainAnimate != 0 ? uint(floor(params.time * 24.0 + 0.5)) : 0u;
  const uint baseSeed = params.grainSeed ^ frameSeed;
  const float2 filmUm = spektra_output_pixel_film_um(gid, params, dims);

  const bool finalPrintSimulation = params.process == 0;
  const bool finalScanNegative = params.process == 1;
  pixel.rgb = spektra_develop_film_density(
    spektra_film_log_raw(
      pixel.rgb,
      params,
      colorInfo,
      spectralInfo,
      logSensitivity,
      bandpassHanatos2025,
      hanatosSpectraLut,
      mallettBasisIlluminant,
      inputToReferenceXyz,
      inputToSrgb,
      decodeLuts,
      transferKinds
    ),
    params,
    curveInfo,
    logExposure,
    densityCurves
  );

  if (params.grainEnabled != 0 && (finalPrintSimulation || finalScanNegative)) {
    pixel.rgb = spektra_apply_grain_to_density(
      pixel.rgb,
      params,
      curveInfo,
      spectralInfo,
      densityCurves,
      filmDensityCurveLayers,
      filmDensityCurveLayerMaxima,
      filmUm,
      baseSeed
    );
  }

  if (finalPrintSimulation) {
    pixel.rgb = spektra_print_log_raw(
      pixel.rgb,
      params,
      colorInfo,
      curveInfo,
      spectralInfo,
      logExposure,
      densityCurves,
      logSensitivity,
      bandpassHanatos2025,
      hanatosSpectraLut,
      mallettBasisIlluminant,
      inputToReferenceXyz,
      filmChannelDensity,
      filmBaseDensity,
      paperLogSensitivity,
      thKg3Illuminant,
      customEnlargerFilters,
      neutralPrintFilters,
      academyPrinterDensityData
    );
  }

  if (finalPrintSimulation) {
    pixel.rgb = spektra_develop_print_density(
      pixel.rgb,
      params,
      spectralInfo,
      paperCurveInfo,
      paperLogExposure,
      paperDensityCurves
    );
  }

  if (finalPrintSimulation) {
    const float3 printDensityCmy = pixel.rgb;
    const float3 bypassedPrintDensityCmy = spektra_bleach_bypass_dye_density(
      printDensityCmy,
      params.printBleachBypassAmount,
      true,
      spectralInfo
    );
    SpektraScanResult scan = spektra_scan_density_to_output_rgb_linear_y(
      bypassedPrintDensityCmy,
      spektra_bleach_bypass_retained_silver_density(printDensityCmy, params.printBleachBypassAmount, true, spectralInfo),
      true,
      params,
      colorInfo,
      spectralInfo,
      paperChannelDensity,
      paperBaseDensity,
      paperScanIlluminant,
      standardObserverCmfs,
      paperScanToOutputRgb
    );
    pixel.rgb = scan.rgb;
    pixel.rgb = spektra_finalize_output_rgb(pixel.rgb, params, colorInfo, encodeLuts, transferKinds);
  } else if (finalScanNegative) {
    const float3 filmDensityCmy = pixel.rgb;
    const float3 bypassedFilmDensityCmy = spektra_negative_bleach_bypass_dye_density(
      filmDensityCmy,
      params.negativeBleachBypassAmount,
      params,
      spectralInfo
    );
    SpektraScanResult scan = spektra_scan_density_to_output_rgb_linear_y(
      bypassedFilmDensityCmy,
      spektra_bleach_bypass_retained_silver_density(filmDensityCmy, params.negativeBleachBypassAmount, false, spectralInfo),
      false,
      params,
      colorInfo,
      spectralInfo,
      filmChannelDensity,
      filmBaseDensity,
      filmScanIlluminant,
      standardObserverCmfs,
      filmScanToOutputRgb
    );
    if (params.scanNegativeInvert == 0u) {
      pixel.rgb = scan.rgb;
    } else {
      const float3 filmDmax = spektra_density_curve_max_cmy(curveInfo, densityCurves);
      const SpektraScanResult filmDmaxScan = spektra_scan_density_to_output_rgb_linear_y(
        filmDmax,
        0.0,
        false,
        params,
        colorInfo,
        spectralInfo,
        filmChannelDensity,
        filmBaseDensity,
        filmScanIlluminant,
        standardObserverCmfs,
        filmScanToOutputRgb
      );
      const SpektraScanResult filmDminScan = spektra_scan_density_to_output_rgb_linear_y(
        float3(0.0),
        0.0,
        false,
        params,
        colorInfo,
        spectralInfo,
        filmChannelDensity,
        filmBaseDensity,
        filmScanIlluminant,
        standardObserverCmfs,
        filmScanToOutputRgb
      );
      const float4 normalized = spektra_normalize_film_scan_rgb_y(
        scan,
        filmDmaxScan,
        filmDminScan,
        spectralInfo.filmPositive != 0u
      );
      pixel.rgb = spektra_rcm_enabled(params)
        ? normalized.rgb
        : spektra_apply_scanner_black_white_correction(normalized.rgb, normalized.a, 0.0, 1.0, params);
    }
    pixel.rgb = spektra_finalize_output_rgb(pixel.rgb, params, colorInfo, encodeLuts, transferKinds);
  }

  destination[index] = pixel;
}

kernel void spektrafilm_film_exposure_stub(
  device const float4 *source [[buffer(0)]],
  device float4 *filmRaw [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float exposure = exp2(params.filmExposureEv);
  const float3 rgb = max(source[index].rgb * exposure, float3(0.0));
  filmRaw[index] = float4(log10(rgb + 1.0e-10), source[index].a);
}

kernel void spektrafilm_curve_develop_stub(
  device const float4 *filmRaw [[buffer(0)]],
  device float4 *density [[buffer(1)]],
  constant SpektraKernelParams &params [[buffer(2)]],
  constant uint2 &dims [[buffer(3)]],
  uint2 gid [[thread_position_in_grid]]
) {
  if (gid.x >= dims.x || gid.y >= dims.y) {
    return;
  }
  const uint index = gid.y * dims.x + gid.x;
  const float3 logRaw = filmRaw[index].rgb;
  const float3 normalized = clamp((logRaw * params.filmGamma + 4.0) / 8.0, 0.0, 1.0);
  density[index] = float4(normalized, filmRaw[index].a);
}
