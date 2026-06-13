@echo off
echo Building KisanCare APK...
echo.

REM Set environment variables for better build performance
set GRADLE_OPTS=-Xmx4g -XX:MaxMetaspaceSize=1g
set TEMP=E:\temp
set TMP=E:\temp

echo Step 1: Cleaning previous build...
flutter clean

echo.
echo Step 2: Getting dependencies...
flutter pub get

echo.
echo Step 3: Building APK (Debug version for testing)...
flutter build apk --debug

echo.
echo Step 4: Building APK (Release version for distribution)...
flutter build apk --release

echo.
echo Build complete!
echo.
echo APK files location:
echo Debug APK: build\app\outputs\flutter-apk\app-debug.apk
echo Release APK: build\app\outputs\flutter-apk\app-release.apk
echo.
echo You can install either APK on your Android device.
echo The release APK is smaller and optimized for production use.
echo.
pause
