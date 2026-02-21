@echo off
setlocal
set "BUILDDIR=%~1"
if "%BUILDDIR%"=="" set "BUILDDIR=out"
echo %BUILDDIR%
set "EXTRA_CFLAGS=%~3"
if defined EXTRA_CFLAGS (
    set "EXTRA_CFLAGS=%EXTRA_CFLAGS:$==%"
)
echo %EXTRA_CFLAGS%
set "MODES=%~2"
set "EXTRA_BUILD_NAME=%~4"
if "%MODES%"=="DEBUG" (
    echo Debug mode selected
) else if "%MODES%"=="RELEASE" (
    echo Release mode selected
) else if "%MODES%"=="ALL" (
    echo Both modes selected
) else (
    echo Invalid MODES value: %MODES%
    exit /b 1
)


python3 tools/git-sync-deps
python3 bin/fetch-ninja

set IS_OFFICIAL_BUILD=false
if /I NOT "%EXTRA_BUILD_NAME%"=="ASAN" set IS_OFFICIAL_BUILD=true
bin\gn gen %BUILDDIR%\Release%EXTRA_BUILD_NAME% --args="skia_enable_svg=true skia_use_direct3d=true is_debug=false is_official_build=%IS_OFFICIAL_BUILD% skia_enable_graphite=true skia_use_vulkan=true skia_use_system_libjpeg_turbo=false skia_use_system_zlib=false skia_use_system_harfbuzz=false skia_use_system_libpng=false skia_use_system_libwebp=false skia_use_system_expat=false skia_use_system_icu=false skia_enable_skottie=true extra_cflags_cc=[\"/MD\",\"/std:c++20\",%EXTRA_CFLAGS%]"
bin\gn gen %BUILDDIR%\Debug%EXTRA_BUILD_NAME% --args="skia_enable_svg=true skia_use_direct3d=true is_debug=false is_official_build=false skia_enable_graphite=true skia_use_vulkan=true skia_use_system_libjpeg_turbo=false skia_use_system_zlib=false skia_use_system_harfbuzz=false skia_use_system_libpng=false skia_use_system_libwebp=false skia_use_system_expat=false skia_use_system_icu=false extra_cflags_cc=[\"/MDd\",\"/std:c++20\",%EXTRA_CFLAGS%]"

if /I "%MODES%"=="RELEASE" (
	   powershell -NoLogo -Command ^
  "ninja -C '%BUILDDIR%\Release%EXTRA_BUILD_NAME%' skia -j $env:NUMBER_OF_PROCESSORS 2>&1 | Tee-Object '%BUILDDIR%\release%EXTRA_BUILD_NAME%.log'"
  	   powershell -NoLogo -Command ^
  "ninja -C '%BUILDDIR%\Release%EXTRA_BUILD_NAME%' svg -j $env:NUMBER_OF_PROCESSORS 2>&1 | Tee-Object '%BUILDDIR%\releaseSVG%EXTRA_BUILD_NAME%.log'"
)

if "%MODES%"=="DEBUG" (
powershell -NoLogo -Command ^
  "ninja -C '%BUILDDIR%\Debug%EXTRA_BUILD_NAME%' skia -j $env:NUMBER_OF_PROCESSORS 2>&1 | Tee-Object '%BUILDDIR%\debug%EXTRA_BUILD_NAME%.log'"
  powershell -NoLogo -Command ^
  "ninja -C '%BUILDDIR%\Debug%EXTRA_BUILD_NAME%' svg -j $env:NUMBER_OF_PROCESSORS 2>&1 | Tee-Object '%BUILDDIR%\debugSVG%EXTRA_BUILD_NAME%.log'"
)

echo Both builds finished, view %BUILDDIR% to get logs
endlocal