#include "SpektraMetalRenderer.h"
#include "SpektraProfileCurves.h"

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <filesystem>
#include <iomanip>
#include <iostream>
#include <limits>
#include <string>
#include <vector>

#include <png.h>

namespace {

struct Options {
  std::string inputPath;
  std::string outputDir;
  std::string inputColorSpaceTag;
  std::string resourceDir;
  float filmExposureEv = 0.0f;
  float printExposureEv = 0.0f;
  int maxLongEdge = 1280;
  bool diagnostics = false;
  bool emitRec709 = false;
};

struct ImageBuffer {
  int width = 0;
  int height = 0;
  std::vector<float> pixels;
};

struct ColorSpaceEntry {
  const char *tag;
  const char *label;
  spektrafilm::ColorSpace value;
};

constexpr ColorSpaceEntry kColorSpaces[] = {
  {"arri_logc4", "ARRI LogC4", spektrafilm::ColorSpace::ArriLogC4},
  {"arri_logc3_ei800", "ARRI LogC3 EI800", spektrafilm::ColorSpace::ArriLogC3Ei800},
  {"bmd_film_wide_gamut_gen5", "BMDFilm WideGamut Gen5", spektrafilm::ColorSpace::BmdFilmWideGamutGen5},
  {"davinci_intermediate_wide_gamut", "DaVinci Intermediate WideGamut", spektrafilm::ColorSpace::DavinciIntermediateWideGamut},
  {"red_log3g10_redwidegamutrgb", "RED Log3G10 REDWideGamutRGB", spektrafilm::ColorSpace::RedLog3G10RedWideGamutRgb},
  {"sony_slog3_sgamut3", "Sony S-Log3 S-Gamut3", spektrafilm::ColorSpace::SonySLog3SGamut3},
  {"sony_slog3_sgamut3cine", "Sony S-Log3 S-Gamut3.Cine", spektrafilm::ColorSpace::SonySLog3SGamut3Cine},
  {"canon_log2_cinemagamut_d55", "Canon Log2 CinemaGamut D55", spektrafilm::ColorSpace::CanonLog2CinemaGamutD55},
  {"canon_log3_cinemagamut_d55", "Canon Log3 CinemaGamut D55", spektrafilm::ColorSpace::CanonLog3CinemaGamutD55},
  {"panasonic_vlog_vgamut", "Panasonic V-Log V-Gamut", spektrafilm::ColorSpace::PanasonicVLogVGamut},
  {"aces2065_1", "ACES2065-1", spektrafilm::ColorSpace::Aces2065_1},
  {"acescg", "ACEScg", spektrafilm::ColorSpace::AcesCg},
  {"acescct", "ACEScct", spektrafilm::ColorSpace::AcesCct},
  {"acescc", "ACEScc", spektrafilm::ColorSpace::AcesCc},
  {"linear_rec2020", "Linear Rec.2020", spektrafilm::ColorSpace::LinearRec2020},
  {"linear_rec709", "Linear Rec.709", spektrafilm::ColorSpace::LinearRec709},
  {"linear_p3_d65", "Linear P3-D65", spektrafilm::ColorSpace::LinearP3D65},
  {"srgb", "sRGB", spektrafilm::ColorSpace::Srgb},
  {"display_p3", "Display P3", spektrafilm::ColorSpace::DisplayP3},
  {"prophoto_rgb", "ProPhoto RGB", spektrafilm::ColorSpace::ProPhotoRgb},
  {"adobe_rgb_1998", "Adobe RGB (1998)", spektrafilm::ColorSpace::AdobeRgb1998},
  {"dci_p3", "DCI-P3", spektrafilm::ColorSpace::DciP3},
  {"p3_d65_gamma_22", "P3-D65 Gamma 2.2", spektrafilm::ColorSpace::P3D65Gamma22},
  {"p3_d65_gamma_26", "P3-D65 Gamma 2.6", spektrafilm::ColorSpace::P3D65Gamma26},
  {"rec709_gamma_22", "Rec.709 Gamma 2.2", spektrafilm::ColorSpace::Rec709Gamma22},
  {"rec709_gamma_24", "Rec.709 Gamma 2.4", spektrafilm::ColorSpace::Rec709Gamma24},
};

void printUsage(const char *name) {
  std::cerr
    << "Usage: " << name << " --input IMAGE --output-dir DIR --input-color-space TAG [options]\n"
    << "\n"
    << "Options:\n"
    << "  --film-exposure-ev EV        Film/negative exposure compensation in stops. Default: 0\n"
    << "  --exposure-ev EV             Alias for --film-exposure-ev.\n"
    << "  --print-exposure-ev EV       Print exposure compensation in stops. Default: 1\n"
    << "  --max-long-edge PIXELS       Scale input before rendering. Default: 1280\n"
    << "  Metal renders Rec.709 Gamma 2.4; normal variants are 8-bit sRGB-tagged PNGs for web/Preview parity.\n"
    << "  --emit-rec709                Also write true Rec.709 Gamma 2.4-tagged debug PNGs.\n"
    << "  --diagnostics                Print input/render parameter and pixel-range diagnostics.\n"
    << "  --resource-dir DIR           Directory containing SpektraFilm.metallib resources\n"
    << "  --list-color-spaces          Print accepted color-space tags\n";
}

std::string normalizedTag(std::string value) {
  std::string normalized;
  normalized.reserve(value.size());
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

bool parseColorSpace(const std::string &tag, spektrafilm::ColorSpace &out) {
  const std::string normalized = normalizedTag(tag);
  for (const ColorSpaceEntry &entry : kColorSpaces) {
    if (normalized == normalizedTag(entry.tag) || normalized == normalizedTag(entry.label)) {
      out = entry.value;
      return true;
    }
  }
  return false;
}

void printColorSpaces() {
  for (const ColorSpaceEntry &entry : kColorSpaces) {
    std::cout << entry.tag << "  # " << entry.label << "\n";
  }
}

const char *colorSpaceLabel(spektrafilm::ColorSpace value) {
  for (const ColorSpaceEntry &entry : kColorSpaces) {
    if (entry.value == value) {
      return entry.label;
    }
  }
  return "Unknown";
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

bool parseInt(const char *text, int &out) {
  char *end = nullptr;
  const long value = std::strtol(text, &end, 10);
  if (!end || *end != '\0' || value <= 0 || value > 16384) {
    return false;
  }
  out = static_cast<int>(value);
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
    } else if (arg == "--list-color-spaces") {
      printColorSpaces();
      std::exit(0);
    } else if (arg == "--input") {
      const char *value = requireValue("--input");
      if (!value) {
        return false;
      }
      options.inputPath = value;
    } else if (arg == "--output-dir") {
      const char *value = requireValue("--output-dir");
      if (!value) {
        return false;
      }
      options.outputDir = value;
    } else if (arg == "--input-color-space") {
      const char *value = requireValue("--input-color-space");
      if (!value) {
        return false;
      }
      options.inputColorSpaceTag = value;
    } else if (arg == "--exposure-ev" || arg == "--film-exposure-ev") {
      const char *value = requireValue(arg.c_str());
      if (!value || !parseFloat(value, options.filmExposureEv)) {
        std::cerr << arg << " must be a finite number.\n";
        return false;
      }
    } else if (arg == "--print-exposure-ev") {
      const char *value = requireValue("--print-exposure-ev");
      if (!value || !parseFloat(value, options.printExposureEv)) {
        std::cerr << "--print-exposure-ev must be a finite number.\n";
        return false;
      }
    } else if (arg == "--max-long-edge") {
      const char *value = requireValue("--max-long-edge");
      if (!value || !parseInt(value, options.maxLongEdge)) {
        std::cerr << "--max-long-edge must be an integer in [1, 16384].\n";
        return false;
      }
    } else if (arg == "--resource-dir") {
      const char *value = requireValue("--resource-dir");
      if (!value) {
        return false;
      }
      options.resourceDir = value;
    } else if (arg == "--diagnostics") {
      options.diagnostics = true;
    } else if (arg == "--emit-rec709") {
      options.emitRec709 = true;
    } else {
      std::cerr << "Unknown argument: " << arg << "\n";
      return false;
    }
  }

  if (options.inputPath.empty() || options.outputDir.empty() || options.inputColorSpaceTag.empty()) {
    std::cerr << "--input, --output-dir, and --input-color-space are required.\n";
    return false;
  }
  return true;
}

std::string nsStringToStd(NSString *value) {
  return value ? std::string([value UTF8String]) : std::string();
}

std::string lowercaseExtension(const std::string &path) {
  std::filesystem::path fsPath(path);
  std::string extension = fsPath.extension().string();
  for (char &ch : extension) {
    ch = static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
  }
  return extension;
}

ImageBuffer resizeImageBilinear(const ImageBuffer &source, int maxLongEdge) {
  const int longEdge = std::max(source.width, source.height);
  if (longEdge <= 0 || longEdge <= maxLongEdge) {
    return source;
  }

  const double scale = static_cast<double>(maxLongEdge) / static_cast<double>(longEdge);
  ImageBuffer out;
  out.width = std::max(1, static_cast<int>(std::lround(static_cast<double>(source.width) * scale)));
  out.height = std::max(1, static_cast<int>(std::lround(static_cast<double>(source.height) * scale)));
  out.pixels.assign(static_cast<size_t>(out.width) * out.height * 4u, 1.0f);

  const double xScale = static_cast<double>(source.width) / static_cast<double>(out.width);
  const double yScale = static_cast<double>(source.height) / static_cast<double>(out.height);
  for (int y = 0; y < out.height; ++y) {
    const double sourceY = (static_cast<double>(y) + 0.5) * yScale - 0.5;
    const int y0 = std::clamp(static_cast<int>(std::floor(sourceY)), 0, source.height - 1);
    const int y1 = std::min(y0 + 1, source.height - 1);
    const float fy = static_cast<float>(sourceY - static_cast<double>(y0));
    for (int x = 0; x < out.width; ++x) {
      const double sourceX = (static_cast<double>(x) + 0.5) * xScale - 0.5;
      const int x0 = std::clamp(static_cast<int>(std::floor(sourceX)), 0, source.width - 1);
      const int x1 = std::min(x0 + 1, source.width - 1);
      const float fx = static_cast<float>(sourceX - static_cast<double>(x0));

      float *dst = out.pixels.data() + (static_cast<size_t>(y) * out.width + x) * 4u;
      const float *p00 = source.pixels.data() + (static_cast<size_t>(y0) * source.width + x0) * 4u;
      const float *p10 = source.pixels.data() + (static_cast<size_t>(y0) * source.width + x1) * 4u;
      const float *p01 = source.pixels.data() + (static_cast<size_t>(y1) * source.width + x0) * 4u;
      const float *p11 = source.pixels.data() + (static_cast<size_t>(y1) * source.width + x1) * 4u;
      for (int channel = 0; channel < 4; ++channel) {
        const float top = p00[channel] + (p10[channel] - p00[channel]) * fx;
        const float bottom = p01[channel] + (p11[channel] - p01[channel]) * fx;
        dst[channel] = top + (bottom - top) * fy;
      }
    }
  }
  return out;
}

bool loadPngRaw(const std::string &path, int maxLongEdge, ImageBuffer &out, std::string &error) {
  FILE *file = std::fopen(path.c_str(), "rb");
  if (!file) {
    error = "Unable to open PNG input: " + path;
    return false;
  }

  png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING, nullptr, nullptr, nullptr);
  if (!png) {
    std::fclose(file);
    error = "Unable to initialize PNG decoder.";
    return false;
  }
  png_infop info = png_create_info_struct(png);
  if (!info) {
    png_destroy_read_struct(&png, nullptr, nullptr);
    std::fclose(file);
    error = "Unable to initialize PNG metadata decoder.";
    return false;
  }
  if (setjmp(png_jmpbuf(png))) {
    png_destroy_read_struct(&png, &info, nullptr);
    std::fclose(file);
    error = "Unable to decode PNG input: " + path;
    return false;
  }

