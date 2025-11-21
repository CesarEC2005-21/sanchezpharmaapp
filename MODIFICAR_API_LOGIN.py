# ============================================================
# MODIFICACIÓN DEL ENDPOINT /api_login
# ============================================================
# Este código modifica el endpoint de login para soportar
# autenticación de clientes además de usuarios internos
# ============================================================

# IMPORTANTE: Reemplaza la función api_login() existente en tu archivo rutas.txt
# con este código actualizado

@app.route('/api_login', methods=['POST'])
def api_login():
    try:
        data = request.json
        username = data.get("username")
        password = data.get("password")

        if not username or not password:
            return jsonify({"code": 0, "message": "Usuario y contraseña son requeridos"}), 400

        logging.info(f"Intentando autenticar: {username}")

        # ============================================================
        # PASO 1: Intentar autenticar como usuario interno
        # ============================================================
        user = authenticate(username, password)  # Función existente
        
        if user:
            # Es usuario interno
            logging.info(f"Usuario interno autenticado: {username}")
            token = jwt.jwt_encode_callback(user)
            return jsonify({
                "code": 1,
                "message": "Inicio de sesión exitoso",
                "token": token.decode('utf-8') if hasattr(token, 'decode') else token,
                "user_type": "usuario",
                "user": {"id": user.id, "username": user.username}
            })
        
        # ============================================================
        # PASO 2: Si no es usuario interno, intentar como cliente
        # ============================================================
        conn = obtenerconexion_sanchezpharma()
        cliente = None
        
        with conn:
            with conn.cursor() as cursor:
                # Buscar cliente por email o documento
                # OPCIÓN A: Si usas contraseña en texto plano
                # sql = """
                #     SELECT id, nombre, email, documento, telefono 
                #     FROM clientes 
                #     WHERE (email = %s OR documento = %s) 
                #     AND password = %s 
                #     AND estado = 'activo'
                # """
                # cursor.execute(sql, (username, username, password))
                # cliente = cursor.fetchone()
                
                # OPCIÓN B: Si usas hash SHA256 (RECOMENDADO) - ACTIVADA
                sql = """
                    SELECT id, nombre, email, documento, telefono 
                    FROM clientes 
                    WHERE (email = %s OR documento = %s) 
                    AND password = SHA2(%s, 256)
                    AND estado = 'activo'
                """
                cursor.execute(sql, (username, username, password))
                cliente = cursor.fetchone()
        
        if cliente:
            # Es cliente - crear token JWT
            logging.info(f"Cliente autenticado: {username} (ID: {cliente['id']})")
            
            # Crear un objeto similar a User para el token JWT
            # El token necesita un objeto con atributos id, username, password
            cliente_user = UserSanchezPharma(
                cliente["id"], 
                cliente["email"] or cliente["documento"] or str(cliente["id"]), 
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
                    "username": cliente["email"] or cliente["documento"] or str(cliente["id"])
                }
            })
        
        # Si no es ni usuario ni cliente
        logging.warning(f"Credenciales incorrectas para: {username}")
        return jsonify({"code": 0, "message": "Credenciales incorrectas"}), 401

    except Exception as e:
        logging.error(f"Error en api_login: {repr(e)}")
        return jsonify({"code": 0, "message": repr(e)}), 500


# ============================================================
# VERSIÓN ALTERNATIVA: Con hash de contraseña en Python
# ============================================================
# Si prefieres hacer el hash en Python en lugar de MySQL:

# import hashlib
# 
# @app.route('/api_login', methods=['POST'])
# def api_login():
#     try:
#         data = request.json
#         username = data.get("username")
#         password = data.get("password")
# 
#         # Intentar usuario interno primero
#         user = authenticate(username, password)
#         if user:
#             token = jwt.jwt_encode_callback(user)
#             return jsonify({
#                 "code": 1,
#                 "message": "Inicio de sesión exitoso",
#                 "token": token.decode('utf-8') if hasattr(token, 'decode') else token,
#                 "user_type": "usuario",
#                 "user": {"id": user.id, "username": user.username}
#             })
# 
#         # Intentar como cliente
#         conn = obtenerconexion_sanchezpharma()
#         cliente = None
#         
#         with conn:
#             with conn.cursor() as cursor:
#                 # Obtener todos los clientes que coincidan con email/documento
#                 sql = """
#                     SELECT id, nombre, email, documento, telefono, password
#                     FROM clientes 
#                     WHERE (email = %s OR documento = %s) 
#                     AND estado = 'activo'
#                 """
#                 cursor.execute(sql, (username, username))
#                 cliente = cursor.fetchone()
#                 
#                 if cliente:
#                     # Verificar contraseña con hash
#                     password_hash = hashlib.sha256(password.encode()).hexdigest()
#                     if cliente["password"] == password_hash:
#                         # Contraseña correcta
#                         cliente_user = UserSanchezPharma(
#                             cliente["id"], 
#                             cliente["email"] or cliente["documento"], 
#                             password
#                         )
#                         token = jwt.jwt_encode_callback(cliente_user)
#                         return jsonify({
#                             "code": 1,
#                             "message": "Inicio de sesión exitoso",
#                             "token": token.decode('utf-8') if hasattr(token, 'decode') else token,
#                             "user_type": "cliente",
#                             "cliente_id": cliente["id"],
#                             "user": {
#                                 "id": cliente["id"], 
#                                 "username": cliente["email"] or cliente["documento"]
#                             }
#                         })
#                     else:
#                         cliente = None  # Contraseña incorrecta
# 
#         if not cliente:
#             return jsonify({"code": 0, "message": "Credenciales incorrectas"}), 401
# 
#     except Exception as e:
#         logging.error(f"Error en api_login: {repr(e)}")
#         return jsonify({"code": 0, "message": repr(e)}), 500

