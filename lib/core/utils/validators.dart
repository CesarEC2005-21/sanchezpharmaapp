import 'package:flutter/services.dart';

/// Utilidades de validación para formularios

class Validators {
  /// InputFormatter para DNI
  /// Solo permite números y máximo 8 dígitos
  static FilteringTextInputFormatter dniFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9]'));
  
  /// InputFormatter para teléfono peruano
  /// Solo permite números y máximo 9 dígitos
  static FilteringTextInputFormatter telefonoFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9]'));

  /// Valida un número de teléfono peruano
  /// - Debe tener máximo 9 dígitos
  /// - Solo números
  /// 
  /// Retorna null si es válido, o un mensaje de error si no lo es
  static String? validateTelefono(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      if (required) {
        return 'El teléfono es requerido';
      }
      return null; // Si no es requerido y está vacío, es válido
    }

    // Limpiar el teléfono (solo números)
    final telefonoLimpio = value.trim().replaceAll(RegExp(r'[^0-9]'), '');

    // Validar que tenga máximo 9 dígitos
    if (telefonoLimpio.length > 9) {
      return 'El teléfono no puede tener más de 9 dígitos';
    }

    // Validar que tenga al menos 9 dígitos si se ingresó algo
    if (telefonoLimpio.isNotEmpty && telefonoLimpio.length < 9) {
      return 'El teléfono debe tener 9 dígitos';
    }

    // Validar que empiece con 9 si tiene 9 dígitos
    if (telefonoLimpio.length == 9 && !telefonoLimpio.startsWith('9')) {
      return 'El teléfono debe empezar con 9';
    }

    return null; // Válido
  }

  /// Valida un número de teléfono peruano (versión que permite vacío)
  /// Útil para campos opcionales
  static String? validateTelefonoOpcional(String? value) {
    return validateTelefono(value, required: false);
  }

  /// Valida un número de teléfono peruano (versión requerida)
  /// Útil para campos obligatorios
  static String? validateTelefonoRequerido(String? value) {
    return validateTelefono(value, required: true);
  }
}

