# 🔑 Cómo Configurar la API Key de Google Maps

## ⚠️ IMPORTANTE: El error "Cannot read properties of undefined (reading 'maps')" ocurre porque falta la API Key de Google Maps

## 📋 Pasos para Obtener tu API Key

### 1. Ir a Google Cloud Console
1. Ve a: https://console.cloud.google.com/
2. Inicia sesión con tu cuenta de Google

### 2. Crear o Seleccionar un Proyecto
1. En la parte superior, haz clic en el selector de proyectos
2. Haz clic en "NUEVO PROYECTO"
3. Ingresa un nombre (ej: "Sanchez Pharma Maps")
4. Haz clic en "CREAR"
5. Espera a que se cree el proyecto (puede tardar unos segundos)

### 3. Habilitar las APIs Necesarias
1. En el menú lateral, ve a **"APIs y servicios"** → **"Biblioteca"**
2. Busca y habilita estas APIs (una por una):
   - **Maps JavaScript API** ⚠️ **IMPORTANTE para Flutter Web**
   - **Maps SDK for Android** (para Android)
   - **Maps SDK for iOS** (para iOS)
   - **Geocoding API** (para convertir direcciones a coordenadas)
   - **Directions API** (opcional, para rutas)

### 4. Crear la API Key
1. Ve a **"APIs y servicios"** → **"Credenciales"**
2. Haz clic en **"+ CREAR CREDENCIALES"** → **"Clave de API"**
3. Se creará una nueva API Key
4. **COPIA LA API KEY** (la necesitarás en los siguientes pasos)

### 5. (Opcional pero Recomendado) Restringir la API Key
1. Haz clic en la API Key que acabas de crear
2. En "Restricciones de aplicación":
   - Para Android: Agrega el nombre del paquete: `com.example.sanchez_pharma`
   - Para iOS: Agrega el ID del bundle (puedes encontrarlo en Xcode)
3. En "Restricciones de API": Selecciona solo las APIs que habilitaste
4. Haz clic en "GUARDAR"

## 🔧 Configurar la API Key en tu Proyecto

### Para Android:

1. Abre el archivo: `android/app/src/main/AndroidManifest.xml`
2. Busca esta línea (alrededor de la línea 40):
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="TU_API_KEY_DE_GOOGLE_MAPS_AQUI"/>
   ```
3. Reemplaza `TU_API_KEY_DE_GOOGLE_MAPS_AQUI` con tu API Key real
4. Debería quedar así:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"/>
   ```

### Para iOS:

1. Abre el archivo: `ios/Runner/AppDelegate.swift`
2. Busca esta línea (alrededor de la línea 12):
   ```swift
   GMSServices.provideAPIKey("TU_API_KEY_DE_GOOGLE_MAPS_AQUI")
   ```
3. Reemplaza `TU_API_KEY_DE_GOOGLE_MAPS_AQUI` con tu API Key real
4. Debería quedar así:
   ```swift
   GMSServices.provideAPIKey("AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
   ```

### Para Flutter Web (⚠️ IMPORTANTE si ejecutas en navegador):

1. Abre el archivo: `web/index.html`
2. Busca la sección `<head>` y agrega esta línea ANTES de `</head>`:
   ```html
   <!-- Google Maps JavaScript API para Flutter Web -->
   <script src="https://maps.googleapis.com/maps/api/js?key=TU_API_KEY_AQUI&libraries=places"></script>
   ```
3. Reemplaza `TU_API_KEY_AQUI` con tu API Key real
4. Debería quedar así:
   ```html
   <!-- Google Maps JavaScript API para Flutter Web -->
   <script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx&libraries=places"></script>
   ```
   
   ⚠️ **NOTA**: Asegúrate de que la API **Maps JavaScript API** esté habilitada en Google Cloud Console (no solo las SDKs para Android/iOS)

## ✅ Verificar la Configuración

Después de configurar la API Key:

1. **Limpia el proyecto:**
   ```bash
   flutter clean
   ```

2. **Obtén las dependencias:**
   ```bash
   flutter pub get
   ```

3. **Ejecuta la aplicación:**
   ```bash
   flutter run
   ```

## 🐛 Solución de Problemas

### Error: "Cannot read properties of undefined (reading 'maps')"
- ✅ Verifica que la API Key esté correctamente configurada en ambos archivos
- ✅ Asegúrate de que las APIs estén habilitadas en Google Cloud Console
- ✅ Verifica que no haya espacios extra en la API Key

### Error: "API key not valid"
- ✅ Verifica que la API Key sea correcta
- ✅ Asegúrate de que las APIs estén habilitadas
- ✅ Verifica que la API Key no tenga restricciones que bloqueen tu aplicación

### El mapa no se muestra
- ✅ Verifica tu conexión a internet
- ✅ Asegúrate de que los permisos de ubicación estén habilitados
- ✅ Revisa los logs de la consola para ver errores específicos

## 💰 Costos

Google Maps tiene un plan gratuito generoso:
- **$200 USD de crédito mensual gratuito**
- Esto cubre aproximadamente:
  - 28,000 cargas de mapas
  - 40,000 solicitudes de geocodificación
  - 2,500 solicitudes de direcciones

Para la mayoría de aplicaciones pequeñas/medianas, esto es suficiente.

## 📞 Soporte

Si sigues teniendo problemas:
1. Revisa los logs de la aplicación
2. Verifica la documentación oficial: https://pub.dev/packages/google_maps_flutter
3. Asegúrate de que tu API Key esté activa en Google Cloud Console

