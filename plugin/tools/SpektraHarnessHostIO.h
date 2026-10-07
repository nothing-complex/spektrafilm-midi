#pragma once

#include "SpektraParameters.h"

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

namespace spektrafilm_harness {

enum class HostPixelFormat {
  Float32,
  Float16,
};

enum class HostLayout {
  Contiguous,
  Strided,
  Offset,
};

inline bool parseHostPixelFormat(const std::string &text, HostPixelFormat &out) {
  if (text == "float" || text == "float32") {
    out = HostPixelFormat::Float32;
    return true;
  }
  if (text == "half" || text == "float16") {
    out = HostPixelFormat::Float16;
    return true;
  }
  return false;
}

inline bool parseHostLayout(const std::string &text, HostLayout &out) {
  if (text == "contiguous") {
    out = HostLayout::Contiguous;
    return true;
  }
  if (text == "strided") {
    out = HostLayout::Strided;
    return true;
  }
  if (text == "offset") {
    out = HostLayout::Offset;
    return true;
  }
  return false;
}

inline const char *hostPixelFormatName(HostPixelFormat format) {
  return format == HostPixelFormat::Float16 ? "half" : "float";
}

inline const char *hostLayoutName(HostLayout layout) {
  switch (layout) {
    case HostLayout::Strided:
      return "strided";
    case HostLayout::Offset:
      return "offset";
    case HostLayout::Contiguous:
    default:
      return "contiguous";
  }
}

inline uint32_t halfToFloatBits(uint16_t h) {
  const uint32_t sign = (static_cast<uint32_t>(h & 0x8000u)) << 16;
  uint32_t exponent = (h >> 10) & 0x1fu;
  uint32_t mantissa = h & 0x03ffu;

  if (exponent == 0) {
    if (mantissa == 0) {
      return sign;
    }
    exponent = 1;
    while ((mantissa & 0x0400u) == 0) {
      mantissa <<= 1;
      --exponent;
    }
    mantissa &= 0x03ffu;
  } else if (exponent == 31) {
    return sign | 0x7f800000u | (mantissa << 13);
  }

  exponent = exponent + (127 - 15);
  return sign | (exponent << 23) | (mantissa << 13);
}

inline float halfToFloat(uint16_t h) {
  const uint32_t bits = halfToFloatBits(h);
  float out = 0.0f;
  std::memcpy(&out, &bits, sizeof(out));
  return out;
}

inline uint16_t floatToHalf(float value) {
  uint32_t bits = 0;
  std::memcpy(&bits, &value, sizeof(bits));
  const uint32_t sign = (bits >> 16) & 0x8000u;
  int32_t exponent = static_cast<int32_t>((bits >> 23) & 0xffu) - 127 + 15;
  uint32_t mantissa = bits & 0x007fffffu;

  if (exponent <= 0) {
    if (exponent < -10) {
      return static_cast<uint16_t>(sign);
    }
    mantissa = (mantissa | 0x00800000u) >> static_cast<uint32_t>(1 - exponent);
    return static_cast<uint16_t>(sign | ((mantissa + 0x00001000u) >> 13));
  }
  if (exponent >= 31) {
    return static_cast<uint16_t>(sign | 0x7c00u);
  }
  return static_cast<uint16_t>(sign | (static_cast<uint32_t>(exponent) << 10) | ((mantissa + 0x00001000u) >> 13));
}

struct HostRgbaBuffer {
  HostPixelFormat format = HostPixelFormat::Float32;
  HostLayout layout = HostLayout::Contiguous;
  int width = 0;
  int height = 0;
  int storageWidth = 0;
  int storageHeight = 0;
  int rowPixels = 0;
  int windowX = 0;
  int windowY = 0;
  std::vector<float> floatPixels;
  std::vector<uint16_t> halfPixels;

  int bytesPerComponent() const {
    return format == HostPixelFormat::Float16 ? 2 : 4;
  }

  int rowBytes() const {
    return rowPixels * 4 * bytesPerComponent();
  }

  const void *data() const {
    return format == HostPixelFormat::Float16 ? static_cast<const void *>(halfPixels.data()) : static_cast<const void *>(floatPixels.data());
  }

