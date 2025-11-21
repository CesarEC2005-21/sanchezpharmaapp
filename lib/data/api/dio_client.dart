import 'package:dio/dio.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/constants/api_constants.dart';

class DioClient {
  static Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor para agregar el token automáticamente
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Agregar token si existe
          try {
            final token = await SharedPrefsHelper.getToken();
            if (token != null && token.isNotEmpty) {
              // Limpiar el token (eliminar espacios en blanco)
              final cleanToken = token.trim();
              
              // Asegurar que el header esté en el formato correcto para Flask-JWT
              // Flask-JWT espera: Authorization: Bearer <token>
              final authHeader = 'Bearer $cleanToken';
              
              // Usar tanto 'Authorization' como 'authorization' para compatibilidad
              options.headers['Authorization'] = authHeader;
              options.headers['authorization'] = authHeader; // Por si acaso es case-sensitive
              
              print('🔑 Token agregado al header Authorization para: ${options.path}');
              print('   Método: ${options.method}');
              print('   URL completa: ${options.baseUrl}${options.path}');
              print('   Token (primeros 50 chars): ${cleanToken.substring(0, cleanToken.length > 50 ? 50 : cleanToken.length)}...');
              print('   Header completo: Authorization: Bearer ${cleanToken.substring(0, cleanToken.length > 20 ? 20 : cleanToken.length)}...');
            } else {
              print('⚠️ No se encontró token para la petición: ${options.path}');
            }
          } catch (e) {
            print('❌ Error al obtener token: $e');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log de respuestas exitosas
          print('✅ Response: ${response.statusCode} - ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          // Manejo de errores
          print('❌ Error: ${error.response?.statusCode} - ${error.requestOptions.path}');
          print('   Mensaje: ${error.message}');
          if (error.requestOptions.headers.containsKey('Authorization')) {
            print('   Header Authorization presente: ${error.requestOptions.headers['Authorization']?.substring(0, 30)}...');
          } else {
            print('   ⚠️ Header Authorization NO presente');
          }
          
          // Si el token es inválido (401), verificar antes de limpiar
          if (error.response?.statusCode == 401) {
            print('🔒 Error 401 - Token rechazado por el servidor');
            print('   Verificando si el token sigue siendo válido...');
            
            // Solo limpiar si el error es realmente de autenticación
            // No limpiar si es un error temporal del servidor
            final errorData = error.response?.data;
            if (errorData is Map && errorData['message']?.toString().contains('Token inválido') == true) {
              print('🔒 Token confirmado como inválido, limpiando datos');
              await SharedPrefsHelper.clearAuthData();
            } else {
              print('⚠️ Error 401 pero no se confirma token inválido - manteniendo sesión');
            }
          }
          
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}

