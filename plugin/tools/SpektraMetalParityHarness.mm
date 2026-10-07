#include "SpektraMetalRenderer.h"
#include "SpektraHarnessHostIO.h"
#include "SpektraProfileCurves.h"

#import <Foundation/Foundation.h>

#include <algorithm>
#include <cctype>
#include <cerrno>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <limits>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

namespace {

struct Options {
  std::string inputPath;
  std::string outputPath;
  std::string paramsPath;
  std::string resourceDir;
  std::string stage = "final_linear_rgb";
  std::string sourceFormat = "float";
  std::string destinationFormat = "float";
  std::string hostLayout = "contiguous";
  int width = 0;
  int height = 0;
  double time = 0.0;
};

void printUsage(const char *name) {
  std::cerr
    << "Usage: " << name << " --input INPUT.f32 --output OUTPUT.f32 --width W --height H --stage STAGE [options]\n"
    << "\n"
    << "Stages:\n"
    << "  film_log_raw | film_density_cmy | film_density_cmy_grain | print_log_raw | print_density_cmy | final_linear_rgb\n"
    << "\n"
    << "Options:\n"
    << "  --params PATH        Key=value parity parameter file.\n"
    << "  --resource-dir DIR   Directory containing SpektraFilm.metallib and SpektraHanatos2025Spectra.f32.\n"
    << "  --source-format FMT  Host source format: float or half. Default: float.\n"
    << "  --destination-format FMT Host destination format: float or half. Default: float.\n"
    << "  --host-layout LAYOUT Host memory layout: contiguous, strided, or offset. Default: contiguous.\n"
    << "  --time SECONDS       Render time used for deterministic animated grain. Default: 0.\n";
}

std::string trim(const std::string &value) {
  size_t first = 0;
  while (first < value.size() && std::isspace(static_cast<unsigned char>(value[first]))) {
    ++first;
  }
  size_t last = value.size();
  while (last > first && std::isspace(static_cast<unsigned char>(value[last - 1u]))) {
    --last;
  }
  return value.substr(first, last - first);
}

std::string normalizedTag(const std::string &value) {
  std::string normalized;
  bool pendingUnderscore = false;
  for (char ch : value) {
    const unsigned char c = static_cast<unsigned char>(ch);
    if (std::isalnum(c)) {
      if (pendingUnderscore && !normalized.empty()) {
        normalized.push_back('_');
      }
      normalized.push_back(static_cast<char>(std::tolower(c)));
      pendingUnderscore = false;
    } else {
      pendingUnderscore = true;
    }
  }
  return normalized;
}

bool parseInt(const std::string &text, int &out) {
  char *end = nullptr;
  errno = 0;
  const long value = std::strtol(text.c_str(), &end, 10);
  if (errno != 0 || !end || *end != '\0' || value < std::numeric_limits<int>::min() || value > std::numeric_limits<int>::max()) {
    return false;
  }
  out = static_cast<int>(value);
  return true;
}

bool parseUInt(const std::string &text, uint32_t &out) {
  int value = 0;
  if (!parseInt(text, value) || value < 0) {
    return false;
  }
  out = static_cast<uint32_t>(value);
  return true;
}

bool parseFloat(const std::string &text, float &out) {
  char *end = nullptr;
  errno = 0;
  const float value = std::strtof(text.c_str(), &end);
  if (errno != 0 || !end || *end != '\0' || !std::isfinite(value)) {
    return false;
  }
  out = value;
  return true;
}

bool parseDouble(const std::string &text, double &out) {
  char *end = nullptr;
  errno = 0;
  const double value = std::strtod(text.c_str(), &end);
  if (errno != 0 || !end || *end != '\0' || !std::isfinite(value)) {
    return false;
  }
  out = value;
  return true;
}

bool parseBool(const std::string &text, bool &out) {
  const std::string value = normalizedTag(text);
  if (value == "1" || value == "true" || value == "yes" || value == "on") {
    out = true;
    return true;
  }
  if (value == "0" || value == "false" || value == "no" || value == "off") {
    out = false;
    return true;
  }
  return false;
}

std::vector<std::string> splitList(const std::string &text) {
  std::vector<std::string> values;
  std::string current;
  for (char ch : text) {
    if (ch == ',' || std::isspace(static_cast<unsigned char>(ch))) {
      if (!current.empty()) {
        values.push_back(current);
        current.clear();
      }
    } else {
      current.push_back(ch);
    }
  }
  if (!current.empty()) {
    values.push_back(current);
  }
  return values;
}

bool parseFloat3(const std::string &text, float &a, float &b, float &c) {
  const std::vector<std::string> values = splitList(text);
  if (values.size() != 3u) {
    return false;
  }
  return parseFloat(values[0], a) && parseFloat(values[1], b) && parseFloat(values[2], c);
}

bool parseFloat2(const std::string &text, float &a, float &b) {
  const std::vector<std::string> values = splitList(text);
  if (values.size() != 2u) {
    return false;
  }
  return parseFloat(values[0], a) && parseFloat(values[1], b);
}

bool parseColorSpace(const std::string &text, spektrafilm::ColorSpace &out) {
  static const std::unordered_map<std::string, spektrafilm::ColorSpace> kColorSpaces = {
    {"arri_logc4", spektrafilm::ColorSpace::ArriLogC4},
    {"arri_logc3_ei800", spektrafilm::ColorSpace::ArriLogC3Ei800},
    {"bmd_film_wide_gamut_gen5", spektrafilm::ColorSpace::BmdFilmWideGamutGen5},
    {"davinci_intermediate_wide_gamut", spektrafilm::ColorSpace::DavinciIntermediateWideGamut},
    {"red_log3g10_redwidegamutrgb", spektrafilm::ColorSpace::RedLog3G10RedWideGamutRgb},
    {"sony_slog3_sgamut3", spektrafilm::ColorSpace::SonySLog3SGamut3},
    {"sony_slog3_sgamut3cine", spektrafilm::ColorSpace::SonySLog3SGamut3Cine},
    {"canon_log2_cinema_gamut_d55", spektrafilm::ColorSpace::CanonLog2CinemaGamutD55},
    {"canon_log3_cinema_gamut_d55", spektrafilm::ColorSpace::CanonLog3CinemaGamutD55},
    {"panasonic_vlog_vgamut", spektrafilm::ColorSpace::PanasonicVLogVGamut},
    {"aces2065_1", spektrafilm::ColorSpace::Aces2065_1},
    {"acescg", spektrafilm::ColorSpace::AcesCg},
    {"acescct", spektrafilm::ColorSpace::AcesCct},
    {"aces_cct", spektrafilm::ColorSpace::AcesCct},
    {"acescc", spektrafilm::ColorSpace::AcesCc},
    {"aces_cc", spektrafilm::ColorSpace::AcesCc},
    {"linear_rec2020", spektrafilm::ColorSpace::LinearRec2020},
    {"itu_r_bt_2020", spektrafilm::ColorSpace::LinearRec2020},
    {"linear_rec709", spektrafilm::ColorSpace::LinearRec709},
    {"linear_p3_d65", spektrafilm::ColorSpace::LinearP3D65},
    {"srgb", spektrafilm::ColorSpace::Srgb},
    {"display_p3", spektrafilm::ColorSpace::DisplayP3},
    {"prophoto_rgb", spektrafilm::ColorSpace::ProPhotoRgb},
    {"adobe_rgb_1998", spektrafilm::ColorSpace::AdobeRgb1998},
    {"dci_p3", spektrafilm::ColorSpace::DciP3},
    {"p3_d65_gamma_22", spektrafilm::ColorSpace::P3D65Gamma22},
    {"p3_d65_gamma_26", spektrafilm::ColorSpace::P3D65Gamma26},
    {"rec709_gamma_22", spektrafilm::ColorSpace::Rec709Gamma22},
    {"rec709_gamma_24", spektrafilm::ColorSpace::Rec709Gamma24},
  };
  int raw = 0;
  if (parseInt(text, raw)) {
    out = static_cast<spektrafilm::ColorSpace>(raw);
    return true;
  }
  const auto found = kColorSpaces.find(normalizedTag(text));
  if (found == kColorSpaces.end()) {
    return false;
  }
  out = found->second;
  return true;
}

bool parseRenderOutput(const std::string &stage, spektrafilm::RenderOutputMode &out) {
  const std::string value = normalizedTag(stage);
  if (value == "film_log_raw") {
    out = spektrafilm::RenderOutputMode::FilmLogRaw;
  } else if (value == "film_density_cmy") {
    out = spektrafilm::RenderOutputMode::FilmDensityCmy;
  } else if (value == "film_density_cmy_grain") {
    out = spektrafilm::RenderOutputMode::FilmDensityCmyWithGrain;
  } else if (value == "print_log_raw") {
    out = spektrafilm::RenderOutputMode::PrintLogRaw;
  } else if (value == "print_density_cmy") {
    out = spektrafilm::RenderOutputMode::PrintDensityCmy;
  } else if (value == "final_linear_rgb") {
    out = spektrafilm::RenderOutputMode::FinalPreview;
  } else {
    return false;
  }
  return true;
}

bool findFilmIndex(const std::string &text, int &out) {
  if (parseInt(text, out)) {
    return out >= 0 && out < static_cast<int>(spektrafilm::kSpektraFilmCount);
  }
  const std::string wanted = normalizedTag(text);
  for (uint32_t index = 0; index < spektrafilm::kSpektraFilmCount; ++index) {
    const spektrafilm::ProfileCurveSet *curves = spektrafilm::filmProfileCurves(static_cast<int32_t>(index));
    if (curves && curves->stock && normalizedTag(curves->stock) == wanted) {
      out = static_cast<int>(index);
      return true;
    }
  }
  return false;
}

bool findPaperIndex(const std::string &text, int &out) {
  if (parseInt(text, out)) {
    return out >= 0 && out < static_cast<int>(spektrafilm::kSpektraPaperCount);
  }
  const std::string wanted = normalizedTag(text);
  for (uint32_t index = 0; index < spektrafilm::kSpektraPaperCount; ++index) {
    const spektrafilm::ProfileCurveSet *curves = spektrafilm::paperProfileCurves(static_cast<int32_t>(index));
    if (curves && curves->stock && normalizedTag(curves->stock) == wanted) {
      out = static_cast<int>(index);
      return true;
    }
  }
  return false;
}

spektrafilm::RenderParams parityDefaults() {
  spektrafilm::RenderParams params;
  params.process = spektrafilm::ProcessMode::PrintSimulation;
  params.renderOutput = spektrafilm::RenderOutputMode::FinalPreview;
  params.rgbToRawMethod = spektrafilm::RgbToRawMethod::Hanatos2025;
  params.inputColorSpace = spektrafilm::ColorSpace::LinearRec2020;
  params.outputColorSpace = spektrafilm::ColorSpace::LinearRec2020;
  params.outputRole = spektrafilm::OutputRole::DisplaySdr;
  params.film = spektrafilm::kSpektraDefaultFilmIndex;
  params.paper = spektrafilm::kSpektraDefaultPaperIndex;
  params.printTiming = spektrafilm::PrintTimingMode::FilteredEnlarger;
  params.autoExposure = false;
  params.printExposureEv = 0.0f;
  params.grainEnabled = false;
  params.grainAnimate = false;
  params.halationEnabled = false;
  params.cameraDiffusionEnabled = false;
  params.printDiffusionEnabled = false;
  params.dirCouplersAmount = 0.0f;
  params.scannerEnabled = false;
  return params;
}

bool applyParam(const std::string &keyRaw, const std::string &valueRaw, spektrafilm::RenderParams &params, std::string &error) {
  const std::string key = normalizedTag(keyRaw);
  const std::string value = trim(valueRaw);
  auto fail = [&]() {
    error = "Invalid value for parameter '" + keyRaw + "': " + valueRaw;
    return false;
  };
  auto assignFloat = [&](float &target) {
    return parseFloat(value, target) || fail();
  };
  auto assignBool = [&](bool &target) {
    return parseBool(value, target) || fail();
  };
  auto assignInt = [&](int32_t &target) {
    int parsed = 0;
    if (!parseInt(value, parsed)) {
      return fail();
    }
    target = parsed;
    return true;
  };

  if (key == "stage" || key == "render_output") {
    return parseRenderOutput(value, params.renderOutput) || fail();
  }
  if (key == "process") {
    const std::string mode = normalizedTag(value);
    int processValue = 0;
    if (parseInt(value, processValue)) {
      switch (processValue) {
        case 0:
          params.process = spektrafilm::ProcessMode::PrintSimulation;
          return true;
        case 1:
          params.process = spektrafilm::ProcessMode::ScanNegative;
          return true;
        case 2:
          params.process = spektrafilm::ProcessMode::ProcessNegative;
          params.rgbToRawMethod = spektrafilm::RgbToRawMethod::Hanatos2026;
          return true;
        default:
          return fail();
      }
    }
    if (mode == "print_simulation" || mode == "print") {
      params.process = spektrafilm::ProcessMode::PrintSimulation;
      return true;
    }
    if (mode == "scan_negative" || mode == "scan") {
      params.process = spektrafilm::ProcessMode::ScanNegative;
      return true;
    }
    if (mode == "process_negative" || mode == "negative_process" || mode == "negative_print") {
      params.process = spektrafilm::ProcessMode::ProcessNegative;
      params.rgbToRawMethod = spektrafilm::RgbToRawMethod::Hanatos2026;
      return true;
    }
    return fail();
  }
  if (key == "rgb_to_raw_method") {
    const std::string method = normalizedTag(value);
    if (method == "hanatos2025") {
      params.rgbToRawMethod = spektrafilm::RgbToRawMethod::Hanatos2025;
      return true;
    }
    if (method == "mallett2019") {
      params.rgbToRawMethod = spektrafilm::RgbToRawMethod::Mallett2019;
      return true;
    }
    if (method == "hanatos2026") {
      params.rgbToRawMethod = spektrafilm::RgbToRawMethod::Hanatos2026;
      return true;
    }
    return fail();
  }
  if (key == "input_color_space" || key == "input_colorspace") {
    return parseColorSpace(value, params.inputColorSpace) || fail();
  }
  if (key == "output_color_space" || key == "output_colorspace") {
    return parseColorSpace(value, params.outputColorSpace) || fail();
  }
  if (key == "output_role") {
    const std::string role = normalizedTag(value);
    if (role == "display_sdr" || role == "sdr") {
      params.outputRole = spektrafilm::OutputRole::DisplaySdr;
      return true;
    }
    if (role == "display_hdr" || role == "hdr") {
      params.outputRole = spektrafilm::OutputRole::DisplayHdr;
      return true;
    }
    if (role == "rcm" || role == "resolve_color_management" || role == "scene_handoff" || role == "scene") {
      params.outputRole = spektrafilm::OutputRole::Rcm;
      return true;
    }
    return fail();
  }
  if (key == "color_adaptation") return assignBool(params.colorAdaptation);
  if (key == "film" || key == "film_stock") {
    return findFilmIndex(value, params.film) || fail();
  }
  if (key == "paper" || key == "print_stock" || key == "paper_stock") {
    return findPaperIndex(value, params.paper) || fail();
  }
  if (key == "film_exposure_ev") return assignFloat(params.filmExposureEv);
  if (key == "auto_exposure") return assignBool(params.autoExposure);
  if (key == "print_exposure_ev") return assignFloat(params.printExposureEv);
  if (key == "film_gamma") return assignFloat(params.filmGamma);
  if (key == "print_gamma") return assignFloat(params.printGamma);
  if (key == "filter_c") return assignFloat(params.filterC);
  if (key == "filter_m_shift") return assignFloat(params.filterMShift);
  if (key == "filter_y_shift") return assignFloat(params.filterYShift);
  if (key == "enlarger_scale") return assignFloat(params.enlargerScale);
  if (key == "enlarger_offset_x_percent") return assignFloat(params.enlargerOffsetXPercent);
  if (key == "enlarger_offset_y_percent") return assignFloat(params.enlargerOffsetYPercent);
  if (key == "preflash_exposure") return assignFloat(params.preflashExposure);
  if (key == "preflash_m_filter_shift") return assignFloat(params.preflashMFilterShift);
  if (key == "preflash_y_filter_shift") return assignFloat(params.preflashYFilterShift);
  if (key == "negative_bleach_bypass_amount") return assignFloat(params.negativeBleachBypassAmount);
  if (key == "negative_leuco_cyan_coupling") return assignFloat(params.negativeLeucoCyanCoupling);
  if (key == "print_bleach_bypass_amount") return assignFloat(params.printBleachBypassAmount);

  if (key == "dir_amount") return assignFloat(params.dirCouplersAmount);
  if (key == "dir_diffusion_um") return assignFloat(params.dirCouplersDiffusionUm);
  if (key == "dir_diffusion_tail_um") return assignFloat(params.dirCouplersDiffusionTailUm);
  if (key == "dir_diffusion_tail_weight") return assignFloat(params.dirCouplersDiffusionTailWeight);
  if (key == "dir_inhibition_same_layer") return assignFloat(params.dirCouplersInhibitionSameLayer);
  if (key == "dir_inhibition_interlayer") return assignFloat(params.dirCouplersInhibitionInterlayer);
  if (key == "dir_gamma_same_layer_rgb") return parseFloat3(value, params.dirCouplersGammaSameLayerR, params.dirCouplersGammaSameLayerG, params.dirCouplersGammaSameLayerB) || fail();
  if (key == "dir_gamma_r_to_gb") return parseFloat2(value, params.dirCouplersGammaRToG, params.dirCouplersGammaRToB) || fail();
  if (key == "dir_gamma_g_to_rb") return parseFloat2(value, params.dirCouplersGammaGToR, params.dirCouplersGammaGToB) || fail();
  if (key == "dir_gamma_b_to_rg") return parseFloat2(value, params.dirCouplersGammaBToR, params.dirCouplersGammaBToG) || fail();

  if (key == "grain_enabled") return assignBool(params.grainEnabled);
  if (key == "grain_model") {
    const std::string model = normalizedTag(value);
    if (model == "preview") params.grainModel = spektrafilm::GrainModel::Preview;
    else if (model == "production") params.grainModel = spektrafilm::GrainModel::Production;
    else if (model == "synthesis" || model == "grain_synthesis") params.grainModel = spektrafilm::GrainModel::GrainSynthesis;
    else return fail();
    return true;
  }
  if (key == "grain_amount") return assignFloat(params.grainAmount);
  if (key == "grain_saturation") return assignFloat(params.grainSaturation);
  if (key == "grain_sublayers_enabled") return assignBool(params.grainSublayersEnabled);
  if (key == "grain_sub_layer_count") return assignInt(params.grainSubLayerCount);
  if (key == "grain_particle_area_um2") return assignFloat(params.grainParticleAreaUm2);
  if (key == "grain_particle_scale_rgb") return parseFloat3(value, params.grainParticleScaleR, params.grainParticleScaleG, params.grainParticleScaleB) || fail();
  if (key == "grain_particle_scale_layers") return parseFloat3(value, params.grainParticleScaleLayer0, params.grainParticleScaleLayer1, params.grainParticleScaleLayer2) || fail();
  if (key == "grain_density_min_rgb") return parseFloat3(value, params.grainDensityMinR, params.grainDensityMinG, params.grainDensityMinB) || fail();
  if (key == "grain_uniformity_rgb") return parseFloat3(value, params.grainUniformityR, params.grainUniformityG, params.grainUniformityB) || fail();
  if (key == "grain_final_blur_um") return assignFloat(params.grainFinalBlurUm);
  if (key == "grain_blur_dye_clouds_um") return assignFloat(params.grainBlurDyeCloudsUm);
  if (key == "grain_micro_structure_scale") return assignFloat(params.grainMicroStructureScale);
  if (key == "grain_micro_structure_sigma_nm") return assignFloat(params.grainMicroStructureSigmaNm);
  if (key == "grain_seed") return parseUInt(value, params.grainSeed) || fail();
  if (key == "grain_animate") return assignBool(params.grainAnimate);

  if (key == "halation_enabled") return assignBool(params.halationEnabled);
  if (key == "scatter_amount") return assignFloat(params.scatterAmount);
  if (key == "scatter_scale") return assignFloat(params.scatterScale);
  if (key == "halation_amount") return assignFloat(params.halationAmount);
  if (key == "halation_scale") return assignFloat(params.halationScale);
  if (key == "halation_strength_rgb") return parseFloat3(value, params.halationStrengthR, params.halationStrengthG, params.halationStrengthB) || fail();
  if (key == "halation_first_sigma_um_rgb") return parseFloat3(value, params.halationFirstSigmaUmR, params.halationFirstSigmaUmG, params.halationFirstSigmaUmB) || fail();
  if (key == "halation_boost_ev") return assignFloat(params.halationBoostEv);
  if (key == "halation_boost_range") return assignFloat(params.halationBoostRange);
  if (key == "halation_protect_ev") return assignFloat(params.halationProtectEv);

  if (key == "camera_diffusion_enabled") return assignBool(params.cameraDiffusionEnabled);
  if (key == "camera_diffusion_strength") return assignFloat(params.cameraDiffusionStrength);
  if (key == "camera_diffusion_spatial_scale") return assignFloat(params.cameraDiffusionSpatialScale);
  if (key == "camera_diffusion_halo_warmth") return assignFloat(params.cameraDiffusionHaloWarmth);
  if (key == "camera_diffusion_core_intensity") return assignFloat(params.cameraDiffusionCoreIntensity);
  if (key == "camera_diffusion_core_size") return assignFloat(params.cameraDiffusionCoreSize);
  if (key == "camera_diffusion_halo_intensity") return assignFloat(params.cameraDiffusionHaloIntensity);
  if (key == "camera_diffusion_halo_size") return assignFloat(params.cameraDiffusionHaloSize);
  if (key == "camera_diffusion_bloom_intensity") return assignFloat(params.cameraDiffusionBloomIntensity);
  if (key == "camera_diffusion_bloom_size") return assignFloat(params.cameraDiffusionBloomSize);

  if (key == "print_diffusion_enabled") return assignBool(params.printDiffusionEnabled);
  if (key == "print_diffusion_strength") return assignFloat(params.printDiffusionStrength);
  if (key == "print_diffusion_spatial_scale") return assignFloat(params.printDiffusionSpatialScale);
  if (key == "print_diffusion_halo_warmth") return assignFloat(params.printDiffusionHaloWarmth);
  if (key == "print_diffusion_core_intensity") return assignFloat(params.printDiffusionCoreIntensity);
  if (key == "print_diffusion_core_size") return assignFloat(params.printDiffusionCoreSize);
  if (key == "print_diffusion_halo_intensity") return assignFloat(params.printDiffusionHaloIntensity);
  if (key == "print_diffusion_halo_size") return assignFloat(params.printDiffusionHaloSize);
  if (key == "print_diffusion_bloom_intensity") return assignFloat(params.printDiffusionBloomIntensity);
  if (key == "print_diffusion_bloom_size") return assignFloat(params.printDiffusionBloomSize);

  if (key == "scanner_enabled") return assignBool(params.scannerEnabled);
  if (key == "scanner_white_correction") return assignBool(params.scannerWhiteCorrection);
  if (key == "scanner_black_correction") return assignBool(params.scannerBlackCorrection);
  if (key == "scanner_white_level") return assignFloat(params.scannerWhiteLevel);
  if (key == "scanner_black_level") return assignFloat(params.scannerBlackLevel);
  if (key == "glare_percent") return assignFloat(params.glarePercent);
  if (key == "glare_roughness") return assignFloat(params.glareRoughness);
  if (key == "glare_blur") return assignFloat(params.glareBlur);
  if (key == "scanner_mtf50_lp_mm") return assignFloat(params.scannerMtf50LpMm);
  if (key == "scanner_unsharp_radius_um") return assignFloat(params.scannerUnsharpRadiusUm);
  if (key == "scanner_unsharp_amount") return assignFloat(params.scannerUnsharpAmount);

  if (key == "deactivate_spatial_effects") {
    bool enabled = false;
    if (!parseBool(value, enabled)) return fail();
    if (enabled) {
      params.halationEnabled = false;
      params.cameraDiffusionEnabled = false;
      params.printDiffusionEnabled = false;
      params.dirCouplersDiffusionUm = 0.0f;
      params.dirCouplersDiffusionTailUm = 0.0f;
      params.grainFinalBlurUm = 0.0f;
      params.grainBlurDyeCloudsUm = 0.0f;
      params.scannerMtf50LpMm = 0.0f;
      params.scannerUnsharpRadiusUm = 0.0f;
      params.scannerUnsharpAmount = 0.0f;
      params.glareBlur = 0.0f;
    }
    return true;
  }
  if (key == "deactivate_stochastic_effects") {
    bool enabled = false;
    if (!parseBool(value, enabled)) return fail();
    if (enabled) {
      params.grainEnabled = false;
      params.glarePercent = 0.0f;
    }
    return true;
  }

  error = "Unknown parity parameter: " + keyRaw;
  return false;
}

bool applyParamFile(const std::string &path, spektrafilm::RenderParams &params, std::string &error) {
  if (path.empty()) {
    return true;
  }
  std::ifstream file(path);
  if (!file) {
    error = "Unable to open params file: " + path;
    return false;
  }
  std::string line;
  int lineNumber = 0;
  while (std::getline(file, line)) {
    ++lineNumber;
    const size_t comment = line.find('#');
    if (comment != std::string::npos) {
      line = line.substr(0, comment);
    }
    line = trim(line);
    if (line.empty()) {
      continue;
    }
    const size_t equals = line.find('=');
    if (equals == std::string::npos) {
      error = "Invalid params line " + std::to_string(lineNumber) + ": " + line;
      return false;
    }
    if (!applyParam(trim(line.substr(0, equals)), trim(line.substr(equals + 1u)), params, error)) {
      error += " at " + path + ":" + std::to_string(lineNumber);
      return false;
    }
  }
  return true;
}

bool parseArgs(int argc, const char **argv, Options &options) {
  for (int i = 1; i < argc; ++i) {
    const std::string arg = argv[i];
    auto requireValue = [&](const char *flag) -> const char * {
      if (i + 1 >= argc) {
        std::cerr << flag << " requires a value.\n";
        return nullptr;
      }
      return argv[++i];
    };
    if (arg == "--help" || arg == "-h") {
      printUsage(argv[0]);
      std::exit(0);
    } else if (arg == "--input") {
      const char *value = requireValue("--input");
      if (!value) return false;
      options.inputPath = value;
    } else if (arg == "--output") {
      const char *value = requireValue("--output");
      if (!value) return false;
      options.outputPath = value;
    } else if (arg == "--params") {
      const char *value = requireValue("--params");
      if (!value) return false;
      options.paramsPath = value;
    } else if (arg == "--resource-dir") {
      const char *value = requireValue("--resource-dir");
      if (!value) return false;
      options.resourceDir = value;
    } else if (arg == "--stage") {
      const char *value = requireValue("--stage");
      if (!value) return false;
      options.stage = value;
    } else if (arg == "--source-format") {
      const char *value = requireValue("--source-format");
      spektrafilm_harness::HostPixelFormat format;
      if (!value || !spektrafilm_harness::parseHostPixelFormat(value, format)) return false;
      options.sourceFormat = spektrafilm_harness::hostPixelFormatName(format);
    } else if (arg == "--destination-format") {
      const char *value = requireValue("--destination-format");
      spektrafilm_harness::HostPixelFormat format;
      if (!value || !spektrafilm_harness::parseHostPixelFormat(value, format)) return false;
      options.destinationFormat = spektrafilm_harness::hostPixelFormatName(format);
    } else if (arg == "--host-layout") {
      const char *value = requireValue("--host-layout");
      spektrafilm_harness::HostLayout layout;
      if (!value || !spektrafilm_harness::parseHostLayout(value, layout)) return false;
      options.hostLayout = spektrafilm_harness::hostLayoutName(layout);
    } else if (arg == "--width") {
      const char *value = requireValue("--width");
      if (!value || !parseInt(value, options.width) || options.width <= 0) return false;
    } else if (arg == "--height") {
      const char *value = requireValue("--height");
      if (!value || !parseInt(value, options.height) || options.height <= 0) return false;
    } else if (arg == "--time") {
      const char *value = requireValue("--time");
      if (!value || !parseDouble(value, options.time)) return false;
    } else {
      std::cerr << "Unknown argument: " << arg << "\n";
      return false;
    }
  }
  return !options.inputPath.empty() && !options.outputPath.empty() && options.width > 0 && options.height > 0;
}

bool readFloatRgba(const std::string &path, int width, int height, std::vector<float> &pixels) {
  const size_t count = static_cast<size_t>(width) * static_cast<size_t>(height) * 4u;
  pixels.assign(count, 0.0f);
  std::ifstream file(path, std::ios::binary);
  if (!file) {
    return false;
  }
  file.read(reinterpret_cast<char *>(pixels.data()), static_cast<std::streamsize>(count * sizeof(float)));
  return file.good() || file.gcount() == static_cast<std::streamsize>(count * sizeof(float));
}

bool writeFloatRgba(const std::string &path, const std::vector<float> &pixels) {
  const std::filesystem::path outPath(path);
  if (outPath.has_parent_path()) {
    std::error_code ec;
    std::filesystem::create_directories(outPath.parent_path(), ec);
  }
  std::ofstream file(path, std::ios::binary);
  if (!file) {
    return false;
  }
  file.write(reinterpret_cast<const char *>(pixels.data()), static_cast<std::streamsize>(pixels.size() * sizeof(float)));
  return file.good();
}

} // namespace

