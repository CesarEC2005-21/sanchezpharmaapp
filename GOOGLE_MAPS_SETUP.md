# Configuración de Google Maps para Seguimiento de Envíos

## Pasos para configurar Google Maps

### 1. Obtener API Key de Google Maps

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita las siguientes APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API
   - Directions API (opcional, para rutas)
4. Ve a "Credenciales" y crea una nueva API Key
5. Restringe la API Key para mayor seguridad (recomendado)

### 2. Configurar Android

✅ **YA CONFIGURADO** - Solo necesitas agregar tu API Key

1. Abre `android/app/src/main/AndroidManifest.xml`
2. Busca la línea que dice `android:value="TU_API_KEY_DE_GOOGLE_MAPS_AQUI"`
3. Reemplaza `TU_API_KEY_DE_GOOGLE_MAPS_AQUI` con tu API Key real

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_DE_GOOGLE_MAPS_AQUI"/>
```

✅ **Permisos ya configurados** en `AndroidManifest.xml`

### 3. Configurar iOS

✅ **YA CONFIGURADO** - Solo necesitas agregar tu API Key

1. Abre `ios/Runner/AppDelegate.swift`
2. Busca la línea que dice `GMSServices.provideAPIKey("TU_API_KEY_DE_GOOGLE_MAPS_AQUI")`
3. Reemplaza `TU_API_KEY_DE_GOOGLE_MAPS_AQUI` con tu API Key real

```swift
import GoogleMaps

// En application(_:didFinishLaunchingWithOptions:)
GMSServices.provideAPIKey("TU_API_KEY_DE_GOOGLE_MAPS_AQUI")
```

✅ **Permisos ya configurados** en `ios/Runner/Info.plist`

### 5. Instalar dependencias

```bash
flutter pub get
```

### 6. Ejecutar la aplicación

```bash
flutter run
```

## Notas Importantes

- **En producción**: La ubicación del repartidor debe venir del backend en tiempo real
- **Geocodificación**: Actualmente se usa la dirección para obtener coordenadas, pero es mejor almacenar lat/lng en la base de datos
- **Actualizaciones en tiempo real**: El mapa se actualiza cada 5 segundos cuando el envío está "en_camino"
- **Simulación**: Actualmente se simula el movimiento del repartidor. En producción, esto debe conectarse con un sistema de tracking GPS real

## Mejoras Futuras

1. Integrar con backend para obtener ubicación real del repartidor
2. Agregar rutas optimizadas usando Directions API
3. Notificaciones push cuando el repartidor está cerca
4. Historial de ruta recorrida
5. Tiempo estimado de llegada basado en tráfico