  png_init_io(png, file);
  png_read_info(png, info);

  png_uint_32 width = 0;
  png_uint_32 height = 0;
  int bitDepth = 0;
  int colorType = 0;
  png_get_IHDR(png, info, &width, &height, &bitDepth, &colorType, nullptr, nullptr, nullptr);
  if (width == 0 || height == 0 || width > static_cast<png_uint_32>(std::numeric_limits<int>::max()) ||
      height > static_cast<png_uint_32>(std::numeric_limits<int>::max())) {
    png_destroy_read_struct(&png, &info, nullptr);
    std::fclose(file);
    error = "PNG input has invalid dimensions.";
    return false;
  }

  if (colorType == PNG_COLOR_TYPE_PALETTE) {
    png_set_palette_to_rgb(png);
  }
  if (colorType == PNG_COLOR_TYPE_GRAY && bitDepth < 8) {
    png_set_expand_gray_1_2_4_to_8(png);
  }
  if (png_get_valid(png, info, PNG_INFO_tRNS)) {
    png_set_tRNS_to_alpha(png);
  }
  if (colorType == PNG_COLOR_TYPE_GRAY || colorType == PNG_COLOR_TYPE_GRAY_ALPHA) {
    png_set_gray_to_rgb(png);
  }
  if (bitDepth == 16) {
    png_set_swap(png);
  }

