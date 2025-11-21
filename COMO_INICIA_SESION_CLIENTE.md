# 🔐 Cómo Inicia Sesión el Cliente

## 📱 Proceso Actual (Frontend)

El cliente usa **la misma pantalla de login** que los usuarios internos, pero el sistema detecta automáticamente el tipo de usuario y lo redirige a la pantalla correcta.

### Pasos del Cliente:

1. **Abrir la aplicación** → Se muestra la pantalla de login
2. **Ingresar credenciales**:
   - **Usuario**: Puede ser:
     - Email del cliente
     - Número de documento (DNI, RUC, etc.)
   - **Contraseña**: La contraseña asignada al cliente
3. **Presionar "Ingresar"**
4. **El sistema detecta** que es cliente y lo redirige automáticamente a la **Tienda**

## 🔄 Flujo Técnico

```
Cliente ingresa credenciales
         ↓
Frontend envía POST a /api_login
         ↓
Backend verifica en tabla 'clientes'
         ↓
Si es válido → Retorna user_type: "cliente"
         ↓
Frontend guarda tipo y redirige a TiendaScreen
```

## ⚙️ Configuración Necesaria en el Backend

### 1. Modificar el Endpoint `/api_login`

El backend debe modificar la función `api_login()` para:

1. **Primero intentar** autenticar como usuario interno (tabla `usuarios`)
2. **Si falla**, intentar autenticar como cliente (tabla `clientes`)
3. **Retornar** el `user_type` correspondiente

### 2. Estructura de la Tabla `clientes`

**⚠️ IMPORTANTE**: La tabla `clientes` actual NO tiene campo `password`. Necesitas agregarlo:

```sql
-- Agregar campo password a la tabla clientes
ALTER TABLE clientes 
ADD COLUMN password VARCHAR(255) AFTER email;
```

La tabla `clientes` debe tener estos campos para autenticación:

```sql
- id (INT, PRIMARY KEY)
- nombre (VARCHAR)
- email (VARCHAR) -- Para login
- password (VARCHAR) -- ⚠️ AGREGAR ESTE CAMPO
- documento (VARCHAR) -- DNI/RUC, también para login
- estado (ENUM) -- 'activo' o 'inactivo'
```

### 3. Código del Backend (Python/Flask)

```python
@app.route('/api_login', methods=['POST'])
def api_login():
    try:
        data = request.json
        username = data.get("username")
        password = data.get("password")

        # PASO 1: Intentar autenticar como usuario interno
        user = authenticate(username, password)  # Función existente
        
        if user:
            # Es usuario interno
            token = jwt.jwt_encode_callback(user)
            return jsonify({
                "code": 1,
                "message": "Inicio de sesión exitoso",
                "token": token.decode('utf-8') if hasattr(token, 'decode') else token,
                "user_type": "usuario",
                "user": {"id": user.id, "username": user.username}
            })
        
        # PASO 2: Si no es usuario interno, intentar como cliente
        conn = obtenerconexion_sanchezpharma()
        cliente = None
        with conn:
            with conn.cursor() as cursor:
                # Buscar cliente por email o documento
                sql = """
                    SELECT id, nombre, email, documento, telefono 
                    FROM clientes 
                    WHERE (email = %s OR documento = %s) 
                    AND password = %s 
                    AND estado = 'activo'
                """
                cursor.execute(sql, (username, username, password))
                cliente = cursor.fetchone()
        
        if cliente:
            # Es cliente - crear token JWT
            # Necesitas crear un objeto similar a User para el token
            cliente_user = UserSanchezPharma(
                cliente["id"], 
                cliente["email"] or cliente["documento"], 
                password
            )
            token = jwt.jwt_encode_callback(cliente_user)
            
            return jsonify({
                "code": 1,
                "message": "Inicio de sesión exitoso",
                "token": token.decode('utf-8') if hasattr(token, 'decode') else token,
                "user_type": "cliente",
                "cliente_id": cliente["id"],
                "user": {
                    "id": cliente["id"], 
                    "username": cliente["email"] or cliente["documento"]
                }
            })
        
        # Si no es ni usuario ni cliente
        return jsonify({"code": 0, "message": "Credenciales incorrectas"}), 401

    except Exception as e:
        return jsonify({"code": 0, "message": repr(e)})
```

