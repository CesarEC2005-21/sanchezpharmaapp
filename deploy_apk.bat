@echo off
REM Script de automatización para Windows (CMD)
REM Uso: deploy_apk.bat

echo 🚀 Iniciando despliegue automático de APK...

REM ============================================
REM CONFIGURACIÓN - AJUSTA ESTOS VALORES
REM ============================================
set PYTHONANYWHERE_USER=nxlsxx
set PYTHONANYWHERE_HOST=ssh.pythonanywhere.com
set REMOTE_PATH=/home/nxlsxx/mysite/static/downloads
REM Nota: El backend está en PythonAnywhere, no en el proyecto local

REM ============================================
REM PASO 1: Leer versión del pubspec.yaml
REM ============================================
echo.
echo 📖 Leyendo versión del pubspec.yaml...

for /f "tokens=2 delims=: " %%a in ('findstr /r "^version:" pubspec.yaml') do set VERSION_LINE=%%a
for /f "tokens=1 delims=+" %%a in ("%VERSION_LINE%") do set VERSION=%%a

if "%VERSION%"=="" (
    echo ❌ No se pudo leer la versión del pubspec.yaml
    exit /b 1
)

echo ✅ Versión encontrada: %VERSION%

REM ============================================
REM PASO 2: Generar APK
REM ============================================
echo.
echo 🔨 Generando APK...

flutter build apk --release

if errorlevel 1 (
    echo ❌ Error al generar el APK
    exit /b 1
)

echo ✅ APK generado correctamente

REM ============================================
REM PASO 3: Renombrar APK
REM ============================================
echo.
echo 📝 Renombrando APK...

set SOURCE_APK=build\app\outputs\flutter-apk\app-release.apk
set TARGET_APK=sanchezpharmaapp-v%VERSION%.apk

if exist "%SOURCE_APK%" (
    copy "%SOURCE_APK%" "%TARGET_APK%" >nul
    echo ✅ APK renombrado: %TARGET_APK%
) else (
    echo ❌ No se encontró el APK generado
    exit /b 1
)

REM ============================================
REM PASO 4: Subir APK a PythonAnywhere
REM ============================================
echo.
echo 📤 Subiendo APK a PythonAnywhere...
echo    Usuario: %PYTHONANYWHERE_USER%
echo    Host: %PYTHONANYWHERE_HOST%
echo    Destino: %REMOTE_PATH%

set REMOTE_FILE=%PYTHONANYWHERE_USER%@%PYTHONANYWHERE_HOST%:%REMOTE_PATH%/%TARGET_APK%

REM Verificar si SCP está disponible
where scp >nul 2>&1
if errorlevel 1 (
    echo ⚠️  SCP no está disponible. Sube el archivo manualmente:
    echo    Archivo: %TARGET_APK%
    echo    Destino: %REMOTE_PATH%
) else (
    scp "%TARGET_APK%" "%REMOTE_FILE%"
    if errorlevel 1 (
        echo ❌ Error al subir el APK. Verifica tus credenciales SSH.
    ) else (
        echo ✅ APK subido correctamente
    )
)

REM ============================================
REM PASO 5: Instrucciones para actualizar backend
REM ============================================
echo.
echo ⚙️  Información para actualizar backend en PythonAnywhere...
echo    El backend está en PythonAnywhere, actualiza manualmente:
echo.
echo    📝 Edita el archivo de rutas en PythonAnywhere:
echo       Busca la línea: LATEST_VERSION = "X.X.X"
echo       Cámbiala a:     LATEST_VERSION = "%VERSION%"
echo.
echo    📏 Actualiza el tamaño del APK:
echo       Busca la línea: APK_SIZE = XXXXXXX
echo       Cámbiala a:     APK_SIZE = [tamaño en bytes]
echo.
echo    🔄 Después de editar, reinicia el servidor en PythonAnywhere

REM ============================================
REM RESUMEN
REM ============================================
echo.
echo ═══════════════════════════════════════════════════
echo ✅ DESPLIEGUE COMPLETADO
echo ═══════════════════════════════════════════════════
echo Versión: %VERSION%
echo APK: %TARGET_APK%
echo URL: https://nxlsxx.pythonanywhere.com/static/downloads/%TARGET_APK%
echo.
echo 📋 Próximos pasos:
echo    1. Ve a PythonAnywhere → Files
echo    2. Edita tu archivo de rutas (ej: rutas.txt o app.py)
echo    3. Actualiza LATEST_VERSION = "%VERSION%"
echo    4. Actualiza APK_SIZE = [tamaño en bytes]
echo    5. Reinicia el servidor en PythonAnywhere
echo    6. Verifica la URL del APK en el navegador
echo ═══════════════════════════════════════════════════

pause

