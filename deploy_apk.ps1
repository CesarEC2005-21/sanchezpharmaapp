# Script de automatización para Windows (PowerShell)
# Uso: .\deploy_apk.ps1

Write-Host "Iniciando despliegue automatico de APK..." -ForegroundColor Cyan

# Colores
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Yellow"

# ============================================
# CONFIGURACIÓN - AJUSTA ESTOS VALORES
# ============================================
$PYTHONANYWHERE_USER = "nxlsxx"
$PYTHONANYWHERE_HOST = "ssh.pythonanywhere.com"
$REMOTE_PATH = "/home/nxlsxx/mysite/static/downloads"
# Nota: El backend está en PythonAnywhere, no en el proyecto local

# ============================================
# PASO 1: Leer versión del pubspec.yaml
# ============================================
Write-Host "`nLeyendo version del pubspec.yaml..." -ForegroundColor $infoColor

$pubspecContent = Get-Content "pubspec.yaml" -Raw
if ($pubspecContent -match 'version:\s*([\d.]+)\+(\d+)') {
    $version = $matches[1]
    $build = $matches[2]
    Write-Host "Version encontrada: $version (build $build)" -ForegroundColor $successColor
} else {
    Write-Host "Error: No se pudo leer la version del pubspec.yaml" -ForegroundColor $errorColor
    exit 1
}

# ============================================
# PASO 2: Generar APK
# ============================================
Write-Host "`nGenerando APK..." -ForegroundColor $infoColor

$buildResult = flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Error al generar el APK" -ForegroundColor $errorColor
    exit 1
}

Write-Host "APK generado correctamente" -ForegroundColor $successColor

# ============================================
# PASO 3: Renombrar APK
# ============================================
Write-Host "`nRenombrando APK..." -ForegroundColor $infoColor

$sourceApk = "build\app\outputs\flutter-apk\app-release.apk"
$targetApk = "sanchezpharmaapp-v$version.apk"

if (Test-Path $sourceApk) {
    Copy-Item $sourceApk $targetApk -Force
    Write-Host "APK renombrado: $targetApk" -ForegroundColor $successColor
    
    # Obtener tamaño del APK
    $apkSize = (Get-Item $targetApk).Length
    $apkSizeMB = [math]::Round($apkSize / 1MB, 2)
    Write-Host "   Tamano: $apkSizeMB MB ($apkSize bytes)" -ForegroundColor $infoColor
} else {
    Write-Host "Error: No se encontro el APK generado" -ForegroundColor $errorColor
    exit 1
}

# ============================================
# PASO 4: Subir APK a PythonAnywhere (vía SCP)
# ============================================
Write-Host "`nSubiendo APK a PythonAnywhere..." -ForegroundColor $infoColor

Write-Host "   Usuario: $PYTHONANYWHERE_USER" -ForegroundColor $infoColor
Write-Host "   Host: $PYTHONANYWHERE_HOST" -ForegroundColor $infoColor
Write-Host "   Destino: $REMOTE_PATH" -ForegroundColor $infoColor

# Verificar si SCP está disponible (requiere OpenSSH en Windows)
$scpCommand = "scp"
$scpAvailable = Get-Command $scpCommand -ErrorAction SilentlyContinue