  png_read_update_info(png, info);
  bitDepth = png_get_bit_depth(png, info);
  const int channels = png_get_channels(png, info);
  const png_size_t rowBytes = png_get_rowbytes(png, info);
  if ((bitDepth != 8 && bitDepth != 16) || channels < 3 || channels > 4) {
    png_destroy_read_struct(&png, &info, nullptr);
    std::fclose(file);
    error = "PNG input format is unsupported after expansion.";
    return false;
  }

  std::vector<uint8_t> bytes(rowBytes * height);
  std::vector<png_bytep> rows(height);
  for (png_uint_32 y = 0; y < height; ++y) {
    rows[y] = bytes.data() + static_cast<size_t>(y) * rowBytes;
  }
  png_read_image(png, rows.data());
  png_read_end(png, nullptr);
  png_destroy_read_struct(&png, &info, nullptr);
  std::fclose(file);

  ImageBuffer decoded;
  decoded.width = static_cast<int>(width);
  decoded.height = static_cast<int>(height);
  decoded.pixels.assign(static_cast<size_t>(decoded.width) * decoded.height * 4u, 1.0f);
  for (png_uint_32 y = 0; y < height; ++y) {
    const uint8_t *row = bytes.data() + static_cast<size_t>(y) * rowBytes;
    for (png_uint_32 x = 0; x < width; ++x) {
      float *dst = decoded.pixels.data() + (static_cast<size_t>(y) * decoded.width + x) * 4u;
      if (bitDepth == 16) {
        const uint16_t *src = reinterpret_cast<const uint16_t *>(row) + static_cast<size_t>(x) * channels;
        dst[0] = static_cast<float>(src[0]) / 65535.0f;
        dst[1] = static_cast<float>(src[1]) / 65535.0f;
        dst[2] = static_cast<float>(src[2]) / 65535.0f;
        dst[3] = channels == 4 ? static_cast<float>(src[3]) / 65535.0f : 1.0f;
      } else {
        const uint8_t *src = row + static_cast<size_t>(x) * channels;
        dst[0] = static_cast<float>(src[0]) / 255.0f;
        dst[1] = static_cast<float>(src[1]) / 255.0f;
        dst[2] = static_cast<float>(src[2]) / 255.0f;
        dst[3] = channels == 4 ? static_cast<float>(src[3]) / 255.0f : 1.0f;
      }
    }
  }

