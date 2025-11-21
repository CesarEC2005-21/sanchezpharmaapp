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
              
              // Flask-JWT configurado para aceptar "Bearer" (estándar OAuth2/JWT)
              // Formato: Authorization: Bearer <token>
              // IMPORTANTE: El servidor está configurado con JWT_AUTH_HEADER_PREFIX = 'Bearer'
              final authHeader = 'Bearer $cleanToken';
              
              options.headers['Authorization'] = authHeader;
              
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
          
          // Log detallado de headers
          print('   Headers enviados:');
          error.requestOptions.headers.forEach((key, value) {
            if (key.toLowerCase().contains('auth')) {
              print('     $key: ${value.toString().substring(0, value.toString().length > 50 ? 50 : value.toString().length)}...');
            }
          });
          
          // Log de respuesta del servidor
          if (error.response != null) {
            print('   Respuesta del servidor:');
            print('     Status: ${error.response?.statusCode}');
            print('     Data: ${error.response?.data}');
            print('     Headers recibidos: ${error.response?.headers}');
          }
          
          // Si el token es inválido (401), verificar antes de limpiar
          if (error.response?.statusCode == 401) {
            print('🔒 Error 401 - Token rechazado por el servidor');
            print('   Posibles causas:');
            print('     1. El servidor (PythonAnywhere/Apache) puede estar eliminando el header Authorization');
            print('     2. Flask-JWT no está reconociendo el formato del token');
            print('     3. El token puede estar expirado o ser inválido');
            print('     4. Problema de configuración CORS o WSGI');
            
            // Solo limpiar si el error es realmente de autenticación confirmada
            final errorData = error.response?.data;
            if (errorData is Map) {
              final description = errorData['description']?.toString() ?? '';
              final errorMsg = errorData['error']?.toString() ?? '';
              final message = errorData['message']?.toString() ?? '';
              
              print('   Descripción del servidor: $description');
              print('   Error del servidor: $errorMsg');
              print('   Mensaje del servidor: $message');
              
              // Detectar errores específicos de formato de token
              if (description.contains('Unsupported authorization type') || 
                  errorMsg.contains('Invalid JWT header')) {
                print('⚠️ Error de formato de header detectado');
                print('   Flask-JWT no reconoce el formato del header Authorization');
                print('   El token se mantiene - el problema es de formato, no de validez');
              } else if (message.contains('Token inválido') || 
                  message.contains('Invalid token') ||
                  message.contains('Token expired') ||
                  errorMsg.contains('Token expired')) {
                print('🔒 Token confirmado como inválido o expirado, limpiando datos');
                await SharedPrefsHelper.clearAuthData();
              } else {
                print('⚠️ Error 401 pero el servidor no confirma token inválido específicamente');
                print('   El token se mantiene en el cliente para reintentar');
              }
            } else {
              print('⚠️ Error 401 sin mensaje específico del servidor');
              print('   Probable problema de configuración del servidor');
            }
          }
          
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}

