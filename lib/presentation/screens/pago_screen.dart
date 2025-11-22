import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../core/utils/shared_prefs_helper.dart';
import 'tienda_screen.dart';
import 'seleccionar_ubicacion_screen.dart';

class PagoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;

  const PagoScreen({
    super.key,
    required this.carrito,
  });

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  final _formKey = GlobalKey<FormState>();
  bool _isGuardando = false;
  
  // Datos del cliente (obtenidos del login)
  int? _clienteId;
  
  // Datos de envío
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _nombreDestinatarioController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  
  // Coordenadas de la ubicación seleccionada
  double? _latitudDestino;
  double? _longitudDestino;
  
  String _tipoEntrega = 'recojo_tienda'; // 'recojo_tienda' o 'envio_domicilio'
  int? _metodoPagoId;
  List<Map<String, dynamic>> _metodosPago = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _direccionController.dispose();
    _telefonoController.dispose();
    _nombreDestinatarioController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    _clienteId = await SharedPrefsHelper.getClienteId();
    
    try {
      final response = await _apiService.getMetodosPago();
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> metodosJson = data['data'];
          setState(() {
            _metodosPago = metodosJson.map((json) => json as Map<String, dynamic>).toList();
            if (_metodosPago.isNotEmpty) {
              _metodoPagoId = _metodosPago.first['id'] as int;
            }
          });
        }
      }
    } catch (e) {
      print('Error al cargar métodos de pago: $e');
    }
  }

  double get _subtotal {
    return widget.carrito.fold(0.0, (sum, item) {
      final precio = (item['precio'] as num).toDouble();
      final cantidad = (item['cantidad'] as int);
      return sum + (precio * cantidad);
    });
  }

  double get _costoEnvio {
    return _tipoEntrega == 'envio_domicilio' ? 10.0 : 0.0;
  }

  double get _total {
    return _subtotal + _costoEnvio;
  }

  Future<void> _procesarPago() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar que el cliente_id esté disponible
    if (_clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo identificar al cliente. Por favor, inicie sesión nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_metodoPagoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un método de pago'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGuardando = true;
    });

    try {
      // Obtener el userId
      // Nota: Para clientes, el userId puede ser el clienteId, pero el backend necesita
      // un usuario_id válido de la tabla usuarios. Si el backend no acepta NULL,
      // necesitarás crear un usuario "sistema" o modificar el backend.
      // Preparar datos de la venta
      // El backend espera 'productos' (array con producto_id y cantidad) no 'detalle'
      // El backend obtendrá el usuario_id del token JWT automáticamente
      final productos = widget.carrito.map((item) => {
        'producto_id': item['id'],
        'cantidad': item['cantidad'],
      }).toList();

      final datosVenta = {
        'cliente_id': _clienteId,
        'tipo_venta': _tipoEntrega,
        'metodo_pago_id': _metodoPagoId,
        'subtotal': _subtotal,
        'descuento': 0.0,
        'productos': productos, // El backend espera 'productos' no 'detalle'
      };

      // Si es envío a domicilio, agregar datos de envío
      if (_tipoEntrega == 'envio_domicilio') {
        datosVenta['direccion_entrega'] = _direccionController.text;
        datosVenta['telefono_contacto'] = _telefonoController.text;
        datosVenta['nombre_destinatario'] = _nombreDestinatarioController.text;
        datosVenta['referencia_direccion'] = _referenciaController.text;
        datosVenta['costo_envio'] = _costoEnvio;
        
        // Agregar coordenadas si están disponibles
        if (_latitudDestino != null && _longitudDestino != null) {
          datosVenta['latitud_destino'] = _latitudDestino;
          datosVenta['longitud_destino'] = _longitudDestino;
        }
      }

      final response = await _apiService.registrarVenta(datosVenta);

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          // Limpiar el carrito después de una compra exitosa
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('carrito_cliente');
          
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('¡Compra Exitosa!'),
                content: Text(data['message'] ?? 'Su pedido ha sido registrado correctamente'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Cerrar diálogo
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const TiendaScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'Error al procesar el pago');
        }
      } else {
        throw Exception('Error de conexión');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGuardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Compra'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Resumen del pedido
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen del Pedido',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.carrito.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${item['nombre']} x${item['cantidad']}'),
                                Text('S/ ${((item['precio'] as num) * (item['cantidad'] as int)).toStringAsFixed(2)}'),
                              ],
                            ),
                          )),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:'),
                          Text('S/ ${_subtotal.toStringAsFixed(2)}'),
                        ],
                      ),
                      if (_costoEnvio > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Costo de envío:'),
                            Text('S/ ${_costoEnvio.toStringAsFixed(2)}'),
                          ],
                        ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'S/ ${_total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Tipo de entrega
              const Text(
                'Tipo de Entrega',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('Recojo en Tienda'),
                value: 'recojo_tienda',
                groupValue: _tipoEntrega,
                onChanged: (value) {
                  setState(() {
                    _tipoEntrega = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Envío a Domicilio'),
                value: 'envio_domicilio',
                groupValue: _tipoEntrega,
                onChanged: (value) {
                  setState(() {
                    _tipoEntrega = value!;
                  });
                },
              ),
              
              // Datos de envío (solo si es envío a domicilio)
              if (_tipoEntrega == 'envio_domicilio') ...[
                const SizedBox(height: 16),
                const Text(
                  'Datos de Envío',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) {
                    if (_tipoEntrega == 'envio_domicilio' && (value == null || value.isEmpty)) {
                      return 'Por favor ingrese la dirección';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                // Botón para marcar ubicación en el mapa
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final resultado = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SeleccionarUbicacionScreen(
                            direccionInicial: _direccionController.text,
                            latitudInicial: _latitudDestino,
                            longitudInicial: _longitudDestino,
                          ),
                        ),
                      );
                      
                      if (resultado != null) {
                        setState(() {
                          _latitudDestino = resultado['latitud'] as double;
                          _longitudDestino = resultado['longitud'] as double;
                          _direccionController.text = resultado['direccion'] as String;
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ubicación seleccionada correctamente'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Marcar Ubicación en el Mapa'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.green.shade700),
                    ),
                  ),
                ),
                if (_latitudDestino != null && _longitudDestino != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Ubicación marcada: ${_latitudDestino!.toStringAsFixed(6)}, ${_longitudDestino!.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono de Contacto',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (_tipoEntrega == 'envio_domicilio' && (value == null || value.isEmpty)) {
                      return 'Por favor ingrese el teléfono';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nombreDestinatarioController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Destinatario',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_tipoEntrega == 'envio_domicilio' && (value == null || value.isEmpty)) {
                      return 'Por favor ingrese el nombre del destinatario';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _referenciaController,
                  decoration: const InputDecoration(
                    labelText: 'Referencia (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Método de pago
              const Text(
                'Método de Pago',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._metodosPago.map((metodo) => RadioListTile<int>(
                    title: Text(metodo['nombre'] as String),
                    value: metodo['id'] as int,
                    groupValue: _metodoPagoId,
                    onChanged: (value) {
                      setState(() {
                        _metodoPagoId = value;
                      });
                    },
                  )),
              
              const SizedBox(height: 24),
              
              // Botón de pago
              ElevatedButton(
                onPressed: _isGuardando ? null : _procesarPago,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isGuardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Confirmar Compra',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