  out = resizeImageBilinear(decoded, maxLongEdge);
  return true;
}

CGImageRef createImageByReplacingColorSpace(CGImageRef image, CGColorSpaceRef colorSpace) {
  CGDataProviderRef provider = CGImageGetDataProvider(image);
  if (!provider || !colorSpace) {
    return nullptr;
  }
  return CGImageCreate(
    CGImageGetWidth(image),
    CGImageGetHeight(image),
    CGImageGetBitsPerComponent(image),
    CGImageGetBitsPerPixel(image),
    CGImageGetBytesPerRow(image),
    colorSpace,
    CGImageGetBitmapInfo(image),
    provider,
    CGImageGetDecode(image),
    CGImageGetShouldInterpolate(image),
    CGImageGetRenderingIntent(image)
  );
}

bool loadAndScaleImage(const std::string &path, int maxLongEdge, ImageBuffer &out, std::string &error) {
  @autoreleasepool {
    NSString *inputPath = [NSString stringWithUTF8String:path.c_str()];
    NSURL *url = [NSURL fileURLWithPath:inputPath];
    NSDictionary *sourceOptions = @{(__bridge NSString *)kCGImageSourceShouldCache : @NO};
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, (__bridge CFDictionaryRef)sourceOptions);
    if (!source) {
      error = "Unable to open input image: " + path;
      return false;
    }

    NSDictionary *imageOptions = @{
      (__bridge NSString *)kCGImageSourceShouldCacheImmediately : @YES,
    };
    CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, (__bridge CFDictionaryRef)imageOptions);
    CFRelease(source);
    if (!image) {
      error = "Unable to decode input image: " + path;
      return false;
    }

    const size_t sourceWidth = CGImageGetWidth(image);
    const size_t sourceHeight = CGImageGetHeight(image);
    if (sourceWidth == 0 || sourceHeight == 0 || sourceWidth > static_cast<size_t>(std::numeric_limits<int>::max()) ||
        sourceHeight > static_cast<size_t>(std::numeric_limits<int>::max())) {
      CGImageRelease(image);
      error = "Input image has invalid dimensions.";
      return false;
    }

    const double scale = std::min(
      1.0,
      static_cast<double>(maxLongEdge) / static_cast<double>(std::max(sourceWidth, sourceHeight))
    );
    const size_t width = std::max<size_t>(1u, static_cast<size_t>(std::lround(static_cast<double>(sourceWidth) * scale)));
    const size_t height = std::max<size_t>(1u, static_cast<size_t>(std::lround(static_cast<double>(sourceHeight) * scale)));

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef untaggedImage = createImageByReplacingColorSpace(image, colorSpace);
    CGImageRef imageToDraw = untaggedImage ? untaggedImage : image;

    std::vector<uint16_t> rgba(width * height * 4u, 0u);
    CGContextRef context = CGBitmapContextCreate(
      rgba.data(),
      width,
      height,
      16,
      width * 4u * sizeof(uint16_t),
      colorSpace,
      kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder16Big
    );
    if (!context) {
      if (untaggedImage) {
        CGImageRelease(untaggedImage);
      }
      CGImageRelease(image);
      CGColorSpaceRelease(colorSpace);
      error = "Unable to allocate 16-bit image conversion buffer.";
      return false;
    }

    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextDrawImage(context, CGRectMake(0.0, 0.0, static_cast<CGFloat>(width), static_cast<CGFloat>(height)), imageToDraw);
    CGContextRelease(context);
    if (untaggedImage) {
      CGImageRelease(untaggedImage);
    }
    CGImageRelease(image);
    CGColorSpaceRelease(colorSpace);

    out.width = static_cast<int>(width);
    out.height = static_cast<int>(height);
    out.pixels.assign(width * height * 4u, 1.0f);
    for (size_t i = 0; i < width * height; ++i) {
      const uint16_t *src = rgba.data() + i * 4u;
      float *dst = out.pixels.data() + i * 4u;
      const float alpha = static_cast<float>(src[3]) / 65535.0f;
      dst[0] = static_cast<float>(src[0]) / 65535.0f;
      dst[1] = static_cast<float>(src[1]) / 65535.0f;
      dst[2] = static_cast<float>(src[2]) / 65535.0f;
      dst[3] = alpha;
    }
    return true;
  }
}

