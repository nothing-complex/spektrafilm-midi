#include "SpektraProfileStore.h"

#include <fstream>

namespace spektrafilm {

bool ProfileStore::loadManifest(const std::string &path) {
  std::ifstream input(path, std::ios::binary);
  if (!input) {
    lastError_ = "Unable to open compiled profile data: " + path;
    return false;
  }

  char magic[8] = {};
  input.read(magic, sizeof(magic));
  if (!input || std::string(magic, sizeof(magic)) != "SPKOFX1\0") {
    lastError_ = "Compiled profile data has an invalid SpektraFilm header.";
    return false;
  }

  // The native renderer does not consume profile payloads yet. Loading the
  // magic header here gives the OFX host a deterministic diagnostic path while
  // the Metal spectral stages are being filled in.
  manifest_ = CompiledDataManifest{};
  manifest_.version = 1;
  lastError_.clear();
  return true;
}

} // namespace spektrafilm
