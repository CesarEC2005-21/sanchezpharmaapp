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
          final token = await SharedPrefsHelper.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log de respuestas exitosas
          print('Response: ${response.statusCode} - ${response.data}');
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          // Manejo de errores
          print('Error: ${error.response?.statusCode} - ${error.message}');
          
          // Si el token es inválido (401), limpiar datos
          if (error.response?.statusCode == 401) {
            await SharedPrefsHelper.clearAuthData();
          }
          
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}

