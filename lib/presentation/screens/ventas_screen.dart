import 'package:flutter/material.dart';
import 'package:retrofit/retrofit.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/venta_model.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/cliente_model.dart';
import '../../data/models/metodo_pago_model.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/utils/error_message_helper.dart';
import '../../core/utils/validators.dart';
import 'clientes_screen.dart';
import 'escanner_qr_screen.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<VentaModel> _ventas = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await SharedPrefsHelper.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'No hay sesión activa. Por favor, inicie sesión nuevamente.';
          _isLoading = false;
        });
        return;
      }

      final response = await _apiService.getVentas(null);

      if (response.response.statusCode == 200) {
        final data = response.data;

        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> ventasJson = data['data'];
          setState(() {
            _ventas = ventasJson
                .map((json) => VentaModel.fromJson(json))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Error al cargar ventas';
            _isLoading = false;
          });
        }
      } else if (response.response.statusCode == 401) {
        // Error 401 (token expirado) - no mostrar error en pantalla
        // El modal de "Atención" ya lo maneja
        setState(() {
          _errorMessage = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error al conectar con el servidor';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Si es un error 401 (token expirado), no mostrar el error en la pantalla
      // porque el modal de "Atención" ya lo maneja
      final errorString = e.toString();
      if (errorString.contains('401') || 
          errorString.contains('status code: 401') ||
          errorString.contains('Token inválido') ||
          errorString.contains('token expirado')) {
        setState(() {
          _errorMessage = null;
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _errorMessage = ErrorMessageHelper.getFriendlyErrorMessage(e);
        _isLoading = false;
      });
      // No mostrar SnackBar adicional si es error 401 (el interceptor ya lo maneja)
      if (mounted) {
        final errorString = e.toString().toLowerCase();
        if (!errorString.contains('401') && 
            !errorString.contains('sesión expirada') &&
            !errorString.contains('unauthorized')) {
          ErrorMessageHelper.showErrorSnackBar(context, e);
        }
      }
    }
  }

  Future<void> _mostrarNuevaVenta() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NuevaVentaScreen(),
      ),
    );
    _cargarVentas();
  }

  Future<void> _verDetalleVenta(VentaModel venta) async {
    if (venta.id == null) return;

    try {
      final response = await _apiService.getVenta(venta.id!);

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          final ventaCompleta = VentaModel.fromJson(data['data']);
          
          if (mounted) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Venta ${ventaCompleta.numeroVenta ?? ventaCompleta.id}'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cliente: ${ventaCompleta.clienteCompleto}'),
                      Text('Fecha: ${ventaCompleta.fechaVenta != null ? "${ventaCompleta.fechaVenta!.day}/${ventaCompleta.fechaVenta!.month}/${ventaCompleta.fechaVenta!.year}" : "N/A"}'),
                      Text('Tipo: ${ventaCompleta.tipoVenta == "recojo_tienda" ? "Recojo en Tienda" : "Envío a Domicilio"}'),
                      Text('Método de Pago: ${ventaCompleta.metodoPagoNombre ?? "N/A"}'),
                      Text('Estado: ${ventaCompleta.estado}'),
                      const Divider(),
                      const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...(ventaCompleta.detalle ?? []).map((detalle) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('${detalle.productoNombre ?? "N/A"} x${detalle.cantidad} - \$${detalle.subtotal.toStringAsFixed(2)}'),
                      )),
                      const Divider(),
                      Text('Subtotal (sin IGV): \$${ventaCompleta.subtotal.toStringAsFixed(2)}'),
                      if (ventaCompleta.impuesto > 0)
                        Text('IGV (18%): \$${ventaCompleta.impuesto.toStringAsFixed(2)}'),
                      if (ventaCompleta.descuento > 0)
                        Text('Descuento: \$${ventaCompleta.descuento.toStringAsFixed(2)}'),
                      Text('Total (IGV incluido): \$${ventaCompleta.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      // Botón para escanear QR si es recojo en tienda y está pendiente
                      if (ventaCompleta.tipoVenta == 'recojo_tienda' && ventaCompleta.estado == 'pendiente') ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.of(context).pop(); // Cerrar diálogo
                              final resultado = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EscannerQrScreen(
                                    titulo: 'Escanear QR de Recojo',
                                    mensajeAyuda: 'Escanea el código QR del pedido para marcarlo como entregado',
                                  ),
                                ),
                              );
                              if (resultado == true) {
                                // Recargar ventas después de escanear exitosamente
                                _cargarVentas();
                              }
                            },
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Escanear QR para Entregar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessageHelper.getFriendlyErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarVentas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarVentas,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _ventas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay ventas registradas',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarVentas,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _ventas.length,
                        itemBuilder: (context, index) {
                          final venta = _ventas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 8,
                            ),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: venta.estado == 'completada'
                                    ? Colors.green.shade700
                                    : venta.estado == 'anulada'
                                        ? Colors.red.shade700
                                        : Colors.orange.shade700,
                                child: Icon(
                                  venta.tipoVenta == 'recojo_tienda'
                                      ? Icons.store
                                      : Icons.local_shipping,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                venta.numeroVenta ?? 'Venta #${venta.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cliente: ${venta.clienteCompleto}'),
                                  Text('Fecha: ${venta.fechaVenta != null ? "${venta.fechaVenta!.day}/${venta.fechaVenta!.month}/${venta.fechaVenta!.year}" : "N/A"}'),
                                  Text('Tipo: ${venta.tipoVenta == "recojo_tienda" ? "Recojo en Tienda" : "Envío a Domicilio"}'),
                                  Text('Total: \$${venta.total.toStringAsFixed(2)}'),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: venta.estado == 'completada'
                                          ? Colors.green.shade100
                                          : venta.estado == 'anulada'
                                              ? Colors.red.shade100
                                              : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      venta.estado.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: venta.estado == 'completada'
                                            ? Colors.green.shade700
                                            : venta.estado == 'anulada'
                                                ? Colors.red.shade700
                                                : Colors.orange.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.visibility, color: Colors.green),
                                onPressed: () => _verDetalleVenta(venta),
                                tooltip: 'Ver Detalle',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarNuevaVenta,
        backgroundColor: Colors.orange.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// Pantalla para crear nueva venta
