@echo off
setlocal

echo ==========================================
echo   Building Optimized Kita Story APK
echo   Target: ARM64 (Smallest APK Size)
echo ==========================================

where flutter >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set FLUTTER_CMD=flutter
) else (
    set FLUTTER_CMD="C:\Users\CAS-NB-0024\flutter\bin\flutter.bat"
)

%FLUTTER_CMD% build apk --release --target-platform android-arm64 --no-tree-shake-icons --obfuscate --split-debug-info=build\app\outputs\symbols

if %ERRORLEVEL% equ 0 (
    echo.
    echo ==========================================
    echo  Build Successful!
    echo  Output: build\app\outputs\flutter-apk\app-release.apk
    echo ==========================================
) else (
    echo.
    echo Build failed with error code %ERRORLEVEL%
)

endlocal
