#include "SpektraMetalRenderer.h"
#include "SpektraProfileCurves.h"

#import <Foundation/Foundation.h>

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <limits>
#include <string>
#include <vector>

namespace {

struct Options {
  int samples = 256;
  int rows = 2048;
  float logMin = -2.0f;
  float logMax = 3.0f;
  int filmIndex = 2;
  std::string domain = "density";
  std::string grainMode = "production";
  bool halationEnabled = false;
  float grainParticleAreaUm2 = 0.1f;
  float grainDyeCloudBlurUm = 1.0f;
  float grainFinalBlurUm = 0.0f;
  float grainParticleScale[3] = {1.2f, 1.0f, 2.5f};
  float grainParticleScaleLayers[3] = {6.0f, 1.0f, 0.4f};
  float grainUniformity[3] = {0.99f, 0.97f, 0.98f};
  float grainDensityMin[3] = {0.04f, 0.05f, 0.06f};
  std::string resourceDir;
};

void printUsage(const char *name) {
  std::cerr
    << "Usage: " << name << " [--samples N] [--rows N]\n"
    << "       [--log-min X] [--log-max X] [--film-index N]\n"
    << "       [--domain density|final]\n"
    << "       [--grain-mode preview|production|synthesis] [--halation]\n"
    << "       [--grain-particle-area-um2 X]\n"
    << "       [--grain-dye-cloud-blur-um X]\n"
    << "       [--grain-final-blur-um X]\n"
    << "       [--grain-particle-scale-rgb R G B]\n"
    << "       [--grain-particle-scale-layers A B C]\n"
    << "       [--grain-uniformity-rgb R G B]\n"
    << "       [--grain-density-min-rgb R G B]\n"
    << "       [--resource-dir PATH]\n";
}

bool parseInt(const char *text, int &out) {
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

bool parseFloat3(const char *a, const char *b, const char *c, float out[3]) {
  return parseFloat(a, out[0]) && parseFloat(b, out[1]) && parseFloat(c, out[2]);
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
    } else if (arg == "--samples") {
      const char *value = requireValue("--samples");
      if (!value || !parseInt(value, options.samples)) {
        return false;
      }
    } else if (arg == "--rows") {
      const char *value = requireValue("--rows");
      if (!value || !parseInt(value, options.rows)) {
        return false;
      }
    } else if (arg == "--log-min") {
      const char *value = requireValue("--log-min");
      if (!value || !parseFloat(value, options.logMin)) {
        return false;
      }
    } else if (arg == "--log-max") {
      const char *value = requireValue("--log-max");
      if (!value || !parseFloat(value, options.logMax)) {
        return false;
      }
    } else if (arg == "--film-index") {
      const char *value = requireValue("--film-index");
      if (!value || !parseInt(value, options.filmIndex)) {
        return false;
      }
    } else if (arg == "--domain") {
      const char *value = requireValue("--domain");
      const std::string domain = value ? std::string(value) : "";
      if (domain != "density" && domain != "final") {
        std::cerr << "--domain must be density or final.\n";
        return false;
      }
      options.domain = domain;
    } else if (arg == "--grain-mode") {
      const char *value = requireValue("--grain-mode");
      const std::string mode = value ? std::string(value) : "";
      if (mode != "preview" && mode != "production" && mode != "synthesis") {
        std::cerr << "--grain-mode must be preview, production, or synthesis.\n";
        return false;
      }
      options.grainMode = mode;
    } else if (arg == "--halation") {
      options.halationEnabled = true;
    } else if (arg == "--grain-particle-area-um2") {
      const char *value = requireValue("--grain-particle-area-um2");
      if (!value || !parseFloat(value, options.grainParticleAreaUm2)) {
        return false;
      }
    } else if (arg == "--grain-dye-cloud-blur-um") {
      const char *value = requireValue("--grain-dye-cloud-blur-um");
      if (!value || !parseFloat(value, options.grainDyeCloudBlurUm)) {
        return false;
      }
    } else if (arg == "--grain-final-blur-um") {
      const char *value = requireValue("--grain-final-blur-um");
      if (!value || !parseFloat(value, options.grainFinalBlurUm)) {
        return false;
      }
    } else if (arg == "--grain-particle-scale-rgb") {
      if (i + 3 >= argc || !parseFloat3(argv[i + 1], argv[i + 2], argv[i + 3], options.grainParticleScale)) {
        std::cerr << "--grain-particle-scale-rgb requires three numeric values.\n";
        return false;
      }
      i += 3;
    } else if (arg == "--grain-particle-scale-layers") {
      if (i + 3 >= argc || !parseFloat3(argv[i + 1], argv[i + 2], argv[i + 3], options.grainParticleScaleLayers)) {
        std::cerr << "--grain-particle-scale-layers requires three numeric values.\n";
        return false;
      }
      i += 3;
    } else if (arg == "--grain-uniformity-rgb") {
      if (i + 3 >= argc || !parseFloat3(argv[i + 1], argv[i + 2], argv[i + 3], options.grainUniformity)) {
        std::cerr << "--grain-uniformity-rgb requires three numeric values.\n";
        return false;
      }
      i += 3;
    } else if (arg == "--grain-density-min-rgb") {
      if (i + 3 >= argc || !parseFloat3(argv[i + 1], argv[i + 2], argv[i + 3], options.grainDensityMin)) {
        std::cerr << "--grain-density-min-rgb requires three numeric values.\n";
        return false;
      }
      i += 3;
    } else if (arg == "--resource-dir") {
      const char *value = requireValue("--resource-dir");
      if (!value) {
        return false;
      }
      options.resourceDir = value;
    } else {
      std::cerr << "Unknown argument: " << arg << "\n";
      return false;
    }
  }

