#include "SpektraMetalRenderer.h"
#include "SpektraHarnessHostIO.h"

#import <Foundation/Foundation.h>

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <map>
#include <numeric>
#include <sstream>
#include <string>
#include <thread>
#include <tuple>
#include <vector>

namespace {

using Clock = std::chrono::steady_clock;

double elapsedMs(Clock::time_point start, Clock::time_point end) {
  return std::chrono::duration<double, std::milli>(end - start).count();
}

struct SampleStats {
  double average = 0.0;
  double median = 0.0;
  double p95 = 0.0;
  double standardDeviation = 0.0;
  double coefficientOfVariation = 0.0;
};

SampleStats sampleStats(std::vector<double> values) {
  SampleStats stats;
  if (values.empty()) {
    return stats;
  }
  stats.average = std::accumulate(values.begin(), values.end(), 0.0) / static_cast<double>(values.size());
  std::sort(values.begin(), values.end());
  const auto percentile = [&](double fraction) {
    const double position = fraction * static_cast<double>(values.size() - 1u);
    const size_t lo = static_cast<size_t>(std::floor(position));
    const size_t hi = std::min(lo + 1u, values.size() - 1u);
    return values[lo] + (values[hi] - values[lo]) * (position - static_cast<double>(lo));
  };
  stats.median = percentile(0.5);
  stats.p95 = percentile(0.95);
  double squaredError = 0.0;
  for (const double value : values) {
    const double delta = value - stats.average;
    squaredError += delta * delta;
  }
  stats.standardDeviation = std::sqrt(squaredError / static_cast<double>(values.size()));
  stats.coefficientOfVariation = stats.average != 0.0 ? stats.standardDeviation / stats.average : 0.0;
  return stats;
}

struct Options {
  int width = 1920;
  int height = 1080;
  int warmup = 1;
  int iterations = 3;
  std::string caseName = "default-final";
  std::string resourceDir;
  std::string scratchStorage = "private";
  std::string threadgroup = "auto";
  std::string passTiming = "off";
  std::string diffusionGroupSize = "2";
  std::string scannerImageStorage = "buffer";
  std::string blurBackend = "custom";
  std::string blurDownsample = "auto";
  std::string intermediatePrecision = "float";
  std::string diffusionClusterSigma = "0.10";
  std::string halationGroupedTail = "0";
  std::string scannerMps = "0";
  std::string grainBlurRecurrence = "1";
  std::string dirTailBackend = "mps";
  std::string densityCurveLookup = "binary";
  std::string spectralTransmittance = "pow";
  std::string finalCoreMode = "fused";
  std::string sourceFormat = "float";
  std::string destinationFormat = "float";
  std::string hostLayout = "contiguous";
  std::string profileReportDir;
  std::string captureGpuTracePath;
  int captureIteration = 0;
  bool detail = false;
  bool passCounters = false;
  bool passTimingExplicit = false;
  int grainSynthesisSamples = -1;
  bool grainSynthesisLayeredOverride = false;
  bool grainSynthesisLayered = true;
  bool grainSynthesisRadiusStdDevOverride = false;
  float grainSynthesisRadiusStdDev = 0.0f;
  bool grainSynthesisObservationSigmaOverride = false;
  float grainSynthesisObservationSigmaUm = 0.0f;
  std::string grainSynthesisSampler = "r2";
  std::string grainSynthesisRadiusLut = "512";
  std::string grainSynthesisTargetStorage = "float-buffer";
  std::string grainSynthesisCellMode = "offset-list";
};

void printUsage(const char *name) {
  std::cerr
    << "Usage: " << name << " [--width N] [--height N] [--iterations N] [--warmup N]\n"
    << "       [--case standard-core|default-final|production-grain|enlarged-production-grain|production-grain-no-sublayers|production-grain-no-blur|auto-exposure|halation-only|halation-boost|camera-diffusion-only|diffusion-only|print-diffusion-only|dir-only|scanner-only|scanner-glare|all-effects|all]\n"
    << "       [--resource-dir PATH] [--scratch-storage private|shared]\n"
    << "       [--threadgroup auto|16x16|32x8|8x32|64x4]\n"
    << "       [--scanner-image-storage buffer|texture]\n"
    << "       [--source-format float|half] [--destination-format float|half]\n"
    << "       [--host-layout contiguous|strided|offset]\n"
    << "       [--diffusion-group-size 1|2|4] [--pass-timing off|auto|counter|split]\n"
    << "       [--blur-backend custom|mps|auto] [--blur-downsample off|2|4|8|auto]\n"
    << "       [--intermediate-precision float|half-blur] [--diffusion-cluster-sigma off|0.05|0.10]\n"
    << "       [--halation-grouped-tail 0|1] [--scanner-mps 0|1] [--grain-blur-recurrence 0|1]\n"
    << "       [--dir-tail-backend fused|mps]\n"
    << "       [--density-curve-lookup binary|uniform-linear|uniform-nearest]\n"
    << "       [--spectral-transmittance pow|exp2|fast-exp]\n"
    << "       [--final-core-mode fused|staged]\n"
    << "       [--grain-synthesis-samples N] [--grain-synthesis-layered on|off]\n"
    << "       [--grain-synthesis-radius-stddev X] [--grain-synthesis-observation-sigma-um X]\n"
    << "       [--grain-synthesis-sampler r2|antithetic|sobol-blue]\n"
    << "       [--grain-synthesis-radius-lut off|256|512]\n"
    << "       [--grain-synthesis-target-storage float-buffer|half-buffer|r16-texture-array]\n"
    << "       [--grain-synthesis-cell-mode current|offset-list|threadgroup-cache]\n"
    << "       [--profile-report DIR] [--capture-gputrace PATH] [--capture-iteration N]\n"
    << "       [--detail] [--pass-counters]\n";
}

bool parseInt(const char *text, int &out) {
  char *end = nullptr;
  const long value = std::strtol(text, &end, 10);
  if (!end || *end != '\0' || value <= 0 || value > 32768) {
    return false;
  }
  out = static_cast<int>(value);
  return true;
}

bool parseNonNegativeInt(const char *text, int &out) {
  char *end = nullptr;
  const long value = std::strtol(text, &end, 10);
  if (!end || *end != '\0' || value < 0 || value > 32768) {
    return false;
  }
  out = static_cast<int>(value);
  return true;
}

bool parseFloat(const char *text, float &out) {
  char *end = nullptr;
  const float value = std::strtof(text, &end);
  if (!end || *end != '\0' || !std::isfinite(value)) {
    return false;
  }
  out = value;
  return true;
}

bool parseBool(const char *text, bool &out) {
  const std::string value = text ? std::string(text) : "";
  if (value == "1" || value == "true" || value == "TRUE" || value == "yes" || value == "YES" || value == "on" || value == "ON") {
    out = true;
    return true;
  }
  if (value == "0" || value == "false" || value == "FALSE" || value == "no" || value == "NO" || value == "off" || value == "OFF") {
    out = false;
    return true;
  }
  return false;
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
    } else if (arg == "--width") {
      const char *value = requireValue("--width");
      if (!value || !parseInt(value, options.width)) {
        return false;
      }
    } else if (arg == "--height") {
      const char *value = requireValue("--height");
      if (!value || !parseInt(value, options.height)) {
        return false;
      }
    } else if (arg == "--iterations") {
      const char *value = requireValue("--iterations");
      if (!value || !parseInt(value, options.iterations)) {
        return false;
      }
    } else if (arg == "--warmup") {
      const char *value = requireValue("--warmup");
      if (!value || !parseNonNegativeInt(value, options.warmup)) {
        return false;
      }
    } else if (arg == "--case") {
      const char *value = requireValue("--case");
      if (!value) {
        return false;
      }
      options.caseName = value;
    } else if (arg == "--resource-dir") {
      const char *value = requireValue("--resource-dir");
      if (!value) {
        return false;
      }
      options.resourceDir = value;
    } else if (arg == "--scratch-storage") {
      const char *value = requireValue("--scratch-storage");
      if (!value || (std::string(value) != "private" && std::string(value) != "shared")) {
        return false;
      }
      options.scratchStorage = value;
    } else if (arg == "--threadgroup") {
      const char *value = requireValue("--threadgroup");
      const std::string mode = value ? std::string(value) : "";
      if (mode != "auto" && mode != "16x16" && mode != "32x8" && mode != "8x32" && mode != "64x4") {
        return false;
      }
      options.threadgroup = mode;
    } else if (arg == "--pass-timing") {
      const char *value = requireValue("--pass-timing");
      const std::string mode = value ? std::string(value) : "";
      if (mode != "off" && mode != "auto" && mode != "counter" && mode != "split") {
        return false;
      }
      options.passTiming = mode;
      options.passTimingExplicit = true;
    } else if (arg == "--scanner-image-storage") {
      const char *value = requireValue("--scanner-image-storage");
      const std::string mode = value ? std::string(value) : "";
      if (mode != "buffer" && mode != "texture") {
        return false;
      }
      options.scannerImageStorage = mode;
    } else if (arg == "--source-format") {
      const char *value = requireValue("--source-format");
      spektrafilm_harness::HostPixelFormat format;
      if (!value || !spektrafilm_harness::parseHostPixelFormat(value, format)) {
        return false;
      }
      options.sourceFormat = spektrafilm_harness::hostPixelFormatName(format);
    } else if (arg == "--destination-format") {
      const char *value = requireValue("--destination-format");
      spektrafilm_harness::HostPixelFormat format;
      if (!value || !spektrafilm_harness::parseHostPixelFormat(value, format)) {
        return false;
      }
      options.destinationFormat = spektrafilm_harness::hostPixelFormatName(format);
    } else if (arg == "--host-layout") {
      const char *value = requireValue("--host-layout");
      spektrafilm_harness::HostLayout layout;
      if (!value || !spektrafilm_harness::parseHostLayout(value, layout)) {
        return false;
      }
      options.hostLayout = spektrafilm_harness::hostLayoutName(layout);
    } else if (arg == "--profile-report") {
      const char *value = requireValue("--profile-report");
      if (!value) {
        return false;
      }
      options.profileReportDir = value;
    } else if (arg == "--capture-gputrace") {
      const char *value = requireValue("--capture-gputrace");
      if (!value) {
        return false;
      }
      options.captureGpuTracePath = value;
    } else if (arg == "--capture-iteration") {
      const char *value = requireValue("--capture-iteration");
      if (!value || !parseNonNegativeInt(value, options.captureIteration)) {
        return false;
      }
    } else if (arg == "--diffusion-group-size") {
      const char *value = requireValue("--diffusion-group-size");
      const std::string size = value ? std::string(value) : "";
      if (size != "1" && size != "2" && size != "4") {
        return false;
      }
      options.diffusionGroupSize = size;
    } else if (arg == "--blur-backend") {
      const char *value = requireValue("--blur-backend");
      const std::string mode = value ? std::string(value) : "";
      if (mode != "custom" && mode != "mps" && mode != "auto") {
        return false;
      }
      options.blurBackend = mode;
    } else if (arg == "--blur-downsample") {
      const char *value = requireValue("--blur-downsample");
      const std::string mode = value ? std::string(value) : "";
      if (mode != "off" && mode != "2" && mode != "4" && mode != "8" && mode != "auto") {
        return false;
      }
      options.blurDownsample = mode;
    } else if (arg == "--intermediate-precision") {
      const char *value = requireValue("--intermediate-precision");
      const std::string mode = value ? std::string(value) : "";
      if (mode != "float" && mode != "half-blur") {
        return false;
      }
      options.intermediatePrecision = mode;
    } else if (arg == "--diffusion-cluster-sigma") {
      const char *value = requireValue("--diffusion-cluster-sigma");
      const std::string mode = value ? std::string(value) : "";
      if (mode != "off" && mode != "0.05" && mode != "0.10") {
        return false;
      }
      options.diffusionClusterSigma = mode;
    } else if (arg == "--halation-grouped-tail") {
      const char *value = requireValue("--halation-grouped-tail");
      bool parsed = false;
      if (!value || !parseBool(value, parsed)) {
        return false;
      }
      options.halationGroupedTail = parsed ? "1" : "0";
    } else if (arg == "--scanner-mps") {
      const char *value = requireValue("--scanner-mps");
      bool parsed = false;
      if (!value || !parseBool(value, parsed)) {
        return false;
      }
      options.scannerMps = parsed ? "1" : "0";
    } else if (arg == "--grain-blur-recurrence") {
      const char *value = requireValue("--grain-blur-recurrence");
      bool parsed = false;
      if (!value || !parseBool(value, parsed)) {
        return false;
      }
      options.grainBlurRecurrence = parsed ? "1" : "0";
    } else if (arg == "--dir-tail-backend") {
      const char *value = requireValue("--dir-tail-backend");
      const std::string mode = value ? std::string(value) : "";
      if (mode != "fused" && mode != "mps") {
        return false;
      }
      options.dirTailBackend = mode;
    } else if (arg == "--density-curve-lookup") {
      const char *value = requireValue("--density-curve-lookup");
      std::string mode = value ? std::string(value) : "";
      if (mode == "uniform" || mode == "linear") {
        mode = "uniform-linear";
      } else if (mode == "nearest") {
        mode = "uniform-nearest";
      }
      if (mode != "binary" && mode != "uniform-linear" && mode != "uniform-nearest") {
        return false;
      }
      options.densityCurveLookup = mode;
    } else if (arg == "--spectral-transmittance") {
      const char *value = requireValue("--spectral-transmittance");
      std::string mode = value ? std::string(value) : "";
      if (mode == "fast" || mode == "fast-exp2") {
        mode = "fast-exp";
      }
      if (mode != "pow" && mode != "exp2" && mode != "fast-exp") {
        return false;
      }
      options.spectralTransmittance = mode;
    } else if (arg == "--final-core-mode") {
      const char *value = requireValue("--final-core-mode");
      const std::string mode = value ? std::string(value) : "";
      if (mode != "fused" && mode != "staged") {
        return false;
      }
      options.finalCoreMode = mode;
    } else if (arg == "--detail") {
      options.detail = true;
    } else if (arg == "--pass-counters") {
      options.passCounters = true;
    } else if (arg == "--grain-synthesis-samples") {
      const char *value = requireValue("--grain-synthesis-samples");
      if (!value || !parseInt(value, options.grainSynthesisSamples)) {
        return false;
      }
    } else if (arg == "--grain-synthesis-layered") {
      const char *value = requireValue("--grain-synthesis-layered");
      if (!value || !parseBool(value, options.grainSynthesisLayered)) {
        return false;
      }
      options.grainSynthesisLayeredOverride = true;
    } else if (arg == "--grain-synthesis-radius-stddev") {
      const char *value = requireValue("--grain-synthesis-radius-stddev");
      if (!value || !parseFloat(value, options.grainSynthesisRadiusStdDev) || options.grainSynthesisRadiusStdDev < 0.0f) {
        return false;
      }
      options.grainSynthesisRadiusStdDevOverride = true;
    } else if (arg == "--grain-synthesis-observation-sigma-um") {
      const char *value = requireValue("--grain-synthesis-observation-sigma-um");
      if (!value || !parseFloat(value, options.grainSynthesisObservationSigmaUm) || options.grainSynthesisObservationSigmaUm < 0.0f) {
        return false;
      }
      options.grainSynthesisObservationSigmaOverride = true;
    } else if (arg == "--grain-synthesis-sampler") {
      const char *value = requireValue("--grain-synthesis-sampler");
      const std::string mode = value ? std::string(value) : "";
      if (mode != "r2" && mode != "antithetic" && mode != "sobol-blue") {
        return false;
      }
      options.grainSynthesisSampler = mode;
    } else if (arg == "--grain-synthesis-radius-lut") {
      const char *value = requireValue("--grain-synthesis-radius-lut");
      const std::string mode = value ? std::string(value) : "";
      if (mode != "off" && mode != "256" && mode != "512") {
        return false;
      }
      options.grainSynthesisRadiusLut = mode;
    } else if (arg == "--grain-synthesis-target-storage") {
      const char *value = requireValue("--grain-synthesis-target-storage");
      const std::string mode = value ? std::string(value) : "";
      if (mode != "float-buffer" && mode != "half-buffer" && mode != "r16-texture-array") {
        return false;
      }
      options.grainSynthesisTargetStorage = mode;
    } else if (arg == "--grain-synthesis-cell-mode") {
      const char *value = requireValue("--grain-synthesis-cell-mode");
      const std::string mode = value ? std::string(value) : "";
      if (mode != "current" && mode != "offset-list" && mode != "threadgroup-cache") {
        return false;
      }
      options.grainSynthesisCellMode = mode;
    } else {
      std::cerr << "Unknown argument: " << arg << "\n";
      return false;
    }
  }
  return true;
}

