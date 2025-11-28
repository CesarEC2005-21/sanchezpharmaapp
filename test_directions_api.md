# Guía para Habilitar Google Directions API

## Problema
Si ves una línea recta en lugar de una ruta que sigue las calles, es porque la **Google Directions API no está habilitada** en tu proyecto de Google Cloud.

## Solución

### Paso 1: Ir a Google Cloud Console
1. Ve a https://console.cloud.google.com/
2. Selecciona tu proyecto (o crea uno nuevo)

### Paso 2: Habilitar Directions API
1. En el menú lateral, ve a **"APIs & Services"** > **"Library"**
2. Busca **"Directions API"**
3. Haz clic en **"Enable"** (Habilitar)

### Paso 3: Verificar la API Key
1. Ve a **"APIs & Services"** > **"Credentials"**
2. Busca tu API key: `AIzaSyAF5En1vgFxedwFiErCGL-FADIBCrpcOMc`
3. Asegúrate de que tenga habilitadas estas APIs:
   - **Maps SDK for Android** (ya debería estar)
   - **Directions API** (esta es la que falta)
   - **Geocoding API** (opcional, pero recomendado)

### Paso 4: Verificar Restricciones
1. En la misma página de Credentials, haz clic en tu API key
2. Verifica las **"API restrictions"**:
   - Debe tener **"Directions API"** en la lista
   - O puede estar sin restricciones (para desarrollo)

### Paso 5: Probar la API
Puedes probar la API directamente en el navegador:
```
https://maps.googleapis.com/maps/api/directions/json?origin=-6.7744,-79.8414&destination=-6.7844,-79.8514&key=AIzaSyAF5En1vgFxedwFiErCGL-FADIBCrpcOMc&mode=driving
```

Si funciona, deberías ver un JSON con información de la ruta.

## Paso Adicional: Habilitar la API en el Proyecto

**IMPORTANTE:** Tener la API en la lista de la clave NO es suficiente. También debes habilitarla en el proyecto:

1. Ve a **"APIs & Services"** > **"Library"** (no "Credentials")
2. Busca **"Directions API"**
3. Si dice **"Enable"**, haz clic para habilitarla
4. Si ya dice **"Manage"**, entonces ya está habilitada

## Verificación en la App

Cuando ejecutes la app, revisa los logs en la consola. Deberías ver:

✅ **Si funciona correctamente:**
- `✅ Respuesta OK, procesando ruta...`
- `Pasos encontrados: X` (donde X > 0)
- `📍 Procesando X pasos de la ruta...`
- `✅ Total de puntos de steps: X` (donde X > 10)
- `✅ Ruta obtenida: X puntos` (donde X > 10)
- `✅ Ruta dibujada correctamente con X puntos`

❌ **Si hay problemas:**
- `⚠️ Error en la respuesta de Directions API: REQUEST_DENIED`
- `⚠️ Mensaje de error de API: This API project is not authorized to use this API`
- `❌ ERROR: No se obtuvieron puntos de ruta`
- `⚠️ No se obtuvieron puntos de steps, usando overview_polyline como fallback` (esto puede causar línea recta)

## Costos

La Directions API tiene un plan gratuito:
- **$200 USD de crédito gratis por mes** (equivalente a ~40,000 solicitudes)
- Después de eso, $5 USD por cada 1,000 solicitudes adicionales

Para una app pequeña, el plan gratuito debería ser suficiente.

