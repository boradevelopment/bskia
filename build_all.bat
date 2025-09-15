@echo off
setlocal

set "BUILDDIR=%~1"
if "%BUILDDIR%"=="" set "BUILDDIR=out"
echo %BUILDDIR%
python3 tools/git-sync-deps
python3 bin/fetch-ninja
bin\gn gen %BUILDDIR%\Release --args="is_official_build=true skia_use_system_libjpeg_turbo=false skia_use_system_zlib=false skia_use_system_harfbuzz=false skia_use_system_libpng=false skia_use_system_libwebp=false skia_use_system_expat=false skia_use_system_icu=false skia_enable_skottie=true extra_cflags_cc=[\"/MD\",\"/std:c++20\"]"
bin\gn gen %BUILDDIR%\Debug --args="is_debug=true is_official_build=false skia_use_system_libjpeg_turbo=false skia_use_system_zlib=false skia_use_system_harfbuzz=false skia_use_system_libpng=false skia_use_system_libwebp=false skia_use_system_expat=false skia_use_system_icu=false extra_cflags_cc=[\"/MDd\",\"/std:c++20\"]"
echo building in seperate processes.

:: Run release build, redirect output to file
start "Skia Release Build" /b cmd /c "ninja -C %BUILDDIR%\Release skia -j %NUMBER_OF_PROCESSORS% > %BUILDDIR%\release.log 2>&1"

:: Run debug build, redirect output to file
start "Skia Debug Build" /b cmd /c "ninja -C %BUILDDIR%\Debug skia -j %NUMBER_OF_PROCESSORS% > %BUILDDIR%\debug.log 2>&1"

:: Wait for both background tasks to finish
echo Waiting for builds to complete...
:waitloop
tasklist | findstr /i "ninja.exe" >nul
if not errorlevel 1 (	
    timeout /t 5 >nul
    goto :waitloop
)

echo Both builds finished.
echo --- Release log ---
type %BUILDDIR%\release.log
echo --- Debug log ---
type %BUILDDIR%\debug.log

endlocal