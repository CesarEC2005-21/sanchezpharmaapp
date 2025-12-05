import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/notifiers/cart_notifier.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/producto_model.dart';
import '../widgets/cliente_bottom_nav.dart';
import 'pago_screen.dart';

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<Map<String, dynamic>> _carrito = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarCarrito();
    _actualizarContadorCarrito();
  }

  Future<void> _cargarCarrito() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final carritoJson = prefs.getString('carrito_cliente');
    
    if (carritoJson != null && carritoJson.isNotEmpty) {
      try {
        final items = carritoJson.split('|');
        _carrito = [];
        for (var item in items) {
          if (item.isNotEmpty) {
            // Separar imagen si existe (formato: id:nombre:precio:cantidad:stock||imagen_url)
            final imagenIndex = item.indexOf('||');
            String itemData = item;
            String? imagenUrl;
            if (imagenIndex != -1) {
              itemData = item.substring(0, imagenIndex);
              imagenUrl = item.substring(imagenIndex + 2);
            }
            
            final parts = itemData.split(':');
            if (parts.length >= 4) {
              _carrito.add({
                'id': int.parse(parts[0]),
                'nombre': parts[1],
                'precio': double.parse(parts[2]),
                'cantidad': int.parse(parts[3]),
                'stock': int.parse(parts.length > 4 ? parts[4] : '0'),
                'imagen_url': imagenUrl,
              });
            }
          }
        }
      } catch (e) {
        print('Error al cargar carrito: $e');
        _carrito = [];
      }
    } else {
      _carrito = [];
    }

    // Actualizar imágenes de productos que no tienen imagen
    await _actualizarImagenesProductos();
    
    setState(() {
      _isLoading = false;
    });
    
    // Actualizar contador global
    final totalItems = _carrito.fold(0, (sum, item) => sum + (item['cantidad'] as int));
    CartNotifier.instance.updateCount(totalItems);
  }

  Future<void> _actualizarImagenesProductos() async {
    // Verificar si hay productos sin imagen
    final productosSinImagen = _carrito.where((item) {
      final imagenUrl = item['imagen_url'] as String?;
      return imagenUrl == null || imagenUrl.isEmpty;
    }).toList();

    if (productosSinImagen.isEmpty) return;

    try {
      // Cargar todos los productos desde la API
      final response = await _apiService.getProductos();
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> productosJson = data['data'];
          final productos = productosJson.map((json) => ProductoModel.fromJson(json)).toList();
          
          // Crear un mapa de productos por ID para búsqueda rápida
          final productosMap = {for (var p in productos) p.id: p};
          
          // Actualizar imágenes en el carrito
          bool actualizado = false;
          for (var item in _carrito) {
            final imagenUrl = item['imagen_url'] as String?;
            if (imagenUrl == null || imagenUrl.isEmpty) {
              final productoId = item['id'] as int;
              final producto = productosMap[productoId];
              if (producto != null) {
                final nuevaImagenUrl = producto.imagenUrl ?? (producto.imagenes != null && producto.imagenes!.isNotEmpty ? producto.imagenes!.first : null);
                if (nuevaImagenUrl != null && nuevaImagenUrl.isNotEmpty) {
                  item['imagen_url'] = nuevaImagenUrl;
                  actualizado = true;
                }
              }
            }
          }
          
          // Guardar carrito actualizado si hubo cambios
          if (actualizado) {
            await _guardarCarrito();
          }
        }
      }
    } catch (e) {
      print('Error al actualizar imágenes de productos: $e');
      // No mostrar error al usuario, simplemente continuar sin imágenes
    }
  }

  void _actualizarCantidad(int index, int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      _eliminarItem(index);
      return;
    }

    setState(() {
      _carrito[index]['cantidad'] = nuevaCantidad;
    });
    _guardarCarrito();
  }

  void _eliminarItem(int index) {
    setState(() {
      _carrito.removeAt(index);
    });
    _guardarCarrito();
  }

  Future<void> _guardarCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    if (_carrito.isEmpty) {
      await prefs.remove('carrito_cliente');
      CartNotifier.instance.updateCount(0);
    } else {
      final carritoString = _carrito.map((item) {
        final base = '${item['id']}:${item['nombre']}:${item['precio']}:${item['cantidad']}:${item['stock']}';
        final imagenUrl = item['imagen_url'] as String?;
        return imagenUrl != null && imagenUrl.isNotEmpty ? '$base||$imagenUrl' : base;
      }).join('|');
      await prefs.setString('carrito_cliente', carritoString);
      // Actualizar el contador global
      final totalItems = _carrito.fold(0, (sum, item) => sum + (item['cantidad'] as int));
      CartNotifier.instance.updateCount(totalItems);
    }
  }

  Future<void> _actualizarContadorCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    final carritoJson = prefs.getString('carrito_cliente');
    if (carritoJson != null && carritoJson.isNotEmpty) {
      final items = carritoJson.split('|');
      int total = 0;
      for (final item in items) {
        if (item.isNotEmpty) {
          final parts = item.split(':');
          if (parts.length >= 4) {
            total += int.tryParse(parts[3]) ?? 0;
          }
        }
      }
      CartNotifier.instance.updateCount(total);
    } else {
      CartNotifier.instance.updateCount(0);
    }
  }

  double get _subtotal {
    return _carrito.fold(0.0, (sum, item) {
      final precio = (item['precio'] as num).toDouble();
      final cantidad = (item['cantidad'] as int);
      return sum + (precio * cantidad);
    });
  }

  double get _total {
    return _subtotal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const ClienteBottomNav(currentIndex: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _carrito.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'Tu carrito está vacío',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega productos desde la tienda',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Ir a la Tienda'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _carrito.length,
                        itemBuilder: (context, index) {
                          final item = _carrito[index];
                          final imagenUrl = item['imagen_url'] as String?;
                          final tieneImagen = imagenUrl != null && imagenUrl.isNotEmpty;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: tieneImagen
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imagenUrl!,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return CircleAvatar(
                                            backgroundColor: Colors.green.shade100,
                                            child: Icon(Icons.medication, color: Colors.green.shade700),
                                          );
                                        },
                                      ),
                                    )
                                  : CircleAvatar(
                                      backgroundColor: Colors.green.shade100,
                                      child: Icon(Icons.medication, color: Colors.green.shade700),
                                    ),
                              title: Text(item['nombre'] as String),
                              subtitle: Text('S/ ${(item['precio'] as num).toStringAsFixed(2)} c/u'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () {
                                      _actualizarCantidad(index, (item['cantidad'] as int) - 1);
                                    },
                                  ),
                                  Text(
                                    '${item['cantidad']}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      final stock = item['stock'] as int;
                                      if ((item['cantidad'] as int) < stock) {
                                        _actualizarCantidad(index, (item['cantidad'] as int) + 1);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('No hay suficiente stock disponible'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _eliminarItem(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal:',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                'S/ ${_subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'S/ ${_total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _carrito.isNotEmpty
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PagoScreen(carrito: _carrito),
                                        ),
                                      ).then((_) {
                                        _cargarCarrito();
                                        _actualizarContadorCarrito();
                                      });
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Proceder al Pago',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

