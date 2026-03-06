@echo off
:: ============================================================
::  NutriScan — Script de build APK Android (Windows)
::  Double-clique sur ce fichier pour lancer le build
:: ============================================================

color 0B
echo.
echo  ╔════════════════════════════════════╗
echo  ║   NutriScan — Build APK Android   ║
echo  ╚════════════════════════════════════╝
echo.

:: 1. Vérifie Node.js
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERREUR] Node.js non trouve. Telecharge : https://nodejs.org
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('node --version') do echo [OK] Node.js %%v

:: 2. Vérifie Java
where java >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERREUR] Java JDK requis. Telecharge : https://adoptium.net
    pause
    exit /b 1
)
echo [OK] Java detecte

:: 3. Vérifie ANDROID_HOME
if "%ANDROID_HOME%"=="" (
    if "%ANDROID_SDK_ROOT%"=="" (
        echo.
        echo [ATTENTION] ANDROID_HOME non defini.
        echo Installe Android Studio : https://developer.android.com/studio
        echo Puis : SDK Manager - SDK Tools - Build Tools 34
        echo.
        echo Variables a definir :
        echo   ANDROID_HOME=C:\Users\TON_NOM\AppData\Local\Android\Sdk
        echo   PATH += %%ANDROID_HOME%%\tools;%%ANDROID_HOME%%\platform-tools
        echo.
    )
)

:: 4. npm install
echo.
echo [2/6] Installation dependances npm...
call npm install
if %errorlevel% neq 0 ( echo [ERREUR] npm install echoue & pause & exit /b 1 )

:: 5. Cap add android
echo.
echo [3/6] Ajout plateforme Android...
if not exist android (
    call npx cap add android
) else (
    echo Dossier android/ existant, skip.
)

:: 6. Copie ressources
echo.
echo [4/6] Application ressources Android...
if exist android-resources\AndroidManifest.xml (
    copy /Y android-resources\AndroidManifest.xml android\app\src\main\AndroidManifest.xml
    echo [OK] AndroidManifest.xml
)
if exist android-resources\strings.xml (
    copy /Y android-resources\strings.xml android\app\src\main\res\values\strings.xml
    echo [OK] strings.xml
)
if exist android-resources\styles.xml (
    copy /Y android-resources\styles.xml android\app\src\main\res\values\styles.xml
    echo [OK] styles.xml
)

:: 7. Sync
echo.
echo [5/6] Sync Capacitor...
call npx cap sync android

:: 8. Build
echo.
echo [6/6] Compilation APK (3-5 minutes)...
cd android
call gradlew.bat assembleDebug --no-daemon
if %errorlevel% neq 0 (
    cd ..
    echo.
    echo Build echoue. Ouvre avec Android Studio :
    echo   npx cap open android
    echo   Build - Build APK
    pause
    exit /b 1
)
cd ..

:: Trouve l'APK
for /r android\app\build\outputs\apk\debug %%f in (*.apk) do (
    copy "%%f" "NutriScan-v1.0-debug.apk"
    goto found
)

:found
echo.
echo  ╔═══════════════════════════════════════╗
echo  ║   APK GENERE : NutriScan-v1.0-debug  ║
echo  ╚═══════════════════════════════════════╝
echo.
echo  Pour installer :
echo  - USB  : adb install NutriScan-v1.0-debug.apk
echo  - Direct : transfere le .apk sur ton tel et installe
echo.
pause