int main(int argc, const char **argv) {
  @autoreleasepool {
    setenv("SPEKTRAFILM_LINEAR_FINAL_OUTPUT", "1", 1);
    Options options;
    if (!parseArgs(argc, argv, options)) {
      printUsage(argv[0]);
      return 2;
    }
    if (!options.resourceDir.empty()) {
      setenv("SPEKTRAFILM_RESOURCE_DIR", options.resourceDir.c_str(), 1);
    }

    spektrafilm::RenderParams params = parityDefaults();
    if (!parseRenderOutput(options.stage, params.renderOutput)) {
      std::cerr << "Unknown parity stage: " << options.stage << "\n";
      return 2;
    }
    std::string paramError;
    if (!applyParamFile(options.paramsPath, params, paramError)) {
      std::cerr << paramError << "\n";
      return 2;
    }

    if (params.renderOutput == spektrafilm::RenderOutputMode::PrintLogRaw ||
        params.renderOutput == spektrafilm::RenderOutputMode::PrintDensityCmy) {
      params.process = spektrafilm::ProcessMode::PrintSimulation;
    }
    std::vector<float> sourcePixels;
    if (!readFloatRgba(options.inputPath, options.width, options.height, sourcePixels)) {
      std::cerr << "Unable to read input float RGBA file: " << options.inputPath << "\n";
      return 2;
    }
    spektrafilm_harness::HostPixelFormat sourceFormat;
    spektrafilm_harness::HostPixelFormat destinationFormat;
    spektrafilm_harness::HostLayout hostLayout;
    if (!spektrafilm_harness::parseHostPixelFormat(options.sourceFormat, sourceFormat) ||
        !spektrafilm_harness::parseHostPixelFormat(options.destinationFormat, destinationFormat) ||
        !spektrafilm_harness::parseHostLayout(options.hostLayout, hostLayout)) {
      std::cerr << "Invalid host I/O configuration.\n";
      return 2;
    }
    spektrafilm_harness::HostRgbaBuffer source = spektrafilm_harness::makeSourceHostRgba(
      sourcePixels,
      options.width,
      options.height,
      sourceFormat,
      hostLayout
    );
    spektrafilm_harness::HostRgbaBuffer destination = spektrafilm_harness::makeDestinationHostRgba(
      options.width,
      options.height,
      destinationFormat,
      hostLayout
    );

    spektrafilm::MetalRenderer renderer;
    if (!renderer.isAvailable()) {
      std::cerr << "Metal renderer unavailable: " << renderer.lastError() << "\n";
      return 1;
    }

    const spektrafilm::ImageView sourceView = spektrafilm_harness::imageView(source);
    spektrafilm::MutableImageView destinationView = spektrafilm_harness::mutableImageView(destination);
    const spektrafilm::RenderWindow window = spektrafilm_harness::renderWindowForLayout(hostLayout, options.width, options.height);
    if (!renderer.render(sourceView, destinationView, window, params, options.time)) {
      std::cerr << "Render failed: " << renderer.lastError() << "\n";
      return 1;
    }
    const std::vector<float> destinationPixels = spektrafilm_harness::extractWindowFloatRgba(destination);
    if (!writeFloatRgba(options.outputPath, destinationPixels)) {
      std::cerr << "Unable to write output float RGBA file: " << options.outputPath << "\n";
      return 2;
    }

    std::cout << "stage=" << normalizedTag(options.stage)
              << "\nwidth=" << options.width
              << "\nheight=" << options.height
              << "\nsource_format=" << options.sourceFormat
              << "\ndestination_format=" << options.destinationFormat
              << "\nhost_layout=" << options.hostLayout
              << "\noutput=" << options.outputPath << "\n";
  }
  return 0;
}