uint8_t toByte(float value) {
  const float clamped = std::clamp(value, 0.0f, 1.0f);
  return static_cast<uint8_t>(std::lround(clamped * 255.0f));
}

uint16_t toWord(float value) {
  const float clamped = std::clamp(value, 0.0f, 1.0f);
  return static_cast<uint16_t>(std::lround(clamped * 65535.0f));
}

struct ImageStats {
  float min[3] = {0.0f, 0.0f, 0.0f};
  float max[3] = {0.0f, 0.0f, 0.0f};
  double mean[3] = {0.0, 0.0, 0.0};
  float p01[3] = {0.0f, 0.0f, 0.0f};
  float p50[3] = {0.0f, 0.0f, 0.0f};
  float p99[3] = {0.0f, 0.0f, 0.0f};
};

ImageStats computeStats(const ImageBuffer &image) {
  ImageStats stats;
  const size_t pixelCount = static_cast<size_t>(image.width) * image.height;
  if (pixelCount == 0) {
    return stats;
  }

  std::vector<float> channelValues[3];
  for (std::vector<float> &values : channelValues) {
    values.reserve(pixelCount);
  }
  for (size_t i = 0; i < pixelCount; ++i) {
    const float *pixel = image.pixels.data() + i * 4u;
    for (int channel = 0; channel < 3; ++channel) {
      const float value = pixel[channel];
      if (i == 0) {
        stats.min[channel] = value;
        stats.max[channel] = value;
      } else {
        stats.min[channel] = std::min(stats.min[channel], value);
        stats.max[channel] = std::max(stats.max[channel], value);
      }
      stats.mean[channel] += value;
      channelValues[channel].push_back(value);
    }
  }

  auto percentile = [](std::vector<float> &values, double p) -> float {
    if (values.empty()) {
      return 0.0f;
    }
    std::sort(values.begin(), values.end());
    const double position = std::clamp(p, 0.0, 1.0) * static_cast<double>(values.size() - 1u);
    const size_t lo = static_cast<size_t>(std::floor(position));
    const size_t hi = std::min(lo + 1u, values.size() - 1u);
    const float t = static_cast<float>(position - static_cast<double>(lo));
    return values[lo] + (values[hi] - values[lo]) * t;
  };

  for (int channel = 0; channel < 3; ++channel) {
    stats.mean[channel] /= static_cast<double>(pixelCount);
    stats.p01[channel] = percentile(channelValues[channel], 0.01);
    stats.p50[channel] = percentile(channelValues[channel], 0.50);
    stats.p99[channel] = percentile(channelValues[channel], 0.99);
  }
  return stats;
}

