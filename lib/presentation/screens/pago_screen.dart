import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/utils/validators.dart';
import '../widgets/cliente_bottom_nav.dart';
import 'home_cliente_screen.dart';
import 'seleccionar_ubicacion_screen.dart';

// Formateador para fecha de vencimiento (MM/AA)
class _FechaVencimientoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    if (text.length <= 2) {
      return newValue.copyWith(text: text);
    }
    
    return newValue.copyWith(
      text: '${text.substring(0, 2)}/${text.substring(2)}',
      selection: TextSelection.collapsed(
        offset: '${text.substring(0, 2)}/${text.substring(2)}'.length,
      ),
    );
  }
}

// Formateador para número de tarjeta (espacios cada 4 dígitos)
class _NumeroTarjetaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    
    return newValue.copyWith(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

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
  
  // Controllers para simulación de pagos
  final TextEditingController _numeroTelefonoController = TextEditingController();
  final TextEditingController _codigoAprobacionController = TextEditingController();
  final TextEditingController _numeroTarjetaController = TextEditingController();
  final TextEditingController _nombreTarjetaController = TextEditingController();
  final TextEditingController _fechaVencimientoController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

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
    _numeroTelefonoController.dispose();
    _codigoAprobacionController.dispose();
    _numeroTarjetaController.dispose();
    _nombreTarjetaController.dispose();
    _fechaVencimientoController.dispose();
    _cvvController.dispose();
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

  // Subtotal con IGV incluido (lo que el usuario ve en los precios)
  double get _subtotalConIGV {
    return widget.carrito.fold(0.0, (sum, item) {
      final precio = (item['precio'] as num).toDouble();
      final cantidad = (item['cantidad'] as int);
      return sum + (precio * cantidad);
    });
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

  double get _costoEnvio {
    return _tipoEntrega == 'envio_domicilio' ? 10.0 : 0.0;
  }

  // Total con IGV incluido
  double get _total {
    return _subtotalConIGV + _costoEnvio;
  }

  // Obtener el nombre del método de pago seleccionado
  String? get _nombreMetodoPago {
    if (_metodoPagoId == null) return null;
    final metodo = _metodosPago.firstWhere(
      (m) => m['id'] == _metodoPagoId,
      orElse: () => {},
    );
    return metodo['nombre'] as String?;
  }

  // Verificar si el método de pago requiere simulación
  bool _requiereSimulacion(String? nombreMetodo) {
    if (nombreMetodo == null) return false;
    final nombre = nombreMetodo.toLowerCase();
    return nombre.contains('plin') || 
           nombre.contains('yape') || 
           nombre.contains('tarjeta de crédito') || 
           nombre.contains('tarjeta de debito') ||
           nombre.contains('tarjeta crédito') ||
           nombre.contains('tarjeta débito');
  }

  // Mostrar diálogo de simulación de pago
  Future<bool> _mostrarSimulacionPago() async {
    final nombreMetodo = _nombreMetodoPago;
    if (nombreMetodo == null) return false;

    final nombre = nombreMetodo.toLowerCase();
    
    // Plin y Yape
    if (nombre.contains('plin') || nombre.contains('yape')) {
      return await _mostrarSimulacionPlinYape(nombreMetodo);
    }
    
    // Tarjeta de crédito
    if (nombre.contains('tarjeta de crédito') || nombre.contains('tarjeta crédito')) {
      return await _mostrarSimulacionTarjetaCredito();
    }
    
    // Tarjeta de débito
    if (nombre.contains('tarjeta de debito') || nombre.contains('tarjeta débito')) {
      return await _mostrarSimulacionTarjetaDebito();
    }
    
    // Transferencia bancaria - no requiere simulación
    return true;
  }

  Future<bool> _mostrarSimulacionPlinYape(String nombreMetodo) async {
    _numeroTelefonoController.clear();
    _codigoAprobacionController.clear();
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Simulación de Pago - $nombreMetodo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _numeroTelefonoController,
                decoration: InputDecoration(
                  labelText: 'Número de $nombreMetodo',
                  hintText: 'Ej: 987654321',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 9,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el número';
                  }
                  if (value.length != 9) {
                    return 'El número debe tener 9 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codigoAprobacionController,
                decoration: const InputDecoration(
                  labelText: 'Código de Aprobación',
                  hintText: 'Ej: 123456',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el código de aprobación';
                  }
                  if (value.length != 6) {
                    return 'El código debe tener 6 dígitos';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final numero = _numeroTelefonoController.text.trim();
              final codigo = _codigoAprobacionController.text.trim();
              
              if (numero.length == 9 && codigo.length == 6) {
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      numero.length != 9 
                        ? 'El número debe tener 9 dígitos'
                        : 'El código de aprobación debe tener 6 dígitos'
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _mostrarSimulacionTarjetaCredito() async {
    _numeroTarjetaController.clear();
    _nombreTarjetaController.clear();
    _fechaVencimientoController.clear();
    _cvvController.clear();
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Simulación de Pago - Tarjeta de Crédito'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _numeroTarjetaController,
                decoration: const InputDecoration(
                  labelText: 'Número de Tarjeta',
                  hintText: '1234 5678 9012 3456',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                maxLength: 23, // 19 dígitos + 4 espacios
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _NumeroTarjetaFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el número de tarjeta';
                  }
                  final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
                  if (digitsOnly.length < 13 || digitsOnly.length > 19) {
                    return 'El número de tarjeta debe tener entre 13 y 19 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreTarjetaController,
                decoration: const InputDecoration(
                  labelText: 'Nombre en la Tarjeta',
                  hintText: 'Ej: JUAN PEREZ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child:               TextFormField(
                controller: _fechaVencimientoController,
                decoration: const InputDecoration(
                  labelText: 'MM/AA',
                  hintText: '12/25',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                maxLength: 5,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _FechaVencimientoFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requerido';
                  }
                  if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                    return 'Formato: MM/AA';
                  }
                  return null;
                },
              ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        if (value.length < 3 || value.length > 4) {
                          return 'CVV inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final numeroTarjeta = _numeroTarjetaController.text.replaceAll(RegExp(r'[^\d]'), '');
              final nombre = _nombreTarjetaController.text.trim();
              final fecha = _fechaVencimientoController.text.trim();
              final cvv = _cvvController.text.trim();
              
              String? error;
              if (numeroTarjeta.length < 13 || numeroTarjeta.length > 19) {
                error = 'El número de tarjeta debe tener entre 13 y 19 dígitos';
              } else if (nombre.isEmpty) {
                error = 'Por favor ingrese el nombre en la tarjeta';
              } else if (fecha.length != 5 || !RegExp(r'^\d{2}/\d{2}$').hasMatch(fecha)) {
                error = 'La fecha debe tener el formato MM/AA';
              } else if (cvv.length < 3 || cvv.length > 4) {
                error = 'El CVV debe tener 3 o 4 dígitos';
              }
              
              if (error == null) {
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _mostrarSimulacionTarjetaDebito() async {
    _numeroTarjetaController.clear();
    _nombreTarjetaController.clear();
    _fechaVencimientoController.clear();
    _cvvController.clear();
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Simulación de Pago - Tarjeta de Débito'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _numeroTarjetaController,
                decoration: const InputDecoration(
                  labelText: 'Número de Tarjeta',
                  hintText: '1234 5678 9012 3456',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                maxLength: 19,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el número de tarjeta';
                  }
                  if (value.length < 13 || value.length > 19) {
                    return 'El número de tarjeta debe tener entre 13 y 19 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreTarjetaController,
                decoration: const InputDecoration(
                  labelText: 'Nombre en la Tarjeta',
                  hintText: 'Ej: JUAN PEREZ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child:               TextFormField(
                controller: _fechaVencimientoController,
                decoration: const InputDecoration(
                  labelText: 'MM/AA',
                  hintText: '12/25',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                maxLength: 5,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _FechaVencimientoFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requerido';
                  }
                  if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                    return 'Formato: MM/AA';
                  }
                  return null;
                },
              ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        if (value.length < 3 || value.length > 4) {
                          return 'CVV inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final numeroTarjeta = _numeroTarjetaController.text.replaceAll(RegExp(r'[^\d]'), '');
              final nombre = _nombreTarjetaController.text.trim();
              final fecha = _fechaVencimientoController.text.trim();
              final cvv = _cvvController.text.trim();
              
              String? error;
              if (numeroTarjeta.length < 13 || numeroTarjeta.length > 19) {
                error = 'El número de tarjeta debe tener entre 13 y 19 dígitos';
              } else if (nombre.isEmpty) {
                error = 'Por favor ingrese el nombre en la tarjeta';
              } else if (fecha.length != 5 || !RegExp(r'^\d{2}/\d{2}$').hasMatch(fecha)) {
                error = 'La fecha debe tener el formato MM/AA';
              } else if (cvv.length < 3 || cvv.length > 4) {
                error = 'El CVV debe tener 3 o 4 dígitos';
              }
              
              if (error == null) {
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ?? false;
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

    // Validar campos de simulación si es necesario
    if (_requiereSimulacion(_nombreMetodoPago)) {
      final nombre = _nombreMetodoPago?.toLowerCase() ?? '';
      
      // Validar Plin y Yape
      if (nombre.contains('plin') || nombre.contains('yape')) {
        if (_numeroTelefonoController.text.length != 9) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor ingrese el número de teléfono (9 dígitos)'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        if (_codigoAprobacionController.text.length != 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor ingrese el código de aprobación (6 dígitos)'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }
      
      // Validar tarjetas
      if (nombre.contains('tarjeta')) {
        final numeroTarjeta = _numeroTarjetaController.text.replaceAll(RegExp(r'[^\d]'), '');
        if (numeroTarjeta.length < 13 || numeroTarjeta.length > 19) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor ingrese un número de tarjeta válido'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        if (_nombreTarjetaController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor ingrese el nombre en la tarjeta'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        if (_fechaVencimientoController.text.length != 5 || 
            !RegExp(r'^\d{2}/\d{2}$').hasMatch(_fechaVencimientoController.text)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor ingrese una fecha de vencimiento válida (MM/AA)'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        if (_cvvController.text.length < 3 || _cvvController.text.length > 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor ingrese un CVV válido (3 o 4 dígitos)'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }
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
        'subtotal': _subtotalConIGV, // Enviar el subtotal con IGV incluido
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
                          builder: (context) => const HomeClienteScreen(initialIndex: 0),
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
      bottomNavigationBar: const ClienteBottomNav(currentIndex: 0),
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
                                Expanded(
                                  child: Text(
                                    '${item['nombre']} x${item['cantidad']}',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('S/ ${((item['precio'] as num) * (item['cantidad'] as int)).toStringAsFixed(2)}'),
                              ],
                            ),
                          )),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text('Subtotal (sin IGV):'),
                          ),
                          Text('S/ ${_subtotal.toStringAsFixed(2)}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text('IGV (18%):'),
                          ),
                          Text('S/ ${_impuesto.toStringAsFixed(2)}'),
                        ],
                      ),
                      if (_costoEnvio > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(
                              child: Text('Costo de envío:'),
                            ),
                            Text('S/ ${_costoEnvio.toStringAsFixed(2)}'),
                          ],
                        ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'Total (IGV incluido):',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
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
                        Expanded(
                          child: Text(
                            'Ubicación marcada: ${_latitudDestino!.toStringAsFixed(6)}, ${_longitudDestino!.toStringAsFixed(6)}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontStyle: FontStyle.italic,
                            ),
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
                    helperText: 'Máximo 9 dígitos, solo números',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 9,
                  inputFormatters: [Validators.telefonoFormatter],
                  validator: (value) {
                    if (_tipoEntrega == 'envio_domicilio') {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el teléfono';
                      }
                      return Validators.validateTelefonoRequerido(value);
                    }
                    return Validators.validateTelefonoOpcional(value);
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
                        // Limpiar campos de simulación al cambiar método de pago
                        _numeroTelefonoController.clear();
                        _codigoAprobacionController.clear();
                        _numeroTarjetaController.clear();
                        _nombreTarjetaController.clear();
                        _fechaVencimientoController.clear();
                        _cvvController.clear();
                      });
                    },
                  )),
              
              // Campos de simulación según el método de pago seleccionado
              if (_requiereSimulacion(_nombreMetodoPago)) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.payment, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Datos de Pago - ${_nombreMetodoPago}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Campos para Plin y Yape
                        if (_nombreMetodoPago?.toLowerCase().contains('plin') == true ||
                            _nombreMetodoPago?.toLowerCase().contains('yape') == true) ...[
                          TextFormField(
                            controller: _numeroTelefonoController,
                            decoration: InputDecoration(
                              labelText: 'Número de ${_nombreMetodoPago}',
                              hintText: 'Ej: 987654321',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            maxLength: 9,
                            validator: (value) {
                              if (_requiereSimulacion(_nombreMetodoPago)) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese el número';
                                }
                                if (value.length != 9) {
                                  return 'El número debe tener 9 dígitos';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _codigoAprobacionController,
                            decoration: const InputDecoration(
                              labelText: 'Código de Aprobación',
                              hintText: 'Ej: 123456',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            validator: (value) {
                              if (_requiereSimulacion(_nombreMetodoPago)) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese el código de aprobación';
                                }
                                if (value.length != 6) {
                                  return 'El código debe tener 6 dígitos';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                        // Campos para tarjeta de crédito o débito
                        if ((_nombreMetodoPago?.toLowerCase().contains('tarjeta de crédito') == true ||
                             _nombreMetodoPago?.toLowerCase().contains('tarjeta crédito') == true ||
                             _nombreMetodoPago?.toLowerCase().contains('tarjeta de debito') == true ||
                             _nombreMetodoPago?.toLowerCase().contains('tarjeta débito') == true)) ...[
                          TextFormField(
                            controller: _numeroTarjetaController,
                            decoration: const InputDecoration(
                              labelText: 'Número de Tarjeta',
                              hintText: '1234 5678 9012 3456',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.credit_card),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 23,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _NumeroTarjetaFormatter(),
                            ],
                            validator: (value) {
                              if (_requiereSimulacion(_nombreMetodoPago)) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese el número de tarjeta';
                                }
                                final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
                                if (digitsOnly.length < 13 || digitsOnly.length > 19) {
                                  return 'El número debe tener entre 13 y 19 dígitos';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nombreTarjetaController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre en la Tarjeta',
                              hintText: 'Ej: JUAN PEREZ',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (_requiereSimulacion(_nombreMetodoPago)) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese el nombre';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _fechaVencimientoController,
                                  decoration: const InputDecoration(
                                    labelText: 'MM/AA',
                                    hintText: '12/25',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 5,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                    _FechaVencimientoFormatter(),
                                  ],
                                  validator: (value) {
                                    if (_requiereSimulacion(_nombreMetodoPago)) {
                                      if (value == null || value.isEmpty) {
                                        return 'Requerido';
                                      }
                                      if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                                        return 'MM/AA';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _cvvController,
                                  decoration: const InputDecoration(
                                    labelText: 'CVV',
                                    hintText: '123',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.lock),
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  obscureText: true,
                                  validator: (value) {
                                    if (_requiereSimulacion(_nombreMetodoPago)) {
                                      if (value == null || value.isEmpty) {
                                        return 'Requerido';
                                      }
                                      if (value.length < 3 || value.length > 4) {
                                        return 'CVV inválido';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              
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

