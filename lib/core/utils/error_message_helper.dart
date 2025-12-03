import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/// Helper para mostrar mensajes de error amigables al usuario
class ErrorMessageHelper {
  /// Convierte cualquier error en un mensaje amigable para el usuario
  static String getFriendlyErrorMessage(dynamic error) {
    // IMPORTANTE: Si el error ya tiene un mensaje amigable (del interceptor), usarlo directamente
    if (error is DioException) {
      // Si el mensaje del error ya es amigable (no contiene detalles técnicos), usarlo
      final errorMessage = error.message ?? '';
      if (errorMessage.isNotEmpty && 
          !errorMessage.contains('DioException') &&
          !errorMessage.contains('bad response') &&
          !errorMessage.contains('status code') &&
          !errorMessage.contains('RequestOptions')) {
        return errorMessage;
      }
      // Si no, usar el manejo específico
      return _getDioExceptionMessage(error);
    }
    
    // Convertir a string y analizar
    final errorString = error.toString().toLowerCase();
    
    // Errores de conexión
    if (errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection timeout') ||
        errorString.contains('receive timeout') ||
        errorString.contains('send timeout')) {
      return 'Sin conexión a Internet. Verifica tu conexión e intenta nuevamente.';
    }
    
    // Errores 401 (No autorizado)
    if (errorString.contains('401') || 
        errorString.contains('status code: 401') ||
        errorString.contains('unauthorized') ||
        errorString.contains('no autenticado')) {
      return 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
    }
    
    // Errores 403 (Prohibido)
    if (errorString.contains('403') || 
        errorString.contains('status code: 403') ||
        errorString.contains('forbidden') ||
        errorString.contains('prohibido')) {
      return 'No tienes permisos para realizar esta acción.';
    }
    
    // Errores 404 (No encontrado)
    if (errorString.contains('404') || 
        errorString.contains('status code: 404') ||
        errorString.contains('not found') ||
        errorString.contains('no encontrado')) {
      return 'El recurso solicitado no fue encontrado.';
    }
    
    // Errores 500 (Error del servidor)
    if (errorString.contains('500') || 
        errorString.contains('status code: 500') ||
        errorString.contains('internal server error')) {
      return 'Error del servidor. Por favor, intenta más tarde.';
    }
    
    // Errores de DioException genéricos
    if (errorString.contains('dioexception')) {
      return 'Error al comunicarse con el servidor. Por favor, intenta nuevamente.';
    }
    
    // Mensaje genérico
    return 'Ocurrió un error inesperado. Por favor, intenta nuevamente.';
  }
  
  /// Parsea un mensaje técnico y lo convierte en amigable
  static String _parseTechnicalMessage(String technicalMessage) {
    final message = technicalMessage.toLowerCase();
    
    // Detectar errores 401
    if (message.contains('401') || message.contains('unauthorized')) {
      return 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
    }
    
    // Detectar errores 403
    if (message.contains('403') || message.contains('forbidden')) {
      return 'No tienes permisos para realizar esta acción.';
    }
    
    // Detectar errores 404
    if (message.contains('404') || message.contains('not found')) {
      return 'El recurso solicitado no fue encontrado.';
    }
    
    // Detectar errores 500
    if (message.contains('500') || message.contains('internal server error')) {
      return 'Error del servidor. Por favor, intenta más tarde.';
    }
    
    // Detectar errores de conexión
    if (message.contains('connection') || message.contains('timeout') || message.contains('socket')) {
      return 'Sin conexión a Internet. Verifica tu conexión e intenta nuevamente.';
    }
    
    // Mensaje genérico para mensajes técnicos
    return 'Error al comunicarse con el servidor. Por favor, intenta nuevamente.';
  }
  
  /// Obtiene un mensaje amigable para DioException
  static String _getDioExceptionMessage(DioException error) {
    // Errores de conexión
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'El tiempo de espera se agotó. Verifica tu conexión a Internet.';
    }
    
    if (error.type == DioExceptionType.connectionError) {
      return 'Sin conexión a Internet. Verifica tu conexión e intenta nuevamente.';
    }
    
    // Errores de respuesta HTTP
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      
      if (statusCode == 401) {
        return 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
      }
      
      if (statusCode == 403) {
        return 'No tienes permisos para realizar esta acción.';
      }
      
      if (statusCode == 404) {
        return 'El recurso solicitado no fue encontrado.';
      }
      
      if (statusCode == 500) {
        return 'Error del servidor. Por favor, intenta más tarde.';
      }
      
