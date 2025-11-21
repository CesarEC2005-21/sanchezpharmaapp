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
    await prefs.setString(_keyToken, token);
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUsername, username);
    
    // Log para verificar que se guardó
    print('✅ Token guardado exitosamente');
    print('   - Token: ${token.substring(0, 20)}...'); // Solo primeros 20 caracteres
    print('   - User ID: $userId');
    print('   - Username: $username');
  }

  // Obtener token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    
    if (token != null) {
      print('📥 Token recuperado: ${token.substring(0, 20)}...');
    } else {
      print('⚠️ No hay token guardado');
    }
    
    return token;
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