  if (options.samples < 2) {
    std::cerr << "--samples must be at least 2.\n";
    return false;
  }
  if (options.rows < 2) {
    std::cerr << "--rows must be at least 2.\n";
    return false;
  }
  if (!(options.logMax > options.logMin)) {
    std::cerr << "--log-max must be greater than --log-min.\n";
    return false;
  }
  if (options.filmIndex < 0 || options.filmIndex >= static_cast<int>(spektrafilm::kSpektraFilmCount)) {
    std::cerr << "--film-index must be in [0, " << (spektrafilm::kSpektraFilmCount - 1u) << "].\n";
    return false;
  }
  if (options.grainParticleAreaUm2 <= 0.0f) {
    std::cerr << "--grain-particle-area-um2 must be greater than zero.\n";
    return false;
  }
  if (options.grainDyeCloudBlurUm < 0.0f) {
    std::cerr << "--grain-dye-cloud-blur-um must be non-negative.\n";
    return false;
  }
  if (options.grainFinalBlurUm < 0.0f) {
    std::cerr << "--grain-final-blur-um must be non-negative.\n";
    return false;
  }
  return true;
}

std::vector<float> makeNeutralLogExposureRamp(const Options &options, std::vector<float> &logExposure) {
  logExposure.resize(static_cast<size_t>(options.samples));
  std::vector<float> pixels(static_cast<size_t>(options.samples) * static_cast<size_t>(options.rows) * 4u, 1.0f);
  for (int x = 0; x < options.samples; ++x) {
    const float t = static_cast<float>(x) / static_cast<float>(options.samples - 1);
    const float logValue = options.logMin + (options.logMax - options.logMin) * t;
    const float value = 0.184f * std::pow(10.0f, logValue);
    logExposure[static_cast<size_t>(x)] = logValue;
    for (int y = 0; y < options.rows; ++y) {
      float *pixel = pixels.data() + (static_cast<size_t>(y) * options.samples + x) * 4u;
      pixel[0] = value;
      pixel[1] = value;
      pixel[2] = value;
      pixel[3] = 1.0f;
    }
  }
  return pixels;
}

spektrafilm::RenderParams baseParams(const Options &options) {
  spektrafilm::RenderParams params;
  params.process = spektrafilm::ProcessMode::ScanNegative;
  params.inputColorSpace = spektrafilm::ColorSpace::LinearRec709;
  params.outputColorSpace = spektrafilm::ColorSpace::LinearRec709;
  params.film = options.filmIndex;
  params.paper = 3;
  params.autoExposure = false;
  params.halationEnabled = options.halationEnabled;
  params.cameraDiffusionEnabled = false;
  params.printDiffusionEnabled = false;
  params.dirCouplersAmount = 0.0f;
  params.scannerEnabled = false;
  params.grainAnimate = false;
  params.grainSeed = 42u;
  if (options.grainMode == "preview") {
    params.grainModel = spektrafilm::GrainModel::Preview;
  } else if (options.grainMode == "synthesis") {
    params.grainModel = spektrafilm::GrainModel::GrainSynthesis;
  } else {
    params.grainModel = spektrafilm::GrainModel::Production;
  }
  params.grainParticleAreaUm2 = options.grainParticleAreaUm2;
  params.grainBlurDyeCloudsUm = options.grainDyeCloudBlurUm;
  params.grainFinalBlurUm = options.grainFinalBlurUm;
  params.grainParticleScaleR = options.grainParticleScale[0];
  params.grainParticleScaleG = options.grainParticleScale[1];
  params.grainParticleScaleB = options.grainParticleScale[2];
  params.grainParticleScaleLayer0 = options.grainParticleScaleLayers[0];
  params.grainParticleScaleLayer1 = options.grainParticleScaleLayers[1];
  params.grainParticleScaleLayer2 = options.grainParticleScaleLayers[2];
  params.grainSynthesisRadiusScaleR = options.grainParticleScale[0];
  params.grainSynthesisRadiusScaleG = options.grainParticleScale[1];
  params.grainSynthesisRadiusScaleB = options.grainParticleScale[2];
  params.grainSynthesisLayerScale0 = options.grainParticleScaleLayers[0];
  params.grainSynthesisLayerScale1 = options.grainParticleScaleLayers[1];
  params.grainSynthesisLayerScale2 = options.grainParticleScaleLayers[2];
  params.grainUniformityR = options.grainUniformity[0];
  params.grainUniformityG = options.grainUniformity[1];
  params.grainUniformityB = options.grainUniformity[2];
  params.grainDensityMinR = options.grainDensityMin[0];
  params.grainDensityMinG = options.grainDensityMin[1];
  params.grainDensityMinB = options.grainDensityMin[2];
  return params;
}

