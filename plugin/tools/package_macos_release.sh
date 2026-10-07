#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: tools/package_macos_release.sh [--build-dir DIR] [--output-dir DIR]

Builds the public macOS OFX bundles, signs them, creates a signed installer
package, submits it for notarization, staples the accepted ticket, and writes
the public ZIP.

Required environment:
  SPEKTRAFILM_DEVELOPER_ID_APP        Developer ID Application identity
  SPEKTRAFILM_DEVELOPER_ID_INSTALLER  Developer ID Installer identity
  SPEKTRAFILM_NOTARY_PROFILE          notarytool keychain profile

Optional environment:
  CMAKE_BUILD_TYPE                    Release by default
  CMAKE_OSX_ARCHITECTURES             arm64;x86_64 by default for public macOS releases
USAGE
}

log() {
  printf '[macOS release] %s\n' "$*"
}

die() {
  printf '[macOS release] error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required"
}

require_env() {
  if [[ -z "${!1:-}" ]]; then
    die "$1 is required"
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build-macos-release"
OUTPUT_DIR="${PROJECT_ROOT}/../../website/public/downloads"
BUILD_TYPE="${CMAKE_BUILD_TYPE:-Release}"
MACOS_ARCHITECTURES="${CMAKE_OSX_ARCHITECTURES:-arm64;x86_64}"

[[ "${BUILD_TYPE}" == "Release" ]] || die "public macOS packages must use CMAKE_BUILD_TYPE=Release"

IFS=';' read -r -a EXPECTED_MACOS_ARCHS <<< "${MACOS_ARCHITECTURES}"
if [[ "${#EXPECTED_MACOS_ARCHS[@]}" -eq 0 ]]; then
  die "CMAKE_OSX_ARCHITECTURES must list at least one architecture"
fi

for expected_arch in "${EXPECTED_MACOS_ARCHS[@]}"; do
  [[ -n "${expected_arch}" ]] || die "CMAKE_OSX_ARCHITECTURES contains an empty architecture"
done

has_expected_arch() {
  local arch="$1"
  local expected_arch
  for expected_arch in "${EXPECTED_MACOS_ARCHS[@]}"; do
    if [[ "${arch}" == "${expected_arch}" ]]; then
      return 0
    fi
  done
  return 1
}

verify_macho_architectures() {
  local binary="$1"
  local label="$2"
  local actual_archs
  local arch
  local expected_arch
  local found

  [[ -f "${binary}" ]] || die "missing executable for architecture check: ${binary}"
  actual_archs="$(lipo -archs "${binary}")" || die "could not read architectures for ${binary}"

  for expected_arch in "${EXPECTED_MACOS_ARCHS[@]}"; do
    found=0
    for arch in ${actual_archs}; do
      if [[ "${arch}" == "${expected_arch}" ]]; then
        found=1
        break
      fi
    done
    [[ "${found}" -eq 1 ]] || die "${label} is missing ${expected_arch}; found: ${actual_archs}"
  done

  for arch in ${actual_archs}; do
    if ! has_expected_arch "${arch}"; then
      die "${label} has unexpected architecture ${arch}; expected: ${MACOS_ARCHITECTURES}; found: ${actual_archs}"
    fi
  done

  log "${label} architectures: ${actual_archs}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-dir)
      [[ $# -ge 2 ]] || die "--build-dir requires a path"
      BUILD_DIR="$2"
      shift 2
      ;;
    --output-dir)
      [[ $# -ge 2 ]] || die "--output-dir requires a path"
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ "$(uname -s)" == "Darwin" ]] || die "macOS is required for signing, packaging, and notarization"

require_command cmake
require_command codesign
require_command pkgbuild
require_command pkgutil
require_command spctl
require_command ditto
require_command lipo
require_command xcrun
require_env SPEKTRAFILM_DEVELOPER_ID_APP
require_env SPEKTRAFILM_DEVELOPER_ID_INSTALLER
require_env SPEKTRAFILM_NOTARY_PROFILE

NOTARYTOOL="$(xcrun --find notarytool)"
STAPLER="$(xcrun --find stapler)"

VERSION="$(sed -nE 's/^set\(SPEKTRAFILM_MACOS_VERSION "([^"]+)".*/\1/p' "${PROJECT_ROOT}/CMakeLists.txt" | head -n 1)"
[[ -n "${VERSION}" ]] || die "could not read SPEKTRAFILM_MACOS_VERSION from CMakeLists.txt"

DEFAULT_MANUAL="${PROJECT_ROOT}/../../docs/user_manual/main.pdf"
if [[ -f "${DEFAULT_MANUAL}" ]]; then
  USER_MANUAL="${DEFAULT_MANUAL}"
else
  USER_MANUAL="${PROJECT_ROOT}/documentation/spektrafilm_reference_guide.pdf"
fi
[[ -f "${USER_MANUAL}" ]] || die "manual PDF not found"

mkdir -p "${BUILD_DIR}" "${OUTPUT_DIR}"
BUILD_DIR="$(cd "${BUILD_DIR}" && pwd)"
OUTPUT_DIR="$(cd "${OUTPUT_DIR}" && pwd)"

RELEASE_DIR="${BUILD_DIR}/macos-release"
PAYLOAD_ROOT="${RELEASE_DIR}/payload-root"
PLUGINS_DIR="${PAYLOAD_ROOT}/Library/OFX/Plugins"
SCRIPTS_DIR="${RELEASE_DIR}/scripts"
DIST_DIR="${RELEASE_DIR}/dist"
ZIP_STAGE="${RELEASE_DIR}/zip-stage"
PKG_NAME="spektrafilm-OFX-macOS.pkg"
ZIP_NAME="spektrafilm-OFX-macOS.zip"
PKG_PATH="${DIST_DIR}/${PKG_NAME}"
ZIP_PATH="${OUTPUT_DIR}/${ZIP_NAME}"
LEGACY_FLOW_ZIP_PATH="${OUTPUT_DIR}/spektrafilm_flow-OFX-macOS.zip"

log "configuring ${BUILD_TYPE} macOS release build in ${BUILD_DIR} (${MACOS_ARCHITECTURES})"
cmake -S "${PROJECT_ROOT}" -B "${BUILD_DIR}" \
  -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
  -DCMAKE_OSX_ARCHITECTURES="${MACOS_ARCHITECTURES}" \
  -DSPEKTRAFILM_RELEASE_LTO=ON \
  -DSPEKTRAFILM_METAL_OPTIMIZATION_LEVEL=-O3 \
  -DSPEKTRAFILM_METAL_PROFILE_SOURCES=OFF \
  -DSPEKTRAFILM_NATIVE_FAST_MATH=OFF \
  -DSPEKTRAFILM_METAL_FAST_MATH=OFF \
  -DSPEKTRAFILM_OFX_METAL_GPU_BUFFERS=ON

log "building public OFX bundles"
cmake --build "${BUILD_DIR}" \
  --config "${BUILD_TYPE}" \
  --target spektrafilmBundleResources spektrafilm_flowBundleResources \
  --parallel

log "staging installer payload"
rm -rf "${RELEASE_DIR}"
mkdir -p "${PLUGINS_DIR}" "${SCRIPTS_DIR}" "${DIST_DIR}" "${ZIP_STAGE}/Legal"

cat > "${SCRIPTS_DIR}/preinstall" <<'PREINSTALL'
#!/bin/sh
set -eu

target_volume="${3:-/}"
if [ "${target_volume}" = "/" ]; then
  plugins_dir="/Library/OFX/Plugins"
else
  plugins_dir="${target_volume%/}/Library/OFX/Plugins"
fi

for bundle in spektrafilm.ofx.bundle spektrafilm_flow.ofx.bundle; do
  bundle_path="${plugins_dir}/${bundle}"
  if [ -e "${bundle_path}" ] || [ -L "${bundle_path}" ]; then
    /bin/rm -rf "${bundle_path}"
  fi
done

exit 0
PREINSTALL
chmod 0755 "${SCRIPTS_DIR}/preinstall"

for artifact in spektrafilm spektrafilm_flow; do
  source_bundle="${BUILD_DIR}/${artifact}.ofx.bundle"
  staged_bundle="${PLUGINS_DIR}/${artifact}.ofx.bundle"
  expected_executable="${staged_bundle}/Contents/MacOS/${artifact}.ofx"
  legacy_executable="${staged_bundle}/Contents/MacOS/${artifact}"

  [[ -d "${source_bundle}" ]] || die "missing built bundle: ${source_bundle}"
  COPYFILE_DISABLE=1 /usr/bin/ditto --norsrc "${source_bundle}" "${staged_bundle}"
  rm -f "${legacy_executable}"

  [[ -f "${expected_executable}" ]] || die "missing OFX executable: ${expected_executable}"
  [[ ! -e "${legacy_executable}" ]] || die "legacy executable still present: ${legacy_executable}"
  verify_macho_architectures "${expected_executable}" "${artifact}.ofx.bundle staged executable"

  log "signing ${artifact}.ofx.bundle"
  codesign --force --timestamp --options runtime \
    --sign "${SPEKTRAFILM_DEVELOPER_ID_APP}" \
    "${staged_bundle}"
  codesign --verify --strict --verbose=2 "${staged_bundle}"
done

find "${PAYLOAD_ROOT}" -name '._*' -delete

if find "${PLUGINS_DIR}" -maxdepth 1 -name 'spektrafilm_dev.ofx.bundle' | grep -q .; then
  die "dev bundle must not be included in the public installer payload"
fi

log "building signed installer package"
COPYFILE_DISABLE=1 pkgbuild \
  --root "${PAYLOAD_ROOT}" \
  --scripts "${SCRIPTS_DIR}" \
  --install-location "/" \
  --ownership recommended \
  --identifier "org.spektrafilm.ofx.pkg" \
  --version "${VERSION}" \
  --sign "${SPEKTRAFILM_DEVELOPER_ID_INSTALLER}" \
  "${PKG_PATH}"

pkgutil --check-signature "${PKG_PATH}"

log "verifying installer package architectures"
PKG_VERIFY_DIR="${RELEASE_DIR}/pkg-verify"
rm -rf "${PKG_VERIFY_DIR}"
pkgutil --expand-full "${PKG_PATH}" "${PKG_VERIFY_DIR}"
for artifact in spektrafilm spektrafilm_flow; do
  verify_macho_architectures \
    "${PKG_VERIFY_DIR}/Payload/Library/OFX/Plugins/${artifact}.ofx.bundle/Contents/MacOS/${artifact}.ofx" \
    "${artifact}.ofx.bundle packaged executable"
done
rm -rf "${PKG_VERIFY_DIR}"

log "submitting package for notarization"
"${NOTARYTOOL}" submit "${PKG_PATH}" \
  --keychain-profile "${SPEKTRAFILM_NOTARY_PROFILE}" \
  --wait

log "stapling notarization ticket"
"${STAPLER}" staple "${PKG_PATH}"
"${STAPLER}" validate "${PKG_PATH}"
spctl -a -t install -vv "${PKG_PATH}"

log "assembling public ZIP"
COPYFILE_DISABLE=1 /usr/bin/ditto --norsrc "${PKG_PATH}" "${ZIP_STAGE}/${PKG_NAME}"
COPYFILE_DISABLE=1 /usr/bin/ditto --norsrc "${PROJECT_ROOT}/install_instructions.txt" "${ZIP_STAGE}/install_instructions.txt"
COPYFILE_DISABLE=1 /usr/bin/ditto --norsrc "${USER_MANUAL}" "${ZIP_STAGE}/manual.pdf"
COPYFILE_DISABLE=1 /usr/bin/ditto --norsrc "${PROJECT_ROOT}/Legal/SPEKTRAFILM_OFX_LICENSE.txt" "${ZIP_STAGE}/Legal/SPEKTRAFILM_OFX_LICENSE.txt"
COPYFILE_DISABLE=1 /usr/bin/ditto --norsrc "${PROJECT_ROOT}/Legal/SPEKTRAFILM_OFX_LUT_LICENSE.txt" "${ZIP_STAGE}/Legal/SPEKTRAFILM_OFX_LUT_LICENSE.txt"
COPYFILE_DISABLE=1 /usr/bin/ditto --norsrc "${PROJECT_ROOT}/Legal/THIRD_PARTY_NOTICES.txt" "${ZIP_STAGE}/Legal/THIRD_PARTY_NOTICES.txt"

rm -f "${ZIP_PATH}" "${LEGACY_FLOW_ZIP_PATH}"
COPYFILE_DISABLE=1 /usr/bin/ditto -c -k --norsrc "${ZIP_STAGE}" "${ZIP_PATH}"

log "wrote ${ZIP_PATH}"
