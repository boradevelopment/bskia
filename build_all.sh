#!/bin/bash

# 1. Argument Handling
BUILDDIR="${1:-out}"
MODES="${2:-ALL}"
EXTRA_CFLAGS="${3:-}"
EXTRA_BUILD_NAME="${4:-}"

# Clean up EXTRA_CFLAGS (removing $ if present)
EXTRA_CFLAGS=$(echo "$EXTRA_CFLAGS" | sed 's/\$//g')

# 2. OS Detection (macOS vs Linux)
OS_NAME=$(uname -s)
IS_MAC=false
if [ "$OS_NAME" == "Darwin" ]; then
    IS_MAC=true
    echo "--- Target: macOS ---"
else
    echo "--- Target: Linux ---"
fi

# 3. GN Argument Configuration
# Core flags for both macOS and Linux
GN_ARGS="skia_enable_svg=true \
skia_use_vulkan=true \
skia_use_gl=true \
skia_enable_graphite=true \
skia_use_system_libjpeg_turbo=false \
skia_use_system_zlib=false \
skia_use_system_harfbuzz=false \
skia_use_system_libpng=false \
skia_use_system_libwebp=false \
skia_use_system_expat=false \
skia_use_system_icu=false \
skia_enable_skottie=true"

# Add Metal only if on macOS
if [ "$IS_MAC" = true ]; then
    GN_ARGS="$GN_ARGS skia_use_metal=true"
fi

# 4. Dependency Sync
python3 tools/git-sync-deps
python3 bin/fetch-ninja
python3 bin/fetch-gn

# 5. Build Settings
IS_OFFICIAL_BUILD="true"
if [ "$EXTRA_BUILD_NAME" == "ASAN" ]; then
    IS_OFFICIAL_BUILD="false"
fi

# Determine CPU count (Linux: nproc | Mac: sysctl)
NUM_JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu)

# Format CFLAGS for GN array [ "-std=c++20", "extra_flag" ]
FINAL_CFLAGS="\"-std=c++20\""
if [ -n "$EXTRA_CFLAGS" ]; then
    FINAL_CFLAGS="$FINAL_CFLAGS, \"$EXTRA_CFLAGS\""
fi

# 6. GN Generation
echo "Generating GN Build Files..."

# Release
./bin/gn gen "$BUILDDIR/Release$EXTRA_BUILD_NAME" --args="is_debug=false is_official_build=$IS_OFFICIAL_BUILD extra_cflags_cc=[$FINAL_CFLAGS] $GN_ARGS"

# Debug
./bin/gn gen "$BUILDDIR/Debug$EXTRA_BUILD_NAME" --args="is_debug=true is_official_build=false extra_cflags_cc=[$FINAL_CFLAGS] $GN_ARGS"

# 7. Ninja Build Function
run_build() {
    local type=$1 
    local target_dir="$BUILDDIR/${type}${EXTRA_BUILD_NAME}"
    local log_prefix=$(echo "$type" | tr '[:upper:]' '[:lower:]')
    
    echo "--- Building $type ---"
    ./bin/ninja -C "$target_dir" skia -j "$NUM_JOBS" 2>&1 | tee "$BUILDDIR/${log_prefix}${EXTRA_BUILD_NAME}.log"
    ./bin/ninja -C "$target_dir" svg -j "$NUM_JOBS" 2>&1 | tee "$BUILDDIR/${log_prefix}SVG${EXTRA_BUILD_NAME}.log"
}

# Execute based on MODES argument
if [[ "$MODES" == "RELEASE" || "$MODES" == "ALL" ]]; then
    run_build "Release"
fi

if [[ "$MODES" == "DEBUG" || "$MODES" == "ALL" ]]; then
    run_build "Debug"
fi

echo "Finished. Check $BUILDDIR for logs."