import 'package:flutter/material.dart';

/// Paleta de colores oficial de Sánchez Pharma
/// Basada en el logo y la identidad corporativa
class AppColors {
  // Colores principales de la empresa
  static const Color primary = Color(0xFF2E7D32); // Verde principal
  static const Color primaryDark = Color(0xFF1B5E20); // Verde oscuro
  static const Color primaryLight = Color(0xFF4CAF50); // Verde claro
  
  // Colores secundarios
  static const Color secondary = Color(0xFF1976D2); // Azul corporativo
  static const Color accent = Color(0xFFFF6F00); // Naranja/Ámbar
  
  // Colores de estado
  static const Color success = Color(0xFF2E7D32); // Verde éxito
  static const Color warning = Color(0xFFFF8F00); // Naranja advertencia
  static const Color error = Color(0xFFC62828); // Rojo error
  static const Color info = Color(0xFF1976D2); // Azul información
  
  // Colores de fondo
  static const Color background = Color(0xFFF5F5F5); // Gris claro
  static const Color backgroundDark = Color(0xFFE0E0E0); // Gris medio
  static const Color cardBackground = Colors.white;
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF212121); // Negro primario
  static const Color textSecondary = Color(0xFF757575); // Gris texto
  static const Color textLight = Colors.white;
  
  // Gradientes corporativos
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4CAF50), // Verde claro
      Color(0xFF2E7D32), // Verde principal
    ],
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2E7D32), // Verde principal
      Color(0xFF1B5E20), // Verde oscuro
    ],
  );
}