class NuevaVentaScreen extends StatefulWidget {
  const NuevaVentaScreen({super.key});

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<ProductoModel> _productos = [];
  List<ClienteModel> _clientes = [];
  List<MetodoPagoModel> _metodosPago = [];
  
  // Carrito de compra
  final List<Map<String, dynamic>> _carrito = [];
  
  int? _clienteIdSeleccionado;
  String _tipoVenta = 'recojo_tienda';
  int? _metodoPagoIdSeleccionado;
  double _descuento = 0.0;
  String? _observaciones;
  int? _usuarioId;
  
  // Datos de envío (solo para tipo envio_domicilio)
  final TextEditingController _direccionEnvioController = TextEditingController();
  final TextEditingController _telefonoEnvioController = TextEditingController();
  final TextEditingController _nombreDestinatarioController = TextEditingController();
  final TextEditingController _referenciaDireccionController = TextEditingController();
  double? _latitudDestino;
  double? _longitudDestino;

  bool _isLoading = true;
  bool _isGuardando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _direccionEnvioController.dispose();
    _telefonoEnvioController.dispose();
    _nombreDestinatarioController.dispose();
    _referenciaDireccionController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _usuarioId = await SharedPrefsHelper.getUserId();

      final productosFuture = _apiService.getProductos();
      final clientesFuture = _apiService.getClientes({'estado': 'activo'});
      final metodosPagoFuture = _apiService.getMetodosPago();

      final results = await Future.wait([
        productosFuture,
        clientesFuture,
        metodosPagoFuture,
      ]);