std::vector<float> makeSyntheticFrame(int width, int height) {
  std::vector<float> pixels(static_cast<size_t>(width) * static_cast<size_t>(height) * 4u, 1.0f);
  for (int y = 0; y < height; ++y) {
    const float fy = height > 1 ? static_cast<float>(y) / static_cast<float>(height - 1) : 0.0f;
    for (int x = 0; x < width; ++x) {
      const float fx = width > 1 ? static_cast<float>(x) / static_cast<float>(width - 1) : 0.0f;
      const float edge = x > width / 2 ? 0.18f : 0.0f;
      const float chip = ((x / 96 + y / 96) & 1) ? 0.04f : 0.0f;
      float *pixel = pixels.data() + (static_cast<size_t>(y) * width + x) * 4u;
      pixel[0] = std::clamp(0.02f + 0.85f * fx + edge, 0.0f, 1.25f);
      pixel[1] = std::clamp(0.03f + 0.75f * fy + chip, 0.0f, 1.15f);
      pixel[2] = std::clamp(0.04f + 0.55f * (1.0f - fx) + 0.25f * fy, 0.0f, 1.10f);
      pixel[3] = 1.0f;
    }
  }
  return pixels;
}

spektrafilm::RenderParams baseParams() {
  spektrafilm::RenderParams params;
  params.inputColorSpace = spektrafilm::ColorSpace::LinearRec2020;
  params.outputColorSpace = spektrafilm::ColorSpace::Rec709Gamma24;
  params.grainSeed = 42u;
  params.grainAnimate = false;
  return params;
}

spektrafilm::RenderParams paramsForCase(const std::string &caseName) {
  spektrafilm::RenderParams params = baseParams();

  if (caseName == "standard-core") {
    params.process = spektrafilm::ProcessMode::PrintSimulation;
    params.renderOutput = spektrafilm::RenderOutputMode::FinalPreview;
    params.outputRole = spektrafilm::OutputRole::DisplaySdr;
    params.autoExposure = false;
    params.grainEnabled = false;
    params.grainModel = spektrafilm::GrainModel::Preview;
    params.halationEnabled = false;
    params.scatterAmount = 0.0f;
    params.halationAmount = 0.0f;
    params.cameraDiffusionEnabled = false;
    params.printDiffusionEnabled = false;
    params.dirCouplersAmount = 0.0f;
    params.scannerEnabled = false;
    params.glarePercent = 0.0f;
    params.scannerMtf50LpMm = 0.0f;
    params.scannerUnsharpRadiusUm = 0.0f;
    params.scannerUnsharpAmount = 0.0f;
    return params;
  }
  if (caseName == "default-final") {
    return params;
  }
  if (caseName == "production-grain") {
    params.grainEnabled = true;
    params.grainModel = spektrafilm::GrainModel::Production;
    return params;
  }
  if (caseName == "enlarged-production-grain") {
    params.grainEnabled = true;
    params.grainModel = spektrafilm::GrainModel::Production;
    params.enlargerScale = 4.0f;
    params.enlargerOffsetXPercent = 0.0f;
    params.enlargerOffsetYPercent = 0.0f;
    return params;
  }
  if (caseName == "grain-synthesis") {
    params.grainEnabled = true;
    params.grainModel = spektrafilm::GrainModel::GrainSynthesis;
    params.grainSynthesisSamples = 64;
    params.grainSynthesisRadiusStdDevRatio = 0.0f;
    return params;
  }
  if (caseName == "grain-synthesis-hq") {
    params.grainEnabled = true;
    params.grainModel = spektrafilm::GrainModel::GrainSynthesis;
    params.grainSynthesisSamples = 256;
    params.grainSynthesisRadiusStdDevRatio = 0.2f;
    params.grainSynthesisMaxGrainsPerCell = 64;
    return params;
  }
  if (caseName == "grain-synthesis-nonlayered") {
    params.grainEnabled = true;
    params.grainModel = spektrafilm::GrainModel::GrainSynthesis;
    params.grainSynthesisSamples = 64;
    params.grainSynthesisRadiusStdDevRatio = 0.0f;
    params.grainSynthesisLayered = false;
    return params;
  }
  if (caseName == "production-grain-no-sublayers") {
    params.grainEnabled = true;
    params.grainModel = spektrafilm::GrainModel::Production;
    params.grainSublayersEnabled = false;
    return params;
  }
  if (caseName == "production-grain-no-blur") {
    params.grainEnabled = true;
    params.grainModel = spektrafilm::GrainModel::Production;
    params.grainFinalBlurUm = 0.0f;
    params.grainBlurDyeCloudsUm = 0.0f;
    params.grainMicroStructureScale = 0.0f;
    return params;
  }
  if (caseName == "auto-exposure") {
    params.autoExposure = true;
    params.autoExposureMethod = spektrafilm::AutoExposureMethod::Median;
    params.grainEnabled = false;
    params.halationEnabled = false;
    params.cameraDiffusionEnabled = false;
    params.printDiffusionEnabled = false;
    params.scannerEnabled = false;
    params.dirCouplersAmount = 0.0f;
    return params;
  }
  if (caseName == "halation-only") {
    params.grainEnabled = false;
    params.cameraDiffusionEnabled = false;
    params.printDiffusionEnabled = false;
    params.scannerEnabled = false;
    params.dirCouplersAmount = 0.0f;
    params.halationEnabled = true;
    params.scatterAmount = 1.0f;
    params.halationAmount = 1.0f;
    return params;
  }
  if (caseName == "halation-boost") {
    params.grainEnabled = false;
    params.cameraDiffusionEnabled = false;
    params.printDiffusionEnabled = false;
    params.scannerEnabled = false;
    params.dirCouplersAmount = 0.0f;
    params.halationEnabled = true;
    params.scatterAmount = 1.0f;
    params.halationAmount = 1.0f;
    params.halationBoostEv = 1.0f;
    return params;
  }
  if (caseName == "camera-diffusion-only" || caseName == "diffusion-only") {
    params.grainEnabled = false;
    params.halationEnabled = false;
    params.cameraDiffusionEnabled = true;
    params.cameraDiffusionStrength = 0.5f;
    params.printDiffusionEnabled = false;
    params.scannerEnabled = false;
    params.dirCouplersAmount = 0.0f;
    return params;
  }
  if (caseName == "print-diffusion-only") {
    params.grainEnabled = false;
    params.halationEnabled = false;
    params.cameraDiffusionEnabled = false;
    params.printDiffusionEnabled = true;
    params.printDiffusionStrength = 0.5f;
    params.scannerEnabled = false;
    params.dirCouplersAmount = 0.0f;
    return params;
  }
  if (caseName == "dir-only") {
    params.grainEnabled = false;
    params.halationEnabled = false;
    params.cameraDiffusionEnabled = false;
    params.printDiffusionEnabled = false;
    params.scannerEnabled = false;
    params.dirCouplersAmount = 0.6f;
    return params;
  }
  if (caseName == "scanner-only") {
    params.grainEnabled = false;
    params.halationEnabled = false;
    params.cameraDiffusionEnabled = false;
    params.printDiffusionEnabled = false;
    params.dirCouplersAmount = 0.0f;
    params.process = spektrafilm::ProcessMode::ScanNegative;
    params.scannerEnabled = true;
    params.scannerMtf50LpMm = 60.0f;
    params.scannerUnsharpRadiusUm = 5.0f;
    params.scannerUnsharpAmount = 0.7f;
    params.scannerWhiteCorrection = true;
    params.scannerBlackCorrection = true;
    return params;
  }
  if (caseName == "scanner-glare") {
    params.grainEnabled = false;
    params.halationEnabled = false;
    params.cameraDiffusionEnabled = false;
    params.printDiffusionEnabled = false;
    params.dirCouplersAmount = 0.0f;
    params.process = spektrafilm::ProcessMode::PrintSimulation;
    params.scannerEnabled = true;
    params.scannerMtf50LpMm = 0.0f;
    params.scannerUnsharpRadiusUm = 0.0f;
    params.scannerUnsharpAmount = 0.0f;
    params.glarePercent = 0.03f;
    return params;
  }
  if (caseName == "all-effects") {
    params.grainEnabled = true;
    params.grainModel = spektrafilm::GrainModel::Production;
    params.grainSubLayerCount = 3;
    params.dirCouplersAmount = 0.6f;
    params.cameraDiffusionEnabled = true;
    params.cameraDiffusionStrength = 0.7f;
    params.printDiffusionEnabled = false;
    params.printDiffusionStrength = 0.0f;
    params.scannerEnabled = true;
    params.scannerMtf50LpMm = 60.0f;
    params.scannerUnsharpRadiusUm = 5.0f;
    params.scannerUnsharpAmount = 0.7f;
    return params;
  }

  return params;
}

