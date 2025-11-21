import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';

  // Guardar token y datos de usuario
  static Future<void> saveAuthData({
    required String token,
    required int userId,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    // Limpiar el token (eliminar espacios en blanco)
    final cleanToken = token.trim();
    await prefs.setString(_keyToken, cleanToken);
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUsername, username);
    
    // Log para verificar que se guardó
    print('✅ Token guardado exitosamente');
    print('   - Token (limpio): ${cleanToken.substring(0, cleanToken.length > 20 ? 20 : cleanToken.length)}...');
    print('   - Longitud del token: ${cleanToken.length} caracteres');
    print('   - User ID: $userId');
    print('   - Username: $username');
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

  // Limpiar datos (logout)
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUsername);
    
    print('🗑️ Token y datos de usuario eliminados (logout)');
  }
}

