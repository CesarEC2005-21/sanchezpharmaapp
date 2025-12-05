# 📱 Guía Completa: Sistema de Actualización de la App

## 🎯 Resumen
Este sistema permite que los usuarios actualicen la app directamente desde la aplicación, sin necesidad de Play Store.

---

## 📋 PASO 1: Generar el APK de Producción

### 1.1 Actualizar la versión en `pubspec.yaml`
```yaml
version: 1.0.1+2  # Incrementa el número cuando subas nueva versión
# Formato: version: X.Y.Z+build
# X.Y.Z = versión visible (1.0.1)
# +build = número de build interno (2)
```

### 1.2 Generar el APK firmado
```bash
# En la terminal, desde la raíz del proyecto:
flutter build apk --release

# El APK se generará en:
# build/app/outputs/flutter-apk/app-release.apk
```

### 1.3 Renombrar el APK
Renombra el APK con el formato que espera el backend:
```
app-release.apk → sanchezpharmaapp-v1.0.1.apk
```

---

## 📤 PASO 2: Subir el APK al Servidor (PythonAnywhere)

### 2.1 Opción A: Subir vía Web (Más fácil)
1. Ve a tu cuenta de PythonAnywhere: https://www.pythonanywhere.com
2. Entra a la pestaña **"Files"**
3. Navega a: `/home/nxlsxx/mysite/static/downloads/`
   - Si la carpeta `downloads` no existe, créala
4. Sube el archivo `sanchezpharmaapp-v1.0.1.apk`
5. Asegúrate de que el archivo sea accesible públicamente

### 2.2 Opción B: Subir vía SSH (Si tienes acceso)
```bash
# Conecta por SSH a PythonAnywhere
ssh nxlsxx@ssh.pythonanywhere.com

# Crea la carpeta si no existe
mkdir -p ~/mysite/static/downloads

# Sube el archivo (desde tu computadora local)
scp sanchezpharmaapp-v1.0.1.apk nxlsxx@ssh.pythonanywhere.com:~/mysite/static/downloads/
```

### 2.3 Verificar que el APK sea accesible
Abre en el navegador:
```
https://nxlsxx.pythonanywhere.com/static/downloads/sanchezpharmaapp-v1.0.1.apk
```
**Debe descargar el archivo**, si no, revisa la configuración de archivos estáticos.

---

## ⚙️ PASO 3: Configurar el Backend (rutas.txt)

### 3.1 Editar el endpoint de versión
Abre `rutas.txt` y busca la línea ~6730. Actualiza estos valores:

```python
# Versión actual de la app en producción
CURRENT_VERSION = "1.0.0"        # Versión base (no cambia)
MINIMUM_VERSION = "1.0.0"        # Versión mínima requerida (forzada)
LATEST_VERSION = "1.0.1"         # ← ACTUALIZA ESTA cuando subas nueva versión

# URL donde está alojado el APK
APK_BASE_URL = "https://nxlsxx.pythonanywhere.com/static/downloads"
APK_FILENAME = f"sanchezpharmaapp-v{LATEST_VERSION}.apk"
APK_URL = f"{APK_BASE_URL}/{APK_FILENAME}"

# Tamaño del APK en bytes (ajusta según el tamaño real)
# Para obtenerlo: tamaño del archivo en bytes
APK_SIZE = 25000000  # 25 MB (ajusta según tu APK)
```

### 3.2 Ejemplo de actualización
Cuando quieras subir la versión 1.0.2:

```python
LATEST_VERSION = "1.0.2"  # ← Cambia esto
APK_FILENAME = f"sanchezpharmaapp-v1.0.2.apk"  # Se genera automáticamente
APK_SIZE = 26000000  # Ajusta según el tamaño real del nuevo APK
```

### 3.3 Reiniciar el servidor
Después de cambiar `rutas.txt`, reinicia el servidor en PythonAnywhere:
- Ve a la pestaña **"Web"**
- Haz clic en **"Reload"** o **"Restart"**

---

## 🔧 PASO 4: Configurar Permisos en Android

### 4.1 Editar AndroidManifest.xml
Abre: `android/app/src/main/AndroidManifest.xml`

Agrega este permiso (después de la línea 16):

```xml
<!-- Permisos para actualización de app -->
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
<uses-permission android:name="android.permission.INSTALL_PACKAGES" tools:ignore="ProtectedPermissions"/>
```

El archivo debería verse así:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
    <!-- ... otros permisos ... -->
    
    <!-- Permisos para actualización de app -->
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
    <uses-permission android:name="android.permission.INSTALL_PACKAGES" tools:ignore="ProtectedPermissions"/>
    
    <application ...>
        ...
    </application>