## 📋 Credenciales del Cliente

### Opciones de Login:

El cliente puede iniciar sesión usando:

1. **Email** (si tiene email registrado)
   - Ejemplo: `cliente@example.com`
   
2. **Número de Documento** (DNI, RUC, etc.)
   - Ejemplo: `12345678`

### Contraseña:

- ⚠️ **La contraseña debe agregarse a la tabla `clientes`** (ver sección anterior)
- Puede ser texto plano o hash (según tu implementación de seguridad)
- **Recomendación**: Asignar una contraseña temporal cuando se crea el cliente, y permitir que el cliente la cambie después

## 🔒 Seguridad Recomendada

### 1. Hash de Contraseñas

**IMPORTANTE**: No almacenes contraseñas en texto plano. Usa hash:

```python
import hashlib

# Al crear/actualizar cliente
password_hash = hashlib.sha256(password.encode()).hexdigest()

# Al verificar login
password_hash = hashlib.sha256(password.encode()).hexdigest()
sql = "SELECT ... WHERE password = %s"
cursor.execute(sql, (password_hash,))
```

### 2. Validación de Estado

Solo permitir login a clientes con `estado = 'activo'`

### 3. Rate Limiting

Implementar límite de intentos de login para prevenir ataques de fuerza bruta

## 🎯 Ejemplo de Uso

### Cliente Nuevo:

1. **Agregar campo password a la tabla** (si no existe):
   ```sql
   ALTER TABLE clientes ADD COLUMN password VARCHAR(255);
   ```

2. El cliente se registra o es registrado por un vendedor
3. Se le asigna:
   - Email: `juan.perez@email.com`
   - Documento: `12345678`
   - Contraseña: `miPassword123` (o hash de la contraseña)
4. El cliente puede iniciar sesión con:
   - Usuario: `juan.perez@email.com` o `12345678`
   - Contraseña: `miPassword123`
5. El sistema lo redirige automáticamente a la tienda

### Crear Cliente de Prueba:

```sql
-- Insertar cliente con contraseña
INSERT INTO clientes (nombre, email, documento, password, estado)
VALUES ('Cliente Test', 'test@example.com', '12345678', 'password123', 'activo');

-- O si usas hash:
INSERT INTO clientes (nombre, email, documento, password, estado)
VALUES ('Cliente Test', 'test@example.com', '12345678', SHA2('password123', 256), 'activo');
```

## ✅ Verificación

Para verificar que funciona:

1. **Crear un cliente de prueba** en la base de datos:
   ```sql
   INSERT INTO clientes (nombre, email, documento, password, estado)
   VALUES ('Cliente Test', 'test@example.com', '12345678', 'password123', 'activo');
   ```

2. **Intentar login** desde la app con:
   - Usuario: `test@example.com` o `12345678`
   - Contraseña: `password123`

3. **Verificar** que:
   - ✅ Se redirige a la TiendaScreen
   - ✅ No muestra el Dashboard administrativo
   - ✅ Puede ver productos y agregar al carrito

## 🚨 Problemas Comunes

### Error: "Credenciales incorrectas"
- Verificar que el cliente existe en la tabla `clientes`
- Verificar que el `estado` es `'activo'`
- Verificar que la contraseña coincide (considerar hash si aplica)

### Error: Se redirige al Dashboard en lugar de la Tienda
- Verificar que el backend retorna `user_type: "cliente"`
- Verificar que el frontend está leyendo correctamente el `userType`

### Error: No se guarda el cliente_id
- Verificar que el backend retorna `cliente_id` en la respuesta
- Verificar que `SharedPrefsHelper.saveAuthData()` recibe el `clienteId`

