import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/utils/error_message_helper.dart';
import '../../core/services/session_timeout_service.dart';
import '../../core/services/token_refresh_service.dart';
import '../../core/constants/api_constants.dart';
import '../../main.dart';
import '../../presentation/screens/login_screen.dart';

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
          // Excluir endpoints públicos que no requieren token
          final publicEndpoints = [
            '/api_login',
            '/api_version_check',  // Endpoint de verificación de versión
            '/registrar_cliente_publico_sanchezpharma',
            '/login_google_sanchezpharma',
            '/registrar_cliente_google_sanchezpharma',
            '/verificar_documento_sanchezpharma',
            '/enviar_codigo_recuperacion_sanchezpharma',
            '/verificar_codigo_recuperacion_sanchezpharma',
            '/cambiar_password_recuperacion_sanchezpharma',
          ];
          final isPublicEndpoint = publicEndpoints.any((endpoint) => 
            options.path.contains(endpoint) || options.uri.path.contains(endpoint)
          );
          
          // Solo agregar token si NO es un endpoint público
          if (!isPublicEndpoint) {
            try {
              // Verificar y renovar token automáticamente si es necesario
              final tokenRefreshService = TokenRefreshService();
              await tokenRefreshService.renovarSiEsNecesario();
              
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
          } else {
            print('🔓 Endpoint público detectado: ${options.path} - No se requiere token');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log de respuestas exitosas
          print('✅ Response: ${response.statusCode} - ${response.requestOptions.path}');
          
          // Registrar actividad del usuario cuando hay una respuesta exitosa
          // Esto indica que el usuario está interactuando con la app
          SessionTimeoutService().registerActivity();
          
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          // Manejo de errores
          print('❌ Error: ${error.response?.statusCode} - ${error.requestOptions.path}');
          print('   Tipo: ${error.type}');
          print('   Mensaje: ${error.message}');
          
          // PRIMERO: Manejar errores de conexión/red (sin internet)
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.connectionError) {
            print('🌐 Error de conexión detectado');
            
            // Mostrar mensaje amigable al usuario
            if (navigatorKey.currentContext != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final context = navigatorKey.currentContext;
                if (context != null) {
                  String mensaje = '🌐 Sin conexión a Internet\n\n';
                  
                  if (error.type == DioExceptionType.connectionTimeout ||
                      error.type == DioExceptionType.receiveTimeout ||
                      error.type == DioExceptionType.sendTimeout) {
                    mensaje += 'El tiempo de espera se agotó. Verifica tu conexión a Internet e intenta nuevamente.';
                  } else {
                    mensaje += 'No se pudo conectar al servidor. Verifica tu conexión a Internet e intenta nuevamente.';
                  }
                  
                  // Mostrar diálogo amigable
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      title: Row(
                        children: [
                          Icon(
                            Icons.wifi_off,
                            color: Colors.orange.shade700,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Sin Conexión',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        mensaje,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Entendido',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
                    ),
                  );
                }
              });
            }
            
            // Crear un error controlado con mensaje amigable
            // Esto evita que se muestre el error técnico completo
            final friendlyError = DioException(
              requestOptions: error.requestOptions,
              type: error.type,
              error: 'Sin conexión a Internet',
              message: 'No se pudo conectar al servidor. Verifica tu conexión a Internet.',
            );
            
            return handler.next(friendlyError);
          }
          
          // Verificar errores de red en el mensaje
          final errorMessage = error.message?.toLowerCase() ?? '';
          if (errorMessage.contains('socketexception') ||
              errorMessage.contains('failed host lookup') ||
              errorMessage.contains('network is unreachable') ||
              errorMessage.contains('connection refused')) {
            print('🌐 Error de red detectado en el mensaje');
            
            // Mostrar mensaje amigable al usuario
            if (navigatorKey.currentContext != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final context = navigatorKey.currentContext;
                if (context != null) {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      title: Row(
                        children: [
                          Icon(
                            Icons.wifi_off,
                            color: Colors.orange.shade700,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Sin Conexión',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      content: const Text(
                        '🌐 Sin conexión a Internet\n\nNo se pudo conectar al servidor. Verifica tu conexión a Internet e intenta nuevamente.',
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Entendido',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
                    ),
                  );
                }
              });
            }
            
            return handler.next(error);
          }
          
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
          
          // IMPORTANTE: Capturar y manejar errores 401 antes de que se propaguen
          // Esto evita que se muestren mensajes técnicos al usuario
          if (error.response?.statusCode == 401) {
            // Verificar si realmente es un error de conexión (sin respuesta del servidor)
            // Si no hay respuesta o el error es de conexión, no tratarlo como 401 de autenticación
            if (error.response == null && 
                (error.type == DioExceptionType.connectionError ||
                 error.type == DioExceptionType.connectionTimeout ||
                 error.type == DioExceptionType.receiveTimeout)) {
              print('⚠️ Error 401 detectado pero es realmente un error de conexión');
              print('   No se tratará como error de autenticación');
              // Ya se manejó arriba el error de conexión, solo continuar
              return handler.next(error);
            }
            
            // Verificar si es un endpoint público (login, etc.)
            final publicEndpoints = [
              '/api_login',
              '/registrar_cliente_publico_sanchezpharma',
              '/login_google_sanchezpharma',
              '/registrar_cliente_google_sanchezpharma',
              '/enviar_codigo_recuperacion_sanchezpharma',
              '/verificar_codigo_recuperacion_sanchezpharma',
              '/cambiar_password_recuperacion_sanchezpharma',
            ];
            final isPublicEndpoint = publicEndpoints.any((endpoint) => 
              error.requestOptions.path.contains(endpoint) || 
              error.requestOptions.uri.path.contains(endpoint)
            );
            
            if (isPublicEndpoint) {
              // Para endpoints públicos, 401 significa credenciales incorrectas, no token inválido
              print('🔐 Error 401 en endpoint público - Credenciales incorrectas');
              print('   Este es un error de autenticación (usuario/contraseña incorrectos)');
              print('   No se requiere token para este endpoint');
            } else {
              // Para endpoints protegidos, 401 significa token inválido
              print('🔒 Error 401 - Token rechazado por el servidor');
              print('   Posibles causas:');
              print('     1. El servidor (PythonAnywhere/Apache) puede estar eliminando el header Authorization');
              print('     2. Flask-JWT no está reconociendo el formato del token');
              print('     3. El token puede estar expirado o ser inválido');
              print('     4. Problema de configuración CORS o WSGI');
            }
            
            // Solo limpiar token si NO es un endpoint público
            if (!isPublicEndpoint) {
              // Verificar si es cliente - los clientes NO deben cerrarse automáticamente
              final isCliente = await SharedPrefsHelper.isCliente();
              
              if (isCliente) {
                // Para clientes, NO cerrar sesión automáticamente para que puedan recibir notificaciones
                // Solo mostrar mensaje amigable indicando que algunas funciones pueden no estar disponibles
                print('🔒 Error 401 para cliente - Mostrando mensaje amigable sin cerrar sesión (para mantener notificaciones)');
                
                // Mostrar mensaje amigable al cliente sin cerrar sesión
                // Esto permite que el cliente siga recibiendo notificaciones
                if (navigatorKey.currentContext != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final context = navigatorKey.currentContext;
                    if (context != null) {
                      // Mostrar SnackBar amigable en lugar de cerrar sesión
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Tu sesión ha expirado. Algunas funciones pueden no estar disponibles, pero seguirás recibiendo notificaciones.',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.orange.shade700,
                          duration: const Duration(seconds: 5),
                          action: SnackBarAction(
                            label: 'Cerrar',
                            textColor: Colors.white,
                            onPressed: () {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            },
                          ),
                        ),
                      );
                    }
                  });
                }
                
                // IMPORTANTE: Crear un error controlado SIN detalles técnicos
                // Usar un mensaje simple que no revele información técnica
                // NO limpiar la sesión para que el cliente pueda seguir recibiendo notificaciones
                final friendlyError = DioException(
                  requestOptions: error.requestOptions,
                  type: DioExceptionType.badResponse,
                  response: Response(
                    requestOptions: error.requestOptions,
                    statusCode: 401,
                    statusMessage: 'Unauthorized',
                    data: {'message': 'Tu sesión ha expirado'},
                  ),
                  error: 'Sesión expirada',
                  message: 'Tu sesión ha expirado',
                );
                
                // NO propagar el error original, solo el error controlado
                return handler.next(friendlyError);
              } else {
                // Para usuarios administrativos, manejar el error normalmente
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
                  } else {
                    // Cualquier error 401 en endpoint protegido significa que la sesión no es válida
                    // Puede ser: token expirado, usuario desactivado, token inválido, etc.
                    print('🔒 Error 401 confirmado - Sesión no válida, limpiando datos');
                    await SharedPrefsHelper.clearAuthData();
                    
                    // Redirigir al login si estamos en una pantalla autenticada
                    if (navigatorKey.currentContext != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final context = navigatorKey.currentContext;
                        if (context != null) {
                          // Mostrar diálogo amigable con el mensaje apropiado
                          ErrorMessageHelper.showAuthErrorDialog(
                            context,
                            description: description,
                            errorMsg: errorMsg,
                            message: message,
                            onConfirm: () {
                              // Redirigir al login después de cerrar el diálogo
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                          );
                        }
                      });
                    }
                  }
                } else {
                  // Error 401 sin datos estructurados - tratar como sesión expirada
                  print('⚠️ Error 401 sin mensaje específico del servidor');
                  print('   Tratando como sesión expirada');
                  await SharedPrefsHelper.clearAuthData();
                  
                  // Redirigir al login si estamos en una pantalla autenticada
                  if (navigatorKey.currentContext != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final context = navigatorKey.currentContext;
                      if (context != null) {
                        // Mostrar diálogo amigable
                        ErrorMessageHelper.showAuthErrorDialog(
                          context,
                          onConfirm: () {
                            // Redirigir al login después de cerrar el diálogo
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          },
                        );
                      }
                    });
                  }
                }
              }
            }
          }
          
          // IMPORTANTE: Para cualquier otro error no manejado, 
          // crear un error controlado que no muestre detalles técnicos
          if (error.response != null && error.response!.statusCode != null) {
            final statusCode = error.response!.statusCode!;
            
            // Crear un error controlado con mensaje amigable para TODOS los errores HTTP
            String friendlyMessage = 'Error al comunicarse con el servidor. Por favor, intenta nuevamente.';
            
            if (statusCode == 403) {
              friendlyMessage = 'No tienes permisos para realizar esta acción.';
            } else if (statusCode == 404) {
              friendlyMessage = 'El recurso solicitado no fue encontrado.';
            } else if (statusCode >= 500) {
              friendlyMessage = 'Error del servidor. Por favor, intenta más tarde.';
            } else if (statusCode >= 400 && statusCode < 500) {
              friendlyMessage = 'Error en la solicitud. Por favor, verifica los datos e intenta nuevamente.';
            }
            
            // Crear error controlado sin detalles técnicos
            final controlledError = DioException(
              requestOptions: error.requestOptions,
              type: error.type,
              response: error.response,
              error: friendlyMessage,
              message: friendlyMessage,
            );
            
            print('⚠️ Error HTTP $statusCode convertido a mensaje amigable: $friendlyMessage');
            return handler.next(controlledError);
          }
          
          // Si no hay respuesta del servidor, crear error controlado genérico
          final genericError = DioException(
            requestOptions: error.requestOptions,
            type: error.type,
            error: 'Error al comunicarse con el servidor',
            message: 'No se pudo completar la solicitud. Por favor, intenta nuevamente.',
          );
          
          return handler.next(genericError);
        },
      ),
    );

    return dio;
  }
}

