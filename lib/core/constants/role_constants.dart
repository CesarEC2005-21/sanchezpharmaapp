import 'package:flutter/material.dart';

/// Constantes para los roles del sistema
/// Basado en la tabla roles de MySQL:
/// 1 = admin, 3 = vendedor, 4 = repartidor, 5 = almacen, 6 = ingeniero
class RoleConstants {
  // IDs de roles según la base de datos
  static const int ROL_ADMINISTRADOR = 1;
  static const int ROL_VENDEDOR = 3;
  static const int ROL_REPARTIDOR = 4;
  static const int ROL_ALMACEN = 5;
  static const int ROL_INGENIERO = 6;

  /// Obtener nombre del rol
  static String getNombreRol(int? rolId) {
    switch (rolId) {
      case ROL_ADMINISTRADOR:
        return 'Administrador';
      case ROL_VENDEDOR:
        return 'Vendedor';
      case ROL_REPARTIDOR:
        return 'Repartidor';
      case ROL_ALMACEN:
        return 'Almacén';
      case ROL_INGENIERO:
        return 'Ingeniero';
      default:
        return 'Usuario';
    }
  }

  /// Obtener badge de color según el rol
  static Color getColorRol(int? rolId) {
    switch (rolId) {
      case ROL_ADMINISTRADOR:
        return Colors.red;
      case ROL_VENDEDOR:
        return Colors.orange;
      case ROL_REPARTIDOR:
        return Colors.purple;
      case ROL_ALMACEN:
        return Colors.blue;
      case ROL_INGENIERO:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  /// Obtener icono según el rol
  static IconData getIconoRol(int? rolId) {
    switch (rolId) {
      case ROL_ADMINISTRADOR:
        return Icons.admin_panel_settings;
      case ROL_VENDEDOR:
        return Icons.shopping_cart;
      case ROL_REPARTIDOR:
        return Icons.local_shipping;
      case ROL_ALMACEN:
        return Icons.warehouse;
      case ROL_INGENIERO:
        return Icons.engineering;
      default:
        return Icons.person;
    }
  }

  // ============================================================
  // PERMISOS DE ACCESO POR ROL
  // ============================================================

  /// USUARIOS: Admin e Ingeniero
  static bool tieneAccesoAUsuarios(int? rolId) {
    if (rolId == null) return false;
    return rolId == ROL_ADMINISTRADOR || rolId == ROL_INGENIERO;
  }

  /// INVENTARIO (Productos, Categorías, Proveedores): Admin, Ingeniero y Almacén
  static bool tieneAccesoAInventario(int? rolId) {
    if (rolId == null) return false;
    return rolId == ROL_ADMINISTRADOR || 
           rolId == ROL_INGENIERO ||
           rolId == ROL_ALMACEN;
  }

  /// VENTAS (Registrar Venta, Clientes): Admin, Ingeniero y Vendedor
  static bool tieneAccesoAVentas(int? rolId) {
    if (rolId == null) return false;
    return rolId == ROL_ADMINISTRADOR || 
           rolId == ROL_INGENIERO ||
           rolId == ROL_VENDEDOR;
  }

  /// ENVÍOS: Admin, Ingeniero, Vendedor y Repartidor
  /// Vendedor necesita acceso para asignar repartidores
  static bool tieneAccesoAEnvios(int? rolId) {
    if (rolId == null) return false;
    return rolId == ROL_ADMINISTRADOR || 
           rolId == ROL_INGENIERO ||
           rolId == ROL_VENDEDOR ||
           rolId == ROL_REPARTIDOR;
  }

  /// REPORTES: Admin e Ingeniero
  static bool tieneAccesoAReportes(int? rolId) {
    if (rolId == null) return false;
    return rolId == ROL_ADMINISTRADOR || rolId == ROL_INGENIERO;
  }

  /// BACKUPS: Solo Ingeniero (acceso exclusivo)
  static bool tieneAccesoABackups(int? rolId) {
    if (rolId == null) return false;
    return rolId == ROL_INGENIERO;
  }

  // Verificadores de rol específico
  static bool esAdministrador(int? rolId) {
    return rolId == ROL_ADMINISTRADOR;
  }

  static bool esVendedor(int? rolId) {
    return rolId == ROL_VENDEDOR;
  }

  static bool esRepartidor(int? rolId) {
    return rolId == ROL_REPARTIDOR;
  }

  static bool esAlmacen(int? rolId) {
    return rolId == ROL_ALMACEN;
  }

  static bool esIngeniero(int? rolId) {
    return rolId == ROL_INGENIERO;
  }

  /// Verifica si el rol puede asignar repartidores
  /// Admin (1), Ingeniero (6) y Vendedor (3)
  static bool puedeAsignarRepartidor(int? rolId) {
    if (rolId == null) return false;
    return rolId == ROL_ADMINISTRADOR || 
           rolId == ROL_INGENIERO ||
           rolId == ROL_VENDEDOR;
  }
}