</manifest>
```

---

## 🧪 PASO 5: Probar el Sistema

### 5.1 Instalar dependencias
```bash
flutter pub get
```

### 5.2 Probar en la app
1. Abre la app en tu dispositivo
2. Abre el menú lateral (☰)
3. Busca **"Actualizar App"**
4. Deberías ver:
   - Tu versión actual (ej: v1.0.0)
   - Badge rojo si hay actualización disponible

### 5.3 Simular actualización
Para probar sin subir un APK real:

1. **Opción A**: Cambia temporalmente `LATEST_VERSION` en el backend a una versión mayor
2. **Opción B**: Instala una versión antigua de la app (1.0.0) y luego verifica

---

## 📝 Flujo Completo de Actualización

### Cuando quieras publicar una nueva versión:

1. **Desarrollar cambios** en la app
2. **Actualizar versión** en `pubspec.yaml`:
   ```yaml
   version: 1.0.2+3
   ```
3. **Generar APK**:
   ```bash
   flutter build apk --release
   ```
4. **Renombrar APK**:
   ```
   app-release.apk → sanchezpharmaapp-v1.0.2.apk
   ```
5. **Subir APK** a PythonAnywhere:
   - Carpeta: `/home/nxlsxx/mysite/static/downloads/`
   - Archivo: `sanchezpharmaapp-v1.0.2.apk`
6. **Actualizar backend** (`rutas.txt`):
   ```python
   LATEST_VERSION = "1.0.2"
   APK_SIZE = 26000000  # Tamaño real del nuevo APK
   ```
7. **Reiniciar servidor** en PythonAnywhere
8. **Verificar URL**:
   ```
   https://nxlsxx.pythonanywhere.com/static/downloads/sanchezpharmaapp-v1.0.2.apk
   ```

---

## 🎯 Configuración de Versiones

### Versión Mínima (MINIMUM_VERSION)
- **Uso**: Para actualizaciones **FORZADAS** (críticas)
- **Ejemplo**: Si hay un bug crítico de seguridad, fuerza a todos a actualizar
- **Comportamiento**: El usuario NO puede cerrar el diálogo hasta actualizar

### Versión Recomendada (LATEST_VERSION)
- **Uso**: Para actualizaciones **OPCIONALES** (mejoras)
- **Ejemplo**: Nuevas funcionalidades, mejoras de UI
- **Comportamiento**: El usuario puede elegir "Más tarde"

### Ejemplo práctico:
```python
CURRENT_VERSION = "1.0.0"    # Versión base (no cambia)
MINIMUM_VERSION = "1.0.0"    # Todos deben tener al menos 1.0.0
LATEST_VERSION = "1.0.2"      # Última versión disponible (1.0.2)
```

**Escenario**: 
- Usuario con 1.0.0 → Ve actualización disponible (1.0.2)
- Usuario con 1.0.1 → Ve actualización disponible (1.0.2)
- Usuario con 1.0.2 → No ve actualización (ya tiene la última)

---

## ⚠️ Consideraciones Importantes

### 1. Tamaño del APK
- El tamaño debe ser **exacto** en bytes
- Para obtenerlo: Click derecho en el APK → Propiedades → Tamaño en bytes
- O usa: `ls -l sanchezpharmaapp-v1.0.1.apk` (en Linux/Mac)

### 2. Permisos de Instalación
- Android 8.0+ requiere permiso `REQUEST_INSTALL_PACKAGES`
- El usuario debe permitir "Instalar desde fuentes desconocidas"
- Esto se solicita automáticamente la primera vez

### 3. Seguridad
- **Firma el APK** con tu keystore antes de subirlo
- **Usa HTTPS** para la descarga (ya está configurado)
- **Verifica el hash** del APK si quieres mayor seguridad (opcional)

### 4. PythonAnywhere - Archivos Estáticos
- Asegúrate de que la carpeta `static/downloads/` esté configurada como estática
- En PythonAnywhere, los archivos en `/static/` son accesibles públicamente

---

## 🔍 Solución de Problemas

### ❌ "No se pudo verificar actualizaciones"
- Verifica que el endpoint `/api_version_check` funcione
- Abre: `https://nxlsxx.pythonanywhere.com/api_version_check?version=1.0.0`
- Debe devolver JSON con información de versión

### ❌ "URL de descarga no disponible"
- Verifica que el APK esté en la carpeta correcta
- Verifica que la URL sea accesible en el navegador
- Revisa que `APK_BASE_URL` y `APK_FILENAME` sean correctos

### ❌ "Error al descargar la actualización"
- Verifica permisos de almacenamiento
- Verifica conexión a internet
- Revisa que el APK no esté corrupto

### ❌ "No se puede instalar"
- Verifica permisos en AndroidManifest.xml
- El usuario debe permitir "Fuentes desconocidas"
- Verifica que el APK esté firmado correctamente

---

## 📞 Checklist Rápido

Antes de publicar una actualización, verifica:

- [ ] Versión actualizada en `pubspec.yaml`
- [ ] APK generado y renombrado correctamente
- [ ] APK subido a PythonAnywhere
- [ ] URL del APK accesible en navegador
- [ ] Backend actualizado con nueva versión
- [ ] Servidor reiniciado
- [ ] Tamaño del APK correcto en bytes
- [ ] Permisos agregados en AndroidManifest.xml

---

## 🎉 ¡Listo!

Una vez completados estos pasos, el sistema de actualización funcionará automáticamente. Los usuarios verán el botón "Actualizar App" en el menú y podrán actualizar cuando haya una nueva versión disponible.

