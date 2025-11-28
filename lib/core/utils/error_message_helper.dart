import 'package:flutter/material.dart';

/// Helper para mostrar mensajes de error amigables al usuario
class ErrorMessageHelper {
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

