# Solución al Error 401 - Token No Reconocido

## 🔍 Diagnóstico del Problema

El token se está enviando correctamente desde el cliente (puedes verlo en los logs), pero el servidor Flask-JWT está devolviendo 401. Esto indica que:

1. ✅ El token se guarda correctamente en SharedPreferences
2. ✅ El token se envía correctamente en el header `Authorization: Bearer <token>`
3. ❌ El servidor no está reconociendo/validando el token

## 🎯 Causa Probable

**PythonAnywhere usa Apache**, y Apache por defecto **elimina el header `Authorization`** antes de pasarlo a la aplicación WSGI. Esto es un problema conocido con Flask-JWT en servidores Apache.

## ✅ Soluciones

### Solución 1: Configurar WSGIPassAuthorization (RECOMENDADO)

Necesitas agregar esta configuración en PythonAnywhere:

1. Ve a tu panel de PythonAnywhere
2. Ve a la sección **Web** → **WSGI configuration file**
3. Edita el archivo de configuración y agrega:

```apache
WSGIPassAuthorization On
```

O si estás usando un archivo `.htaccess`, agrega:

```apache
<IfModule mod_wsgi.c>
    WSGIPassAuthorization On
</IfModule>
```

### Solución 2: Modificar el Servidor Flask para Aceptar Token en Query Parameter

Si no puedes modificar la configuración de Apache, puedes modificar tu servidor Flask para que también acepte el token como query parameter:

```python
@app.route('/usuarios_sanchezpharma')
@jwt_required()
def usuarios_sanchezpharma():
    # Intentar obtener token del header primero
    auth_header = request.headers.get("Authorization")
    token = None
    
    if auth_header and auth_header.startswith("Bearer "):
        token = auth_header.replace("Bearer ", "")
    # Si no está en el header, intentar query parameter
    elif request.args.get('token'):
        token = request.args.get('token')
    
    # Verificar blacklist
    if token and token_en_lista_negra(token):
        return jsonify({"code": 0, "message": "Token inválido (logout realizado)"}), 401
    
    # Resto del código...
```

### Solución 3: Usar Flask-JWT-Extended (Alternativa Moderna)

Flask-JWT es una librería antigua. Considera migrar a `Flask-JWT-Extended` que tiene mejor soporte y más opciones de configuración.

## 📝 Nota Importante sobre Tokens JWT

**Los tokens JWT NO se guardan en la base de datos normalmente**. Solo se validan usando la firma y el secret key. La tabla `jwt_blacklist` solo se usa para tokens que han sido invalidados explícitamente (por ejemplo, después de un logout).

El token que recibes del servidor es válido y se puede usar para autenticar peticiones. El problema es que el servidor no lo está recibiendo debido a la configuración de Apache.

## 🔧 Verificación

Después de aplicar la Solución 1, verifica:

1. Reinicia tu aplicación web en PythonAnywhere
2. Intenta hacer login nuevamente
3. Verifica los logs del servidor para ver si el header Authorization está llegando

## 📊 Logs Actuales

Los logs muestran que:
- ✅ Token guardado: 168 caracteres
- ✅ Token enviado en header: `Authorization: Bearer eyJ0eXAiOiJKV1QiLCJh...`
- ❌ Servidor responde: 401 Unauthorized

Esto confirma que el problema está en el servidor, no en el cliente.