bool renderEvaluationFrame(
  spektrafilm::MetalRenderer &renderer,
  const std::vector<float> &source,
  std::vector<float> &destination,
  const Options &options,
  spektrafilm::RenderParams params
) {
  const spektrafilm::ImageView sourceView{
    source.data(),
    0,
    0,
    options.samples,
    options.rows,
    options.samples * static_cast<int>(4 * sizeof(float)),
    4,
    4,
  };
  spektrafilm::MutableImageView destinationView{
    destination.data(),
    0,
    0,
    options.samples,
    options.rows,
    options.samples * static_cast<int>(4 * sizeof(float)),
    4,
    4,
  };
  const spektrafilm::RenderWindow window{0, 0, options.samples, options.rows};
  return renderer.render(sourceView, destinationView, window, params, 0.0);
}

float channelValue(const std::vector<float> &pixels, int samples, int x, int y, int channel) {
  return pixels[(static_cast<size_t>(y) * samples + x) * 4u + static_cast<size_t>(channel)];
}

} // namespace

int main(int argc, const char **argv) {
  @autoreleasepool {
    Options options;
    if (!parseArgs(argc, argv, options)) {
      printUsage(argv[0]);
      return 2;
    }
    if (!options.resourceDir.empty()) {
      setenv("SPEKTRAFILM_RESOURCE_DIR", options.resourceDir.c_str(), 1);
    }

    spektrafilm::MetalRenderer renderer;
    if (!renderer.isAvailable()) {
      std::cerr << "Metal renderer unavailable: " << renderer.lastError() << "\n";
      return 1;
    }

    std::vector<float> logExposure;
    const std::vector<float> source = makeNeutralLogExposureRamp(options, logExposure);
    std::vector<float> baseline(static_cast<size_t>(options.samples) * static_cast<size_t>(options.rows) * 4u, 0.0f);
    std::vector<float> grained(baseline.size(), 0.0f);

    spektrafilm::RenderParams baselineParams = baseParams(options);
    baselineParams.renderOutput = options.domain == "density"
      ? spektrafilm::RenderOutputMode::FilmDensityCmy
      : spektrafilm::RenderOutputMode::FinalPreview;
    baselineParams.grainEnabled = false;
    if (!renderEvaluationFrame(renderer, source, baseline, options, baselineParams)) {
      std::cerr << (options.domain == "density" ? "Density" : "Final") << " render failed: " << renderer.lastError() << "\n";
      return 1;
    }

    spektrafilm::RenderParams grainParams = baseParams(options);
    grainParams.renderOutput = options.domain == "density"
      ? spektrafilm::RenderOutputMode::FilmDensityCmyWithGrain
      : spektrafilm::RenderOutputMode::FinalPreview;
    grainParams.grainEnabled = true;
    if (!renderEvaluationFrame(renderer, source, grained, options, grainParams)) {
      std::cerr << "Grain render failed: " << renderer.lastError() << "\n";
      return 1;
    }

    std::cout << "log_exposure,"
              << (options.domain == "density" ? "density_r,density_g,density_b" : "final_r,final_g,final_b")
              << ",rms_r,rms_g,rms_b\n";
    std::cout << std::fixed << std::setprecision(7);
    for (int x = 0; x < options.samples; ++x) {
      double meanBaseline[3] = {0.0, 0.0, 0.0};
      double meanGrain[3] = {0.0, 0.0, 0.0};
      double m2Grain[3] = {0.0, 0.0, 0.0};

      for (int y = 0; y < options.rows; ++y) {
        for (int channel = 0; channel < 3; ++channel) {
          meanBaseline[channel] += channelValue(baseline, options.samples, x, y, channel);

          const double value = channelValue(grained, options.samples, x, y, channel);
          const double delta = value - meanGrain[channel];
          meanGrain[channel] += delta / static_cast<double>(y + 1);
          m2Grain[channel] += delta * (value - meanGrain[channel]);
        }
      }

      std::cout << logExposure[static_cast<size_t>(x)];
      for (double value : meanBaseline) {
        std::cout << ',' << (value / static_cast<double>(options.rows));
      }
      for (double value : m2Grain) {
        const double variance = value / static_cast<double>(options.rows);
        std::cout << ',' << (std::sqrt(std::max(variance, 0.0)) * 1000.0);
      }
      std::cout << '\n';
    }
  }
  return 0;
}
