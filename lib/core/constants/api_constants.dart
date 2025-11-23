class ApiConstants {
  // Base URL de tu API Flask
  static const String baseUrl = 'https://nxlsxx.pythonanywhere.com';
  
  // Endpoints - Usuarios
  static const String login = '/api_login';
  static const String logout = '/api_logout';
  static const String usuarios = '/usuarios_sanchezpharma';
  static const String registrarUsuario = '/registrar_usuario_sanchezpharma';
  static const String editarUsuario = '/editar_usuario_sanchezpharma';
  static const String eliminarUsuario = '/eliminar_usuario_sanchezpharma';
  static const String roles = '/roles_sanchezpharma';
  
  // Endpoints - Inventario - Productos
  static const String productos = '/productos_sanchezpharma';
  static const String producto = '/producto_sanchezpharma';
  static const String registrarProducto = '/registrar_producto_sanchezpharma';
  static const String editarProducto = '/editar_producto_sanchezpharma';
  static const String eliminarProducto = '/eliminar_producto_sanchezpharma';
  static const String buscarProductos = '/buscar_productos_sanchezpharma';
  static const String productosStockBajo = '/productos_stock_bajo_sanchezpharma';
  static const String productosProximosVencer = '/productos_proximos_vencer_sanchezpharma';
  
  // Endpoints - Inventario - Categorías
  static const String categorias = '/categorias_sanchezpharma';
  static const String registrarCategoria = '/registrar_categoria_sanchezpharma';
  static const String editarCategoria = '/editar_categoria_sanchezpharma';
  
  // Endpoints - Inventario - Proveedores
  static const String proveedores = '/proveedores_sanchezpharma';
  static const String registrarProveedor = '/registrar_proveedor_sanchezpharma';
  static const String editarProveedor = '/editar_proveedor_sanchezpharma';
  
  // Endpoints - Inventario - Movimientos
  static const String movimientosInventario = '/movimientos_inventario_sanchezpharma';
  static const String registrarMovimiento = '/registrar_movimiento_sanchezpharma';
  static const String tiposMovimiento = '/tipos_movimiento_sanchezpharma';
  
  // Endpoints - Inventario - Alertas
  static const String alertasInventario = '/alertas_inventario_sanchezpharma';
  static const String marcarAlertaLeida = '/marcar_alerta_leida_sanchezpharma';
  
  // Endpoints - Ventas - Clientes
  static const String clientes = '/clientes_sanchezpharma';
  static const String registrarCliente = '/registrar_cliente_sanchezpharma';
  static const String registrarClientePublico = '/registrar_cliente_publico_sanchezpharma';
  static const String loginGoogle = '/login_google_sanchezpharma';
  static const String registrarClienteGoogle = '/registrar_cliente_google_sanchezpharma';
  static const String editarCliente = '/editar_cliente_sanchezpharma';
  static const String cambiarPasswordCliente = '/cambiar_password_cliente_sanchezpharma';
  
  // Endpoints - Ventas - Métodos de Pago
  static const String metodosPago = '/metodos_pago_sanchezpharma';
  
  // Endpoints - Ventas - Ventas
  static const String ventas = '/ventas_sanchezpharma';
  static const String venta = '/venta_sanchezpharma';
  static const String registrarVenta = '/registrar_venta_sanchezpharma';
  static const String anularVenta = '/anular_venta_sanchezpharma';
  
  // Endpoints - Ventas - Envíos
  static const String envios = '/envios_sanchezpharma';
  static const String envio = '/envio_sanchezpharma';
  static const String actualizarEstadoEnvio = '/actualizar_estado_envio_sanchezpharma';
  static const String actualizarEnvio = '/actualizar_envio_sanchezpharma';
  
  // Endpoints - Reportes
  static const String tiposReporte = '/tipos_reporte_sanchezpharma';
  static const String dashboardResumen = '/dashboard_resumen_sanchezpharma';
  static const String reporteVentasPeriodo = '/reporte_ventas_periodo_sanchezpharma';
  static const String reporteProductosMasVendidos = '/reporte_productos_mas_vendidos_sanchezpharma';
  static const String reporteIngresosTotales = '/reporte_ingresos_totales_sanchezpharma';
  static const String reporteEnvios = '/reporte_envios_sanchezpharma';
  static const String vistaVentasDiarias = '/vista_ventas_diarias_sanchezpharma';
  static const String vistaVentasMensuales = '/vista_ventas_mensuales_sanchezpharma';
  static const String vistaProductosMasVendidos = '/vista_productos_mas_vendidos_sanchezpharma';
  static const String vistaVentasPorVendedor = '/vista_ventas_por_vendedor_sanchezpharma';
  static const String vistaVentasPorCliente = '/vista_ventas_por_cliente_sanchezpharma';
  static const String vistaVentasPorMetodoPago = '/vista_ventas_por_metodo_pago_sanchezpharma';
  static const String vistaResumenEnvios = '/vista_resumen_envios_sanchezpharma';
  static const String vistaAnalisisInventario = '/vista_analisis_inventario_sanchezpharma';
  static const String vistaRotacionProductos = '/vista_rotacion_productos_sanchezpharma';
  static const String vistaComparativaPeriodos = '/vista_comparativa_periodos_sanchezpharma';
  static const String guardarReporte = '/guardar_reporte_sanchezpharma';
  static const String reportesGenerados = '/reportes_generados_sanchezpharma';
  static const String reporteGenerado = '/reporte_generado_sanchezpharma';
  static const String eliminarReporte = '/eliminar_reporte_sanchezpharma';
}