      // Intentar obtener mensaje del servidor
      final data = error.response!.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }
    
    // Mensaje genérico
    return 'Error al comunicarse con el servidor. Por favor, intenta nuevamente.';
  }
  
  /// Muestra un SnackBar con mensaje de error amigable
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getFriendlyErrorMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
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
  /// Verifica si un error es de conexión/red
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError;
    }
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection timeout') ||
        errorString.contains('receive timeout') ||
        errorString.contains('send timeout');
  }

  /// Obtiene un mensaje amigable para errores de red
  static String getNetworkErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return '⏱️ Tiempo de espera agotado\n\nEl tiempo de espera se agotó. Verifica tu conexión a Internet e intenta nuevamente.';
      } else if (error.type == DioExceptionType.connectionError) {
        return '🌐 Sin conexión a Internet\n\nNo se pudo conectar al servidor. Verifica tu conexión a Internet e intenta nuevamente.';
      }
    }
    
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('timeout')) {
      return '⏱️ Tiempo de espera agotado\n\nLa conexión está tardando demasiado. Por favor, intenta nuevamente.';
    } else if (errorString.contains('connection refused')) {
      return '🔌 Servidor no disponible\n\nNo se pudo conectar al servidor. Por favor, intenta más tarde.';
    } else {
      return '🌐 Sin conexión a Internet\n\nNo se pudo conectar al servidor. Verifica tu conexión a Internet e intenta nuevamente.';
    }
  }

  /// Muestra un diálogo amigable de error de red
  static void showNetworkErrorDialog(BuildContext context, {dynamic error}) {
    final message = error != null 
        ? getNetworkErrorMessage(error)
        : '🌐 Sin conexión a Internet\n\nNo se pudo conectar al servidor. Verifica tu conexión a Internet e intenta nuevamente.';
    
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
          message,
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
  /// Obtiene un mensaje amigable basado en el error del servidor
  static String getFriendlyMessage(String? message, String? description, String? errorMsg) {
    final allMessages = [
      message ?? '',
      description ?? '',
      errorMsg ?? '',
    ].join(' ').toLowerCase();

    // Cliente desactivado o cuenta inactiva
    if (allMessages.contains('inactivo') || 
        allMessages.contains('desactivado') ||
        allMessages.contains('deshabilitado') ||
        allMessages.contains('cuenta bloqueada') ||
        allMessages.contains('cuenta suspendida')) {
      return '⚠️ Tu cuenta ha sido desactivada\n\nTu cuenta ha sido desactivada por un administrador. Por favor, contacta con soporte para más información.';
    }

    // Token expirado
    if (allMessages.contains('token expirado') || 
        allMessages.contains('token expired') ||
        allMessages.contains('expired') ||
        allMessages.contains('sesión expirada') ||
        allMessages.contains('sesion expirada')) {
      return '⏰ Tu sesión ha expirado\n\nPor seguridad, tu sesión ha expirado. Por favor, inicia sesión nuevamente para continuar.';
    }

    // Token inválido
    if (allMessages.contains('token inválido') || 
        allMessages.contains('invalid token') ||
        allMessages.contains('token no válido')) {
      return '🔒 Sesión inválida\n\nTu sesión ya no es válida. Por favor, inicia sesión nuevamente.';
    }

    // Usuario no autenticado
    if (allMessages.contains('no autenticado') || 
        allMessages.contains('no autenticado') ||
        allMessages.contains('usuario no autenticado') ||
        allMessages.contains('not authenticated')) {
      return '🔐 Sesión no válida\n\nNo se pudo verificar tu sesión. Por favor, inicia sesión nuevamente.';
    }

    // Mensaje genérico del servidor
    if (message != null && message.isNotEmpty) {
      return '⚠️ $message';
    }

    // Mensaje por defecto
    return '⚠️ Error de autenticación\n\nTu sesión ha expirado o ya no es válida. Por favor, inicia sesión nuevamente.';
  }

  /// Muestra un diálogo amigable de error de autenticación
  static void showAuthErrorDialog(
    BuildContext context, {
    String? message,
    String? description,
    String? errorMsg,
    VoidCallback? onConfirm,
  }) {
    // Si se proporciona un mensaje personalizado, usarlo directamente
    // Si no, generar uno amigable basado en los datos del error
    final friendlyMessage = message ?? getFriendlyMessage(message, description, errorMsg);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(
              _getIconForMessage(friendlyMessage),
              color: _getColorForMessage(friendlyMessage),
              size: 28,
            ),
            const SizedBox(width: 10),
            const Text(
              'Atención',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            friendlyMessage,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onConfirm != null) {
                onConfirm();
              }
            },
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

  /// Obtiene el icono apropiado según el mensaje
  static IconData _getIconForMessage(String friendlyMessage) {
    if (friendlyMessage.contains('desactivada')) {
      return Icons.block;
    } else if (friendlyMessage.contains('expirado') || friendlyMessage.contains('expirada')) {
      return Icons.access_time;
    } else if (friendlyMessage.contains('inválida') || friendlyMessage.contains('inválido')) {
      return Icons.lock_outline;
    } else {
      return Icons.warning_amber;
    }
  }

  /// Obtiene el color apropiado según el mensaje
  static Color _getColorForMessage(String friendlyMessage) {
    if (friendlyMessage.contains('desactivada')) {
      return Colors.red;
    } else if (friendlyMessage.contains('expirado') || friendlyMessage.contains('expirada')) {
      return Colors.orange;
    } else if (friendlyMessage.contains('inválida') || friendlyMessage.contains('inválido')) {
      return Colors.blue;
    } else {
      return Colors.orange;
    }
  }
}

