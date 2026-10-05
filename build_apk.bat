@echo off
TITLE PCRM APK Builder
COLOR 0B

echo ==============================================================================
echo                      PCRM Mobile APK Build Utility
echo ==============================================================================
echo.

cd /d "%~dp0mobile"

where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Flutter SDK is not detected in your system PATH.
    echo.
    echo To build the APK locally:
    echo  1. Download Flutter SDK from https://docs.flutter.dev/get-started/install/windows
    echo  2. Add Flutter 'bin' directory to your Windows System PATH.
    echo  3. Run this script again: build_apk.bat
    echo.
    echo Alternatively, push your code to GitHub to have the .github/workflows/build_apk.yml
    echo build and output the APK automatically in GitHub Actions!
    echo.
    pause
    exit /b 1
)

echo [*] Resolving Flutter packages...
flutter pub get

echo [*] Compiling Release APK...
flutter build apk --release

if %errorlevel% equ 0 (
    echo.
    echo ==============================================================================
    echo [SUCCESS] Release APK built successfully!
    echo Location: %~dp0mobile\build\app\outputs\flutter-apk\app-release.apk
    echo ==============================================================================
    explorer.exe "%~dp0mobile\build\app\outputs\flutter-apk"
) else (
    echo [ERROR] Build failed. Review output log above.
)

pause
