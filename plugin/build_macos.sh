#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build-release"
BUILD_TYPE="${CMAKE_BUILD_TYPE:-Release}"
CMAKE_ARGS=(
  "-DSPEKTRAFILM_RELEASE_LTO=ON"
  "-DSPEKTRAFILM_METAL_OPTIMIZATION_LEVEL=-O3"
  "-DSPEKTRAFILM_METAL_PROFILE_SOURCES=OFF"
  "-DSPEKTRAFILM_NATIVE_FAST_MATH=OFF"
  "-DSPEKTRAFILM_METAL_FAST_MATH=OFF"
  "-DSPEKTRAFILM_OFX_METAL_GPU_BUFFERS=ON"
)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --metal-gpu-buffers)
      CMAKE_ARGS+=("-DSPEKTRAFILM_OFX_METAL_GPU_BUFFERS=ON")
      shift
      ;;
    --no-metal-gpu-buffers)
      CMAKE_ARGS+=("-DSPEKTRAFILM_OFX_METAL_GPU_BUFFERS=OFF")
      shift
      ;;
    -D*|-G*|-A*|-T*)
      CMAKE_ARGS+=("$1")
      shift
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        CMAKE_ARGS+=("$1")
        shift
      done
      ;;
    -*)
      CMAKE_ARGS+=("$1")
      shift
      ;;
    *)
      BUILD_DIR="$1"
      shift
      ;;
  esac
done

if ! command -v cmake >/dev/null 2>&1; then
  echo "cmake is required. Install it with Homebrew or from https://cmake.org/download/." >&2
  exit 1
fi

if ! xcrun -sdk macosx metal -v >/dev/null 2>&1; then
  echo "Apple's Metal toolchain is missing." >&2
  echo "Install it with: xcodebuild -downloadComponent MetalToolchain" >&2
  exit 1
fi

cmake -S "${SCRIPT_DIR}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" "${CMAKE_ARGS[@]}"
cmake --build "${BUILD_DIR}" --config "${BUILD_TYPE}" --parallel

echo "Built spektrafilm flow, spektrafilm, and spektrafilm dev OFX bundles in ${BUILD_DIR} (${BUILD_TYPE})"
echo "For the signed public installer ZIP, run:"
echo "  ${SCRIPT_DIR}/tools/package_macos_release.sh --build-dir ${BUILD_DIR}"
echo "Install with: cmake --install ${BUILD_DIR}"
