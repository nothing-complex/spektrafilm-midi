#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace spektrafilm {

struct ProfileRecord {
  std::string stock;
  std::string name;
  std::string type;
  std::string support;
  uint32_t wavelengthCount = 0;
  uint32_t exposureCount = 0;
};

struct CompiledDataManifest {
  uint32_t version = 0;
  std::vector<ProfileRecord> films;
  std::vector<ProfileRecord> papers;
};

class ProfileStore {
public:
  bool loadManifest(const std::string &path);
  const CompiledDataManifest &manifest() const { return manifest_; }
  const std::string &lastError() const { return lastError_; }

private:
  CompiledDataManifest manifest_;
  std::string lastError_;
};

} // namespace spektrafilm