      // Productos
      if (results[0].response.statusCode == 200) {
        final data = results[0].data;
        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> productosJson = data['data'];
          _productos = productosJson
              .map((json) => ProductoModel.fromJson(json))
              .where((p) => p.estado == 'activo' && p.stockActual > 0)
              .toList();
        }
      }

      // Clientes
      if (results[1].response.statusCode == 200) {
        final data = results[1].data;
        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> clientesJson = data['data'];
          _clientes = clientesJson
              .map((json) => ClienteModel.fromJson(json))
              .toList();
        }
      }

      // Métodos de pago
      if (results[2].response.statusCode == 200) {
        final data = results[2].data;
        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> metodosJson = data['data'];
          _metodosPago = metodosJson
              .map((json) => MetodoPagoModel.fromJson(json))
              .toList();
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessageHelper.getFriendlyErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Subtotal con IGV incluido (lo que el usuario ve en los precios)
  double get _subtotalConIGV {
    return _carrito.fold(0.0, (sum, item) => sum + (item['precio'] * item['cantidad']));
  }

  // Subtotal sin IGV (para cálculos internos)
  double get _subtotal {
    // El subtotal con IGV ya incluye el 18%, así que calculamos el subtotal sin IGV
    final totalConIGV = _subtotalConIGV;
    return totalConIGV / 1.18;
  }

  // IGV (18%)
  double get _impuesto {
    final totalConIGV = _subtotalConIGV;
    return totalConIGV * 0.18 / 1.18;
  }

  // Total con IGV incluido
  double get _total {
    return _subtotalConIGV - _descuento;
  }

  void _agregarAlCarrito(ProductoModel producto) {
    final existingIndex = _carrito.indexWhere((item) => item['producto_id'] == producto.id);
    
    if (existingIndex >= 0) {
      if (_carrito[existingIndex]['cantidad'] < producto.stockActual) {
        setState(() {
          _carrito[existingIndex]['cantidad']++;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock insuficiente'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      setState(() {
        _carrito.add({
          'producto_id': producto.id,
          'producto_nombre': producto.nombre,
          'precio': producto.precioVenta,
          'cantidad': 1,
        });
      });
    }
  }

  void _eliminarDelCarrito(int index) {
    setState(() {
      _carrito.removeAt(index);
    });
  }

  void _modificarCantidad(int index, int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      _eliminarDelCarrito(index);
      return;
    }

    final productoId = _carrito[index]['producto_id'];
    final producto = _productos.firstWhere((p) => p.id == productoId);

    if (nuevaCantidad > producto.stockActual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock insuficiente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _carrito[index]['cantidad'] = nuevaCantidad;
    });
  }

  Future<void> _guardarVenta() async {
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo obtener el ID de usuario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar campos de envío si es tipo envio_domicilio
    if (_tipoVenta == 'envio_domicilio') {
      if (_direccionEnvioController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La dirección de entrega es requerida'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (_telefonoEnvioController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El teléfono de contacto es requerido'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (_nombreDestinatarioController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El nombre del destinatario es requerido'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      _isGuardando = true;
    });

    try {
      final productos = _carrito.map((item) => {
        'producto_id': item['producto_id'],
        'cantidad': item['cantidad'],
      }).toList();

      final datos = {
        'cliente_id': _clienteIdSeleccionado,
        'usuario_id': _usuarioId,
        'tipo_venta': _tipoVenta,
        'metodo_pago_id': _metodoPagoIdSeleccionado,
        'descuento': _descuento,
        'observaciones': _observaciones,
        'productos': productos,
      };
      
      // Agregar datos de envío si es tipo envio_domicilio
      if (_tipoVenta == 'envio_domicilio') {
        datos['direccion_entrega'] = _direccionEnvioController.text.trim();
        datos['telefono_contacto'] = _telefonoEnvioController.text.trim();
        datos['nombre_destinatario'] = _nombreDestinatarioController.text.trim();
        datos['referencia_direccion'] = _referenciaDireccionController.text.trim();
        if (_latitudDestino != null && _longitudDestino != null) {
          datos['latitud_destino'] = _latitudDestino;
          datos['longitud_destino'] = _longitudDestino;
        }
      }

      final response = await _apiService.registrarVenta(datos);

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Venta registrada correctamente'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Error al registrar la venta'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessageHelper.getFriendlyErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGuardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Resumen del carrito
                if (_carrito.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.orange.shade50,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Carrito de Compra',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_carrito.length} producto(s)',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._carrito.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return ListTile(
                            dense: true,
                            title: Text(item['producto_nombre']),
                            subtitle: Text('Precio: \$${item['precio'].toStringAsFixed(2)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _modificarCantidad(index, item['cantidad'] - 1),
                                ),
                                Text('${item['cantidad']}'),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _modificarCantidad(index, item['cantidad'] + 1),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _eliminarDelCarrito(index),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal (sin IGV):', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('\$${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('IGV (18%):'),
                            Text('\$${_impuesto.toStringAsFixed(2)}'),
                          ],
                        ),
                        if (_descuento > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Descuento:'),
                              Text('-\$${_descuento.toStringAsFixed(2)}'),
                            ],
                          ),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL (IGV incluido):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                              '\$${_total.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                // Lista de productos
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _productos.length,
                    itemBuilder: (context, index) {
                      final producto = _productos[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: producto.stockActual <= producto.stockMinimo
                                ? Colors.orange
                                : Colors.green,
                            child: Text(
                              producto.stockActual.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          title: Text(producto.nombre),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Stock: ${producto.stockActual}'),
                              Text('Precio: \$${producto.precioVenta.toStringAsFixed(2)}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_shopping_cart, color: Colors.orange),
                            onPressed: () => _agregarAlCarrito(producto),
                            tooltip: 'Agregar al carrito',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 8 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Configuración de venta
            Flexible(
              child: ExpansionTile(
                title: const Text('Configurar Venta'),
                childrenPadding: EdgeInsets.zero,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<int?>(
                              value: _clienteIdSeleccionado,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Cliente',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: [
                                DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text(
                                    'Cliente no registrado',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                ..._clientes.map((cliente) => DropdownMenuItem<int?>(
                                  value: cliente.id,
                                  child: Text(
                                    cliente.nombreCompleto,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _clienteIdSeleccionado = value;
                                });
                              },
                            ),
                            const SizedBox(height: 4),
                            TextButton.icon(
                              icon: const Icon(Icons.person_add, size: 18),
                              label: const Text('Registrar Nuevo Cliente', style: TextStyle(fontSize: 14)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ClientesScreen(),
                                  ),
                                );
                                _cargarDatos();
                              },
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: _tipoVenta,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de Venta',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'recojo_tienda',
                                  child: Text(
                                    'Recojo en Tienda',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'envio_domicilio',
                                  child: Text(
                                    'Envío a Domicilio',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _tipoVenta = value ?? 'recojo_tienda';
                                  // Si cambia a envio_domicilio y hay cliente seleccionado, cargar datos del cliente
                                  if (value == 'envio_domicilio' && _clienteIdSeleccionado != null) {
                                    final cliente = _clientes.firstWhere((c) => c.id == _clienteIdSeleccionado);
                                    _direccionEnvioController.text = cliente.direccion ?? '';
                                    _telefonoEnvioController.text = cliente.telefono ?? '';
                                    _nombreDestinatarioController.text = cliente.nombreCompleto;
                                  } else if (value == 'recojo_tienda') {
                                    // Limpiar campos de envío
                                    _direccionEnvioController.clear();
                                    _telefonoEnvioController.clear();
                                    _nombreDestinatarioController.clear();
                                    _referenciaDireccionController.clear();
                                  }
                                });
                              },
                            ),
                            // Campos de envío (solo si es envio_domicilio)
                            if (_tipoVenta == 'envio_domicilio') ...[
                              const SizedBox(height: 8),
                              const Divider(),
                              const Text(
                                'Datos de Envío',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _direccionEnvioController,
                                decoration: const InputDecoration(
                                  labelText: 'Dirección de Entrega *',
                                  hintText: 'Ej: Los Claveles 213, José Leonardo Ortiz',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_on),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                maxLines: 2,
                                validator: (value) {
                                  if (_tipoVenta == 'envio_domicilio' && (value == null || value.isEmpty)) {
                                    return 'La dirección de entrega es requerida';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _telefonoEnvioController,
                                decoration: const InputDecoration(
                                  labelText: 'Teléfono de Contacto *',
                                  hintText: '987654321',
                                  helperText: 'Máximo 9 dígitos, solo números',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                keyboardType: TextInputType.phone,
                                maxLength: 9,
                                inputFormatters: [Validators.telefonoFormatter],
                                validator: (value) {
                                  if (_tipoVenta == 'envio_domicilio') {
                                    if (value == null || value.isEmpty) {
                                      return 'El teléfono de contacto es requerido';
                                    }
                                    return Validators.validateTelefonoRequerido(value);
                                  }
                                  return Validators.validateTelefonoOpcional(value);
                                },
                              ),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _nombreDestinatarioController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre del Destinatario *',
                                  hintText: 'Nombre completo de quien recibirá',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                validator: (value) {
                                  if (_tipoVenta == 'envio_domicilio' && (value == null || value.isEmpty)) {
                                    return 'El nombre del destinatario es requerido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _referenciaDireccionController,
                                decoration: const InputDecoration(
                                  labelText: 'Referencia de Dirección (Opcional)',
                                  hintText: 'Ej: Casa azul, portón negro, etc.',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.info_outline),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                maxLines: 2,
                              ),
                            ],
                            const SizedBox(height: 6),
                            DropdownButtonFormField<int?>(
                              value: _metodoPagoIdSeleccionado,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Método de Pago',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text(
                                    'Seleccionar método',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                ..._metodosPago.map((metodo) => DropdownMenuItem<int?>(
                                  value: metodo.id,
                                  child: Text(
                                    metodo.nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _metodoPagoIdSeleccionado = value;
                                });
                              },
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Descuento',
                                border: OutlineInputBorder(),
                                prefixText: '\$ ',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  _descuento = double.tryParse(value) ?? 0.0;
                                });
                              },
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGuardando || _carrito.isEmpty ? null : _guardarVenta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                ),
                child: _isGuardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Finalizar Venta - \$${_total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


