# 🔍 Diagnóstico: Asignación de Repartidores

## ✅ Cambios Realizados

He mejorado el código para tener mejor logging y control de permisos:

1. **Agregado verificación de permisos en el menú popup (⋮)**
2. **Agregado logs detallados para diagnosticar el problema**
3. **Mejorado mensajes de error**

## 🧪 Pasos para Diagnosticar el Problema

### 1. Verificar que existan Repartidores en la Base de Datos

Ejecuta esta consulta SQL en tu base de datos:

```sql
-- Verificar si hay usuarios con rol de repartidor (rol_id = 4)
SELECT id, username, email, nombre, apellido, rol_id 
FROM usuarios 
WHERE rol_id = 4;
```

**Resultado esperado:** Debe haber AL MENOS 1 usuario con `rol_id = 4`

**Si NO hay resultados:**
- Debes crear al menos un usuario repartidor
- Ejecuta este SQL para crear uno de prueba:

```sql
INSERT INTO usuarios (username, password, email, nombre, apellido, edad, sexo, rol_id)
VALUES ('repartidor1', '123456', 'repartidor1@test.com', 'Juan', 'Pérez', 25, 'M', 4);
```

### 2. Verificar que el Usuario Vendedor tenga el Rol Correcto

Ejecuta esta consulta SQL:

```sql
-- Verificar el rol del usuario vendedor
SELECT id, username, email, nombre, apellido, rol_id 
FROM usuarios 
WHERE rol_id = 3;  -- 3 = Vendedor
```

**Resultado esperado:** Debes ver tu usuario de vendedor con `rol_id = 3`

**Si tu usuario no tiene rol_id = 3:**
```sql
-- Actualizar el rol de tu usuario (reemplaza 'tu_username' con tu nombre de usuario)
UPDATE usuarios 
SET rol_id = 3 
WHERE username = 'tu_username';
```

### 3. Verificar Roles en el Sistema

```sql
-- Ver todos los roles disponibles
SELECT * FROM roles;
```

**Resultado esperado:**
```
id | nombre        | descripcion
1  | Administrador | Acceso total
3  | Vendedor      | Gestión de ventas
4  | Repartidor    | Gestión de entregas
5  | Almacén       | Gestión de inventario
```

### 4. Verificar Envíos sin Repartidor Asignado

```sql
-- Ver envíos que pueden tener repartidor asignado
SELECT id, numero_seguimiento, estado, conductor_repartidor
FROM envios
WHERE estado IN ('pendiente', 'preparando')
  AND (conductor_repartidor IS NULL OR conductor_repartidor = '');
```

**Resultado esperado:** Debe haber envíos en estado `pendiente` o `preparando` sin repartidor asignado.

## 📱 Verificar en la Aplicación

### 5. Revisar los Logs de la Aplicación

Cuando ejecutes la app y entres a la pantalla de Envíos, deberías ver estos logs:

```
🔐 EnviosScreen - Rol ID cargado: 3
✅ Rol ID es 3
✅ Es Admin: false
✅ Es Vendedor: true
✅ Puede asignar repartidor: true
🔄 Cargando repartidores...
📡 Respuesta del servidor: 200
📦 Data recibida: {...}
✅ Repartidores cargados: X
   - Juan Pérez (repartidor1@test.com)
```

### 6. Verificar que el Botón "Asignar Repartidor" Aparece

El botón azul "Asignar Repartidor" **SOLO** aparece cuando:

✅ El usuario es **Administrador** (rol_id = 1) o **Vendedor** (rol_id = 3)  
✅ El envío está en estado **"pendiente"** o **"preparando"**  
✅ El envío **NO** tiene repartidor asignado  

## 🐛 Problemas Comunes y Soluciones

### Problema 1: "No hay repartidores disponibles"

**Causa:** No hay usuarios con `rol_id = 4` en la base de datos.

**Solución:**
```sql
-- Crear un repartidor de prueba
INSERT INTO usuarios (username, password, email, nombre, apellido, edad, sexo, rol_id)
VALUES ('repartidor1', '123456', 'repartidor1@test.com', 'Juan', 'Pérez', 25, 'M', 4);
```

### Problema 2: "El botón no aparece"

**Posibles causas:**
1. Tu usuario no tiene `rol_id = 3` (vendedor) o `rol_id = 1` (admin)
2. El envío ya tiene repartidor asignado
3. El envío está en estado "en_camino", "entregado" o "cancelado"

**Solución:**
```sql
-- Verificar tu rol
SELECT username, rol_id FROM usuarios WHERE username = 'tu_username';

-- Si es necesario, actualizar tu rol a vendedor
UPDATE usuarios SET rol_id = 3 WHERE username = 'tu_username';
```

### Problema 3: "Error al cargar repartidores"

**Causa:** Problema de conexión con el backend o token JWT expirado.

**Solución:**
1. Cierra sesión en la app
2. Vuelve a iniciar sesión
3. Verifica que el backend esté corriendo en: https://nxlsxx.pythonanywhere.com

### Problema 4: "Error al asignar repartidor"

**Causa:** El campo `conductor_repartidor` en la tabla `envios` es demasiado pequeño.

**Solución:**
```sql
-- Verificar el tamaño del campo
DESCRIBE envios;

-- Si es necesario, aumentar el tamaño
ALTER TABLE envios 
MODIFY COLUMN conductor_repartidor VARCHAR(255);
```

## 🎯 Flujo Completo de Asignación

1. **Usuario Vendedor** inicia sesión
2. Va a "Envíos" en el menú
3. Ve un envío en estado "Pendiente" sin repartidor
4. Hace clic en el botón azul **"Asignar Repartidor"**
5. Se abre un diálogo con la lista de repartidores
6. Selecciona un repartidor
7. El sistema actualiza el envío
8. Aparece un mensaje verde: "Repartidor asignado: [Nombre]"
9. El nombre del repartidor aparece en la tarjeta del envío con ícono verde 🧑

## 📞 Si el Problema Persiste

Si después de seguir todos estos pasos el problema continúa, copia y pega:

1. Los logs de la consola de la app
2. El resultado de la consulta SQL de repartidores
3. El resultado de la consulta SQL de tu usuario
4. Una captura de pantalla de la pantalla de Envíos

Y con eso podremos identificar exactamente qué está fallando.

