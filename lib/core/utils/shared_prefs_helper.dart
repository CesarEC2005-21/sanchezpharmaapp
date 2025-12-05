import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';
  static const String _keyUserType = 'user_type'; // 'cliente' o 'usuario'
  static const String _keyClienteId = 'cliente_id'; // ID del cliente si es tipo 'cliente'
  static const String _keyRolId = 'rol_id'; // ID del rol del usuario

  // Guardar token y datos de usuario
  static Future<void> saveAuthData({
    required String token,
    required int userId,
    required String username,
    String? userType,
    int? clienteId,
    int? rolId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    // Limpiar el token (eliminar espacios en blanco)
    final cleanToken = token.trim();
    await prefs.setString(_keyToken, cleanToken);
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUsername, username);
    if (userType != null) {
      await prefs.setString(_keyUserType, userType);
    }
    if (clienteId != null) {
      await prefs.setInt(_keyClienteId, clienteId);
    }
    if (rolId != null) {
      await prefs.setInt(_keyRolId, rolId);
    }
    
    // Log para verificar que se guardó
    print('✅ Token guardado exitosamente');
    print('   - Token (limpio): ${cleanToken.substring(0, cleanToken.length > 20 ? 20 : cleanToken.length)}...');
    print('   - Longitud del token: ${cleanToken.length} caracteres');
    print('   - User ID: $userId');
    print('   - Username: $username');
    print('   - User Type: ${userType ?? 'usuario'}');
    if (clienteId != null) {
      print('   - Cliente ID: $clienteId');
    }
    if (rolId != null) {
      print('   - Rol ID: $rolId');
    }
  }

  // Obtener token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    
    if (token != null) {
      final cleanToken = token.trim();
      print('📥 Token recuperado: ${cleanToken.substring(0, cleanToken.length > 20 ? 20 : cleanToken.length)}...');
      print('   - Longitud: ${cleanToken.length} caracteres');
      return cleanToken;
    } else {
      print('⚠️ No hay token guardado');
    }
    
    return token?.trim();
  }

  // Guardar solo el token (útil para renovación)
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanToken = token.trim();
    await prefs.setString(_keyToken, cleanToken);
    print('✅ Token actualizado: ${cleanToken.substring(0, cleanToken.length > 20 ? 20 : cleanToken.length)}...');
  }

  // Obtener token de forma síncrona (para uso en servicios)
  static String? getTokenSync() {
    // Nota: Esto requiere acceso síncrono a SharedPreferences
    // En Flutter, SharedPreferences es asíncrono, así que esto puede no funcionar directamente
    // Se recomienda usar getToken() async en su lugar
    // Este método está aquí para compatibilidad, pero puede retornar null
    return null;
  }

  // Obtener ID de usuario
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  // Obtener username
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  // Verificar si está autenticado
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    final isAuth = token != null && token.isNotEmpty;
    
    print('🔐 Estado de autenticación: ${isAuth ? "Autenticado ✅" : "No autenticado ❌"}');
    
    return isAuth;
  }

  // Obtener tipo de usuario
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserType);
  }

  // Obtener ID de cliente
  static Future<int?> getClienteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyClienteId);
  }

  // Verificar si es cliente
  static Future<bool> isCliente() async {
    final userType = await getUserType();
    return userType == 'cliente';
  }

  // Verificar si es usuario interno
  static Future<bool> isUsuarioInterno() async {
    final userType = await getUserType();
    return userType == 'usuario' || userType == null;
  }

  // Obtener ID de rol del usuario
  static Future<int?> getRolId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyRolId);
  }

  // Limpiar datos (logout)
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyUserType);
    await prefs.remove(_keyClienteId);
    await prefs.remove(_keyRolId);
    
    print('🗑️ Token y datos de usuario eliminados (logout)');
  }
}

