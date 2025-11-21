import 'package:flutter/material.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../core/utils/shared_prefs_helper.dart';
import 'tienda_screen.dart';

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
      // Preparar datos de la venta
      final productos = widget.carrito.map((item) => {
        'producto_id': item['id'],
        'cantidad': item['cantidad'],
        'precio_unitario': item['precio'],
        'subtotal': (item['precio'] as num).toDouble() * (item['cantidad'] as int),
      }).toList();

      final datosVenta = {
        'cliente_id': _clienteId,
        'tipo_venta': _tipoEntrega,
        'metodo_pago_id': _metodoPagoId,
        'subtotal': _subtotal,
        'descuento': 0.0,
        'total': _total,
        'detalle': productos,
      };

      // Si es envío a domicilio, agregar datos de envío
      if (_tipoEntrega == 'envio_domicilio') {
        datosVenta['direccion_entrega'] = _direccionController.text;
        datosVenta['telefono_contacto'] = _telefonoController.text;
        datosVenta['nombre_destinatario'] = _nombreDestinatarioController.text;
        datosVenta['referencia_direccion'] = _referenciaController.text;
        datosVenta['costo_envio'] = _costoEnvio;
      }

      final response = await _apiService.registrarVenta(datosVenta);

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
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
                  ),
                  validator: (value) {
                    if (_tipoEntrega == 'envio_domicilio' && (value == null || value.isEmpty)) {
                      return 'Por favor ingrese la dirección';
                    }
                    return null;
                  },
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