std::vector<std::string> selectedCases(const std::string &caseName) {
  const std::vector<std::string> allCases = {
    "default-final",
    "production-grain",
    "enlarged-production-grain",
    "production-grain-no-sublayers",
    "production-grain-no-blur",
    "auto-exposure",
    "halation-only",
    "halation-boost",
    "camera-diffusion-only",
    "print-diffusion-only",
    "dir-only",
    "scanner-only",
    "scanner-glare",
    "all-effects",
  };
  if (caseName == "all") {
    return allCases;
  }
  const std::vector<std::string> aliasCases = {
    "standard-core",
    "diffusion-only",
  };
  const bool knownCase = std::find(allCases.begin(), allCases.end(), caseName) != allCases.end() ||
                         std::find(aliasCases.begin(), aliasCases.end(), caseName) != aliasCases.end();
  if (!knownCase) {
    return {};
  }
  return {caseName};
}

double averageLuma(const std::vector<float> &pixels) {
  double sum = 0.0;
  const size_t count = pixels.size() / 4u;
  for (size_t i = 0; i < count; ++i) {
    const float *pixel = pixels.data() + i * 4u;
    sum += 0.2126 * pixel[0] + 0.7152 * pixel[1] + 0.0722 * pixel[2];
  }
  return count > 0 ? sum / static_cast<double>(count) : 0.0;
}

constexpr double kSixtyFpsBudgetMs = 1000.0 / 60.0;

struct PassSample {
  std::string caseName;
  int iteration = 0;
  size_t passIndex = 0;
  std::string timingMode;
  double frameWallMs = 0.0;
  double frameGpuCommandBufferMs = 0.0;
  spektrafilm::MetalPassDiagnostics pass;
};

struct FrameSample {
  std::string caseName;
  int iteration = 0;
  double wallMs = 0.0;
  double fps = 0.0;
  double cpuSetupMs = 0.0;
  double sourceCopyMs = 0.0;
  double commandEncodingMs = 0.0;
  double commandBufferMs = 0.0;
  double gpuCommandBufferMs = 0.0;
  double outputCopyMs = 0.0;
  uint32_t passCount = 0;
  uint64_t staticAllocationBytes = 0;
  uint64_t staticAllocationCount = 0;
  uint64_t scratchAllocationBytes = 0;
  uint64_t scratchAllocationCount = 0;
  uint64_t sharedScratchAllocationBytes = 0;
  uint64_t sharedScratchAllocationCount = 0;
  uint64_t privateScratchAllocationBytes = 0;
  uint64_t privateScratchAllocationCount = 0;
  uint64_t uploadBytes = 0;
  bool passGpuTiming = false;
  std::string passTimingMode = "off";
};

struct CaseProfile {
  std::string caseName;
  int width = 0;
  int height = 0;
  int iterations = 0;
  double avgWallMs = 0.0;
  double avgFps = 0.0;
  double avgCpuSetupMs = 0.0;
  double avgSourceCopyMs = 0.0;
  double avgCommandEncodingMs = 0.0;
  double avgCommandBufferMs = 0.0;
  double avgGpuCommandBufferMs = 0.0;
  double avgOutputCopyMs = 0.0;
  double avgPassCount = 0.0;
  double avgStaticAllocationBytes = 0.0;
  double avgStaticAllocationCount = 0.0;
  double avgScratchAllocationBytes = 0.0;
  double avgScratchAllocationCount = 0.0;
  double avgSharedScratchAllocationBytes = 0.0;
  double avgSharedScratchAllocationCount = 0.0;
  double avgPrivateScratchAllocationBytes = 0.0;
  double avgPrivateScratchAllocationCount = 0.0;
  double avgUploadBytes = 0.0;
  double meanLuma = 0.0;
  bool sourceNoCopy = false;
  bool destinationNoCopy = false;
  bool privateScratch = false;
  bool passGpuTiming = false;
  bool halation = false;
  bool cameraDiffusion = false;
  bool printDiffusion = false;
  bool dir = false;
  bool productionGrain = false;
  bool grainSynthesis = false;
  bool finalPostProcess = false;
  bool scannerTextureIntermediates = false;
  bool halationGroupedTail = false;
  bool scannerMps = false;
  bool grainBlurRecurrence = false;
  uint32_t diffusionGroupSize = 2u;
  std::string passTimingMode = "off";
  std::string threadgroupMode = "auto";
  std::string blurBackend = "custom";
  std::string blurDownsample = "auto";
  std::string intermediatePrecision = "float";
  std::string diffusionClusterSigma = "0.10";
  std::string dirTailBackend = "mps";
  std::string densityCurveLookup = "binary";
  std::string spectralTransmittance = "pow";
  std::string finalCoreMode = "fused";
  spektrafilm::MetalRenderDiagnostics lastDiagnostics;
  std::vector<FrameSample> frameSamples;
  std::vector<PassSample> passSamples;
};

std::string trimTrailingWhitespace(std::string text) {
  while (!text.empty() && (text.back() == '\n' || text.back() == '\r' || text.back() == ' ' || text.back() == '\t')) {
    text.pop_back();
  }
  return text;
}

std::string runCommandOutput(const char *command) {
  std::array<char, 256> buffer{};
  std::string output;
  FILE *pipe = popen(command, "r");
  if (!pipe) {
    return "";
  }
  while (fgets(buffer.data(), static_cast<int>(buffer.size()), pipe)) {
    output += buffer.data();
  }
  pclose(pipe);
  return trimTrailingWhitespace(output);
}

std::string jsonEscape(const std::string &value) {
  std::ostringstream out;
  for (char ch : value) {
    switch (ch) {
      case '\\': out << "\\\\"; break;
      case '"': out << "\\\""; break;
      case '\b': out << "\\b"; break;
      case '\f': out << "\\f"; break;
      case '\n': out << "\\n"; break;
      case '\r': out << "\\r"; break;
      case '\t': out << "\\t"; break;
      default:
        if (static_cast<unsigned char>(ch) < 0x20u) {
          out << "\\u" << std::hex << std::setw(4) << std::setfill('0') << static_cast<int>(static_cast<unsigned char>(ch))
              << std::dec << std::setfill(' ');
        } else {
          out << ch;
        }
        break;
    }
  }
  return out.str();
}

std::string csvEscape(const std::string &value) {
  const bool needsQuotes = value.find_first_of(",\"\n\r") != std::string::npos;
  if (!needsQuotes) {
    return value;
  }
  std::string escaped = "\"";
  for (char ch : value) {
    if (ch == '"') {
      escaped += "\"\"";
    } else {
      escaped += ch;
    }
  }
  escaped += '"';
  return escaped;
}

uint64_t ceilDiv(uint64_t numerator, uint64_t denominator) {
  if (denominator == 0u) {
    return 0u;
  }
  return (numerator + denominator - 1u) / denominator;
}

uint64_t passTotalThreads(const spektrafilm::MetalPassDiagnostics &pass) {
  return static_cast<uint64_t>(pass.width) *
         static_cast<uint64_t>(pass.height) *
         static_cast<uint64_t>(pass.depth);
}

uint64_t passThreadsPerThreadgroup(const spektrafilm::MetalPassDiagnostics &pass) {
  return static_cast<uint64_t>(pass.threadgroupWidth) *
         static_cast<uint64_t>(pass.threadgroupHeight);
}

uint64_t passThreadgroupCount(const spektrafilm::MetalPassDiagnostics &pass) {
  return ceilDiv(pass.width, pass.threadgroupWidth) *
         ceilDiv(pass.height, pass.threadgroupHeight) *
         static_cast<uint64_t>(pass.depth);
}

double passEstimatedGbPerSecond(const spektrafilm::MetalPassDiagnostics &pass) {
  return pass.gpuMs > 0.0 ? static_cast<double>(pass.estimatedBytes) / pass.gpuMs / 1000000.0 : 0.0;
}

double passEstimatedBytesPerThread(const spektrafilm::MetalPassDiagnostics &pass) {
  const uint64_t totalThreads = passTotalThreads(pass);
  return totalThreads > 0u ? static_cast<double>(pass.estimatedBytes) / static_cast<double>(totalThreads) : 0.0;
}

struct PassAggregate {
  std::string caseName;
  size_t passIndex = 0;
  std::string name;
  uint32_t width = 0;
  uint32_t height = 0;
  uint32_t depth = 0;
  uint32_t threadgroupWidth = 0;
  uint32_t threadgroupHeight = 0;
  uint32_t threadExecutionWidth = 0;
  uint32_t maxTotalThreadsPerThreadgroup = 0;
  uint64_t estimatedBytes = 0;
  uint32_t sampleCount = 0;
  uint32_t gpuTimeAvailableCount = 0;
  double totalMs = 0.0;
  double minMs = std::numeric_limits<double>::max();
  double maxMs = 0.0;
  double frameMs = 0.0;
  std::vector<double> gpuSamples;

