# 🔧 DEBUG: Vendedor No Ve Envíos

## ✅ Cambios Aplicados

He agregado **LOGS SUPER DETALLADOS** en 3 lugares clave:
1. **Login** - Para ver qué rol devuelve el backend
2. **CustomDrawer** - Para ver qué rol tiene al construir el menú
3. **EnviosScreen** - Para ver si puede asignar repartidores

---

## 🚀 PASOS PARA PROBAR (EN ORDEN)

### **📍 Paso 1: Reiniciar el Backend**

```bash
# En la terminal donde corre Python:
Ctrl+C  (detener)

# Luego reiniciar:
python rutas.txt
```

**✅ Verificar:** Debe decir `Running on http://...`

---

### **📍 Paso 2: Hot Restart Flutter**

En la terminal donde corre Flutter, presiona:

```
R  (letra R mayúscula - Full Restart)
```

**NO** hagas `r` minúscula (hot reload), debe ser **`R` mayúscula** (full restart).

**✅ Verificar:** La app se reiniciará completamente.

---

### **📍 Paso 3: CERRAR SESIÓN en la App**

**IMPORTANTE:** Debes hacer logout para que se guarden los nuevos datos.

1. Abrir menú lateral (☰)
2. Scroll hasta abajo
3. Click en **"Cerrar Sesión"**

**✅ Verificar:** Debes volver a la pantalla de login.

---

### **📍 Paso 4: Login con Arny (Vendedor)**

```
Usuario: Arny
Contraseña: 1234
```

**✅ AHORA BUSCA EN LA CONSOLA ESTOS LOGS:**

```
═══════════════════════════════════════════════════
✅ LOGIN EXITOSO - Usuario Interno
═══════════════════════════════════════════════════
📋 Datos del usuario:
   - ID: 8
   - Username: Arny
   - Rol ID: 3  ← ✅ DEBE SER 3 (Vendedor)
   - User Type: usuario
═══════════════════════════════════════════════════
💾 Guardando en SharedPreferences:
   - Rol ID a guardar: 3
✅ Datos guardados correctamente
═══════════════════════════════════════════════════
```

**🔍 SI VES "Rol ID: ❌ NULL"**
→ Significa que el backend NO está devolviendo el rol.
→ Verifica que `rutas.txt` esté actualizado y reiniciado.

---

### **📍 Paso 5: Verificar el Dashboard**

Después del login, la app abre el Dashboard. **Busca en consola:**

```
📊 Dashboard - Datos cargados:
   - Username: Arny
   - Rol ID: 3  ← ✅ DEBE SER 3
```

---

### **📍 Paso 6: Abrir el Menú Lateral**

Click en el ícono de menú (☰) y **busca en consola:**

```
═══════════════════════════════════════════════════
🎨 CustomDrawer construido para: Arny
   📍 Rol ID recibido: 3  ← ✅ DEBE SER 3
   📍 Rol Efectivo: 3 (Vendedor)
   📍 Puede ver Envíos: true  ← ✅ DEBE SER TRUE
   📍 Puede ver Ventas: true
═══════════════════════════════════════════════════
```

**🔍 SI VES "Puede ver Envíos: false"**
→ Hay un problema con `RoleConstants.tieneAccesoAEnvios()`

**🔍 SI VES "Rol ID recibido: NULL"**
→ El Dashboard no está pasando el rol al drawer correctamente

---

### **📍 Paso 7: Verificar Menú Visual**

El menú lateral de Arny (vendedor) DEBE mostrar:

```
┌─────────────────────────────────┐
│  👤 Arny                        │
│  🟠 Vendedor                    │
│  Sánchez Pharma                 │
├─────────────────────────────────┤
│  📊 Dashboard                   │
├─────────────────────────────────┤
│  🛒 Ventas  ▼                   │
│    └─ Registrar Venta           │
│    └─ Clientes                  │
│                                 │
│  🚚 Seguimiento de Envíos       │  ← ✅ DEBE APARECER
├─────────────────────────────────┤
│  ⚙️ Configuración               │
│  ℹ️ Acerca de                   │
├─────────────────────────────────┤
│  🚪 Cerrar Sesión               │
└─────────────────────────────────┘
```

