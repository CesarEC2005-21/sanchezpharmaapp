import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'error_message_helper.dart';

/// Sistema centralizado para manejar errores y evitar mensajes duplicados
class ErrorHandler {
  // Rastrea los errores que ya fueron mostrados para evitar duplicados
  static final Set<String> _handledErrors = <String>{};
  static DateTime? _lastErrorTime;
  static String? _lastErrorMessage;
  
  // Tiempo en milisegundos para considerar un error como "duplicado" (2 segundos)
  static const int _duplicateWindowMs = 2000;

  /// Limpia el registro de errores manejados (útil para testing o reset)
  static void clearHandledErrors() {
    _handledErrors.clear();
    _lastErrorTime = null;
    _lastErrorMessage = null;
  }

  /// Verifica si un error ya fue manejado por el interceptor
  static bool _isErrorAlreadyHandled(DioException error) {
    // Errores de conexión siempre son manejados por el interceptor
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }

    // Errores 401 para clientes son manejados por el interceptor
    if (error.response?.statusCode == 401) {
      // Verificar si el mensaje indica que ya fue manejado
      final message = error.message?.toLowerCase() ?? '';
      if (message.contains('sesión expirada') || 
          message.contains('tu sesión ha expirado')) {
        return true;
      }
    }

    return false;
  }

  /// Verifica si es un error duplicado (mismo mensaje en ventana de tiempo)
  static bool _isDuplicateError(String message) {
    final now = DateTime.now();
    
    // Si es el mismo mensaje y está dentro de la ventana de tiempo, es duplicado
    if (_lastErrorMessage == message && 
        _lastErrorTime != null &&
        now.difference(_lastErrorTime!).inMilliseconds < _duplicateWindowMs) {
      return true;
    }

    // Actualizar registro
    _lastErrorMessage = message;
    _lastErrorTime = now;
    return false;
  }

  /// Maneja un error de forma centralizada, evitando duplicados
  /// Retorna true si el error fue manejado, false si ya fue manejado antes
  static bool handleError(
    BuildContext? context,
    dynamic error, {
    bool showToUser = true,
    String? customMessage,
  }) {
    // Si no hay contexto, solo loguear
    if (context == null) {
      print('⚠️ Error sin contexto: $error');
      return false;
    }

    // Si es DioException, verificar si ya fue manejado por el interceptor
    if (error is DioException) {
      if (_isErrorAlreadyHandled(error)) {
        print('ℹ️ Error ya fue manejado por el interceptor, omitiendo mensaje duplicado');
        return false;
      }
    }

    // Obtener mensaje amigable
    final message = customMessage ?? ErrorMessageHelper.getFriendlyErrorMessage(error);

    // Verificar si es un error duplicado
    if (_isDuplicateError(message)) {
      print('ℹ️ Error duplicado detectado, omitiendo mensaje: $message');
      return false;
    }

    // Si se debe mostrar al usuario
    if (showToUser) {
      // Ocultar cualquier SnackBar anterior para evitar acumulación
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Mostrar nuevo mensaje
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

    return true;
  }

  /// Maneja errores de red de forma centralizada
  static bool handleNetworkError(BuildContext? context, dynamic error) {
    if (context == null) return false;

    // Errores de red siempre son manejados por el interceptor
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return false; // Ya fue manejado por el interceptor
      }
    }

    // Si no fue manejado, usar el helper de red
    ErrorMessageHelper.showNetworkErrorDialog(context, error: error);
    return true;
  }

  /// Maneja errores de autenticación de forma centralizada
  static bool handleAuthError(
    BuildContext? context,
    dynamic error, {
    String? message,
    String? description,
    String? errorMsg,
    VoidCallback? onConfirm,
  }) {
    if (context == null) return false;

    // Errores 401 para clientes son manejados por el interceptor
    if (error is DioException && error.response?.statusCode == 401) {
      final errorMessage = error.message?.toLowerCase() ?? '';
      if (errorMessage.contains('sesión expirada') || 
          errorMessage.contains('tu sesión ha expirado')) {
        return false; // Ya fue manejado por el interceptor
      }
    }

    // Si no fue manejado, usar el helper de autenticación
    ErrorMessageHelper.showAuthErrorDialog(
      context,
      message: message,
      description: description,
      errorMsg: errorMsg,
      onConfirm: onConfirm,
    );
    return true;
  }
}