  void add(const PassSample &sample, double caseFrameMs) {
    caseName = sample.caseName;
    passIndex = sample.passIndex;
    name = sample.pass.name;
    width = sample.pass.width;
    height = sample.pass.height;
    depth = sample.pass.depth;
    threadgroupWidth = sample.pass.threadgroupWidth;
    threadgroupHeight = sample.pass.threadgroupHeight;
    threadExecutionWidth = sample.pass.threadExecutionWidth;
    maxTotalThreadsPerThreadgroup = sample.pass.maxTotalThreadsPerThreadgroup;
    estimatedBytes = sample.pass.estimatedBytes;
    frameMs = caseFrameMs;
    ++sampleCount;
    if (sample.pass.gpuTimeAvailable) {
      ++gpuTimeAvailableCount;
    }
    totalMs += sample.pass.gpuMs;
    gpuSamples.push_back(sample.pass.gpuMs);
    minMs = std::min(minMs, sample.pass.gpuMs);
    maxMs = std::max(maxMs, sample.pass.gpuMs);
  }

  double avgMs() const {
    return sampleCount > 0u ? totalMs / static_cast<double>(sampleCount) : 0.0;
  }

  double percentOfFrame() const {
    return frameMs > 0.0 ? (avgMs() / frameMs) * 100.0 : 0.0;
  }

  double estimatedGbPerSecond() const {
    const double ms = avgMs();
    return ms > 0.0 ? static_cast<double>(estimatedBytes) / ms / 1000000.0 : 0.0;
  }

  SampleStats stats() const {
    return sampleStats(gpuSamples);
  }
};

std::vector<PassAggregate> aggregatePasses(const std::vector<CaseProfile> &profiles) {
  std::map<std::tuple<std::string, size_t, std::string>, PassAggregate> aggregates;
  for (const CaseProfile &profile : profiles) {
    for (const PassSample &sample : profile.passSamples) {
      auto key = std::make_tuple(sample.caseName, sample.passIndex, sample.pass.name);
      aggregates[key].add(sample, profile.avgWallMs);
    }
  }
  std::vector<PassAggregate> rows;
  rows.reserve(aggregates.size());
  for (auto &entry : aggregates) {
    rows.push_back(entry.second);
  }
  return rows;
}

SampleStats frameWallStats(const CaseProfile &profile) {
  std::vector<double> values;
  values.reserve(profile.frameSamples.size());
  for (const FrameSample &frame : profile.frameSamples) {
    values.push_back(frame.wallMs);
  }
  return sampleStats(std::move(values));
}

SampleStats frameGpuStats(const CaseProfile &profile) {
  std::vector<double> values;
  values.reserve(profile.frameSamples.size());
  for (const FrameSample &frame : profile.frameSamples) {
    values.push_back(frame.gpuCommandBufferMs);
  }
  return sampleStats(std::move(values));
}

bool writeTextFile(const std::filesystem::path &path, const std::string &text) {
  std::ofstream out(path);
  if (!out) {
    std::cerr << "Unable to write " << path << "\n";
    return false;
  }
  out << text;
  return true;
}

