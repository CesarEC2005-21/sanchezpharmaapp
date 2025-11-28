/// Utilidades de validación para formularios

class Validators {
  /// Valida un número de teléfono peruano
  /// - Debe tener exactamente 9 dígitos
  /// - Debe empezar con 9
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

    // Validar que tenga exactamente 9 dígitos
    if (telefonoLimpio.length != 9) {
      return 'El teléfono debe tener 9 dígitos';
    }

    // Validar que empiece con 9
    if (!telefonoLimpio.startsWith('9')) {
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

