# Script to build optimized release APK for Kita Story

$ErrorActionPreference = "Stop"

# Detect Flutter path
$flutterCmd = "flutter"
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    $fallbackFlutter = "C:\Users\CAS-NB-0024\flutter\bin\flutter.bat"
    if (Test-Path $fallbackFlutter) {
        $flutterCmd = $fallbackFlutter
    } else {
        Write-Error "Flutter SDK not found! Please ensure Flutter is installed and added to PATH."
        exit 1
    }
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Building Optimized Kita Story APK       " -ForegroundColor Cyan
Write-Host "  Target: ARM64 (Smallest APK Size)       " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

& $flutterCmd build apk --release `
    --target-platform android-arm64 `
    --no-tree-shake-icons `
    --obfuscate `
    --split-debug-info=build/app/outputs/symbols

if ($LASTEXITCODE -eq 0) {
    $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
    if (Test-Path $apkPath) {
        $fileSize = (Get-Item $apkPath).Length / 1MB
        Write-Host ""
        Write-Host "==========================================" -ForegroundColor Green
        Write-Host " Build Successful!" -ForegroundColor Green
        Write-Host (" Output APK: {0}" -f (Resolve-Path $apkPath)) -ForegroundColor Yellow
        Write-Host (" APK Size  : {0:N2} MB" -f $fileSize) -ForegroundColor Yellow
        Write-Host "==========================================" -ForegroundColor Green
    }
} else {
    Write-Host "Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
}