void printStats(const char *label, const ImageBuffer &image) {
  const ImageStats stats = computeStats(image);
  std::cerr << std::fixed << std::setprecision(6);
  std::cerr << label << " " << image.width << "x" << image.height << "\n";
  for (int channel = 0; channel < 3; ++channel) {
    constexpr char kChannelNames[] = {'R', 'G', 'B'};
    const char channelName = kChannelNames[channel];
    std::cerr
      << "  " << channelName
      << " min=" << stats.min[channel]
      << " p01=" << stats.p01[channel]
      << " p50=" << stats.p50[channel]
      << " mean=" << stats.mean[channel]
      << " p99=" << stats.p99[channel]
      << " max=" << stats.max[channel]
      << "\n";
  }
}

bool writePng(const std::string &path, const ImageBuffer &image, std::string &error, bool rec709Tag = false, int bitDepth = 8) {
  if (image.width <= 0 || image.height <= 0 || image.pixels.size() < static_cast<size_t>(image.width) * image.height * 4u) {
    error = "Cannot write PNG from an empty image buffer.";
    return false;
  }

  FILE *file = std::fopen(path.c_str(), "wb");
  if (!file) {
    error = "Unable to create PNG output: " + path;
    return false;
  }

  png_structp png = png_create_write_struct(PNG_LIBPNG_VER_STRING, nullptr, nullptr, nullptr);
  if (!png) {
    std::fclose(file);
    error = "Unable to initialize PNG writer.";
    return false;
  }
  png_infop info = png_create_info_struct(png);
  if (!info) {
    png_destroy_write_struct(&png, nullptr);
    std::fclose(file);
    error = "Unable to initialize PNG metadata writer.";
    return false;
  }
  if (setjmp(png_jmpbuf(png))) {
    png_destroy_write_struct(&png, &info);
    std::fclose(file);
    error = "Unable to write PNG: " + path;
    return false;
  }

  png_init_io(png, file);
  png_set_IHDR(
    png,
    info,
    static_cast<png_uint_32>(image.width),
    static_cast<png_uint_32>(image.height),
    bitDepth,
    PNG_COLOR_TYPE_RGB,
    PNG_INTERLACE_NONE,
    PNG_COMPRESSION_TYPE_DEFAULT,
    PNG_FILTER_TYPE_DEFAULT
  );
  if (rec709Tag) {
    png_set_gAMA(png, info, 1.0 / 2.4);
    png_set_cHRM(png, info, 0.3127, 0.3290, 0.6400, 0.3300, 0.3000, 0.6000, 0.1500, 0.0600);
  } else {
    png_set_sRGB_gAMA_and_cHRM(png, info, PNG_sRGB_INTENT_PERCEPTUAL);
  }
  png_write_info(png, info);

  if (bitDepth == 16) {
    png_set_swap(png);
    std::vector<uint16_t> row(static_cast<size_t>(image.width) * 3u, 0u);
    for (int y = 0; y < image.height; ++y) {
      for (int x = 0; x < image.width; ++x) {
        const float *src = image.pixels.data() + (static_cast<size_t>(y) * image.width + x) * 4u;
        uint16_t *dst = row.data() + static_cast<size_t>(x) * 3u;
        dst[0] = toWord(src[0]);
        dst[1] = toWord(src[1]);
        dst[2] = toWord(src[2]);
      }
      png_write_row(png, reinterpret_cast<png_const_bytep>(row.data()));
    }
  } else {
    std::vector<uint8_t> row(static_cast<size_t>(image.width) * 3u, 0u);
    for (int y = 0; y < image.height; ++y) {
      for (int x = 0; x < image.width; ++x) {
        const float *src = image.pixels.data() + (static_cast<size_t>(y) * image.width + x) * 4u;
        uint8_t *dst = row.data() + static_cast<size_t>(x) * 3u;
        dst[0] = toByte(src[0]);
        dst[1] = toByte(src[1]);
        dst[2] = toByte(src[2]);
      }
      png_write_row(png, reinterpret_cast<png_const_bytep>(row.data()));
    }
  }
  png_write_end(png, info);
  png_destroy_write_struct(&png, &info);
  std::fclose(file);
  return true;
}