  void *data() {
    return format == HostPixelFormat::Float16 ? static_cast<void *>(halfPixels.data()) : static_cast<void *>(floatPixels.data());
  }
};

inline spektrafilm::RenderWindow renderWindowForLayout(HostLayout layout, int width, int height) {
  const int offset = layout == HostLayout::Offset ? 1 : 0;
  return {offset, offset, offset + width, offset + height};
}

inline HostRgbaBuffer makeHostRgbaBuffer(HostPixelFormat format, HostLayout layout, int width, int height) {
  HostRgbaBuffer buffer;
  buffer.format = format;
  buffer.layout = layout;
  buffer.width = width;
  buffer.height = height;
  buffer.windowX = layout == HostLayout::Offset ? 1 : 0;
  buffer.windowY = layout == HostLayout::Offset ? 1 : 0;
  buffer.storageWidth = width + (layout == HostLayout::Offset ? 2 : 0);
  buffer.storageHeight = height + (layout == HostLayout::Offset ? 2 : 0);
  buffer.rowPixels = buffer.storageWidth + (layout == HostLayout::Strided ? 17 : 0);
  const size_t count = static_cast<size_t>(buffer.rowPixels) * static_cast<size_t>(buffer.storageHeight) * 4u;
  if (format == HostPixelFormat::Float16) {
    buffer.halfPixels.assign(count, 0u);
  } else {
    buffer.floatPixels.assign(count, 0.0f);
  }
  return buffer;
}

inline void setHostPixel(HostRgbaBuffer &buffer, int x, int y, const float rgba[4]) {
  const size_t index = (static_cast<size_t>(y) * static_cast<size_t>(buffer.rowPixels) + static_cast<size_t>(x)) * 4u;
  if (buffer.format == HostPixelFormat::Float16) {
    buffer.halfPixels[index] = floatToHalf(rgba[0]);
    buffer.halfPixels[index + 1u] = floatToHalf(rgba[1]);
    buffer.halfPixels[index + 2u] = floatToHalf(rgba[2]);
    buffer.halfPixels[index + 3u] = floatToHalf(rgba[3]);
  } else {
    buffer.floatPixels[index] = rgba[0];
    buffer.floatPixels[index + 1u] = rgba[1];
    buffer.floatPixels[index + 2u] = rgba[2];
    buffer.floatPixels[index + 3u] = rgba[3];
  }
}

inline void getHostPixel(const HostRgbaBuffer &buffer, int x, int y, float rgba[4]) {
  const size_t index = (static_cast<size_t>(y) * static_cast<size_t>(buffer.rowPixels) + static_cast<size_t>(x)) * 4u;
  if (buffer.format == HostPixelFormat::Float16) {
    rgba[0] = halfToFloat(buffer.halfPixels[index]);
    rgba[1] = halfToFloat(buffer.halfPixels[index + 1u]);
    rgba[2] = halfToFloat(buffer.halfPixels[index + 2u]);
    rgba[3] = halfToFloat(buffer.halfPixels[index + 3u]);
  } else {
    rgba[0] = buffer.floatPixels[index];
    rgba[1] = buffer.floatPixels[index + 1u];
    rgba[2] = buffer.floatPixels[index + 2u];
    rgba[3] = buffer.floatPixels[index + 3u];
  }
}

inline HostRgbaBuffer makeSourceHostRgba(
  const std::vector<float> &windowPixels,
  int width,
  int height,
  HostPixelFormat format,
  HostLayout layout
) {
  HostRgbaBuffer buffer = makeHostRgbaBuffer(format, layout, width, height);
  for (int y = 0; y < height; ++y) {
    for (int x = 0; x < width; ++x) {
      const float *source = windowPixels.data() + (static_cast<size_t>(y) * static_cast<size_t>(width) + static_cast<size_t>(x)) * 4u;
      setHostPixel(buffer, buffer.windowX + x, buffer.windowY + y, source);
    }
  }
  return buffer;
}

inline HostRgbaBuffer makeDestinationHostRgba(int width, int height, HostPixelFormat format, HostLayout layout) {
  return makeHostRgbaBuffer(format, layout, width, height);
}

inline spektrafilm::ImageView imageView(const HostRgbaBuffer &buffer) {
  return {
    buffer.data(),
    0,
    0,
    buffer.storageWidth,
    buffer.storageHeight,
    buffer.rowBytes(),
    4,
    buffer.bytesPerComponent(),
  };
}

inline spektrafilm::MutableImageView mutableImageView(HostRgbaBuffer &buffer) {
  return {
    buffer.data(),
    0,
    0,
    buffer.storageWidth,
    buffer.storageHeight,
    buffer.rowBytes(),
    4,
    buffer.bytesPerComponent(),
  };
}

inline std::vector<float> extractWindowFloatRgba(const HostRgbaBuffer &buffer) {
  std::vector<float> out(static_cast<size_t>(buffer.width) * static_cast<size_t>(buffer.height) * 4u, 0.0f);
  for (int y = 0; y < buffer.height; ++y) {
    for (int x = 0; x < buffer.width; ++x) {
      float rgba[4];
      getHostPixel(buffer, buffer.windowX + x, buffer.windowY + y, rgba);
      float *destination = out.data() + (static_cast<size_t>(y) * static_cast<size_t>(buffer.width) + static_cast<size_t>(x)) * 4u;
      destination[0] = rgba[0];
      destination[1] = rgba[1];
      destination[2] = rgba[2];
      destination[3] = rgba[3];
    }
  }
  return out;
}

inline double averageWindowLuma(const HostRgbaBuffer &buffer) {
  double sum = 0.0;
  for (int y = 0; y < buffer.height; ++y) {
    for (int x = 0; x < buffer.width; ++x) {
      float rgba[4];
      getHostPixel(buffer, buffer.windowX + x, buffer.windowY + y, rgba);
      sum += 0.2126 * rgba[0] + 0.7152 * rgba[1] + 0.0722 * rgba[2];
    }
  }
  const size_t count = static_cast<size_t>(buffer.width) * static_cast<size_t>(buffer.height);
  return count > 0 ? sum / static_cast<double>(count) : 0.0;
}

} // namespace spektrafilm_harness
