import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/usuario_model.dart';
import '../models/rol_model.dart';
import '../../core/constants/api_constants.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: ApiConstants.baseUrl)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  // ========== AUTENTICACIÓN ==========
  @POST(ApiConstants.login)
  Future<LoginResponse> login(@Body() LoginRequest request);

  @POST(ApiConstants.logout)
  Future<HttpResponse<dynamic>> logout();

  @POST(ApiConstants.renovarToken)
  Future<HttpResponse<dynamic>> renovarToken();

  // ========== USUARIOS ==========
  @GET(ApiConstants.usuarios)
  Future<HttpResponse<dynamic>> getUsuarios();

  @GET(ApiConstants.repartidores)
  Future<HttpResponse<dynamic>> getRepartidores();

  @GET(ApiConstants.roles)
  Future<HttpResponse<dynamic>> getRoles();

  @POST(ApiConstants.registrarUsuario)
  Future<HttpResponse<dynamic>> registrarUsuario(@Body() Map<String, dynamic> usuario);

  @PUT(ApiConstants.editarUsuario)
  Future<HttpResponse<dynamic>> editarUsuario(@Body() Map<String, dynamic> usuario);

  @DELETE('${ApiConstants.eliminarUsuario}/{id}')
  Future<HttpResponse<dynamic>> eliminarUsuario(@Path('id') int id);

  // ========== INVENTARIO - PRODUCTOS ==========
  @GET(ApiConstants.productos)
  Future<HttpResponse<dynamic>> getProductos();

  @GET('${ApiConstants.producto}/{id}')
  Future<HttpResponse<dynamic>> getProducto(@Path('id') int id);

  @POST(ApiConstants.registrarProducto)
  Future<HttpResponse<dynamic>> registrarProducto(@Body() Map<String, dynamic> producto);

  @PUT(ApiConstants.editarProducto)
  Future<HttpResponse<dynamic>> editarProducto(@Body() Map<String, dynamic> producto);

  @DELETE('${ApiConstants.eliminarProducto}/{id}')
  Future<HttpResponse<dynamic>> eliminarProducto(@Path('id') int id);

  @GET(ApiConstants.buscarProductos)
  Future<HttpResponse<dynamic>> buscarProductos(@Queries() Map<String, dynamic> query);

  @GET(ApiConstants.productosStockBajo)
  Future<HttpResponse<dynamic>> getProductosStockBajo();

  @GET(ApiConstants.productosProximosVencer)
  Future<HttpResponse<dynamic>> getProductosProximosVencer(@Query('dias') int? dias);

  // ========== INVENTARIO - CATEGORÍAS ==========
  @GET(ApiConstants.categorias)
  Future<HttpResponse<dynamic>> getCategorias();

  @POST(ApiConstants.registrarCategoria)
  Future<HttpResponse<dynamic>> registrarCategoria(@Body() Map<String, dynamic> categoria);

  @PUT(ApiConstants.editarCategoria)
  Future<HttpResponse<dynamic>> editarCategoria(@Body() Map<String, dynamic> categoria);

  // ========== INVENTARIO - PROVEEDORES ==========
  @GET(ApiConstants.proveedores)
  Future<HttpResponse<dynamic>> getProveedores();

  @POST(ApiConstants.registrarProveedor)
  Future<HttpResponse<dynamic>> registrarProveedor(@Body() Map<String, dynamic> proveedor);

  @PUT(ApiConstants.editarProveedor)
  Future<HttpResponse<dynamic>> editarProveedor(@Body() Map<String, dynamic> proveedor);

  // ========== INVENTARIO - MOVIMIENTOS ==========
  @GET(ApiConstants.movimientosInventario)
  Future<HttpResponse<dynamic>> getMovimientosInventario(@Queries() Map<String, dynamic>? query);

  @POST(ApiConstants.registrarMovimiento)
  Future<HttpResponse<dynamic>> registrarMovimiento(@Body() Map<String, dynamic> movimiento);

  @GET(ApiConstants.tiposMovimiento)
  Future<HttpResponse<dynamic>> getTiposMovimiento();

  // ========== INVENTARIO - ALERTAS ==========
  @GET(ApiConstants.alertasInventario)
  Future<HttpResponse<dynamic>> getAlertasInventario(@Queries() Map<String, dynamic>? query);

  @PUT('${ApiConstants.marcarAlertaLeida}/{id}')
  Future<HttpResponse<dynamic>> marcarAlertaLeida(@Path('id') int id);

  // ========== VENTAS - CLIENTES ==========
  @GET(ApiConstants.clientes)
  Future<HttpResponse<dynamic>> getClientes(@Queries() Map<String, dynamic>? query);

  @POST(ApiConstants.registrarCliente)
  Future<HttpResponse<dynamic>> registrarCliente(@Body() Map<String, dynamic> cliente);

  @POST(ApiConstants.registrarClientePublico)
  Future<HttpResponse<dynamic>> registrarClientePublico(@Body() Map<String, dynamic> cliente);

  @GET(ApiConstants.verificarDocumento)
  Future<HttpResponse<dynamic>> verificarDocumento(@Query('documento') String documento, @Query('tipo_documento') String? tipoDocumento);

  @POST(ApiConstants.loginGoogle)
  Future<HttpResponse<dynamic>> loginGoogle(@Body() Map<String, dynamic> datos);

  @POST(ApiConstants.registrarClienteGoogle)
  Future<HttpResponse<dynamic>> registrarClienteGoogle(@Body() Map<String, dynamic> cliente);

  @PUT(ApiConstants.editarCliente)
  Future<HttpResponse<dynamic>> editarCliente(@Body() Map<String, dynamic> cliente);

  // ========== RECUPERACIÓN DE CONTRASEÑA ==========
  @POST(ApiConstants.enviarCodigoRecuperacion)
  Future<HttpResponse<dynamic>> enviarCodigoRecuperacion(@Body() Map<String, dynamic> datos);

  @POST(ApiConstants.verificarCodigoRecuperacion)
  Future<HttpResponse<dynamic>> verificarCodigoRecuperacion(@Body() Map<String, dynamic> datos);

  @POST(ApiConstants.cambiarPasswordRecuperacion)
  Future<HttpResponse<dynamic>> cambiarPasswordRecuperacion(@Body() Map<String, dynamic> datos);

  // ========== VENTAS - MÉTODOS DE PAGO ==========
  @GET(ApiConstants.metodosPago)
  Future<HttpResponse<dynamic>> getMetodosPago();

  // ========== VENTAS - VENTAS ==========
  @GET(ApiConstants.ventas)
  Future<HttpResponse<dynamic>> getVentas(@Queries() Map<String, dynamic>? query);

  @GET('${ApiConstants.venta}/{id}')
  Future<HttpResponse<dynamic>> getVenta(@Path('id') int id);

  @POST(ApiConstants.registrarVenta)
  Future<HttpResponse<dynamic>> registrarVenta(@Body() Map<String, dynamic> venta);

  @PUT('${ApiConstants.anularVenta}/{id}')
  Future<HttpResponse<dynamic>> anularVenta(@Path('id') int id);

  @GET('${ApiConstants.codigoQrVenta}/{id}')
  Future<HttpResponse<dynamic>> getCodigoQrVenta(@Path('id') int id);

  @POST(ApiConstants.validarQrEntrega)
  Future<HttpResponse<dynamic>> validarQrEntrega(@Body() Map<String, dynamic> datos);

  // ========== VENTAS - ENVÍOS ==========
  @GET(ApiConstants.envios)
  Future<HttpResponse<dynamic>> getEnvios(@Queries() Map<String, dynamic>? query);

  @GET('${ApiConstants.envio}/{id}')
  Future<HttpResponse<dynamic>> getEnvio(@Path('id') int id);

  @PUT('${ApiConstants.actualizarEstadoEnvio}/{id}')
  Future<HttpResponse<dynamic>> actualizarEstadoEnvio(@Path('id') int id, @Body() Map<String, dynamic> datos);

  @PUT('${ApiConstants.actualizarEnvio}/{id}')
  Future<HttpResponse<dynamic>> actualizarEnvio(@Path('id') int id, @Body() Map<String, dynamic> datos);

  // ========== REPORTES ==========
  @GET(ApiConstants.tiposReporte)
  Future<HttpResponse<dynamic>> getTiposReporte();

  @GET(ApiConstants.dashboardResumen)
  Future<HttpResponse<dynamic>> getDashboardResumen();

  @POST(ApiConstants.reporteVentasPeriodo)
  Future<HttpResponse<dynamic>> reporteVentasPeriodo(@Body() Map<String, dynamic> datos);

  @POST(ApiConstants.reporteProductosMasVendidos)
  Future<HttpResponse<dynamic>> reporteProductosMasVendidos(@Body() Map<String, dynamic> datos);

  @POST(ApiConstants.reporteIngresosTotales)
  Future<HttpResponse<dynamic>> reporteIngresosTotales(@Body() Map<String, dynamic> datos);

  @POST(ApiConstants.reporteEnvios)
  Future<HttpResponse<dynamic>> reporteEnvios(@Body() Map<String, dynamic> datos);

  @GET(ApiConstants.vistaVentasDiarias)
  Future<HttpResponse<dynamic>> getVistaVentasDiarias();

  @GET(ApiConstants.vistaVentasMensuales)
  Future<HttpResponse<dynamic>> getVistaVentasMensuales();

  @GET(ApiConstants.vistaProductosMasVendidos)
  Future<HttpResponse<dynamic>> getVistaProductosMasVendidos(@Query('limite') int? limite);

  @GET(ApiConstants.vistaVentasPorVendedor)
  Future<HttpResponse<dynamic>> getVistaVentasPorVendedor();

  @GET(ApiConstants.vistaVentasPorCliente)
  Future<HttpResponse<dynamic>> getVistaVentasPorCliente();

  @GET(ApiConstants.vistaVentasPorMetodoPago)
  Future<HttpResponse<dynamic>> getVistaVentasPorMetodoPago();

  @GET(ApiConstants.vistaResumenEnvios)
  Future<HttpResponse<dynamic>> getVistaResumenEnvios();

  @GET(ApiConstants.vistaAnalisisInventario)
  Future<HttpResponse<dynamic>> getVistaAnalisisInventario();

  @GET(ApiConstants.vistaRotacionProductos)
  Future<HttpResponse<dynamic>> getVistaRotacionProductos(@Query('limite') int? limite);

  @GET(ApiConstants.vistaComparativaPeriodos)
  Future<HttpResponse<dynamic>> getVistaComparativaPeriodos();

  @POST(ApiConstants.guardarReporte)
  Future<HttpResponse<dynamic>> guardarReporte(@Body() Map<String, dynamic> datos);

  @GET(ApiConstants.reportesGenerados)
  Future<HttpResponse<dynamic>> getReportesGenerados(@Queries() Map<String, dynamic>? query);

  @GET('${ApiConstants.reporteGenerado}/{id}')
  Future<HttpResponse<dynamic>> getReporteGenerado(@Path('id') int id);

  @DELETE('${ApiConstants.eliminarReporte}/{id}')
  Future<HttpResponse<dynamic>> eliminarReporte(@Path('id') int id);

  // ========== BANNERS PROMOCIONALES ==========
  @GET(ApiConstants.bannersActivos)
  Future<HttpResponse<dynamic>> getBannersActivos();

  @GET(ApiConstants.banners)
  Future<HttpResponse<dynamic>> getBanners();

  @GET('${ApiConstants.banner}/{id}')
  Future<HttpResponse<dynamic>> getBanner(@Path('id') int id);

  @POST(ApiConstants.registrarBanner)
  Future<HttpResponse<dynamic>> registrarBanner(@Body() Map<String, dynamic> banner);

  @PUT(ApiConstants.editarBanner)
  Future<HttpResponse<dynamic>> editarBanner(@Body() Map<String, dynamic> banner);

  @DELETE('${ApiConstants.eliminarBanner}/{id}')
  Future<HttpResponse<dynamic>> eliminarBanner(@Path('id') int id);

  @PUT('${ApiConstants.toggleBanner}/{id}')
  Future<HttpResponse<dynamic>> toggleBanner(@Path('id') int id);

  // ========== DIRECCIONES DE CLIENTES ==========
  @GET('/direcciones_cliente_sanchezpharma/{clienteId}')
  Future<HttpResponse<dynamic>> getDireccionesCliente(@Path('clienteId') int clienteId);

  @POST('/registrar_direccion_sanchezpharma')
  Future<HttpResponse<dynamic>> registrarDireccion(@Body() Map<String, dynamic> direccion);

  @PUT('/editar_direccion_sanchezpharma')
  Future<HttpResponse<dynamic>> editarDireccion(@Body() Map<String, dynamic> direccion);

  @DELETE('/eliminar_direccion_sanchezpharma/{id}')
  Future<HttpResponse<dynamic>> eliminarDireccion(@Path('id') int id);

  @PUT('/marcar_direccion_principal_sanchezpharma/{id}')
  Future<HttpResponse<dynamic>> marcarDireccionPrincipal(@Path('id') int id);

  // ========== NOTIFICACIONES DE CLIENTES ==========
  @GET('${ApiConstants.notificacionesCliente}/{clienteId}')
  Future<HttpResponse<dynamic>> getNotificacionesCliente(
    @Path('clienteId') int clienteId,
    @Query('leida') String? leida,
  );

  @PUT('${ApiConstants.marcarNotificacionLeida}/{id}')
  Future<HttpResponse<dynamic>> marcarNotificacionLeida(@Path('id') int id);

  @PUT('${ApiConstants.marcarTodasNotificacionesLeidas}/{clienteId}')
  Future<HttpResponse<dynamic>> marcarTodasNotificacionesLeidas(@Path('clienteId') int clienteId);

  @GET('${ApiConstants.contarNotificacionesNoLeidas}/{clienteId}')
  Future<HttpResponse<dynamic>> contarNotificacionesNoLeidas(@Path('clienteId') int clienteId);

  // ========== BACKUPS (SOLO INGENIERO) ==========
  @GET(ApiConstants.backupsHistorial)
  Future<HttpResponse<dynamic>> getBackupsHistorial();

  @POST(ApiConstants.generarBackupBd)
  Future<HttpResponse<dynamic>> generarBackupBd();

  @POST(ApiConstants.generarBackupArchivos)
  Future<HttpResponse<dynamic>> generarBackupArchivos();

  @POST(ApiConstants.generarBackupCompleto)
  Future<HttpResponse<dynamic>> generarBackupCompleto();

  @GET('${ApiConstants.descargarBackup}/{backupId}')
  Future<HttpResponse<dynamic>> descargarBackup(@Path('backupId') int backupId);
}