std::string stockSlug(const spektrafilm::ProfileCurveSet *profile, int fallbackIndex, const char *fallbackPrefix) {
  if (profile && profile->stock && profile->stock[0] != '\0') {
    return profile->stock;
  }
  std::string value = std::string(fallbackPrefix) + std::to_string(fallbackIndex);
  return normalizedTag(value);
}

bool isNegativeFilm(const spektrafilm::ProfileCurveSet *profile) {
  return profile && profile->type && std::string(profile->type) == "negative";
}

spektrafilm::RenderParams baseParams(const Options &options, spektrafilm::ColorSpace inputColorSpace, spektrafilm::ColorSpace outputColorSpace) {
  spektrafilm::RenderParams params;
  params.process = spektrafilm::ProcessMode::PrintSimulation;
  params.renderOutput = spektrafilm::RenderOutputMode::FinalPreview;
  params.rgbToRawMethod = spektrafilm::RgbToRawMethod::Hanatos2026;
  params.inputColorSpace = inputColorSpace;
  params.outputRole = spektrafilm::OutputRole::DisplaySdr;
  params.outputColorSpace = outputColorSpace;
  params.filmExposureEv = options.filmExposureEv;
  params.printExposureEv = options.printExposureEv;
  params.autoExposure = false;
  params.grainEnabled = false;
  params.halationEnabled = false;
  params.cameraDiffusionEnabled = false;
  params.printDiffusionEnabled = false;
  params.dirCouplersAmount = 0.0f;
  params.scannerEnabled = false;
  return params;
}

bool renderImage(
  spektrafilm::MetalRenderer &renderer,
  const ImageBuffer &source,
  ImageBuffer &destination,
  const spektrafilm::RenderParams &params
) {
  destination.width = source.width;
  destination.height = source.height;
  destination.pixels.assign(static_cast<size_t>(source.width) * source.height * 4u, 0.0f);

  const spektrafilm::ImageView sourceView{
    source.pixels.data(),
    0,
    0,
    source.width,
    source.height,
    source.width * static_cast<int>(4 * sizeof(float)),
    4,
    4,
  };
  spektrafilm::MutableImageView destinationView{
    destination.pixels.data(),
    0,
    0,
    source.width,
    source.height,
    source.width * static_cast<int>(4 * sizeof(float)),
    4,
    4,
  };
  const spektrafilm::RenderWindow window{0, 0, source.width, source.height};
  return renderer.render(sourceView, destinationView, window, params, 0.0);
}

} // namespace

