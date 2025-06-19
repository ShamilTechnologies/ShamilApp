@echo off
REM App Icon Setup Script for ShamilApp (Windows)
REM This script will set up app icons using the flutter_launcher_icons package

echo 🚀 Setting up app icons for ShamilApp...
echo ==========================================

REM Check if logo.svg exists
if not exist "assets\images\logo.svg" (
    echo ❌ Error: assets\images\logo.svg not found!
    echo Please make sure the logo.svg file exists in assets/images/
    pause
    exit /b 1
)

echo ✅ Found logo.svg file

REM Install flutter_launcher_icons package if not already installed
echo 📦 Installing flutter_launcher_icons package...
flutter pub get

REM Generate app icons
echo 🎨 Generating app icons...
flutter pub run flutter_launcher_icons:main

REM Clean Flutter build
echo 🧹 Cleaning Flutter build cache...
flutter clean

REM Get dependencies again
echo 📦 Getting Flutter dependencies...
flutter pub get

echo.
echo ==========================================
echo ✅ App icons setup complete!
echo.
echo 📱 Generated icons for:
echo   • iOS (iPhone ^& iPad)
echo   • Android (all densities)
echo   • Web
echo   • Windows
echo   • macOS
echo.
echo 🎯 Next steps:
echo 1. Test your app: flutter run
echo 2. Build for release: flutter build apk (Android) or flutter build ios (iOS)
echo 3. Check that icons appear correctly on device home screen
echo.
echo 💡 Tip: If icons don't update immediately, try:
echo    • Uninstalling and reinstalling the app
echo    • Clearing device cache
echo    • Restarting the device
echo.
pause 