**❌ Si NO aparece "Seguimiento de Envíos":**
→ Revisa los logs del paso 6

---

### **📍 Paso 8: Ir a Envíos**

Click en **"Seguimiento de Envíos"** y **busca en consola:**

```
🔐 EnviosScreen - Rol ID cargado: 3
✅ Rol ID es 3
✅ Es Admin: false
✅ Es Vendedor: true  ← ✅ DEBE SER TRUE
✅ Puede asignar repartidor: true  ← ✅ DEBE SER TRUE
```

---

### **📍 Paso 9: Verificar Botón "Asignar Repartidor"**

Si hay envíos, **busca en consola** por cada envío:

```
🔍 Envío 1:
   - puedeAsignar: true (rolId: 3)  ← ✅ TRUE
   - estadoCorrecto: true (estado: pendiente)  ← ✅ TRUE
   - sinRepartidor: true (repartidor: null)  ← ✅ TRUE
   - MOSTRAR BOTÓN: true  ← ✅ DEBE SER TRUE
```

**✅ Si todo es `true` → El botón DEBE aparecer**

---

## 📊 Verificar Base de Datos (MySQL)

### **Verificar Rol de Arny:**

```sql
SELECT id, username, nombre, apellido, rol_id 
FROM usuarios 
WHERE username = 'Arny';
```

**✅ Resultado esperado:**
```
+----+----------+-------+----------+--------+
| id | username | nombre| apellido | rol_id |
+----+----------+-------+----------+--------+
|  8 | Arny     | arny  | pizarro  |      3 |
+----+----------+-------+----------+--------+
```

**❌ Si `rol_id` es NULL o diferente de 3:**
```sql
UPDATE usuarios SET rol_id = 3 WHERE username = 'Arny';
```

---

### **Verificar Que Hay Envíos:**

```sql
SELECT e.id, e.numero_seguimiento, e.estado, e.conductor_repartidor
FROM envios e
WHERE e.estado IN ('pendiente', 'preparando')
LIMIT 5;
```

**✅ Si hay envíos → El botón debe aparecer**

**❌ Si NO hay envíos → Crear uno de prueba:**

```sql
-- Primero, verifica que haya ventas
SELECT id, numero_venta, total FROM ventas ORDER BY id DESC LIMIT 1;

-- Si hay ventas, crear un envío de prueba
INSERT INTO envios (
  venta_id, 
  numero_seguimiento, 
  direccion_entrega, 
  telefono_contacto, 
  nombre_destinatario, 
  estado,
  fecha_creacion
) VALUES (
  (SELECT id FROM ventas ORDER BY id DESC LIMIT 1),
  CONCAT('ENV-TEST-', UNIX_TIMESTAMP()),
  'Calle Test 123, Lima',
  '987654321',
  'Cliente Test',
  'pendiente',
  NOW()
);
```

---

## 🎯 Checklist Final

- [ ] Backend reiniciado (`python rutas.txt`)
- [ ] Flutter con Hot Restart (`R` mayúscula)
- [ ] Logout en la app
- [ ] Login con Arny
- [ ] Logs muestran: `Rol ID: 3` ✅
- [ ] Logs muestran: `Puede ver Envíos: true` ✅
- [ ] Menú muestra "Seguimiento de Envíos" ✅
- [ ] Logs muestran: `Puede asignar repartidor: true` ✅
- [ ] Logs muestran: `MOSTRAR BOTÓN: true` ✅
- [ ] Botón "Asignar Repartidor" aparece ✅

---

## 📸 Si Sigue Sin Funcionar

**COPIA Y PEGA AQUÍ:**

1. **TODOS los logs desde el login hasta los envíos**
2. **Resultado de:** `SELECT * FROM usuarios WHERE username = 'Arny';`
3. **Screenshot del menú lateral**
4. **Screenshot de la pantalla de envíos**

---

## 🔥 Solución Rápida

```bash
# 1. Backend
python rutas.txt

# 2. Flutter (en otra terminal)
R

# 3. En la app
Logout → Login (Arny/1234)

# 4. Verificar logs en consola
```

✅ **Con estos logs detallados, podré identificar EXACTAMENTE dónde está el problema.** 🎯