bool waitForGpuTraceDocument(const std::filesystem::path &path) {
  const std::filesystem::path metadataPath = path / "metadata";
  const std::filesystem::path indexPath = path / "index";
  const std::filesystem::path capturePath = path / "capture";
  uintmax_t previousTotalSize = 0u;
  int stableCount = 0;
  for (int attempt = 0; attempt < 50; ++attempt) {
    std::error_code ec;
    const bool hasRequiredFiles =
      std::filesystem::is_directory(path, ec) &&
      std::filesystem::is_regular_file(metadataPath, ec) &&
      std::filesystem::is_regular_file(indexPath, ec) &&
      std::filesystem::is_regular_file(capturePath, ec);
    uintmax_t totalSize = 0u;
    if (hasRequiredFiles) {
      totalSize += std::filesystem::file_size(metadataPath, ec);
      totalSize += std::filesystem::file_size(indexPath, ec);
      totalSize += std::filesystem::file_size(capturePath, ec);
      if (totalSize > 0u && totalSize == previousTotalSize) {
        ++stableCount;
        if (stableCount >= 3) {
          return true;
        }
      } else {
        stableCount = 0;
      }
      previousTotalSize = totalSize;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
  }
  return false;
}

bool writeProfileReport(
  const Options &options,
  const std::vector<std::string> &argv,
  const std::vector<CaseProfile> &profiles
) {
  if (options.profileReportDir.empty()) {
    return true;
  }
  const std::filesystem::path reportDir(options.profileReportDir);
  std::error_code ec;
  std::filesystem::create_directories(reportDir, ec);
  if (ec) {
    std::cerr << "Unable to create profile report directory " << reportDir << ": " << ec.message() << "\n";
    return false;
  }

  std::ostringstream summaryCsv;
  summaryCsv << "case,width,height,iterations,avg_wall_ms,avg_fps,avg_cpu_setup_ms,avg_source_copy_ms,"
             << "avg_command_encoding_ms,avg_command_buffer_ms,avg_gpu_command_buffer_ms,avg_wait_or_overhead_ms,"
             << "avg_output_copy_ms,avg_pass_count,frame_budget_ms,budget_delta_ms,fits_60fps,pass_gpu_timing,"
             << "pass_timing_mode,halation,camera_diffusion,print_diffusion,dir,production_grain,grain_synthesis,"
             << "final_post_process,final_core_mode,wall_median_ms,wall_p95_ms,wall_stddev_ms,wall_cov,"
             << "gpu_median_ms,gpu_p95_ms,gpu_stddev_ms,gpu_cov,mean_luma\n";
  summaryCsv << std::fixed << std::setprecision(6);
  for (const CaseProfile &profile : profiles) {
    const double waitOrOverheadMs = std::max(0.0, profile.avgCommandBufferMs - profile.avgGpuCommandBufferMs);
    const double budgetDeltaMs = profile.avgWallMs - kSixtyFpsBudgetMs;
    const SampleStats wallStats = frameWallStats(profile);
    const SampleStats gpuStats = frameGpuStats(profile);
    summaryCsv << csvEscape(profile.caseName) << ','
               << profile.width << ','
               << profile.height << ','
               << profile.iterations << ','
               << profile.avgWallMs << ','
               << profile.avgFps << ','
               << profile.avgCpuSetupMs << ','
               << profile.avgSourceCopyMs << ','
               << profile.avgCommandEncodingMs << ','
               << profile.avgCommandBufferMs << ','
               << profile.avgGpuCommandBufferMs << ','
               << waitOrOverheadMs << ','
               << profile.avgOutputCopyMs << ','
               << profile.avgPassCount << ','
               << kSixtyFpsBudgetMs << ','
               << budgetDeltaMs << ','
               << (profile.avgWallMs <= kSixtyFpsBudgetMs ? 1 : 0) << ','
               << (profile.passGpuTiming ? 1 : 0) << ','
               << csvEscape(profile.passTimingMode) << ','
               << (profile.halation ? 1 : 0) << ','
               << (profile.cameraDiffusion ? 1 : 0) << ','
               << (profile.printDiffusion ? 1 : 0) << ','
               << (profile.dir ? 1 : 0) << ','
               << (profile.productionGrain ? 1 : 0) << ','
               << (profile.grainSynthesis ? 1 : 0) << ','
               << (profile.finalPostProcess ? 1 : 0) << ','
               << csvEscape(profile.finalCoreMode) << ','
               << wallStats.median << ','
               << wallStats.p95 << ','
               << wallStats.standardDeviation << ','
               << wallStats.coefficientOfVariation << ','
               << gpuStats.median << ','
               << gpuStats.p95 << ','
               << gpuStats.standardDeviation << ','
               << gpuStats.coefficientOfVariation << ','
               << profile.meanLuma
               << '\n';
  }
  if (!writeTextFile(reportDir / "summary.csv", summaryCsv.str())) {
    return false;
  }

  std::ostringstream framesCsv;
  framesCsv << "case,iteration,wall_ms,fps,cpu_setup_ms,source_copy_ms,command_encoding_ms,"
            << "command_buffer_ms,gpu_command_buffer_ms,wait_or_overhead_ms,output_copy_ms,pass_count,"
            << "pass_gpu_timing,pass_timing_mode,static_alloc_bytes,static_alloc_count,scratch_alloc_bytes,"
            << "scratch_alloc_count,shared_scratch_alloc_bytes,shared_scratch_alloc_count,"
            << "private_scratch_alloc_bytes,private_scratch_alloc_count,upload_bytes\n";
  framesCsv << std::fixed << std::setprecision(6);
  for (const CaseProfile &profile : profiles) {
    for (const FrameSample &frame : profile.frameSamples) {
      const double waitOrOverheadMs = std::max(0.0, frame.commandBufferMs - frame.gpuCommandBufferMs);
      framesCsv << csvEscape(frame.caseName) << ','
                << frame.iteration << ','
                << frame.wallMs << ','
                << frame.fps << ','
                << frame.cpuSetupMs << ','
                << frame.sourceCopyMs << ','
                << frame.commandEncodingMs << ','
                << frame.commandBufferMs << ','
                << frame.gpuCommandBufferMs << ','
                << waitOrOverheadMs << ','
                << frame.outputCopyMs << ','
                << frame.passCount << ','
                << (frame.passGpuTiming ? 1 : 0) << ','
                << csvEscape(frame.passTimingMode) << ','
                << frame.staticAllocationBytes << ','
                << frame.staticAllocationCount << ','
                << frame.scratchAllocationBytes << ','
                << frame.scratchAllocationCount << ','
                << frame.sharedScratchAllocationBytes << ','
                << frame.sharedScratchAllocationCount << ','
                << frame.privateScratchAllocationBytes << ','
                << frame.privateScratchAllocationCount << ','
                << frame.uploadBytes
                << '\n';
    }
  }
  if (!writeTextFile(reportDir / "frames.csv", framesCsv.str())) {
    return false;
  }

  const std::vector<PassAggregate> passAggregates = aggregatePasses(profiles);
  std::ostringstream passesCsv;
  passesCsv << "case,pass_index,name,samples,gpu_time_available_samples,avg_ms,min_ms,max_ms,percent_of_frame,"
            << "median_ms,p95_ms,stddev_ms,cov,width,height,depth,threadgroup_width,threadgroup_height,thread_execution_width,"
            << "max_total_threads_per_threadgroup,estimated_bytes,estimated_gb_s\n";
  passesCsv << std::fixed << std::setprecision(6);
  for (const PassAggregate &pass : passAggregates) {
    const SampleStats stats = pass.stats();
    passesCsv << csvEscape(pass.caseName) << ','
              << pass.passIndex << ','
              << csvEscape(pass.name) << ','
              << pass.sampleCount << ','
              << pass.gpuTimeAvailableCount << ','
              << pass.avgMs() << ','
              << (pass.sampleCount > 0u ? pass.minMs : 0.0) << ','
              << pass.maxMs << ','
              << pass.percentOfFrame() << ','
              << stats.median << ','
              << stats.p95 << ','
              << stats.standardDeviation << ','
              << stats.coefficientOfVariation << ','
              << pass.width << ','
              << pass.height << ','
              << pass.depth << ','
              << pass.threadgroupWidth << ','
              << pass.threadgroupHeight << ','
              << pass.threadExecutionWidth << ','
              << pass.maxTotalThreadsPerThreadgroup << ','
              << pass.estimatedBytes << ','
              << pass.estimatedGbPerSecond()
              << '\n';
  }
  if (!writeTextFile(reportDir / "passes.csv", passesCsv.str())) {
    return false;
  }

  std::ostringstream passSamplesCsv;
  passSamplesCsv << "case,iteration,pass_index,name,gpu_ms,percent_of_frame,gpu_time_available,timing_mode,"
                 << "width,height,depth,total_threads,threadgroup_width,threadgroup_height,threads_per_threadgroup,"
                 << "threadgroups,thread_execution_width,max_total_threads_per_threadgroup,estimated_bytes,"
                 << "estimated_bytes_per_thread,estimated_gb_s\n";
  passSamplesCsv << std::fixed << std::setprecision(6);
  for (const CaseProfile &profile : profiles) {
    for (const PassSample &sample : profile.passSamples) {
      const spektrafilm::MetalPassDiagnostics &pass = sample.pass;
      const double percentOfFrame = sample.frameWallMs > 0.0 ? (pass.gpuMs / sample.frameWallMs) * 100.0 : 0.0;
      passSamplesCsv << csvEscape(sample.caseName) << ','
                     << sample.iteration << ','
                     << sample.passIndex << ','
                     << csvEscape(pass.name) << ','
                     << pass.gpuMs << ','
                     << percentOfFrame << ','
                     << (pass.gpuTimeAvailable ? 1 : 0) << ','
                     << csvEscape(sample.timingMode) << ','
                     << pass.width << ','
                     << pass.height << ','
                     << pass.depth << ','
                     << passTotalThreads(pass) << ','
                     << pass.threadgroupWidth << ','
                     << pass.threadgroupHeight << ','
                     << passThreadsPerThreadgroup(pass) << ','
                     << passThreadgroupCount(pass) << ','
                     << pass.threadExecutionWidth << ','
                     << pass.maxTotalThreadsPerThreadgroup << ','
                     << pass.estimatedBytes << ','
                     << passEstimatedBytesPerThread(pass) << ','
                     << passEstimatedGbPerSecond(pass)
                     << '\n';
    }
  }
  if (!writeTextFile(reportDir / "pass_samples.csv", passSamplesCsv.str())) {
    return false;
  }

  std::ostringstream summaryJson;
  summaryJson << std::fixed << std::setprecision(6);
  summaryJson << "{\n  \"frame_budget_ms\": " << kSixtyFpsBudgetMs << ",\n  \"cases\": [\n";
  for (size_t i = 0; i < profiles.size(); ++i) {
    const CaseProfile &profile = profiles[i];
    const double waitOrOverheadMs = std::max(0.0, profile.avgCommandBufferMs - profile.avgGpuCommandBufferMs);
    const double budgetDeltaMs = profile.avgWallMs - kSixtyFpsBudgetMs;
    const SampleStats wallStats = frameWallStats(profile);
    const SampleStats gpuStats = frameGpuStats(profile);
    summaryJson << "    {\n"
                << "      \"case\": \"" << jsonEscape(profile.caseName) << "\",\n"
                << "      \"width\": " << profile.width << ",\n"
                << "      \"height\": " << profile.height << ",\n"
                << "      \"iterations\": " << profile.iterations << ",\n"
                << "      \"avg_wall_ms\": " << profile.avgWallMs << ",\n"
                << "      \"avg_fps\": " << profile.avgFps << ",\n"
                << "      \"avg_cpu_setup_ms\": " << profile.avgCpuSetupMs << ",\n"
                << "      \"avg_source_copy_ms\": " << profile.avgSourceCopyMs << ",\n"
                << "      \"avg_command_encoding_ms\": " << profile.avgCommandEncodingMs << ",\n"
                << "      \"avg_command_buffer_ms\": " << profile.avgCommandBufferMs << ",\n"
                << "      \"avg_gpu_command_buffer_ms\": " << profile.avgGpuCommandBufferMs << ",\n"
                << "      \"avg_wait_or_overhead_ms\": " << waitOrOverheadMs << ",\n"
                << "      \"avg_output_copy_ms\": " << profile.avgOutputCopyMs << ",\n"
                << "      \"avg_pass_count\": " << profile.avgPassCount << ",\n"
                << "      \"budget_delta_ms\": " << budgetDeltaMs << ",\n"
                << "      \"fits_60fps\": " << (profile.avgWallMs <= kSixtyFpsBudgetMs ? "true" : "false") << ",\n"
                << "      \"pass_gpu_timing\": " << (profile.passGpuTiming ? "true" : "false") << ",\n"
                << "      \"pass_timing_mode\": \"" << jsonEscape(profile.passTimingMode) << "\",\n"
                << "      \"final_core_mode\": \"" << jsonEscape(profile.finalCoreMode) << "\",\n"
                << "      \"wall_stats\": {\"median_ms\": " << wallStats.median
                << ", \"p95_ms\": " << wallStats.p95
                << ", \"stddev_ms\": " << wallStats.standardDeviation
                << ", \"cov\": " << wallStats.coefficientOfVariation << "},\n"
                << "      \"gpu_stats\": {\"median_ms\": " << gpuStats.median
                << ", \"p95_ms\": " << gpuStats.p95
                << ", \"stddev_ms\": " << gpuStats.standardDeviation
                << ", \"cov\": " << gpuStats.coefficientOfVariation << "},\n"
                << "      \"paths\": {\n"
                << "        \"halation\": " << (profile.halation ? "true" : "false") << ",\n"
                << "        \"camera_diffusion\": " << (profile.cameraDiffusion ? "true" : "false") << ",\n"
                << "        \"print_diffusion\": " << (profile.printDiffusion ? "true" : "false") << ",\n"
                << "        \"dir\": " << (profile.dir ? "true" : "false") << ",\n"
                << "        \"production_grain\": " << (profile.productionGrain ? "true" : "false") << ",\n"
                << "        \"grain_synthesis\": " << (profile.grainSynthesis ? "true" : "false") << ",\n"
                << "        \"final_post_process\": " << (profile.finalPostProcess ? "true" : "false") << "\n"
                << "      }\n"
                << "    }" << (i + 1u == profiles.size() ? "\n" : ",\n");
  }
  summaryJson << "  ]\n}\n";
  if (!writeTextFile(reportDir / "summary.json", summaryJson.str())) {
    return false;
  }

  std::ostringstream framesJson;
  framesJson << std::fixed << std::setprecision(6);
  framesJson << "{\n  \"frames\": [\n";
  bool firstFrame = true;
  for (const CaseProfile &profile : profiles) {
    for (const FrameSample &frame : profile.frameSamples) {
      const double waitOrOverheadMs = std::max(0.0, frame.commandBufferMs - frame.gpuCommandBufferMs);
      if (!firstFrame) {
        framesJson << ",\n";
      }
      firstFrame = false;
      framesJson << "    {\n"
                 << "      \"case\": \"" << jsonEscape(frame.caseName) << "\",\n"
                 << "      \"iteration\": " << frame.iteration << ",\n"
                 << "      \"wall_ms\": " << frame.wallMs << ",\n"
                 << "      \"fps\": " << frame.fps << ",\n"
                 << "      \"cpu_setup_ms\": " << frame.cpuSetupMs << ",\n"
                 << "      \"source_copy_ms\": " << frame.sourceCopyMs << ",\n"
                 << "      \"command_encoding_ms\": " << frame.commandEncodingMs << ",\n"
                 << "      \"command_buffer_ms\": " << frame.commandBufferMs << ",\n"
                 << "      \"gpu_command_buffer_ms\": " << frame.gpuCommandBufferMs << ",\n"
                 << "      \"wait_or_overhead_ms\": " << waitOrOverheadMs << ",\n"
                 << "      \"output_copy_ms\": " << frame.outputCopyMs << ",\n"
                 << "      \"pass_count\": " << frame.passCount << ",\n"
                 << "      \"pass_gpu_timing\": " << (frame.passGpuTiming ? "true" : "false") << ",\n"
                 << "      \"pass_timing_mode\": \"" << jsonEscape(frame.passTimingMode) << "\",\n"
                 << "      \"static_alloc_bytes\": " << frame.staticAllocationBytes << ",\n"
                 << "      \"static_alloc_count\": " << frame.staticAllocationCount << ",\n"
                 << "      \"scratch_alloc_bytes\": " << frame.scratchAllocationBytes << ",\n"
                 << "      \"scratch_alloc_count\": " << frame.scratchAllocationCount << ",\n"
                 << "      \"shared_scratch_alloc_bytes\": " << frame.sharedScratchAllocationBytes << ",\n"
                 << "      \"shared_scratch_alloc_count\": " << frame.sharedScratchAllocationCount << ",\n"
                 << "      \"private_scratch_alloc_bytes\": " << frame.privateScratchAllocationBytes << ",\n"
                 << "      \"private_scratch_alloc_count\": " << frame.privateScratchAllocationCount << ",\n"
                 << "      \"upload_bytes\": " << frame.uploadBytes << "\n"
                 << "    }";
    }
  }
  framesJson << "\n  ]\n}\n";
  if (!writeTextFile(reportDir / "frames.json", framesJson.str())) {
    return false;
  }

  std::ostringstream passesJson;
  passesJson << std::fixed << std::setprecision(6);
  passesJson << "{\n  \"passes\": [\n";
  for (size_t i = 0; i < passAggregates.size(); ++i) {
    const PassAggregate &pass = passAggregates[i];
    const SampleStats stats = pass.stats();
    passesJson << "    {\n"
               << "      \"case\": \"" << jsonEscape(pass.caseName) << "\",\n"
               << "      \"pass_index\": " << pass.passIndex << ",\n"
               << "      \"name\": \"" << jsonEscape(pass.name) << "\",\n"
               << "      \"samples\": " << pass.sampleCount << ",\n"
               << "      \"gpu_time_available_samples\": " << pass.gpuTimeAvailableCount << ",\n"
               << "      \"avg_ms\": " << pass.avgMs() << ",\n"
               << "      \"min_ms\": " << (pass.sampleCount > 0u ? pass.minMs : 0.0) << ",\n"
               << "      \"max_ms\": " << pass.maxMs << ",\n"
               << "      \"percent_of_frame\": " << pass.percentOfFrame() << ",\n"
               << "      \"median_ms\": " << stats.median << ",\n"
               << "      \"p95_ms\": " << stats.p95 << ",\n"
               << "      \"stddev_ms\": " << stats.standardDeviation << ",\n"
               << "      \"cov\": " << stats.coefficientOfVariation << ",\n"
               << "      \"width\": " << pass.width << ",\n"
               << "      \"height\": " << pass.height << ",\n"
               << "      \"depth\": " << pass.depth << ",\n"
               << "      \"threadgroup_width\": " << pass.threadgroupWidth << ",\n"
               << "      \"threadgroup_height\": " << pass.threadgroupHeight << ",\n"
               << "      \"thread_execution_width\": " << pass.threadExecutionWidth << ",\n"
               << "      \"max_total_threads_per_threadgroup\": " << pass.maxTotalThreadsPerThreadgroup << ",\n"
               << "      \"estimated_bytes\": " << pass.estimatedBytes << ",\n"
               << "      \"estimated_gb_s\": " << pass.estimatedGbPerSecond() << "\n"
               << "    }" << (i + 1u == passAggregates.size() ? "\n" : ",\n");
  }
  passesJson << "  ]\n}\n";
  if (!writeTextFile(reportDir / "passes.json", passesJson.str())) {
    return false;
  }

  std::ostringstream passSamplesJson;
  passSamplesJson << std::fixed << std::setprecision(6);
  passSamplesJson << "{\n  \"pass_samples\": [\n";
  bool firstPassSample = true;
  for (const CaseProfile &profile : profiles) {
    for (const PassSample &sample : profile.passSamples) {
      const spektrafilm::MetalPassDiagnostics &pass = sample.pass;
      const double percentOfFrame = sample.frameWallMs > 0.0 ? (pass.gpuMs / sample.frameWallMs) * 100.0 : 0.0;
      if (!firstPassSample) {
        passSamplesJson << ",\n";
      }
      firstPassSample = false;
      passSamplesJson << "    {\n"
                      << "      \"case\": \"" << jsonEscape(sample.caseName) << "\",\n"
                      << "      \"iteration\": " << sample.iteration << ",\n"
                      << "      \"pass_index\": " << sample.passIndex << ",\n"
                      << "      \"name\": \"" << jsonEscape(pass.name) << "\",\n"
                      << "      \"gpu_ms\": " << pass.gpuMs << ",\n"
                      << "      \"percent_of_frame\": " << percentOfFrame << ",\n"
                      << "      \"gpu_time_available\": " << (pass.gpuTimeAvailable ? "true" : "false") << ",\n"
                      << "      \"timing_mode\": \"" << jsonEscape(sample.timingMode) << "\",\n"
                      << "      \"width\": " << pass.width << ",\n"
                      << "      \"height\": " << pass.height << ",\n"
                      << "      \"depth\": " << pass.depth << ",\n"
                      << "      \"total_threads\": " << passTotalThreads(pass) << ",\n"
                      << "      \"threadgroup_width\": " << pass.threadgroupWidth << ",\n"
                      << "      \"threadgroup_height\": " << pass.threadgroupHeight << ",\n"
                      << "      \"threads_per_threadgroup\": " << passThreadsPerThreadgroup(pass) << ",\n"
                      << "      \"threadgroups\": " << passThreadgroupCount(pass) << ",\n"
                      << "      \"thread_execution_width\": " << pass.threadExecutionWidth << ",\n"
                      << "      \"max_total_threads_per_threadgroup\": " << pass.maxTotalThreadsPerThreadgroup << ",\n"
                      << "      \"estimated_bytes\": " << pass.estimatedBytes << ",\n"
                      << "      \"estimated_bytes_per_thread\": " << passEstimatedBytesPerThread(pass) << ",\n"
                      << "      \"estimated_gb_s\": " << passEstimatedGbPerSecond(pass) << "\n"
                      << "    }";
    }
  }
  passSamplesJson << "\n  ]\n}\n";
  if (!writeTextFile(reportDir / "pass_samples.json", passSamplesJson.str())) {
    return false;
  }

  const spektrafilm::MetalRenderDiagnostics *diag = profiles.empty() ? nullptr : &profiles.back().lastDiagnostics;
  std::ostringstream metadataJson;
  metadataJson << "{\n";
  metadataJson << "  \"argv\": [";
  for (size_t i = 0; i < argv.size(); ++i) {
    metadataJson << (i == 0u ? "" : ", ") << "\"" << jsonEscape(argv[i]) << "\"";
  }
  metadataJson << "],\n";
  metadataJson << "  \"system\": {\n"
               << "    \"macos\": \"" << jsonEscape(runCommandOutput("sw_vers -productVersion")) << "\",\n"
               << "    \"macos_build\": \"" << jsonEscape(runCommandOutput("sw_vers -buildVersion")) << "\",\n"
               << "    \"xcode\": \"" << jsonEscape(runCommandOutput("xcodebuild -version")) << "\",\n"
               << "    \"kernel\": \"" << jsonEscape(runCommandOutput("uname -a")) << "\"\n"
               << "  },\n";
  metadataJson << "  \"git\": {\n"
               << "    \"revision\": \"" << jsonEscape(runCommandOutput("git rev-parse HEAD")) << "\",\n"
               << "    \"status_short\": \"" << jsonEscape(runCommandOutput("git status --short")) << "\"\n"
               << "  },\n";
  metadataJson << "  \"metal\": {\n"
               << "    \"device_name\": \"" << jsonEscape(diag ? diag->metalDeviceName : "") << "\",\n"
               << "    \"recommended_max_working_set_size\": " << (diag ? diag->metalRecommendedMaxWorkingSetSize : 0u) << ",\n"
               << "    \"current_allocated_size\": " << (diag ? diag->metalCurrentAllocatedSize : 0u) << ",\n"
               << "    \"max_buffer_length\": " << (diag ? diag->metalMaxBufferLength : 0u) << ",\n"
               << "    \"dispatch_counter_sampling_supported\": " << ((diag && diag->passDispatchCounterSamplingSupported) ? "true" : "false") << ",\n"
               << "    \"stage_counter_sampling_supported\": " << ((diag && diag->passStageCounterSamplingSupported) ? "true" : "false") << "\n"
               << "  },\n";
  metadataJson << "  \"options\": {\n"
               << "    \"width\": " << options.width << ",\n"
               << "    \"height\": " << options.height << ",\n"
               << "    \"warmup\": " << options.warmup << ",\n"
               << "    \"iterations\": " << options.iterations << ",\n"
               << "    \"case\": \"" << jsonEscape(options.caseName) << "\",\n"
               << "    \"pass_timing\": \"" << jsonEscape(options.passTiming) << "\",\n"
               << "    \"final_core_mode\": \"" << jsonEscape(options.finalCoreMode) << "\",\n"
               << "    \"source_format\": \"" << jsonEscape(options.sourceFormat) << "\",\n"
               << "    \"destination_format\": \"" << jsonEscape(options.destinationFormat) << "\",\n"
               << "    \"host_layout\": \"" << jsonEscape(options.hostLayout) << "\"\n"
               << "  }\n";
  metadataJson << "}\n";
  if (!writeTextFile(reportDir / "metadata.json", metadataJson.str())) {
    return false;
  }

  std::vector<PassAggregate> bottlenecks = passAggregates;
  std::sort(bottlenecks.begin(), bottlenecks.end(), [](const PassAggregate &a, const PassAggregate &b) {
    return a.avgMs() > b.avgMs();
  });
  std::ostringstream report;
  report << "# SpektraFilm Metal Profile Report\n\n";
  report << "Frame budget for 4K/60 target: " << std::fixed << std::setprecision(3) << kSixtyFpsBudgetMs << " ms.\n\n";
  report << "## Summary\n\n";
  report << "| Case | Core mode | Avg ms | Median ms | P95 ms | CoV | FPS | Budget delta | Fits 60 fps | Timing mode |\n";
  report << "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |\n";
  for (const CaseProfile &profile : profiles) {
    const SampleStats wallStats = frameWallStats(profile);
    report << "| " << profile.caseName
           << " | " << profile.finalCoreMode
           << " | " << profile.avgWallMs
           << " | " << wallStats.median
           << " | " << wallStats.p95
           << " | " << wallStats.coefficientOfVariation
           << " | " << profile.avgFps
           << " | " << (profile.avgWallMs - kSixtyFpsBudgetMs)
           << " | " << (profile.avgWallMs <= kSixtyFpsBudgetMs ? "yes" : "no")
           << " | " << profile.passTimingMode
           << " |\n";
  }
  const std::array<std::string, 4> stagedFinalCorePasses = {
    "spektrafilm_print_raw_from_film_density",
    "spektrafilm_print_density_from_print_raw",
    "spektrafilm_profile_print_scan_from_density",
    "spektrafilm_profile_finalize_output",
  };
  double stagedFinalCoreTotalMs = 0.0;
  for (const PassAggregate &pass : passAggregates) {
    if (std::find(stagedFinalCorePasses.begin(), stagedFinalCorePasses.end(), pass.name) != stagedFinalCorePasses.end()) {
      stagedFinalCoreTotalMs += pass.avgMs();
    }
  }
  if (stagedFinalCoreTotalMs > 0.0) {
    report << "\n## Staged Final Core\n\n";
    report << "The staged total includes extra dispatch and intermediate-buffer overhead; compare it with a separate fused run.\n\n";
    report << "| Stage | Avg ms | P95 ms | % staged total |\n";
    report << "| --- | ---: | ---: | ---: |\n";
    for (const std::string &name : stagedFinalCorePasses) {
      const auto pass = std::find_if(passAggregates.begin(), passAggregates.end(), [&](const PassAggregate &candidate) {
        return candidate.name == name;
      });
      if (pass != passAggregates.end()) {
        report << "| `" << name << "` | " << pass->avgMs()
               << " | " << pass->stats().p95
               << " | " << (pass->avgMs() / stagedFinalCoreTotalMs * 100.0) << " |\n";
      }
    }
    report << "| **Total** | **" << stagedFinalCoreTotalMs << "** |  | **100.000** |\n";
  }
  report << "\n## Top Bottlenecks\n\n";
  if (bottlenecks.empty()) {
    report << "No pass rows were recorded.\n";
  } else {
    report << "| Case | Pass | Avg ms | % frame | Est. GB/s |\n";
    report << "| --- | --- | ---: | ---: | ---: |\n";
    const size_t count = std::min<size_t>(bottlenecks.size(), 15u);
    for (size_t i = 0; i < count; ++i) {
      const PassAggregate &pass = bottlenecks[i];
      report << "| " << pass.caseName
             << " | `" << pass.name << "`"
             << " | " << pass.avgMs()
             << " | " << pass.percentOfFrame()
             << " | " << pass.estimatedGbPerSecond()
             << " |\n";
    }
  }
  size_t frameSampleCount = 0u;
  size_t passSampleCount = 0u;
  for (const CaseProfile &profile : profiles) {
    frameSampleCount += profile.frameSamples.size();
    passSampleCount += profile.passSamples.size();
  }
  report << "\n## Detail Files\n\n";
  report << "- `summary.csv/json`: one aggregate row per case with frame budget status.\n";
  report << "- `frames.csv/json`: " << frameSampleCount << " raw measured frame rows with CPU, command-buffer, GPU, allocation, and upload timing.\n";
  report << "- `passes.csv/json`: aggregate pass rows grouped by logical GPU dispatch.\n";
  report << "- `pass_samples.csv/json`: " << passSampleCount << " raw per-iteration pass rows with dispatch geometry, threadgroup counts, estimated bytes/thread, and estimated GB/s.\n";
  report << "- `metadata.json`: system, Xcode, Metal device, counter support, git status, and harness arguments.\n";
  report << "\n`standard-core` intentionally disables spatial effects. Fused mode records the production final-core kernel; staged mode replaces it with four diagnostic dispatches. Use `pass_samples.csv` for every measured dispatch sample, and use a `.gputrace` in Xcode for shader-line or instruction-level profiling inside the fused kernel.\n";
  report << "\n";
  report << "Split timing mode is diagnostic and serializes pass work; use normal `--pass-timing off` runs for representative frame rate.\n";
  return writeTextFile(reportDir / "report.md", report.str());
}

} // namespace

