# Cómo Funciona el Seguimiento de Envíos

## 📍 Sistema Actual

### 1. **Cuando se registra una venta con envío a domicilio:**

Actualmente, el sistema:
- Guarda la dirección de texto (ej: "Av. Principal 123, Lima")
- El backend crea automáticamente un registro en la tabla `envios`

### 2. **Cuando se visualiza el seguimiento:**

El sistema hace lo siguiente:
1. **Obtiene la dirección de texto** del envío
2. **Geocodifica la dirección** (convierte texto a coordenadas GPS usando Google Geocoding API)
3. **Muestra el mapa** con el destino

**Problema:** La geocodificación puede ser imprecisa, especialmente con direcciones ambiguas o incompletas.

---

## ✅ Mejora Propuesta (Implementada)

### 1. **Base de Datos Actualizada:**

Se agregaron campos a la tabla `envios`:
- `latitud_destino` - Coordenada GPS del destino
- `longitud_destino` - Coordenada GPS del destino
- `latitud_repartidor` - Coordenada GPS actual del repartidor (se actualiza en tiempo real)
- `longitud_repartidor` - Coordenada GPS actual del repartidor (se actualiza en tiempo real)

### 2. **Cómo Funciona Ahora:**

1. **Si hay coordenadas almacenadas:**
   - ✅ Usa las coordenadas directamente (más preciso)
   - ✅ No necesita geocodificar

2. **Si NO hay coordenadas (compatibilidad con datos antiguos):**
   - ⚠️ Hace geocodificación como fallback
   - ⚠️ Menos preciso pero funciona

---

## 🚀 Cómo Capturar Coordenadas al Registrar Envío

### Opción 1: Seleccionar en Mapa (Recomendado)

Cuando el usuario registra una venta con envío a domicilio:

1. Mostrar un mapa interactivo
2. El usuario hace clic en el mapa para seleccionar la ubicación exacta
3. Se guardan las coordenadas (latitud/longitud) en la base de datos

### Opción 2: Usar GPS del Cliente

Si el cliente está registrando su propia dirección:

1. Pedir permiso para acceder a la ubicación GPS
2. Obtener coordenadas automáticamente
3. Guardar en la base de datos

### Opción 3: Mejorar Geocodificación

1. Al geocodificar, guardar las coordenadas obtenidas
2. Actualizar el registro del envío con las coordenadas
3. Próximas veces usar las coordenadas guardadas

---

## 📝 Pasos para Implementar Captura de Coordenadas

### 1. Ejecutar el script SQL:

```sql
-- Ejecutar: actualizar_envios_coordenadas.sql
```

### 2. Actualizar el Backend:

Modificar la ruta de registro de ventas para:
- Aceptar `latitud_destino` y `longitud_destino` cuando se registra un envío
- Guardar estas coordenadas en la tabla `envios`

### 3. Actualizar la Pantalla de Ventas:

Agregar un botón "Seleccionar Ubicación en Mapa" cuando:
- Tipo de venta = "envio_domicilio"
- Mostrar mapa para que el usuario seleccione el punto exacto
- Guardar coordenadas junto con la dirección

---

## 🎯 Flujo Ideal Completo

1. **Cliente/Vendedor registra venta con envío:**
   - Ingresa dirección de texto
   - Selecciona ubicación exacta en mapa (o usa GPS)
   - Se guardan coordenadas GPS precisas

2. **Sistema crea envío:**
   - Guarda dirección de texto (para referencia)
   - Guarda coordenadas GPS (para mapa preciso)

3. **Repartidor inicia envío:**
   - Su ubicación GPS se actualiza en tiempo real
   - Se guarda en `latitud_repartidor` y `longitud_repartidor`

4. **Cliente/Admin ve seguimiento:**
   - Mapa muestra ubicación exacta del repartidor
   - Mapa muestra ubicación exacta del destino
   - Ruta calculada con precisión

---

## 💡 Ventajas de Usar Coordenadas GPS

✅ **Precisión:** Ubicación exacta, no aproximada  
✅ **Rutas:** Cálculo de rutas más preciso  
✅ **Tiempo Real:** Seguimiento preciso del repartidor  
✅ **Distancia:** Cálculo de distancia más exacto  
✅ **Experiencia:** Mejor experiencia de usuario

---

## ⚠️ Nota Importante

El código actual ya está preparado para usar coordenadas si están disponibles. Solo necesitas:

1. Ejecutar el script SQL para agregar los campos
2. Modificar el backend para aceptar y guardar coordenadas
3. Agregar captura de coordenadas en la pantalla de ventas

El sistema funcionará con datos antiguos (sin coordenadas) usando geocodificación como fallback.

