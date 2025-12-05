# 🚀 Guía de Despliegue Automático

> 📖 **¿Primera vez configurando?** Lee la [**Guía Completa de Configuración**](GUIA_CONFIGURACION_COMPLETA.md) para configurar SSH, claves, y todo paso a paso.

## 📋 Scripts Disponibles

Este proyecto incluye scripts para automatizar el despliegue del APK:

### Windows
- **PowerShell** (Recomendado): `deploy_apk.ps1`
- **CMD**: `deploy_apk.bat`

### Linux/Mac
- **Bash**: `deploy_apk.sh`

---

## 🎯 Uso Rápido

### Windows (PowerShell)
```powershell
.\deploy_apk.ps1
```

### Windows (CMD)
```cmd
deploy_apk.bat
```

### Linux/Mac
```bash
chmod +x deploy_apk.sh
./deploy_apk.sh
```

---

## ⚙️ Configuración

Antes de usar los scripts, edita las variables de configuración:

### PowerShell (`deploy_apk.ps1`)
```powershell
$PYTHONANYWHERE_USER = "nxlsxx"
$PYTHONANYWHERE_HOST = "ssh.pythonanywhere.com"
$REMOTE_PATH = "/home/nxlsxx/mysite/static/downloads"
```

### Bash (`deploy_apk.sh`)
```bash
PYTHONANYWHERE_USER="nxlsxx"
PYTHONANYWHERE_HOST="ssh.pythonanywhere.com"
REMOTE_PATH="/home/nxlsxx/mysite/static/downloads"
```

### Batch (`deploy_apk.bat`)
```batch
set PYTHONANYWHERE_USER=nxlsxx
set PYTHONANYWHERE_HOST=ssh.pythonanywhere.com
set REMOTE_PATH=/home/nxlsxx/mysite/static/downloads
```

---

## 📝 ¿Qué hace el script?

1. ✅ **Lee la versión** del `pubspec.yaml`
2. ✅ **Genera el APK** con `flutter build apk --release`
3. ✅ **Renombra el APK** al formato esperado
4. ✅ **Sube el APK** a PythonAnywhere vía SCP
5. ✅ **Actualiza el backend** (`rutas.txt`) con la nueva versión y tamaño

---

## 🔐 Requisitos

### Para subir automáticamente (SCP):
- **Windows**: Instalar [OpenSSH](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse)
- **Linux/Mac**: Ya viene instalado
- **Configurar SSH**: Debes tener acceso SSH a PythonAnywhere configurado

### Si no tienes SSH:
El script igualmente:
- ✅ Genera el APK
- ✅ Lo renombra
- ✅ Actualiza el backend
- ⚠️ Te indica que subas el archivo manualmente

---

## 🔄 Flujo Completo Automatizado

```
1. Ejecutas: .\deploy_apk.ps1
   ↓
2. Script lee versión de pubspec.yaml
   ↓
3. Genera APK: flutter build apk --release
   ↓
4. Renombra: sanchezpharmaapp-v1.0.2.apk
   ↓
5. Sube a PythonAnywhere (vía SCP)
   ↓
6. Actualiza rutas.txt automáticamente
   ↓
7. ✅ Listo! Solo falta reiniciar el servidor
```

---

## 🛠️ Configuración SSH (Primera vez)

### 1. Generar clave SSH (si no tienes)
```bash
ssh-keygen -t rsa -b 4096 -C "tu_email@ejemplo.com"
```

### 2. Copiar clave a PythonAnywhere
```bash
ssh-copy-id nxlsxx@ssh.pythonanywhere.com
```

### 3. Probar conexión
```bash
ssh nxlsxx@ssh.pythonanywhere.com
```

Si puedes conectarte sin contraseña, el script funcionará automáticamente.

---

## 📦 Alternativa: Subir Manualmente

Si prefieres no usar SSH, el script igualmente:
1. Genera el APK
2. Lo renombra correctamente
3. Te muestra dónde está el archivo

Luego subes manualmente:
- Ve a PythonAnywhere → Files
- Navega a `/home/nxlsxx/mysite/static/downloads/`
- Sube el archivo `sanchezpharmaapp-vX.Y.Z.apk`

---

## 🎯 Ejemplo de Uso

```powershell
# 1. Actualiza la versión en pubspec.yaml
# version: 1.0.2+3

# 2. Ejecuta el script
.\deploy_apk.ps1

# 3. El script hace todo automáticamente:
#    ✅ Genera APK
#    ✅ Lo sube a PythonAnywhere
#    ✅ Actualiza rutas.txt

# 4. Solo falta:
#    - Subir rutas.txt actualizado a PythonAnywhere
#    - Reiniciar el servidor
```

---

## ⚠️ Notas Importantes

1. **Versión en pubspec.yaml**: El script lee la versión automáticamente
2. **Backend**: El script actualiza `rutas.txt`, pero debes subirlo manualmente
3. **Servidor**: Debes reiniciar el servidor en PythonAnywhere después de subir `rutas.txt`
4. **SSH**: Si no tienes SSH configurado, el script te indicará que subas manualmente

---

## 🐛 Solución de Problemas

### "SCP no está disponible"
- **Windows**: Instala OpenSSH
- **Linux/Mac**: Ya debería estar instalado

### "Error al subir el APK"
- Verifica tus credenciales SSH
- Prueba conectarte manualmente: `ssh nxlsxx@ssh.pythonanywhere.com`

### "No se pudo leer la versión"
- Verifica que `pubspec.yaml` tenga el formato correcto: `version: 1.0.0+1`

---

## 🎉 ¡Listo!

Con estos scripts, el despliegue es **mucho más rápido y automático**. Solo ejecuta el script y listo! 🚀

