@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

set "ROOT_DIR=%~dp0.."
if not defined ANDROID_SDK set "ANDROID_SDK=%LOCALAPPDATA%\Android\Sdk"
if not defined FLUTTER_SDK set "FLUTTER_SDK=%USERPROFILE%\flutter"
if not defined AVD_NAME set "AVD_NAME=flauncher_tv"
if not defined AVD_DEVICE set "AVD_DEVICE=tv_1080p"
if not defined TV_SYSTEM_IMAGE set "TV_SYSTEM_IMAGE=system-images;android-36;android-tv;x86_64"
set "EMULATOR_ACCEL=on"
set "EMULATOR_GPU=host"
if not defined BOOT_TIMEOUT set "BOOT_TIMEOUT=900"

set "SDK=%ANDROID_SDK%"
set "EMULATOR=%SDK%\emulator\emulator.exe"
set "ADB=%SDK%\platform-tools\adb.exe"
set "FLUTTER=%FLUTTER_SDK%\bin\flutter.bat"
set "AVDMANAGER=%SDK%\cmdline-tools\latest\bin\avdmanager.bat"
set "SDKMANAGER=%SDK%\cmdline-tools\latest\bin\sdkmanager.bat"

if not exist "%EMULATOR%" (
    echo No se encontro: "%EMULATOR%" 1>&2
    exit /b 1
)
if not exist "%ADB%" (
    echo No se encontro: "%ADB%" 1>&2
    exit /b 1
)
if not exist "%FLUTTER%" (
    echo No se encontro: "%FLUTTER%" 1>&2
    exit /b 1
)

set "ANDROID_HOME=%SDK%"
set "ANDROID_SDK_ROOT=%SDK%"
set "PATH=%FLUTTER_SDK%\bin;%SDK%\platform-tools;%PATH%"

"%EMULATOR%" -list-avds | findstr /x /c:"%AVD_NAME%" >nul
if errorlevel 1 (
    echo Creando el emulador Android TV %AVD_NAME%...
    if not exist "%SDKMANAGER%" (
        echo No se encontro: "%SDKMANAGER%" 1>&2
        exit /b 1
    )
    if not exist "%AVDMANAGER%" (
        echo No se encontro: "%AVDMANAGER%" 1>&2
        exit /b 1
    )
    call "%SDKMANAGER%" "%TV_SYSTEM_IMAGE%" || exit /b 1
    echo no | call "%AVDMANAGER%" create avd -n "%AVD_NAME%" -k "%TV_SYSTEM_IMAGE%" -d "%AVD_DEVICE%" || exit /b 1
)

if not exist "%SDK%\skins\tv_1080p\layout" (
    echo No se encontro el skin Android TV: "%SDK%\skins\tv_1080p" 1>&2
    exit /b 1
)

echo Comprobando aceleracion de hardware...
"%EMULATOR%" -accel-check > "%TEMP%\flauncher-accel.txt" 2>&1
if errorlevel 1 (
    echo La aceleracion de hardware no esta disponible. El emulador no se inicia. 1>&2
    type "%TEMP%\flauncher-accel.txt" 1>&2
    exit /b 1
)

set "TV_AVD_CONFIG=%USERPROFILE%\.android\avd\%AVD_NAME%.avd\config.ini"
set "TV_SKIN=%SDK%\skins\tv_1080p"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0configure_tv_avd.ps1" || exit /b 1

set "ANDROID_SERIAL=emulator-5554"
"%ADB%" -s "%ANDROID_SERIAL%" emu avd name 2>nul | findstr /b /c:"%AVD_NAME%" >nul
if not errorlevel 1 (
    echo Reutilizando el emulador Android TV %AVD_NAME%.
) else (
    "%ADB%" devices 2>nul | findstr /b "emulator-" >nul
    if not errorlevel 1 (
        echo Hay otro emulador abierto. Cerralo antes de iniciar %AVD_NAME%. 1>&2
        exit /b 1
    )
    echo Iniciando Android TV %AVD_NAME% ^(aceleracion: %EMULATOR_ACCEL%, GPU: %EMULATOR_GPU%, mando: TvRemote^)...
    start "FLauncher Android TV" "%EMULATOR%" -avd "%AVD_NAME%" -accel "%EMULATOR_ACCEL%" -gpu "%EMULATOR_GPU%" -feature TvRemote -skin tv_1080p -skindir "%SDK%\skins" -no-snapshot -verbose
    echo Emulador Android TV iniciado en una ventana independiente.
)

set /a ELAPSED=0
:wait_for_boot
if !ELAPSED! geq %BOOT_TIMEOUT% goto boot_timeout

"%ADB%" -s "%ANDROID_SERIAL%" shell getprop sys.boot_completed 2>nul | findstr /b "1" >nul
if not errorlevel 1 goto boot_ready

"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command "Start-Sleep -Seconds 5"
set /a ELAPSED+=5
goto wait_for_boot

:boot_timeout
echo Android no termino de arrancar en %BOOT_TIMEOUT% segundos. 1>&2
echo Revisa la consola del emulador. 1>&2
exit /b 1

:boot_ready
"%ADB%" -s "%ANDROID_SERIAL%" shell pm list features > "%TEMP%\flauncher-features.txt"
findstr /i /c:"android.hardware.type.television" "%TEMP%\flauncher-features.txt" >nul
if errorlevel 1 (
    echo El emulador no es Android TV. 1>&2
    "%ADB%" -s "%ANDROID_SERIAL%" shell getprop ro.product.name 1>&2
    exit /b 1
)
echo Android TV esta listo. Compilando FLauncher...
echo Mando: flechas, Enter y Escape, o el control del panel lateral del emulador.
cd /d "%ROOT_DIR%"
call "%FLUTTER%" pub get || exit /b 1
call "%FLUTTER%" build apk --debug || exit /b 1

echo Instalando y abriendo FLauncher...
"%ADB%" -s "%ANDROID_SERIAL%" install -r "%ROOT_DIR%\build\app\outputs\flutter-apk\app-debug.apk" || exit /b 1
"%ADB%" -s "%ANDROID_SERIAL%" shell am start -W -n "me.efesser.flauncher/.MainActivity" || exit /b 1

endlocal
