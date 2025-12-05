# 🔧 Guía Completa de Configuración - Despliegue Automático

Esta guía te llevará paso a paso para configurar todo el sistema de despliegue automático del APK.

---

## ⚠️ IMPORTANTE: Tipo de Cuenta PythonAnywhere

**🔴 Cuentas GRATUITAS**: NO tienen acceso SSH. Debes usar el método **manual** de despliegue (ver sección [Despliegue Manual](#alternativa-despliegue-manual)).

**🟢 Cuentas de PAGO**: Tienen acceso SSH y pueden usar despliegue automático vía SCP.

Si tienes cuenta gratuita, puedes saltar directamente a la sección [Despliegue Manual](#alternativa-despliegue-manual). El script `deploy_apk.ps1` igualmente generará el APK correctamente, solo necesitarás subirlo manualmente.

---

## 📋 Tabla de Contenidos

1. [Requisitos Previos](#requisitos-previos)
2. [Configuración de OpenSSH en Windows](#configuración-de-openssh-en-windows)
3. [Configuración de Claves SSH](#configuración-de-claves-ssh)
4. [Configuración en PythonAnywhere](#configuración-en-pythonanywhere)
5. [Configuración de los Scripts](#configuración-de-los-scripts)
6. [Proceso Completo de Despliegue](#proceso-completo-de-despliegue)
7. [Solución de Problemas](#solución-de-problemas)
8. [Alternativa: Despliegue Manual](#alternativa-despliegue-manual)

---

## 📦 Requisitos Previos

Antes de comenzar, asegúrate de tener:

- ✅ Windows 10/11 (o Linux/Mac)
- ✅ Flutter instalado y configurado
- ✅ Cuenta de PythonAnywhere activa
- ✅ Acceso a tu cuenta de PythonAnywhere (usuario: `nxlsxx`)
- ✅ PowerShell 5.1 o superior (Windows)

**Nota sobre SSH:**
- **Cuentas gratuitas**: No tienen acceso SSH. Usa el método manual (sección 8).
- **Cuentas de pago**: Tienen acceso SSH. Puedes configurar despliegue automático (secciones 2-6).

---

## 🪟 Configuración de OpenSSH en Windows

### Paso 1: Verificar si OpenSSH está instalado

Abre PowerShell como **Administrador** y ejecuta:

```powershell
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'
```

Si ves `OpenSSH.Client` y `OpenSSH.Server`, continúa al Paso 3.

### Paso 2: Instalar OpenSSH (si no está instalado)

```powershell
# Instalar cliente SSH
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

# Verificar instalación
ssh -V
```

Deberías ver algo como: `OpenSSH_for_Windows_8.x`

### Paso 3: Verificar que SCP funciona

```powershell
scp
```

Si ves el mensaje de ayuda de SCP, está funcionando correctamente.

---

## 🔐 Configuración de Claves SSH

### Paso 1: Generar una Clave SSH (si no tienes una)

Abre PowerShell (no necesitas ser administrador) y ejecuta:

```powershell
# Generar clave SSH (reemplaza con tu email)
ssh-keygen -t rsa -b 4096 -C "tu_email@ejemplo.com"
```

**Durante la generación:**
- Presiona Enter para usar la ubicación predeterminada: `C:\Users\TuUsuario\.ssh\id_rsa`
- **Opcional**: Ingresa una frase de contraseña (recomendado para mayor seguridad)
- Presiona Enter dos veces más

**Resultado:**
- Se crean dos archivos:
  - `C:\Users\TuUsuario\.ssh\id_rsa` (clave privada - NO compartir)
  - `C:\Users\TuUsuario\.ssh\id_rsa.pub` (clave pública - compartir)

### Paso 2: Verificar que la clave se generó

```powershell
# Ver la clave pública
cat ~\.ssh\id_rsa.pub
```

Deberías ver algo como:
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... tu_email@ejemplo.com
```

### Paso 3: Copiar la Clave Pública

Tienes dos opciones:

#### Opción A: Copiar manualmente
```powershell
# Mostrar la clave pública
Get-Content ~\.ssh\id_rsa.pub | Set-Clipboard
```

Esto copia la clave al portapapeles. Luego ve al Paso 4.

#### Opción B: Usar ssh-copy-id (si está disponible)
```powershell
ssh-copy-id nxlsxx@ssh.pythonanywhere.com
```

**Nota**: `ssh-copy-id` puede no estar disponible en Windows. Si no funciona, usa la Opción A.

---

## 🌐 Configuración en PythonAnywhere

### Paso 1: Acceder a la Configuración de SSH

1. Ve a: https://www.pythonanywhere.com
2. Inicia sesión con tu cuenta
3. Ve a la pestaña **"Account"** (o busca "SSH keys")
4. O directamente: https://www.pythonanywhere.com/user/nxlsxx/ssh_keys/

### Paso 2: Agregar tu Clave SSH Pública

1. En la página de SSH keys, verás un campo de texto
2. Pega tu clave pública (la que copiaste en el Paso 3 anterior)
3. Haz clic en **"Add key"** o **"Save"**

**Formato de la clave:**
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... tu_email@ejemplo.com
```

### Paso 3: Verificar la Conexión SSH

Vuelve a PowerShell y prueba la conexión:

```powershell
# Probar conexión SSH
ssh nxlsxx@ssh.pythonanywhere.com
```

**Primera vez:**
- Te preguntará si confías en el host: escribe `yes` y presiona Enter
- Si configuraste la clave correctamente, deberías conectarte **sin pedir contraseña**
- Si te pide contraseña, la clave no está configurada correctamente

**Si la conexión funciona:**
- Escribe `exit` para salir
- Ahora SCP debería funcionar sin problemas

### Paso 4: Verificar la Estructura de Carpetas

Conéctate por SSH y verifica que existe la carpeta de descargas:

```powershell
ssh nxlsxx@ssh.pythonanywhere.com "ls -la ~/mysite/static/downloads"
```

Si la carpeta no existe, créala:

```powershell
ssh nxlsxx@ssh.pythonanywhere.com "mkdir -p ~/mysite/static/downloads"
```

---

## ⚙️ Configuración de los Scripts

### Paso 1: Editar el Script de PowerShell

Abre `deploy_apk.ps1` y verifica estas líneas (alrededor de la línea 14-16):

```powershell
$PYTHONANYWHERE_USER = "nxlsxx"
$PYTHONANYWHERE_HOST = "ssh.pythonanywhere.com"
$REMOTE_PATH = "/home/nxlsxx/mysite/static/downloads"
```

**Ajusta estos valores si es necesario:**
- `$PYTHONANYWHERE_USER`: Tu usuario de PythonAnywhere
- `$PYTHONANYWHERE_HOST`: Normalmente `ssh.pythonanywhere.com`
- `$REMOTE_PATH`: Ruta donde se subirán los APKs

### Paso 2: Verificar Permisos de Ejecución (PowerShell)

Si PowerShell te da error de "no se puede ejecutar scripts", ejecuta:

```powershell
# Ver política actual
Get-ExecutionPolicy

# Si es "Restricted", cambia a "RemoteSigned" (requiere admin)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 🚀 Proceso Completo de Despliegue

### Paso 1: Actualizar la Versión

Edita `pubspec.yaml`:

```yaml
version: 1.0.1+2  # Incrementa según tu nueva versión
```

### Paso 2: Ejecutar el Script

```powershell
.\deploy_apk.ps1
```

**El script automáticamente:**
1. ✅ Lee la versión del `pubspec.yaml`
2. ✅ Genera el APK con `flutter build apk --release`
3. ✅ Renombra el APK: `sanchezpharmaapp-v1.0.1.apk`
4. ✅ Calcula el tamaño del APK
5. ✅ Intenta subir el APK vía SCP
6. ✅ Muestra instrucciones para actualizar el backend

### Paso 3: Verificar que el APK se Subió

Abre en el navegador:
```
https://nxlsxx.pythonanywhere.com/static/downloads/sanchezpharmaapp-v1.0.1.apk
```

**Debe descargar el archivo**. Si no, revisa:
- Que el archivo esté en la carpeta correcta
- Que la carpeta `static/downloads` esté configurada como estática en PythonAnywhere

### Paso 4: Actualizar el Backend

1. Ve a PythonAnywhere → **Files**
2. Abre el archivo `rutas.txt` (o `app.py` según tu configuración)
3. Busca las líneas alrededor de la línea 6730:

```python
# Versión actual de la app en producción
CURRENT_VERSION = "1.0.0"        # Versión base (no cambia)
MINIMUM_VERSION = "1.0.0"        # Versión mínima requerida
LATEST_VERSION = "1.0.1"         # ← ACTUALIZA ESTA
```

4. Actualiza:
   - `LATEST_VERSION = "1.0.1"` (tu nueva versión)
   - `APK_SIZE = 79726018` (el tamaño que mostró el script)

### Paso 5: Reiniciar el Servidor

1. Ve a PythonAnywhere → **Web**
2. Haz clic en **"Reload"** o **"Restart"**
3. Espera unos segundos hasta que el servidor se reinicie

### Paso 6: Verificar que Todo Funciona

1. Abre la app en tu dispositivo
2. Ve al menú lateral → **"Actualizar App"**
3. Deberías ver la nueva versión disponible

---

## 🐛 Solución de Problemas

### ❌ Error: "SCP no está disponible"

**Causa**: OpenSSH no está instalado o no está en el PATH.

**Solución**:
```powershell
# Verificar si está instalado
Get-Command scp -ErrorAction SilentlyContinue

# Si no está, instálalo
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

# Reinicia PowerShell después de instalar
```

---

### ❌ Error: "Connection closed" inmediatamente

**Síntoma**: La conexión SSH se cierra inmediatamente después de mostrar el mensaje de ayuda de PythonAnywhere.

**Causas posibles**:
1. Permisos incorrectos en `~/.ssh/authorized_keys`
2. La clave tiene saltos de línea o formato incorrecto
3. El archivo `authorized_keys` no tiene salto de línea al final
4. Cuenta gratuita de PythonAnywhere (no tiene acceso SSH)

**Solución paso a paso**:

1. **Verifica permisos en PythonAnywhere (consola Bash):**
   ```bash
   # Verificar permisos actuales
   ls -la ~/.ssh/
   
   # Debe mostrar:
   # drwx------ (700) para ~/.ssh/
   # -rw------- (600) para ~/.ssh/authorized_keys
   
   # Si no, corrígelos:
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```

2. **Verifica el formato de la clave:**
   ```bash
   # Ver el contenido del archivo
   cat ~/.ssh/authorized_keys
   
   # La clave debe estar en UNA SOLA LÍNEA
   # Debe empezar con: ssh-rsa AAAAB3NzaC1yc2E...
   # Y terminar con: ...== tu_email@ejemplo.com
   ```

3. **Si la clave tiene saltos de línea, corrígela:**
   ```bash
   # Eliminar el archivo y recrearlo
   rm ~/.ssh/authorized_keys
   
   # Agregar la clave en una sola línea (pega tu clave completa)
   echo "ssh-rsa AAAAB3NzaC1yc2E...tu_clave_completa...== tu_email@ejemplo.com" > ~/.ssh/authorized_keys
   
   # Configurar permisos
   chmod 600 ~/.ssh/authorized_keys
   ```

4. **Verifica que tienes cuenta de pago:**
   - Las cuentas gratuitas de PythonAnywhere **NO tienen acceso SSH**
   - Ve a: https://www.pythonanywhere.com/account/
   - Verifica tu tipo de cuenta

5. **Prueba la conexión nuevamente:**
   ```powershell
   ssh nxlsxx@ssh.pythonanywhere.com
   ```

---

### ❌ Error: "Permission denied" o pide contraseña

**Causa**: La clave SSH no está configurada correctamente en PythonAnywhere.

**Solución**:

1. **Verifica que la clave esté en PythonAnywhere:**
   - Abre consola Bash en PythonAnywhere
   - Ejecuta: `cat ~/.ssh/authorized_keys`
   - Debe aparecer tu clave pública

2. **Verifica que la clave local sea correcta:**
   ```powershell
   # Mostrar tu clave pública
   Get-Content ~\.ssh\id_rsa.pub
   ```
   - Compara con la que está en PythonAnywhere
   - Deben ser **exactamente iguales** (mismo contenido, misma línea)

3. **Prueba la conexión manualmente:**
   ```powershell
   ssh nxlsxx@ssh.pythonanywhere.com
   ```
   - Si te pide contraseña, la clave no está configurada
   - Si se conecta sin contraseña, la clave está bien

4. **Si sigue fallando, regenera la clave:**
   ```powershell
   # Eliminar clave antigua (opcional)
   Remove-Item ~\.ssh\id_rsa*
   
   # Generar nueva clave
   ssh-keygen -t rsa -b 4096 -C "tu_email@ejemplo.com"
   
   # Copiar nueva clave
   Get-Content ~\.ssh\id_rsa.pub | Set-Clipboard
   
   # Agregar en PythonAnywhere (consola Bash)
   ```

---

### ❌ Error: "Cannot execute script" (PowerShell)

**Causa**: La política de ejecución de PowerShell está restringida.

**Solución**:
```powershell
# Ver política actual
Get-ExecutionPolicy

# Cambiar política (requiere admin)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# O ejecutar con bypass temporal
powershell -ExecutionPolicy Bypass -File .\deploy_apk.ps1
```

---

### ❌ Error: "No se pudo leer la versión"

**Causa**: El formato de versión en `pubspec.yaml` es incorrecto.

**Solución**:
- Verifica que `pubspec.yaml` tenga el formato correcto:
  ```yaml
  version: 1.0.1+2
  ```
- No debe tener espacios extra
- Debe estar en la línea que empieza con `version:`

---

### ❌ Error: "APK no se puede descargar desde la URL"

**Causa**: El archivo no está en la ubicación correcta o no es accesible públicamente.

**Solución**:

1. **Verifica que el archivo esté en la carpeta correcta:**
   ```powershell
   ssh nxlsxx@ssh.pythonanywhere.com "ls -la ~/mysite/static/downloads/"
   ```

2. **Verifica permisos del archivo:**
   ```powershell
   ssh nxlsxx@ssh.pythonanywhere.com "chmod 644 ~/mysite/static/downloads/sanchezpharmaapp-v1.0.1.apk"
   ```

3. **Verifica configuración de archivos estáticos en PythonAnywhere:**
   - Ve a PythonAnywhere → **Web**
   - Busca "Static files"
   - Debe estar configurado: `/static/` → `/home/nxlsxx/mysite/static/`

---

### ❌ Error: "SSH pide contraseña cada vez"

**Causa**: La clave SSH no está configurada o no se está usando.

**Solución**:

1. **Verifica que estés usando la clave correcta:**
   ```powershell
   # Verificar qué clave está usando SSH
   ssh -v nxlsxx@ssh.pythonanywhere.com
   ```
   - Busca la línea que dice "Offering public key"
   - Debe mostrar tu clave

2. **Si no usa la clave, especifícala manualmente:**
   ```powershell
   ssh -i ~\.ssh\id_rsa nxlsxx@ssh.pythonanywhere.com
   ```

3. **Agrega configuración SSH (opcional pero recomendado):**
   Crea/edita `~\.ssh\config`:
   ```
   Host pythonanywhere
       HostName ssh.pythonanywhere.com
       User nxlsxx
       IdentityFile ~\.ssh\id_rsa
   ```
   
   Luego usa:
   ```powershell
   ssh pythonanywhere
   ```

---

## 📤 Despliegue Manual (Para Cuentas Gratuitas)

**Esta es la opción para cuentas GRATUITAS de PythonAnywhere** (que no tienen acceso SSH).

El script `deploy_apk.ps1` funciona perfectamente aunque no tengas SSH: genera el APK, lo renombra y te muestra toda la información necesaria.

### Paso 1: Generar el APK con el Script

Ejecuta el script desde PowerShell:

```powershell
cd "C:\UNIVERSIDAD\AOLICACIONES MOVILES\YASTAYA\sanchezpharmaapp"
.\deploy_apk.ps1
```

**El script automáticamente:**
- ✅ Lee la versión del `pubspec.yaml`
- ✅ Genera el APK con `flutter build apk --release`
- ✅ Renombra el APK: `sanchezpharmaapp-v1.0.1.apk`
- ✅ Calcula el tamaño del APK en bytes
- ⚠️ Te muestra instrucciones para subir manualmente (porque no tiene SSH)

**Al final, verás algo como:**
```
Version: 1.0.1
APK: sanchezpharmaapp-v1.0.1.apk
Tamano: 76.03 MB
APK_SIZE = 79726018  # Este número lo necesitarás
```

### Paso 2: Subir el APK Manualmente a PythonAnywhere

1. **Abre PythonAnywhere:**
   - Ve a: https://www.pythonanywhere.com
   - Inicia sesión
   - Ve a la pestaña **"Files"**

2. **Navega a la carpeta de descargas:**
   - En el explorador de archivos, ve a: `/home/nxlsxx/mysite/static/downloads/`
   - Si la carpeta `downloads` no existe, créala:
     - Ve a `/home/nxlsxx/mysite/static/`
     - Haz clic en "New directory" → nombre: `downloads`

3. **Sube el APK:**
   - Haz clic en **"Upload a file"**
   - Selecciona el archivo: `sanchezpharmaapp-v1.0.1.apk` (está en la carpeta del proyecto)
   - Espera a que termine la subida

4. **Verifica que el archivo esté accesible:**
   - Abre en el navegador: `https://nxlsxx.pythonanywhere.com/static/downloads/sanchezpharmaapp-v1.0.1.apk`
   - **Debe descargar el archivo**. Si no, revisa la configuración de archivos estáticos.

### Paso 3: Actualizar el Backend en PythonAnywhere

1. **Abre el archivo de rutas:**
   - En PythonAnywhere → **Files**
   - Abre: `/home/nxlsxx/mysite/rutas.txt` (o el archivo donde tengas las rutas)

2. **Busca las líneas de configuración de versión** (alrededor de la línea 6730):
   ```python
   LATEST_VERSION = "1.0.0"  # ← Cambia esto
   APK_SIZE = 79726018       # ← Cambia esto (el número que te mostró el script)
   ```

3. **Actualiza los valores:**
   ```python
   LATEST_VERSION = "1.0.1"  # Tu nueva versión
   APK_SIZE = 79726018        # El tamaño en bytes que mostró el script
   ```

4. **Guarda el archivo** (Ctrl+S o botón Save)

### Paso 4: Reiniciar el Servidor

1. Ve a PythonAnywhere → **Web**
2. Haz clic en el botón **"Reload"** o **"Restart"** de tu aplicación web
3. Espera unos segundos hasta que el servidor se reinicie

### Paso 5: Verificar que Todo Funciona

1. **Verifica la URL del APK:**
   - Abre: `https://nxlsxx.pythonanywhere.com/static/downloads/sanchezpharmaapp-v1.0.1.apk`
   - Debe descargar el archivo

2. **Prueba en la app:**
   - Abre la app en tu dispositivo
   - Ve al menú lateral → **"Actualizar App"**
   - Deberías ver la nueva versión disponible

---

## ✅ Resumen: Flujo Completo para Cuentas Gratuitas

```
1. Actualiza versión en pubspec.yaml
   ↓
2. Ejecuta: .\deploy_apk.ps1
   ↓
3. Script genera APK y muestra información
   ↓
4. Sube APK manualmente a PythonAnywhere Files
   ↓
5. Actualiza LATEST_VERSION y APK_SIZE en rutas.txt
   ↓
6. Reinicia servidor en PythonAnywhere
   ↓
7. ✅ ¡Listo!
```

**Tiempo estimado:** 5-10 minutos por despliegue

---

## ✅ Checklist de Configuración

Marca cada paso cuando lo completes:

### Configuración Inicial
- [ ] OpenSSH instalado en Windows
- [ ] Clave SSH generada
- [ ] Clave pública agregada en PythonAnywhere
- [ ] Conexión SSH probada y funcionando
- [ ] Carpeta `~/mysite/static/downloads` existe

### Configuración de Scripts
- [ ] Script `deploy_apk.ps1` configurado con tus datos
- [ ] Política de ejecución de PowerShell configurada
- [ ] Script probado (aunque falle SCP, debe generar APK)

### Primera Prueba
- [ ] APK generado correctamente
- [ ] APK subido (automático o manual)
- [ ] URL del APK accesible en navegador
- [ ] Backend actualizado con nueva versión
- [ ] Servidor reiniciado
- [ ] App muestra actualización disponible

---

## 🎯 Comandos Rápidos de Referencia

### Verificar SSH
```powershell
ssh nxlsxx@ssh.pythonanywhere.com
```

### Subir APK manualmente (si SCP falla)
```powershell
scp sanchezpharmaapp-v1.0.1.apk nxlsxx@ssh.pythonanywhere.com:~/mysite/static/downloads/
```

### Verificar archivos en servidor
```powershell
ssh nxlsxx@ssh.pythonanywhere.com "ls -lh ~/mysite/static/downloads/"
```

### Verificar tamaño del APK
```powershell
(Get-Item sanchezpharmaapp-v1.0.1.apk).Length
```

### Mostrar clave SSH pública
```powershell
Get-Content ~\.ssh\id_rsa.pub
```

---

## 📞 Enlaces Útiles

- **PythonAnywhere SSH Keys**: https://www.pythonanywhere.com/user/nxlsxx/ssh_keys/
- **PythonAnywhere Files**: https://www.pythonanywhere.com/user/nxlsxx/files/
- **PythonAnywhere Web**: https://www.pythonanywhere.com/user/nxlsxx/webapps/
- **OpenSSH para Windows**: https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse
- **Ayuda PythonAnywhere SSH**: https://help.pythonanywhere.com/pages/SSHAccess

---

## 🎉 ¡Listo!

Una vez completada esta configuración, el despliegue será mucho más rápido y automático. Solo necesitarás:

1. Actualizar versión en `pubspec.yaml`
2. Ejecutar `.\deploy_apk.ps1`
3. Actualizar backend en PythonAnywhere
4. Reiniciar servidor

¡Y listo! 🚀

---

## 💡 Consejos Adicionales

1. **Mantén una copia de tu clave SSH**: Si cambias de computadora, necesitarás agregar la nueva clave en PythonAnywhere.

2. **Usa frases de contraseña**: Aunque es opcional, proteger tu clave privada con una frase de contraseña es más seguro.

3. **Verifica antes de desplegar**: Siempre prueba la conexión SSH antes de ejecutar el script de despliegue.

4. **Mantén un registro**: Anota las versiones que has desplegado y sus tamaños para referencia futura.

5. **Backup del APK**: Guarda una copia local de cada APK que despliegues por si necesitas revertir.

---

**¿Problemas?** Revisa la sección de [Solución de Problemas](#solución-de-problemas) o verifica los enlaces útiles.

