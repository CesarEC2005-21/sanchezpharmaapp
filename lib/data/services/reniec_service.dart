import 'package:dio/dio.dart';
import '../api/dio_client.dart';
import '../api/api_service.dart';

class ReniecService {
  static const String _apiBaseUrl = 'https://api.decolecta.com';
  static const String _apiToken = 'sk_11948.1JSj647lps9gpCKSlVpe38nIaby3Lnm4';

  final Dio _dio;
  final ApiService _apiService;

  ReniecService() 
      : _dio = Dio(
          BaseOptions(
            baseUrl: _apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Authorization': 'Bearer $_apiToken',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ),
        _apiService = ApiService(DioClient.createDio());

  /// Verifica un DNI: primero en la BD, luego en RENIEC si no existe
  /// Retorna un mapa con:
  /// - 'valido': bool - Si el DNI es válido
  /// - 'datos': Map? - Datos del DNI si es válido (nombre, apellidos, etc.)
  /// - 'mensaje': String - Mensaje descriptivo
  /// - 'existe_en_bd': bool - Si el DNI ya existe en la base de datos
  Future<Map<String, dynamic>> verificarDNI(String dni, {String tipoDocumento = 'DNI'}) async {
    try {
      // Limpiar el DNI (solo números)
      final dniLimpio = dni.trim().replaceAll(RegExp(r'[^0-9]'), '');

      if (dniLimpio.isEmpty || dniLimpio.length < 8) {
        return {
          'valido': false,
          'datos': null,
          'existe_en_bd': false,
          'mensaje': 'El DNI debe tener al menos 8 dígitos',
        };
      }

      // PASO 1: Verificar primero si el DNI ya existe en la base de datos
      try {
        final responseBD = await _apiService.verificarDocumento(dniLimpio, tipoDocumento);
        
        if (responseBD.response.statusCode == 200) {
          final dataBD = responseBD.data;
          
          if (dataBD['code'] == 1 && dataBD['existe'] == true) {
            // El DNI ya existe en la BD
            return {
              'valido': false,
              'datos': null,
              'existe_en_bd': true,
              'mensaje': 'Este DNI ya está registrado en el sistema. Por favor, use otro documento o inicie sesión.',
            };
          }
        }
      } catch (e) {
        // Si hay error al verificar en BD, continuar con verificación RENIEC
        // pero registrar el error
        print('⚠️ Error al verificar documento en BD: $e');
      }

      // PASO 2: Si no existe en BD, verificar con RENIEC (solo para DNI)
      if (tipoDocumento != 'DNI') {
        return {
          'valido': false,
          'datos': null,
          'existe_en_bd': false,
          'mensaje': 'La verificación automática solo está disponible para DNI',
        };
      }

      // Llamar a la API de RENIEC
      final response = await _dio.get(
        '/v1/reniec/dni',
        queryParameters: {'numero': dniLimpio},
      );

      // Verificar si la respuesta es exitosa
      if (response.statusCode == 200) {
        final data = response.data;

        // Verificar si la respuesta contiene datos válidos
        // La API puede devolver diferentes formatos, verificamos los campos comunes
        if (data is Map) {
          // Verificar si tiene campos que indican un DNI válido
          final tieneNombre = data.containsKey('first_name') || 
                             data.containsKey('nombres') ||
                             data.containsKey('nombre') ||
                             data.containsKey('full_name');
          
          final tieneApellido = data.containsKey('first_last_name') ||
                               data.containsKey('apellido_paterno') ||
                               data.containsKey('apellidos') ||
                               data.containsKey('full_name');

          if (tieneNombre || tieneApellido) {
            // DNI válido - extraer datos
            return {
              'valido': true,
              'datos': {
                'documento': dniLimpio,
                'nombre': data['first_name'] ?? 
                         data['nombres'] ?? 
                         data['nombre'] ?? 
                         _extraerNombre(data['full_name']),
                'apellido_paterno': data['first_last_name'] ?? 
                                   data['apellido_paterno'] ?? 
                                   _extraerApellidoPaterno(data['full_name']),
                'apellido_materno': data['second_last_name'] ?? 
                                   data['apellido_materno'] ?? '',
                'nombre_completo': data['full_name'] ?? 
                                 '${data['first_name'] ?? ''} ${data['first_last_name'] ?? ''}'.trim(),
                'datos_completos': data,
              },
              'existe_en_bd': false,
              'mensaje': 'DNI verificado correctamente',
            };
          } else {
            // Respuesta sin datos válidos
            return {
              'valido': false,
              'datos': null,
              'existe_en_bd': false,
              'mensaje': 'El DNI no fue encontrado en RENIEC. Por favor, verifique que el número sea correcto.',
            };
          }
        } else {
          return {
            'valido': false,
            'datos': null,
            'existe_en_bd': false,
            'mensaje': 'Respuesta inválida de la API de RENIEC',
          };
        }
      } else if (response.statusCode == 400) {
        // DNI inválido
        return {
          'valido': false,
          'datos': null,
          'existe_en_bd': false,
          'mensaje': 'El DNI ingresado no es válido. Por favor, verifique que el número sea correcto.',
        };
      } else if (response.statusCode == 404) {
        // DNI no encontrado
        return {
          'valido': false,
          'datos': null,
          'existe_en_bd': false,
          'mensaje': 'El DNI no fue encontrado en RENIEC. Por favor, verifique que el número sea correcto.',
        };
      } else {
        return {
          'valido': false,
          'datos': null,
          'existe_en_bd': false,
          'mensaje': 'Error al verificar el DNI. Código: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      // Manejar errores de conexión
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return {
          'valido': false,
          'datos': null,
          'existe_en_bd': false,
          'mensaje': 'Tiempo de espera agotado. Por favor, intenta nuevamente.',
        };
      } else if (e.type == DioExceptionType.connectionError) {
        return {
          'valido': false,
          'datos': null,
          'existe_en_bd': false,
          'mensaje': 'Error de conexión. Verifica tu conexión a Internet.',
        };
      } else if (e.response != null) {
        // Error con respuesta del servidor
        final statusCode = e.response!.statusCode;
        if (statusCode == 400 || statusCode == 404) {
          return {
            'valido': false,
            'datos': null,
            'existe_en_bd': false,
            'mensaje': 'El DNI ingresado no es válido o no fue encontrado. Por favor, verifique que el número sea correcto.',
          };
        } else if (statusCode == 401 || statusCode == 403) {
          return {
            'valido': false,
            'datos': null,
            'existe_en_bd': false,
            'mensaje': 'Error de autenticación con el servicio de verificación',
          };
        } else {
          return {
            'valido': false,
            'datos': null,
            'existe_en_bd': false,
            'mensaje': 'Error al verificar el DNI. Código: $statusCode',
          };
        }
      } else {
        return {
          'valido': false,
          'datos': null,
          'existe_en_bd': false,
          'mensaje': 'Error al conectar con el servicio de verificación de DNI',
        };
      }
    } catch (e) {
      return {
        'valido': false,
        'datos': null,
        'existe_en_bd': false,
        'mensaje': 'Error inesperado al verificar el DNI: ${e.toString()}',
      };
    }
  }

  /// Extrae el nombre de un nombre completo
  String _extraerNombre(String? nombreCompleto) {
    if (nombreCompleto == null || nombreCompleto.isEmpty) return '';
    final partes = nombreCompleto.trim().split(' ');
    return partes.isNotEmpty ? partes[0] : '';
  }

  /// Extrae el apellido paterno de un nombre completo
  String _extraerApellidoPaterno(String? nombreCompleto) {
    if (nombreCompleto == null || nombreCompleto.isEmpty) return '';
    final partes = nombreCompleto.trim().split(' ');
    return partes.length > 1 ? partes[1] : '';
  }
}

