import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/producto_model.dart';
import '../../core/notifiers/cart_notifier.dart';
import '../widgets/cliente_bottom_nav.dart';
import 'carrito_screen.dart';
import 'product_detail_screen.dart';

class FavoritosClienteScreen extends StatefulWidget {
  const FavoritosClienteScreen({super.key});

  @override
  State<FavoritosClienteScreen> createState() => _FavoritosClienteScreenState();
}

class _FavoritosClienteScreenState extends State<FavoritosClienteScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<ProductoModel> _productosFavoritos = [];
  Set<int> _favoritos = {};
  bool _isLoading = true;
  String? _errorMessage;
  int _itemsEnCarrito = 0;

  @override
  void initState() {
    super.initState();
    _cargarFavoritos();
    _actualizarContadorCarrito();
  }

  Future<void> _cargarFavoritos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Cargar IDs de favoritos desde SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final favoritosJson = prefs.getString('favoritos_cliente');
      
      if (favoritosJson == null || favoritosJson.isEmpty) {
        setState(() {
          _favoritos = {};
          _productosFavoritos = [];
          _isLoading = false;
        });
        return;
      }

      final ids = favoritosJson.split(',').where((id) => id.isNotEmpty).map((id) => int.tryParse(id)).whereType<int>().toSet();
      _favoritos = ids;

      if (_favoritos.isEmpty) {
        setState(() {
          _productosFavoritos = [];
          _isLoading = false;
        });
        return;
      }

      // Cargar todos los productos desde la API
      final response = await _apiService.getProductos();

      if (response.response.statusCode == 200) {
        final data = response.data;

        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> productosJson = data['data'];
          final todosProductos = productosJson.map((json) => ProductoModel.fromJson(json)).toList();

          // Filtrar solo los productos que están en favoritos
          setState(() {
            _productosFavoritos = todosProductos.where((producto) {
              return producto.id != null && 
                     _favoritos.contains(producto.id) &&
                     producto.estado == 'activo';
            }).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Error al cargar productos';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error de conexión';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _actualizarContadorCarrito() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final carritoJson = prefs.getString('carrito_cliente');
      if (carritoJson != null && carritoJson.isNotEmpty) {
        final items = carritoJson.split('|');
        int totalItems = 0;
        for (var item in items) {
          if (item.isNotEmpty) {
            final parts = item.split(':');
            if (parts.length >= 4) {
              totalItems += int.parse(parts[3]);
            }
          }
        }
        if (mounted) {
          setState(() {
            _itemsEnCarrito = totalItems;
          });
        }
        CartNotifier.instance.updateCount(totalItems);
      } else {
        if (mounted) {
          setState(() {
            _itemsEnCarrito = 0;
          });
        }
        CartNotifier.instance.updateCount(0);
      }
    } catch (e) {
      print('Error al actualizar contador de carrito: $e');
    }
  }

  Future<void> _agregarAlCarrito(ProductoModel producto) async {
    final prefs = await SharedPreferences.getInstance();
    final carritoJson = prefs.getString('carrito_cliente');
    List<Map<String, dynamic>> carrito = [];
    
    if (carritoJson != null && carritoJson.isNotEmpty) {
      try {
        final items = carritoJson.split('|');
        for (var item in items) {
          if (item.isNotEmpty) {
            final parts = item.split(':');
            if (parts.length >= 4) {
              carrito.add({
                'id': int.parse(parts[0]),
                'nombre': parts[1],
                'precio': double.parse(parts[2]),
                'cantidad': int.parse(parts[3]),
                'stock': int.parse(parts.length > 4 ? parts[4] : '0'),
              });
            }
          }
        }
      } catch (e) {
        print('Error al parsear carrito: $e');
      }
    }

    // Agregar o actualizar producto en el carrito
    final index = carrito.indexWhere((item) => item['id'] == producto.id);
    if (index >= 0) {
      final cantidadActual = carrito[index]['cantidad'] as int;
      if (cantidadActual < producto.stockActual) {
        carrito[index]['cantidad'] = cantidadActual + 1;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay suficiente stock disponible'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } else {
      carrito.add({
        'id': producto.id,
        'nombre': producto.nombre,
        'precio': producto.precioVenta,
        'cantidad': 1,
        'stock': producto.stockActual,
      });
    }

    // Guardar carrito
    final carritoString = carrito.map((item) {
      return '${item['id']}:${item['nombre']}:${item['precio']}:${item['cantidad']}:${item['stock']}';
    }).join('|');
    await prefs.setString('carrito_cliente', carritoString);
    
    setState(() {
      _itemsEnCarrito = carrito.fold(0, (sum, item) => sum + (item['cantidad'] as int));
    });
    CartNotifier.instance.updateCount(_itemsEnCarrito);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${producto.nombre} agregado al carrito'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Ver carrito',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CarritoScreen(),
                ),
              ).then((_) => _actualizarContadorCarrito());
            },
          ),
        ),
      );
    }
  }

  Future<void> _eliminarFavorito(ProductoModel producto) async {
    if (producto.id == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _favoritos.remove(producto.id);

      // Guardar favoritos actualizados
      final favoritosString = _favoritos.map((id) => id.toString()).join(',');
      await prefs.setString('favoritos_cliente', favoritosString);

      // Actualizar lista de productos
      setState(() {
        _productosFavoritos.removeWhere((p) => p.id == producto.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${producto.nombre} eliminado de favoritos'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error al eliminar favorito: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar favorito'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const ClienteBottomNav(currentIndex: 2),
      appBar: AppBar(
        title: const Text('Mis Favoritos'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: CartNotifier.instance,
            builder: (context, cartCount, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CarritoScreen(),
                        ),
                      ).then((_) => _actualizarContadorCarrito());
                    },
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          cartCount > 9 ? '9+' : '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
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
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarFavoritos,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _productosFavoritos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No tienes productos favoritos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agrega productos a favoritos para verlos aquí',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.shopping_bag),
                            label: const Text('Explorar productos'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarFavoritos,
                      child: Column(
                        children: [
                          // Resumen
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Tienes ${_productosFavoritos.length} producto${_productosFavoritos.length != 1 ? 's' : ''} en favoritos',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          // Lista de productos
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _productosFavoritos.length,
                              itemBuilder: (context, index) {
                                final producto = _productosFavoritos[index];
                                return _buildProductoCard(producto);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildProductoCard(ProductoModel producto) {
    final stockBajo = producto.stockActual <= producto.stockMinimo;
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(producto: producto),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Banner de stock bajo
          if (stockBajo && producto.stockActual > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Text(
                'Quedan ${producto.stockActual} en stock',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          
          // Contenido del producto
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del producto
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Icon(
                      Icons.medication,
                      size: 50,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Información del producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Presentación
                      if (producto.unidadMedida.isNotEmpty)
                        Text(
                          producto.unidadMedida.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 4),
                      
                      // Nombre del producto
                      Text(
                        producto.nombre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      // Vendedor/Proveedor
                      if (producto.proveedorNombre != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 14, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Text(
                                producto.proveedorNombre!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      
                      // Precio
                      Row(
                        children: [
                          Text(
                            'S/ ${producto.precioVenta.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Precio regular',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Botones de acción
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: producto.stockActual > 0
                        ? () => _agregarAlCarrito(producto)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Agregar al carrito',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () => _eliminarFavorito(producto),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}