int main(int argc, const char **argv) {
  @autoreleasepool {
    Options options;
    if (!parseArgs(argc, argv, options)) {
      printUsage(argv[0]);
      return 2;
    }

    spektrafilm::ColorSpace inputColorSpace = spektrafilm::ColorSpace::Srgb;
    if (!parseColorSpace(options.inputColorSpaceTag, inputColorSpace)) {
      std::cerr << "Unknown input color-space tag: " << options.inputColorSpaceTag << "\n";
      std::cerr << "Use --list-color-spaces to see accepted tags.\n";
      return 2;
    }

    if (!options.resourceDir.empty()) {
      setenv("SPEKTRAFILM_RESOURCE_DIR", options.resourceDir.c_str(), 1);
    }

    std::error_code ec;
    std::filesystem::create_directories(options.outputDir, ec);
    if (ec) {
      std::cerr << "Unable to create output directory: " << options.outputDir << ": " << ec.message() << "\n";
      return 1;
    }

    ImageBuffer source;
    std::string error;
    const bool loaded = lowercaseExtension(options.inputPath) == ".png"
      ? loadPngRaw(options.inputPath, options.maxLongEdge, source, error)
      : loadAndScaleImage(options.inputPath, options.maxLongEdge, source, error);
    if (!loaded) {
      std::cerr << error << "\n";
      return 1;
    }
    if (options.diagnostics) {
      std::cerr << "loader=" << (lowercaseExtension(options.inputPath) == ".png" ? "raw_png_libpng" : "imageio_fallback") << "\n";
      std::cerr << "inputColorSpace=" << colorSpaceLabel(inputColorSpace) << "\n";
      std::cerr << "metalOutputColorSpace=Rec.709 Gamma 2.4\n";
      std::cerr << "pngOutputColorSpace=sRGB tag with Metal Rec.709 Gamma 2.4 code values\n";
      std::cerr << "filmExposureEv=" << options.filmExposureEv << "\n";
      std::cerr << "printExposureEv=" << options.printExposureEv << "\n";
      std::cerr << "autoExposure=false grain=false halation=false cameraDiffusion=false printDiffusion=false dirAmount=0 scanner=false\n";
      printStats("input-buffer", source);
    }

    const std::filesystem::path outputRoot(options.outputDir);
    if (!writePng((outputRoot / "original.png").string(), source, error)) {
      std::cerr << error << "\n";
      return 1;
    }

    spektrafilm::MetalRenderer renderer;
    if (!renderer.isAvailable()) {
      std::cerr << "Metal renderer unavailable: " << renderer.lastError() << "\n";
      return 1;
    }

    const spektrafilm::RenderParams defaults = baseParams(options, inputColorSpace, spektrafilm::ColorSpace::Rec709Gamma24);
    if (options.diagnostics) {
      std::cerr
        << "renderParams process=PrintSimulation rgbToRaw=Hanatos2026"
        << " input=" << colorSpaceLabel(defaults.inputColorSpace)
        << " output=" << colorSpaceLabel(defaults.outputColorSpace)
        << " filmExposureEv=" << defaults.filmExposureEv
        << " printExposureEv=" << defaults.printExposureEv
        << " printTiming=FilteredEnlarger"
        << "\n";
    }
    int renderCount = 0;
    for (uint32_t filmIndex = 0; filmIndex < spektrafilm::kSpektraFilmCount; ++filmIndex) {
      const spektrafilm::ProfileCurveSet *film = spektrafilm::filmProfileCurves(static_cast<int32_t>(filmIndex));
      if (!isNegativeFilm(film)) {
        continue;
      }
      const std::string filmSlug = stockSlug(film, static_cast<int>(filmIndex), "negative_");
      for (uint32_t paperIndex = 0; paperIndex < spektrafilm::kSpektraPaperCount; ++paperIndex) {
        const spektrafilm::ProfileCurveSet *paper = spektrafilm::paperProfileCurves(static_cast<int32_t>(paperIndex));
        const std::string paperSlug = stockSlug(paper, static_cast<int>(paperIndex), "print_");

        spektrafilm::RenderParams params = defaults;
        params.film = static_cast<int32_t>(filmIndex);
        params.paper = static_cast<int32_t>(paperIndex);

        ImageBuffer rendered;
        if (!renderImage(renderer, source, rendered, params)) {
          std::cerr << "Render failed for " << filmSlug << " / " << paperSlug << ": " << renderer.lastError() << "\n";
          return 1;
        }

        if (options.diagnostics && renderCount == 0) {
          std::cerr << "firstVariant=" << filmSlug << "_" << paperSlug << "\n";
          printStats("first-render-rec709-gamma24", rendered);
        }
        if (options.emitRec709) {
          const std::filesystem::path rec709Path = outputRoot / (filmSlug + "_" + paperSlug + "_rec709_gamma24.png");
          if (!writePng(rec709Path.string(), rendered, error, true)) {
            std::cerr << error << "\n";
            return 1;
          }
        }
        const std::filesystem::path outputPath = outputRoot / (filmSlug + "_" + paperSlug + ".png");
        if (!writePng(outputPath.string(), rendered, error)) {
          std::cerr << error << "\n";
          return 1;
        }
        ++renderCount;
        std::cout << "wrote " << outputPath.filename().string() << "\n";
      }
    }

    std::cout << "done: " << renderCount << " variants plus original.png at " << options.outputDir << "\n";
  }
  return 0;
}
