/// Constantes para los roles del sistema
/// IMPORTANTE: Ajustar estos valores según los IDs reales en tu base de datos
class RoleConstants {
  // IDs de roles (ajustar según la base de datos)
  static const int ROL_ADMINISTRADOR = 1;
  static const int ROL_ENCARGADO_ALMACEN = 2;
  static const int ROL_VENDEDOR = 3;
  static const int ROL_REPARTIDOR = 4;
  static const int ROL_CLIENTE = 5;

  /// Verifica si un rol tiene acceso a una funcionalidad específica
  static bool tieneAccesoAInventario(int? rolId) {
    if (rolId == null) return false;
    return rolId == ROL_ADMINISTRADOR || 
           rolId == ROL_ENCARGADO_ALMACEN || 
           rolId == ROL_VENDEDOR;
  }

  static bool tieneAccesoAVentas(int? rolId) {
    if (rolId == null) return false;
    return rolId == ROL_ADMINISTRADOR || 
           rolId == ROL_VENDEDOR || 
           rolId == ROL_ENCARGADO_ALMACEN ||
           rolId == ROL_CLIENTE;  // Cliente puede hacer compras
  }

  static bool tieneAccesoAEnvios(int? rolId) {
    if (rolId == null) return false;
    return rolId == ROL_ADMINISTRADOR || 
           rolId == ROL_REPARTIDOR || 
           rolId == ROL_ENCARGADO_ALMACEN;
  }

  static bool tieneAccesoAReportes(int? rolId) {
    if (rolId == null) return false;
    return rolId == ROL_ADMINISTRADOR || 
           rolId == ROL_REPARTIDOR || 
           rolId == ROL_ENCARGADO_ALMACEN;
  }

  static bool tieneAccesoAUsuarios(int? rolId) {
    if (rolId == null) return false;
    return rolId == ROL_ADMINISTRADOR;
  }

  static bool esCliente(int? rolId) {
    return rolId == ROL_CLIENTE;
  }

  static bool esRepartidor(int? rolId) {
    return rolId == ROL_REPARTIDOR;
  }

  static bool esEncargadoAlmacen(int? rolId) {
    return rolId == ROL_ENCARGADO_ALMACEN;
  }
}