int main(int argc, const char **argv) {
  @autoreleasepool {
    std::vector<std::string> argvVector;
    argvVector.reserve(static_cast<size_t>(argc));
    for (int i = 0; i < argc; ++i) {
      argvVector.emplace_back(argv[i]);
    }

    Options options;
    if (!parseArgs(argc, argv, options)) {
      printUsage(argv[0]);
      return 2;
    }
    if (!options.passTimingExplicit && (options.passCounters || options.detail)) {
      options.passTiming = "auto";
    }
    if (!options.resourceDir.empty()) {
      setenv("SPEKTRAFILM_RESOURCE_DIR", options.resourceDir.c_str(), 1);
    }
    setenv("SPEKTRAFILM_SCRATCH_STORAGE", options.scratchStorage.c_str(), 1);
    setenv("SPEKTRAFILM_THREADGROUP", options.threadgroup.c_str(), 1);
    setenv("SPEKTRAFILM_SCANNER_IMAGE_STORAGE", options.scannerImageStorage.c_str(), 1);
    setenv("SPEKTRAFILM_DIFFUSION_GROUP_SIZE", options.diffusionGroupSize.c_str(), 1);
    setenv("SPEKTRAFILM_BLUR_BACKEND", options.blurBackend.c_str(), 1);
    setenv("SPEKTRAFILM_BLUR_DOWNSAMPLE", options.blurDownsample.c_str(), 1);
    setenv("SPEKTRAFILM_INTERMEDIATE_PRECISION", options.intermediatePrecision.c_str(), 1);
    setenv("SPEKTRAFILM_DIFFUSION_CLUSTER_SIGMA", options.diffusionClusterSigma.c_str(), 1);
    setenv("SPEKTRAFILM_HALATION_GROUPED_TAIL", options.halationGroupedTail.c_str(), 1);
    setenv("SPEKTRAFILM_SCANNER_MPS", options.scannerMps.c_str(), 1);
    setenv("SPEKTRAFILM_GRAIN_BLUR_RECURRENCE", options.grainBlurRecurrence.c_str(), 1);
    setenv("SPEKTRAFILM_DIR_TAIL_BACKEND", options.dirTailBackend.c_str(), 1);
    setenv("SPEKTRAFILM_DENSITY_CURVE_LOOKUP", options.densityCurveLookup.c_str(), 1);
    setenv("SPEKTRAFILM_SPECTRAL_TRANSMITTANCE", options.spectralTransmittance.c_str(), 1);
    setenv("SPEKTRAFILM_FINAL_CORE_MODE", options.finalCoreMode.c_str(), 1);
    setenv("SPEKTRAFILM_PASS_TIMING", options.passTiming.c_str(), 1);
    setenv("SPEKTRAFILM_GRAIN_SYNTHESIS_SAMPLER", options.grainSynthesisSampler.c_str(), 1);
    setenv("SPEKTRAFILM_GRAIN_SYNTHESIS_RADIUS_LUT", options.grainSynthesisRadiusLut.c_str(), 1);
    setenv("SPEKTRAFILM_GRAIN_SYNTHESIS_TARGET_STORAGE", options.grainSynthesisTargetStorage.c_str(), 1);
    setenv("SPEKTRAFILM_GRAIN_SYNTHESIS_CELL_MODE", options.grainSynthesisCellMode.c_str(), 1);
    if (options.passTiming != "off") {
      setenv("SPEKTRAFILM_PASS_COUNTERS", "1", 1);
    }

    const std::vector<std::string> cases = selectedCases(options.caseName);
    if (cases.empty()) {
      std::cerr << "Unknown perf case: " << options.caseName << "\n";
      printUsage(argv[0]);
      return 2;
    }
    if (!options.captureGpuTracePath.empty() && options.captureIteration >= options.iterations) {
      std::cerr << "--capture-iteration must be less than --iterations.\n";
      return 2;
    }

    spektrafilm::MetalRenderer renderer;
    if (!renderer.isAvailable()) {
      std::cerr << "Metal renderer unavailable: " << renderer.lastError() << "\n";
      return 1;
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
    std::vector<float> sourcePixels = makeSyntheticFrame(options.width, options.height);
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
    const spektrafilm::ImageView sourceView = spektrafilm_harness::imageView(source);
    spektrafilm::MutableImageView destinationView = spektrafilm_harness::mutableImageView(destination);
    const spektrafilm::RenderWindow window = spektrafilm_harness::renderWindowForLayout(hostLayout, options.width, options.height);

    std::cout
      << "case,width,height,iterations,avg_wall_ms,avg_fps,avg_cpu_setup_ms,avg_source_copy_ms,"
      << "avg_command_encoding_ms,avg_command_buffer_ms,avg_gpu_command_buffer_ms,avg_output_copy_ms,avg_pass_count,avg_static_alloc_bytes,"
      << "avg_static_alloc_count,avg_scratch_alloc_bytes,avg_scratch_alloc_count,"
      << "avg_shared_scratch_alloc_bytes,avg_shared_scratch_alloc_count,"
      << "avg_private_scratch_alloc_bytes,avg_private_scratch_alloc_count,avg_upload_bytes,"
      << "source_no_copy,destination_no_copy,private_scratch,pass_gpu_timing,pass_timing_mode,threadgroup,diffusion_group_size,"
      << "scanner_image_storage,blur_backend,blur_downsample,intermediate_precision,diffusion_cluster_sigma,halation_grouped_tail,"
      << "scanner_mps,grain_blur_recurrence,dir_tail_backend,density_curve_lookup,spectral_transmittance,source_format,destination_format,host_layout,grain_synthesis_sampler,grain_synthesis_radius_lut,grain_synthesis_target_storage,"
      << "grain_synthesis_cell_mode,final_core_mode,halation,camera_diffusion,print_diffusion,dir,production_grain,grain_synthesis,final_post_process,mean_luma\n";
    std::vector<std::string> detailRows;
    std::vector<CaseProfile> profiles;
    profiles.reserve(cases.size());
    bool captureCompleted = options.captureGpuTracePath.empty();

    for (const std::string &caseName : cases) {
      spektrafilm::RenderParams params = paramsForCase(caseName);
      if (options.grainSynthesisSamples > 0) {
        params.grainSynthesisSamples = options.grainSynthesisSamples;
      }
      if (options.grainSynthesisLayeredOverride) {
        params.grainSynthesisLayered = options.grainSynthesisLayered;
      }
      if (options.grainSynthesisRadiusStdDevOverride) {
        params.grainSynthesisRadiusStdDevRatio = options.grainSynthesisRadiusStdDev;
      }
      if (options.grainSynthesisObservationSigmaOverride) {
        params.grainSynthesisObservationSigmaUm = options.grainSynthesisObservationSigmaUm;
      }

      for (int i = 0; i < options.warmup; ++i) {
        if (!renderer.render(sourceView, destinationView, window, params, static_cast<double>(i))) {
          std::cerr << "Warmup render failed for " << caseName << ": " << renderer.lastError() << "\n";
          return 1;
        }
      }

      double wallMs = 0.0;
      double cpuSetupMs = 0.0;
      double sourceCopyMs = 0.0;
      double commandEncodingMs = 0.0;
      double commandBufferMs = 0.0;
      double gpuCommandBufferMs = 0.0;
      double outputCopyMs = 0.0;
      double passCount = 0.0;
      double staticAllocationBytes = 0.0;
      double staticAllocationCount = 0.0;
      double scratchAllocationBytes = 0.0;
      double scratchAllocationCount = 0.0;
      double sharedScratchAllocationBytes = 0.0;
      double sharedScratchAllocationCount = 0.0;
      double privateScratchAllocationBytes = 0.0;
      double privateScratchAllocationCount = 0.0;
      double uploadBytes = 0.0;
      bool sourceNoCopy = false;
      bool destinationNoCopy = false;
      bool privateScratch = false;
      bool passGpuTiming = false;
      std::string passTimingMode = "off";
      bool halation = false;
      bool cameraDiffusion = false;
      bool printDiffusion = false;
      bool dir = false;
      bool productionGrain = false;
      bool grainSynthesis = false;
      bool finalPostProcess = false;
      bool scannerTextureIntermediates = false;
      bool halationGroupedTail = false;
      bool scannerMps = false;
      bool grainBlurRecurrence = false;
      uint32_t diffusionGroupSize = 2u;
      std::string threadgroupMode = "auto";
      std::string blurBackend = "custom";
      std::string blurDownsample = "auto";
      std::string intermediatePrecision = "float";
      std::string diffusionClusterSigma = "0.10";
      std::string dirTailBackend = "mps";
      std::string densityCurveLookup = "binary";
      std::string spectralTransmittance = "pow";
      std::string finalCoreMode = options.finalCoreMode;
      spektrafilm::MetalRenderDiagnostics lastDiagnostics;
      CaseProfile profile;
      profile.caseName = caseName;
      profile.width = options.width;
      profile.height = options.height;
      profile.iterations = options.iterations;

      for (int i = 0; i < options.iterations; ++i) {
        bool captureActive = false;
        if (!captureCompleted && i == options.captureIteration) {
          const std::filesystem::path capturePath(options.captureGpuTracePath);
          if (std::filesystem::exists(capturePath)) {
            std::cerr << "GPU trace output path already exists: " << capturePath << "\n"
                      << "Choose a fresh .gputrace path for each capture, or move/remove the old bundle before running.\n";
            return 1;
          }
          const std::filesystem::path parentPath = capturePath.parent_path();
          if (!parentPath.empty()) {
            std::error_code ec;
            std::filesystem::create_directories(parentPath, ec);
            if (ec) {
              std::cerr << "Unable to create GPU trace directory " << parentPath << ": " << ec.message() << "\n";
              return 1;
            }
          }
          if (!renderer.startGpuTraceCapture(options.captureGpuTracePath)) {
            std::cerr << "GPU trace capture setup failed: " << renderer.lastError() << "\n";
            return 1;
          }
          captureActive = true;
        }

        const auto start = Clock::now();
        const bool renderOk = renderer.render(sourceView, destinationView, window, params, static_cast<double>(i));
        if (captureActive) {
          renderer.stopGpuTraceCapture();
          if (!waitForGpuTraceDocument(std::filesystem::path(options.captureGpuTracePath))) {
            std::cerr << "GPU trace capture stopped, but the .gputrace bundle did not become complete at "
                      << options.captureGpuTracePath << "\n";
            return 1;
          }
          captureCompleted = true;
        }
        if (!renderOk) {
          std::cerr << "Render failed for " << caseName << ": " << renderer.lastError() << "\n";
          return 1;
        }
        const double iterationWallMs = elapsedMs(start, Clock::now());
        wallMs += iterationWallMs;
        const spektrafilm::MetalRenderDiagnostics &diag = renderer.lastDiagnostics();
        lastDiagnostics = diag;
        cpuSetupMs += diag.cpuSetupMs;
        sourceCopyMs += diag.sourceCopyMs;
        commandEncodingMs += diag.commandEncodingMs;
        commandBufferMs += diag.commandBufferMs;
        gpuCommandBufferMs += diag.gpuCommandBufferMs;
        outputCopyMs += diag.outputCopyMs;
        passCount += diag.passCount;
        staticAllocationBytes += static_cast<double>(diag.staticAllocationBytes);
        staticAllocationCount += static_cast<double>(diag.staticAllocationCount);
        scratchAllocationBytes += static_cast<double>(diag.scratchAllocationBytes);
        scratchAllocationCount += static_cast<double>(diag.scratchAllocationCount);
        sharedScratchAllocationBytes += static_cast<double>(diag.sharedScratchAllocationBytes);
        sharedScratchAllocationCount += static_cast<double>(diag.sharedScratchAllocationCount);
        privateScratchAllocationBytes += static_cast<double>(diag.privateScratchAllocationBytes);
        privateScratchAllocationCount += static_cast<double>(diag.privateScratchAllocationCount);
        uploadBytes += static_cast<double>(diag.uploadBytes);
        sourceNoCopy = diag.sourceNoCopy;
        destinationNoCopy = diag.destinationNoCopy;
        privateScratch = diag.privateScratchEnabled;
        passGpuTiming = diag.passGpuTimingAvailable;
        passTimingMode = diag.passTimingMode;
        halation = diag.halationPath;
        cameraDiffusion = diag.cameraDiffusionPath;
        printDiffusion = diag.printDiffusionPath;
        dir = diag.dirPath;
        productionGrain = diag.productionGrainPath;
        grainSynthesis = diag.grainSynthesisPath;
        finalPostProcess = diag.finalPostProcessPath;
        scannerTextureIntermediates = diag.scannerTextureIntermediates;
        halationGroupedTail = diag.halationGroupedTail;
        scannerMps = diag.scannerMps;
        grainBlurRecurrence = diag.grainBlurRecurrence;
        diffusionGroupSize = diag.diffusionGroupSize;
        threadgroupMode = diag.threadgroupMode;
        blurBackend = diag.blurBackend.empty() ? options.blurBackend : diag.blurBackend;
        blurDownsample = diag.blurDownsample.empty() ? options.blurDownsample : diag.blurDownsample;
        intermediatePrecision = diag.intermediatePrecision.empty() ? options.intermediatePrecision : diag.intermediatePrecision;
        diffusionClusterSigma = diag.diffusionClusterSigma.empty() ? options.diffusionClusterSigma : diag.diffusionClusterSigma;
        dirTailBackend = diag.dirTailBackend.empty() ? options.dirTailBackend : diag.dirTailBackend;
        densityCurveLookup = diag.densityCurveLookup.empty() ? options.densityCurveLookup : diag.densityCurveLookup;
        spectralTransmittance = diag.spectralTransmittance.empty() ? options.spectralTransmittance : diag.spectralTransmittance;
        finalCoreMode = diag.finalCoreMode.empty() ? options.finalCoreMode : diag.finalCoreMode;
        if (!options.profileReportDir.empty()) {
          FrameSample frame;
          frame.caseName = caseName;
          frame.iteration = i;
          frame.wallMs = iterationWallMs;
          frame.fps = iterationWallMs > 0.0 ? 1000.0 / iterationWallMs : 0.0;
          frame.cpuSetupMs = diag.cpuSetupMs;
          frame.sourceCopyMs = diag.sourceCopyMs;
          frame.commandEncodingMs = diag.commandEncodingMs;
          frame.commandBufferMs = diag.commandBufferMs;
          frame.gpuCommandBufferMs = diag.gpuCommandBufferMs;
          frame.outputCopyMs = diag.outputCopyMs;
          frame.passCount = diag.passCount;
          frame.staticAllocationBytes = diag.staticAllocationBytes;
          frame.staticAllocationCount = diag.staticAllocationCount;
          frame.scratchAllocationBytes = diag.scratchAllocationBytes;
          frame.scratchAllocationCount = diag.scratchAllocationCount;
          frame.sharedScratchAllocationBytes = diag.sharedScratchAllocationBytes;
          frame.sharedScratchAllocationCount = diag.sharedScratchAllocationCount;
          frame.privateScratchAllocationBytes = diag.privateScratchAllocationBytes;
          frame.privateScratchAllocationCount = diag.privateScratchAllocationCount;
          frame.uploadBytes = diag.uploadBytes;
          frame.passGpuTiming = diag.passGpuTimingAvailable;
          frame.passTimingMode = diag.passTimingMode;
          profile.frameSamples.push_back(frame);
          for (size_t passIndex = 0; passIndex < diag.passes.size(); ++passIndex) {
            PassSample sample;
            sample.caseName = caseName;
            sample.iteration = i;
            sample.passIndex = passIndex;
            sample.timingMode = diag.passTimingMode;
            sample.frameWallMs = iterationWallMs;
            sample.frameGpuCommandBufferMs = diag.gpuCommandBufferMs;
            sample.pass = diag.passes[passIndex];
            profile.passSamples.push_back(sample);
          }
        }
        if (options.detail) {
          for (size_t passIndex = 0; passIndex < diag.passes.size(); ++passIndex) {
            const spektrafilm::MetalPassDiagnostics &pass = diag.passes[passIndex];
            std::ostringstream row;
            row << csvEscape(caseName) << ','
                << i << ','
                << passIndex << ','
                << csvEscape(pass.name) << ','
                << pass.gpuMs << ','
                << (pass.gpuTimeAvailable ? 1 : 0) << ','
                << csvEscape(diag.passTimingMode) << ','
                << pass.width << ','
                << pass.height << ','
                << pass.depth << ','
                << pass.threadgroupWidth << ','
                << pass.threadgroupHeight << ','
                << pass.threadExecutionWidth << ','
                << pass.maxTotalThreadsPerThreadgroup << ','
                << pass.estimatedBytes;
            detailRows.push_back(row.str());
          }
        }
      }

      const double denom = std::max(options.iterations, 1);
      const double avgWallMs = wallMs / denom;
      const double avgFps = avgWallMs > 0.0 ? 1000.0 / avgWallMs : 0.0;
      std::cout << std::fixed << std::setprecision(3)
                << caseName << ','
                << options.width << ','
                << options.height << ','
                << options.iterations << ','
                << avgWallMs << ','
                << avgFps << ','
                << cpuSetupMs / denom << ','
                << sourceCopyMs / denom << ','
                << commandEncodingMs / denom << ','
                << commandBufferMs / denom << ','
                << gpuCommandBufferMs / denom << ','
                << outputCopyMs / denom << ','
                << passCount / denom << ','
                << staticAllocationBytes / denom << ','
                << staticAllocationCount / denom << ','
                << scratchAllocationBytes / denom << ','
                << scratchAllocationCount / denom << ','
                << sharedScratchAllocationBytes / denom << ','
                << sharedScratchAllocationCount / denom << ','
                << privateScratchAllocationBytes / denom << ','
                << privateScratchAllocationCount / denom << ','
                << uploadBytes / denom << ','
                << (sourceNoCopy ? 1 : 0) << ','
                << (destinationNoCopy ? 1 : 0) << ','
                << (privateScratch ? 1 : 0) << ','
                << (passGpuTiming ? 1 : 0) << ','
                << passTimingMode << ','
                << threadgroupMode << ','
                << diffusionGroupSize << ','
                << (scannerTextureIntermediates ? "texture" : "buffer") << ','
                << blurBackend << ','
                << blurDownsample << ','
                << intermediatePrecision << ','
                << diffusionClusterSigma << ','
                << (halationGroupedTail ? 1 : 0) << ','
                << (scannerMps ? 1 : 0) << ','
                << (grainBlurRecurrence ? 1 : 0) << ','
                << dirTailBackend << ','
                << densityCurveLookup << ','
                << spectralTransmittance << ','
                << options.sourceFormat << ','
                << options.destinationFormat << ','
                << options.hostLayout << ','
                << options.grainSynthesisSampler << ','
                << options.grainSynthesisRadiusLut << ','
                << options.grainSynthesisTargetStorage << ','
                << options.grainSynthesisCellMode << ','
                << finalCoreMode << ','
                << (halation ? 1 : 0) << ','
                << (cameraDiffusion ? 1 : 0) << ','
                << (printDiffusion ? 1 : 0) << ','
                << (dir ? 1 : 0) << ','
                << (productionGrain ? 1 : 0) << ','
                << (grainSynthesis ? 1 : 0) << ','
                << (finalPostProcess ? 1 : 0) << ','
                << spektrafilm_harness::averageWindowLuma(destination)
                << '\n';

      profile.avgWallMs = avgWallMs;
      profile.avgFps = avgFps;
      profile.avgCpuSetupMs = cpuSetupMs / denom;
      profile.avgSourceCopyMs = sourceCopyMs / denom;
      profile.avgCommandEncodingMs = commandEncodingMs / denom;
      profile.avgCommandBufferMs = commandBufferMs / denom;
      profile.avgGpuCommandBufferMs = gpuCommandBufferMs / denom;
      profile.avgOutputCopyMs = outputCopyMs / denom;
      profile.avgPassCount = passCount / denom;
      profile.avgStaticAllocationBytes = staticAllocationBytes / denom;
      profile.avgStaticAllocationCount = staticAllocationCount / denom;
      profile.avgScratchAllocationBytes = scratchAllocationBytes / denom;
      profile.avgScratchAllocationCount = scratchAllocationCount / denom;
      profile.avgSharedScratchAllocationBytes = sharedScratchAllocationBytes / denom;
      profile.avgSharedScratchAllocationCount = sharedScratchAllocationCount / denom;
      profile.avgPrivateScratchAllocationBytes = privateScratchAllocationBytes / denom;
      profile.avgPrivateScratchAllocationCount = privateScratchAllocationCount / denom;
      profile.avgUploadBytes = uploadBytes / denom;
      profile.meanLuma = spektrafilm_harness::averageWindowLuma(destination);
      profile.sourceNoCopy = sourceNoCopy;
      profile.destinationNoCopy = destinationNoCopy;
      profile.privateScratch = privateScratch;
      profile.passGpuTiming = passGpuTiming;
      profile.halation = halation;
      profile.cameraDiffusion = cameraDiffusion;
      profile.printDiffusion = printDiffusion;
      profile.dir = dir;
      profile.productionGrain = productionGrain;
      profile.grainSynthesis = grainSynthesis;
      profile.finalPostProcess = finalPostProcess;
      profile.scannerTextureIntermediates = scannerTextureIntermediates;
      profile.halationGroupedTail = halationGroupedTail;
      profile.scannerMps = scannerMps;
      profile.grainBlurRecurrence = grainBlurRecurrence;
      profile.diffusionGroupSize = diffusionGroupSize;
      profile.passTimingMode = passTimingMode;
      profile.threadgroupMode = threadgroupMode;
      profile.blurBackend = blurBackend;
      profile.blurDownsample = blurDownsample;
      profile.intermediatePrecision = intermediatePrecision;
      profile.diffusionClusterSigma = diffusionClusterSigma;
      profile.dirTailBackend = dirTailBackend;
      profile.densityCurveLookup = densityCurveLookup;
      profile.spectralTransmittance = spectralTransmittance;
      profile.finalCoreMode = finalCoreMode;
      profile.lastDiagnostics = lastDiagnostics;
      profiles.push_back(std::move(profile));
    }
    if (options.detail) {
      std::cout
        << "# pass_detail\n"
        << "detail_case,iteration,pass_index,name,gpu_ms,gpu_time_available,timing_mode,width,height,depth,"
        << "threadgroup_width,threadgroup_height,thread_execution_width,max_total_threads_per_threadgroup,estimated_bytes\n";
      for (const std::string &row : detailRows) {
        std::cout << row << '\n';
      }
    }
    if (!writeProfileReport(options, argvVector, profiles)) {
      return 1;
    }
  }
  return 0;
}
