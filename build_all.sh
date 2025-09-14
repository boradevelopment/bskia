#!/usr/bin/env bash
set -e  # exit on error
# --- Detect OS ---
OS="$(uname)"
case "$OS" in
    Linux*)   PLATFORM="Linux" ;;
    Darwin*)  PLATFORM="macOS" ;;
    *)        echo "Unsupported OS: $OS"; exit 1 ;;
esac

# --- Build directory argument (default = out) ---
BUILDDIR="${1:-out}"
echo "Using build directory: $BUILDDIR"
echo "Detected platform: $PLATFORM"

# --- Sync dependencies ---
python3 tools/git-sync-deps
python3 bin/fetch-ninja

# --- Generate GN configs ---
bin/gn gen "$BUILDDIR/Release" --args='is_official_build=true skia_use_system_libjpeg_turbo=false skia_use_system_zlib=false skia_use_system_harfbuzz=false skia_use_system_libpng=false skia_use_system_libwebp=false skia_use_system_expat=false skia_use_system_icu=false skia_enable_skottie=true extra_cflags_cc=["-std=c++20"]'

bin/gn gen "$BUILDDIR/Debug" --args='is_debug=true is_official_build=false skia_use_system_libjpeg_turbo=false skia_use_system_zlib=false skia_use_system_harfbuzz=false skia_use_system_libpng=false skia_use_system_libwebp=false skia_use_system_expat=false skia_use_system_icu=false extra_cflags_cc=["-std=c++20"]'

# --- Build both in parallel ---
echo "Building in separate processes..."

if [ "$PLATFORM" = "Linux" ] || [ "$PLATFORM" = "macOS" ]; then
    # Run both builds in background
    ninja -C "$BUILDDIR/Release" skia -j"$(nproc || sysctl -n hw.ncpu)" &
    PID1=$!

    ninja -C "$BUILDDIR/Debug" skia -j"$(nproc || sysctl -n hw.ncpu)" &
    PID2=$!

    # Wait for both to finish
    wait $PID1
    wait $PID2
fi

echo "Build finished for both Release and Debug!!"
