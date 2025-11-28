import 'package:flutter/material.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/utils/date_parser.dart';
import '../../data/models/envio_model.dart';
import '../../data/models/venta_model.dart';
import '../widgets/cliente_bottom_nav.dart';
import 'seguimiento_envio_screen.dart';
import 'mapa_recojo_screen.dart';
import 'login_screen.dart';
import 'qr_pedido_screen.dart';

class PedidosClienteScreen extends StatefulWidget {
  const PedidosClienteScreen({super.key});

  @override
  State<PedidosClienteScreen> createState() => _PedidosClienteScreenState();
}

class _PedidosClienteScreenState extends State<PedidosClienteScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<VentaModel> _pedidos = [];
  List<Map<String, dynamic>> _envios = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _cargarPedidos();
  }

  Future<void> _loadUserData() async {
    final username = await SharedPrefsHelper.getUsername();
    setState(() {
      _username = username ?? 'Cliente';
    });
  }

  Future<void> _cargarPedidos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final clienteId = await SharedPrefsHelper.getClienteId();
      
      if (clienteId == null) {
        setState(() {
          _errorMessage = 'No se pudo identificar al cliente. Por favor, inicie sesión nuevamente.';
          _isLoading = false;
        });
        return;
      }

      // Cargar ventas del cliente
      final ventasResponse = await _apiService.getVentas({'cliente_id': clienteId});
      
      if (ventasResponse.response.statusCode == 200) {
        final data = ventasResponse.data;
        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> ventasJson = data['data'];
          setState(() {
            _pedidos = ventasJson.map((json) {
              try {
                return VentaModel.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                print('Error al parsear venta: $e');
                print('JSON: $json');
                // Si falla el parseo, crear un modelo básico
                return VentaModel(
                  id: (json['id'] as num?)?.toInt(),
                  usuarioId: (json['usuario_id'] as num?)?.toInt() ?? 0,
                  tipoVenta: json['tipo_venta'] as String? ?? 'recojo_tienda',
                  subtotal: _parseDouble(json['subtotal']),
                  descuento: _parseDouble(json['descuento']),
                  impuesto: _parseDouble(json['impuesto']),
                  total: _parseDouble(json['total']),
                  estado: json['estado'] as String? ?? 'pendiente',
                  fechaVenta: DateParser.fromJson(json['fecha_venta']),
                );
              }
            }).toList();
          });
        }
      }

      // Cargar envíos del cliente
      final enviosResponse = await _apiService.getEnvios({'cliente_id': clienteId});
      
      if (enviosResponse.response.statusCode == 200) {
        final data = enviosResponse.data;
        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> enviosJson = data['data'];
          setState(() {
            _envios = enviosJson.map((json) => json as Map<String, dynamic>).toList();
          });
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar pedidos: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final dio = DioClient.createDio();
      final apiService = ApiService(dio);
      await apiService.logout();
    } catch (e) {
      print('Error al cerrar sesión en el servidor: $e');
    }

    await SharedPrefsHelper.clearAuthData();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  // Helper para parsear doubles desde strings o números
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'preparando':
        return 'Preparando';
      case 'en_camino':
        return 'En Camino';
      case 'entregado':
        return 'Entregado';
      case 'cancelado':
        return 'Cancelado';
      case 'completada':
      case 'completado':
        return 'Completado';
      case 'anulada':
        return 'Anulada';
      default:
        return estado;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'preparando':
        return Colors.blue;
      case 'en_camino':
        return Colors.purple;
      case 'entregado':
      case 'completada':
      case 'completado':
        return Colors.green;
      case 'cancelado':
      case 'anulada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.pending;
      case 'preparando':
        return Icons.inventory_2;
      case 'en_camino':
        return Icons.local_shipping;
      case 'entregado':
      case 'completada':
      case 'completado':
        return Icons.check_circle;
      case 'cancelado':
      case 'anulada':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bottomNavigationBar: const ClienteBottomNav(currentIndex: 2),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarPedidos,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _pedidos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No tienes pedidos aún',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Realiza tu primera compra en la tienda',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarPedidos,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _pedidos.length,
                        itemBuilder: (context, index) {
                          final pedido = _pedidos[index];
                          final ventaId = pedido.id;
                          
                          // Buscar envío asociado a esta venta
                          final envio = _envios.firstWhere(
                            (e) => e['venta_id'] == ventaId,
                            orElse: () => <String, dynamic>{},
                          );

                          // Formatear fecha
                          final fechaTexto = pedido.fechaVenta != null
                              ? '${pedido.fechaVenta!.day}/${pedido.fechaVenta!.month}/${pedido.fechaVenta!.year}'
                              : 'N/A';

                          // Determinar si puede ver seguimiento
                          final estadoEnvio = envio.isNotEmpty ? (envio['estado'] as String?) ?? 'pendiente' : 'pendiente';
                          final puedVerSeguimiento = estadoEnvio == 'en_camino' || estadoEnvio == 'entregado';
                          
                          // Para envíos a domicilio, mostrar el estado del envío, no de la venta
                          final estadoMostrar = pedido.tipoVenta == 'envio_domicilio' && envio.isNotEmpty 
                              ? estadoEnvio 
                              : pedido.estado;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 2,
                            child: InkWell(
                              onTap: () {
                                // Si es envío a domicilio
                                if (pedido.tipoVenta == 'envio_domicilio' && envio.isNotEmpty) {
                                  // Solo mostrar seguimiento si está en camino o entregado
                                  if (puedVerSeguimiento) {
                                    try {
                                      final envioModel = EnvioModel.fromJson(envio);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SeguimientoEnvioScreen(envio: envioModel),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error al cargar seguimiento: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } else {
                                    // Mostrar mensaje informativo
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          estadoEnvio == 'pendiente'
                                              ? 'Tu pedido está siendo procesado'
                                              : 'Tu pedido está siendo preparado',
                                        ),
                                        backgroundColor: Colors.blue,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                                // Si es recojo en tienda, mostrar mapa
                                else if (pedido.tipoVenta == 'recojo_tienda') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MapaRecojoScreen(
                                        numeroPedido: pedido.numeroVenta ?? pedido.id?.toString(),
                                        fechaPedido: pedido.fechaVenta,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Pedido',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Fecha: $fechaTexto',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(estadoMostrar).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getEstadoIcon(estadoMostrar),
                                size: 16,
                                color: _getEstadoColor(estadoMostrar),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getEstadoTexto(estadoMostrar),
                                style: TextStyle(
                                  color: _getEstadoColor(estadoMostrar),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total:',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(
                                          'S/ ${pedido.total.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (pedido.tipoVenta == 'envio_domicilio' && envio.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Divider(height: 1, color: Colors.grey.shade300),
                                      const SizedBox(height: 8),
                                      if (!puedVerSeguimiento)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                size: 16,
                                                color: Colors.blue.shade600,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  estadoEnvio == 'pendiente'
                                                      ? 'Estamos procesando tu pedido'
                                                      : estadoEnvio == 'preparando'
                                                          ? 'Estamos preparando tu pedido'
                                                          : 'Tu pedido está siendo procesado',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (puedVerSeguimiento) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.map,
                                              size: 16,
                                              color: Colors.green.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Toca para ver seguimiento en tiempo real',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 12,
                                              color: Colors.green.shade700,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ] else if (pedido.tipoVenta == 'recojo_tienda') ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.store,
                                            size: 16,
                                            color: Colors.green.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Ver ubicación del local',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    // Botón para ver código QR (solo si el pedido no está completado)
                                    if (estadoMostrar != 'completada' && estadoMostrar != 'completado')
                                      ...[
                                        const SizedBox(height: 12),
                                        Divider(height: 1, color: Colors.grey.shade300),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => QrPedidoScreen(
                                                    ventaId: pedido.id!,
                                                    numeroVenta: pedido.numeroVenta,
                                                    tipoVenta: pedido.tipoVenta,
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.qr_code),
                                            label: const Text('Ver Código QR'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.green.shade700,
                                              side: BorderSide(color: Colors.green.shade700),
                                            ),
                                          ),
                                        ),
                                      ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

