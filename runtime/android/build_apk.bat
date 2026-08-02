@echo off
rem Packages src\ into a game.love file and builds a debug LOVE-for-Android
rem APK with it embedded, using a local checkout of love2d/love-android.
rem See runtime\android\README.md for one-time setup.

setlocal
if "%LOVE_ANDROID_DIR%"=="" set LOVE_ANDROID_DIR=%~dp0..\..\..\love-android

if not exist "%LOVE_ANDROID_DIR%\gradlew.bat" (
    echo love-android checkout not found at "%LOVE_ANDROID_DIR%".
    echo Set LOVE_ANDROID_DIR, or see runtime\android\README.md for setup.
    exit /b 1
)

rem love-android's pinned Gradle wrapper cannot run under JDK versions newer
rem than 17 (e.g. the JBR bundled with current Android Studio releases is
rem JDK 21+, which fails with "Unsupported class file major version").
rem Set JAVA_HOME_17 to a JDK 17 install if the default JAVA_HOME won't work.
if not "%JAVA_HOME_17%"=="" set JAVA_HOME=%JAVA_HOME_17%

echo Packaging src\ into game.love...
if exist "%TEMP%\game.love" del "%TEMP%\game.love"
pushd "%~dp0..\..\src"
"%~dp0..\7z.exe" a -tzip "%TEMP%\game.love" . -mx=5 -bd >nul
if errorlevel 1 (
    popd
    echo Failed to package src\ into game.love.
    exit /b 1
)
popd

copy /Y "%TEMP%\game.love" "%LOVE_ANDROID_DIR%\app\src\embed\assets\game.love" >nul

pushd "%LOVE_ANDROID_DIR%"
call gradlew.bat assembleEmbedNoRecordDebug
set BUILD_RESULT=%errorlevel%
popd

if %BUILD_RESULT% neq 0 (
    echo Gradle build failed.
    exit /b %BUILD_RESULT%
)

echo.
echo Done. APK output:
echo   %LOVE_ANDROID_DIR%\app\build\outputs\apk\embedNoRecord\debug\
echo Install with: adb install -r "%LOVE_ANDROID_DIR%\app\build\outputs\apk\embedNoRecord\debug\app-embed-noRecord-debug.apk"
