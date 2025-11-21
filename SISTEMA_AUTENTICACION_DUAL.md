# Sistema de Autenticación Dual - Clientes vs Usuarios Internos

## 📋 Resumen

Se ha implementado un sistema de autenticación dual que distingue entre:
- **Clientes**: Acceden a la tienda, pueden comprar productos
- **Usuarios Internos**: Acceden al panel administrativo (admin, vendedor, repartidor, almacén)

## ✅ Implementación Completada (Frontend)

### 1. Modelos de Datos
- ✅ `LoginResponse` actualizado para incluir `userType` y `clienteId`
- ✅ `SharedPrefsHelper` actualizado para guardar y recuperar el tipo de usuario

### 2. Pantallas Creadas
- ✅ **TiendaScreen** (`lib/presentation/screens/tienda_screen.dart`)
  - Muestra productos disponibles
  - Búsqueda y filtrado por categoría
  - Agregar productos al carrito
  - Contador de items en carrito
  - Logout

- ✅ **CarritoScreen** (`lib/presentation/screens/carrito_screen.dart`)
  - Ver productos en el carrito
  - Modificar cantidades
  - Eliminar productos
  - Proceder al pago

- ✅ **PagoScreen** (`lib/presentation/screens/pago_screen.dart`)
  - Resumen del pedido
  - Selección de tipo de entrega (recojo/envío)
  - Datos de envío (si aplica)
  - Selección de método de pago
  - Confirmar compra

### 3. Flujo de Autenticación
- ✅ `LoginScreen` detecta el tipo de usuario y redirige:
  - Clientes → `TiendaScreen`
  - Usuarios internos → `DashboardScreen`
- ✅ `main.dart` actualizado para redirigir según tipo de usuario al iniciar

### 4. Persistencia del Carrito
- ✅ El carrito se guarda en `SharedPreferences` con la clave `carrito_cliente`
- ✅ Formato simple: `id:nombre:precio:cantidad:stock|id:nombre:precio:cantidad:stock`

## ⚠️ Pendiente en el Backend

### Modificación del Endpoint de Login

El endpoint `/api_login` debe modificarse para:

1. **Detectar si el usuario es cliente o usuario interno**
2. **Retornar el tipo de usuario en la respuesta**

#### Ejemplo de respuesta esperada:

**Para Cliente:**
```json
{
  "code": 1,
  "message": "Inicio de sesión exitoso",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user_type": "cliente",
  "cliente_id": 123,
  "user": {
    "id": 123,
    "username": "cliente@example.com"
  }
}
```

**Para Usuario Interno:**
```json
{
  "code": 1,
  "message": "Inicio de sesión exitoso",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user_type": "usuario",
  "user": {
    "id": 1,
    "username": "admin"
  }
}
```

#### Pseudocódigo para el Backend:

```python
@app.route('/api_login', methods=['POST'])
def api_login():
    data = request.json
    username = data.get("username")
    password = data.get("password")

    # Intentar autenticar como usuario interno primero
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
    
    # Si no es usuario interno, intentar como cliente
    conn = obtenerconexion_sanchezpharma()
    with conn:
        with conn.cursor() as cursor:
            # Asumiendo que clientes tienen email/username y password
            sql = "SELECT id, nombre, email FROM clientes WHERE (email = %s OR documento = %s) AND password = %s AND estado = 'activo'"
            cursor.execute(sql, (username, username, password))
            cliente = cursor.fetchone()
    
    if cliente:
        # Es cliente
        # Crear un objeto similar a User para el token
        cliente_user = UserSanchezPharma(cliente["id"], cliente["email"] or cliente["nombre"], password)
        token = jwt.jwt_encode_callback(cliente_user)
        return jsonify({
            "code": 1,
            "message": "Inicio de sesión exitoso",
            "token": token.decode('utf-8') if hasattr(token, 'decode') else token,
            "user_type": "cliente",
            "cliente_id": cliente["id"],
            "user": {"id": cliente["id"], "username": cliente["email"] or cliente["nombre"]}
        })
    
    return jsonify({"code": 0, "message": "Credenciales incorrectas"}), 401
```

## 🔄 Flujo Completo

### Para Clientes:
1. Cliente inicia sesión con sus credenciales
2. Backend detecta que es cliente y retorna `user_type: "cliente"`
3. Frontend guarda el tipo y redirige a `TiendaScreen`
4. Cliente navega por productos, agrega al carrito
5. Cliente va al carrito y procede al pago
6. Cliente completa la compra

### Para Usuarios Internos:
1. Usuario inicia sesión con sus credenciales
2. Backend detecta que es usuario interno y retorna `user_type: "usuario"`
3. Frontend guarda el tipo y redirige a `DashboardScreen`
4. Usuario accede a módulos administrativos (inventario, ventas, envíos, etc.)

## 📝 Notas Importantes

1. **Seguridad**: El backend debe validar que los clientes solo puedan acceder a endpoints de tienda, y los usuarios internos solo a endpoints administrativos.

2. **Tabla de Clientes**: Asegúrate de que la tabla `clientes` tenga campos para autenticación:
   - `email` o `username` (para login)
   - `password` (hash o texto plano según tu implementación)
   - `estado` (para verificar si está activo)

3. **Tokens JWT**: Los tokens deben funcionar igual para ambos tipos de usuarios, pero el frontend los trata diferente según el `user_type`.

4. **Carrito**: El carrito se guarda localmente en el dispositivo. En producción, considera guardarlo en el backend asociado al cliente.

## 🚀 Próximos Pasos

1. Modificar el endpoint `/api_login` en el backend según el pseudocódigo anterior
2. Probar el flujo completo de login para ambos tipos de usuarios
3. Verificar que las redirecciones funcionen correctamente
4. Implementar validación de permisos en endpoints del backend