if (-not $scpAvailable) {
    Write-Host "`n⚠️  Advertencia: SCP no esta disponible." -ForegroundColor $errorColor
    Write-Host "   Instala OpenSSH para Windows:" -ForegroundColor $infoColor
    Write-Host "   https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse" -ForegroundColor $infoColor
    Write-Host "`n   O sube el archivo manualmente:" -ForegroundColor $infoColor
    Write-Host "   Archivo: $targetApk" -ForegroundColor $infoColor
    Write-Host "   Destino: $REMOTE_PATH" -ForegroundColor $infoColor
} else {
    $remoteFile = "$PYTHONANYWHERE_USER@$PYTHONANYWHERE_HOST`:$REMOTE_PATH/$targetApk"
    
    Write-Host "   Subiendo archivo..." -ForegroundColor $infoColor
    Write-Host "   Comando: scp `"$targetApk`" `"$remoteFile`"" -ForegroundColor Gray
    Write-Host "   Nota: Si se solicita contraseña, ingrésala manualmente" -ForegroundColor Gray
    
    # Capturar salida de error de SCP
    # Usar -o ConnectTimeout para evitar esperas largas
    $scpOutput = & scp -o ConnectTimeout=10 "$targetApk" "$remoteFile" 2>&1
    $scpExitCode = $LASTEXITCODE
    
    if ($scpExitCode -eq 0) {
        Write-Host "✅ APK subido correctamente" -ForegroundColor $successColor
    } else {
        Write-Host "`n❌ Error al subir el APK via SCP" -ForegroundColor $errorColor
        
        # Mostrar detalles del error
        if ($scpOutput) {
            Write-Host "   Detalles del error:" -ForegroundColor $errorColor
            $scpOutput | ForEach-Object {
                Write-Host "   $_" -ForegroundColor Gray
            }
        }
        
        Write-Host "`n   Posibles causas:" -ForegroundColor $infoColor
        Write-Host "   • Credenciales SSH incorrectas" -ForegroundColor $infoColor
        Write-Host "   • PythonAnywhere requiere autenticación interactiva" -ForegroundColor $infoColor
        Write-Host "   • Problemas de conexión de red" -ForegroundColor $infoColor
        Write-Host "   • SSH key no configurada correctamente" -ForegroundColor $infoColor
        
        Write-Host "`n   Soluciones:" -ForegroundColor $infoColor
        Write-Host "   1. Configura SSH key en PythonAnywhere:" -ForegroundColor $infoColor
        Write-Host "      https://www.pythonanywhere.com/user/$PYTHONANYWHERE_USER/ssh_keys/" -ForegroundColor Gray
        Write-Host "   2. Prueba la conexión SSH manualmente:" -ForegroundColor $infoColor
        Write-Host "      ssh $PYTHONANYWHERE_USER@$PYTHONANYWHERE_HOST" -ForegroundColor Gray
        Write-Host "   3. Sube el archivo manualmente via PythonAnywhere Files:" -ForegroundColor $infoColor
        Write-Host "      Archivo local: $targetApk" -ForegroundColor Gray
        Write-Host "      Destino remoto: $REMOTE_PATH" -ForegroundColor Gray
        Write-Host "   4. O usa el panel web de PythonAnywhere:" -ForegroundColor $infoColor
        Write-Host "      https://www.pythonanywhere.com/user/$PYTHONANYWHERE_USER/files$REMOTE_PATH" -ForegroundColor Gray
    }
}

# ============================================
# PASO 5: Instrucciones para actualizar backend
# ============================================
Write-Host "`nInformacion para actualizar backend en PythonAnywhere..." -ForegroundColor $infoColor
Write-Host "   El backend esta en PythonAnywhere, actualiza manualmente:" -ForegroundColor $infoColor
Write-Host "`n   Edita el archivo de rutas en PythonAnywhere:" -ForegroundColor $infoColor
Write-Host "      Busca la linea: LATEST_VERSION = `"X.X.X`"" -ForegroundColor $infoColor
Write-Host "      Cambiala a:     LATEST_VERSION = `"$version`"" -ForegroundColor $successColor
Write-Host "`n   Actualiza el tamano del APK:" -ForegroundColor $infoColor
Write-Host "      Busca la linea: APK_SIZE = XXXXXXX" -ForegroundColor $infoColor
Write-Host "      Cambiala a:     APK_SIZE = $apkSize  # $apkSizeMB MB" -ForegroundColor $successColor
Write-Host "`n   Despues de editar, reinicia el servidor en PythonAnywhere" -ForegroundColor $infoColor

# ============================================
# RESUMEN
# ============================================
Write-Host "`n" -NoNewline
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "DESPLIEGUE COMPLETADO" -ForegroundColor $successColor
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "Version: $version" -ForegroundColor $infoColor
Write-Host "APK: $targetApk" -ForegroundColor $infoColor
Write-Host "Tamano: $apkSizeMB MB" -ForegroundColor $infoColor
Write-Host "URL: https://nxlsxx.pythonanywhere.com/static/downloads/$targetApk" -ForegroundColor $infoColor
Write-Host "`nProximos pasos:" -ForegroundColor $infoColor
Write-Host "   1. Ve a PythonAnywhere -> Files" -ForegroundColor $infoColor
Write-Host "   2. Edita tu archivo de rutas (ej: rutas.txt o app.py)" -ForegroundColor $infoColor
Write-Host "   3. Actualiza LATEST_VERSION = `"$version`"" -ForegroundColor $infoColor
Write-Host "   4. Actualiza APK_SIZE = $apkSize" -ForegroundColor $infoColor
Write-Host "   5. Reinicia el servidor en PythonAnywhere" -ForegroundColor $infoColor
Write-Host "   6. Verifica la URL del APK en el navegador" -ForegroundColor $infoColor
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan

