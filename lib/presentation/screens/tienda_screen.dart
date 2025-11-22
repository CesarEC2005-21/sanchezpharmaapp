import 'package:flutter/material.dart';
import 'package:retrofit/retrofit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/categoria_model.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../widgets/cliente_drawer.dart';
import 'carrito_screen.dart';
import 'login_screen.dart';

class TiendaScreen extends StatefulWidget {
  const TiendaScreen({super.key});

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<ProductoModel> _productos = [];
  List<CategoriaModel> _categorias = [];
  List<ProductoModel> _productosFiltrados = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String? _categoriaSeleccionada;
  int _itemsEnCarrito = 0;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _cargarDatos();
    _actualizarContadorCarrito();
  }

  Future<void> _loadUserData() async {
    final username = await SharedPrefsHelper.getUsername();
    setState(() {
      _username = username ?? 'Cliente';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    await Future.wait([
      _cargarProductos(),
      _cargarCategorias(),
    ]);
  }

  Future<void> _cargarCategorias() async {
    try {
      final response = await _apiService.getCategorias();
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> categoriasJson = data['data'];
          setState(() {
            _categorias = categoriasJson
                .map((json) => CategoriaModel.fromJson(json))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error al cargar categorías: $e');
    }
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getProductos();

      if (response.response.statusCode == 200) {
        final data = response.data;

        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> productosJson = data['data'];
          setState(() {
            _productos = productosJson
                .map((json) => ProductoModel.fromJson(json))
                .where((p) => p.estado == 'activo' && p.stockActual > 0)
                .toList();
            _aplicarFiltros();
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

  void _aplicarFiltros() {
    setState(() {
      _productosFiltrados = _productos.where((producto) {
        final coincideBusqueda = _searchController.text.isEmpty ||
            producto.nombre.toLowerCase().contains(_searchController.text.toLowerCase());
        final coincideCategoria = _categoriaSeleccionada == null ||
            producto.categoriaId.toString() == _categoriaSeleccionada;
        return coincideBusqueda && coincideCategoria;
      }).toList();
    });
  }

  Future<void> _actualizarContadorCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    final carritoJson = prefs.getString('carrito_cliente');
    if (carritoJson != null) {
      try {
        // Parsear JSON del carrito
        final carrito = (carritoJson.split(',').map((e) {
          // Implementación simple - en producción usar JSON
          return <String, dynamic>{};
        }).toList());
        setState(() {
          _itemsEnCarrito = 0; // Se actualizará cuando se agregue un item
        });
      } catch (e) {
        print('Error al leer carrito: $e');
      }
    }
  }

  Future<void> _agregarAlCarrito(ProductoModel producto) async {
    final prefs = await SharedPreferences.getInstance();
    final carritoJson = prefs.getString('carrito_cliente');
    List<Map<String, dynamic>> carrito = [];
    
    if (carritoJson != null && carritoJson.isNotEmpty) {
      try {
        // Por simplicidad, usamos un formato simple
        // En producción, usar JSON serialization
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

    // Guardar carrito (formato simple)
    final carritoString = carrito.map((item) {
      return '${item['id']}:${item['nombre']}:${item['precio']}:${item['cantidad']}:${item['stock']}';
    }).join('|');
    await prefs.setString('carrito_cliente', carritoString);
    
    setState(() {
      _itemsEnCarrito = carrito.fold(0, (sum, item) => sum + (item['cantidad'] as int));
    });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: ClienteDrawer(
        username: _username,
        onLogout: _handleLogout,
      ),
      appBar: AppBar(
        title: const Text('Tienda Sánchez Pharma'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          Stack(
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
              if (_itemsEnCarrito > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_itemsEnCarrito',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _aplicarFiltros();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (_) => _aplicarFiltros(),
            ),
          ),
          // Filtro de categorías
          if (_categorias.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _categorias.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Todas'),
                        selected: _categoriaSeleccionada == null,
                        onSelected: (selected) {
                          setState(() {
                            _categoriaSeleccionada = null;
                            _aplicarFiltros();
                          });
                        },
                      ),
                    );
                  }
                  final categoria = _categorias[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(categoria.nombre),
                      selected: _categoriaSeleccionada == categoria.id.toString(),
                      onSelected: (selected) {
                        setState(() {
                          _categoriaSeleccionada = selected ? categoria.id.toString() : null;
                          _aplicarFiltros();
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          // Lista de productos
          Expanded(
            child: _isLoading
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
                              onPressed: _cargarProductos,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _productosFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                const Text(
                                  'No hay productos disponibles',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _cargarProductos,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.7,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _productosFiltrados.length,
                              itemBuilder: (context, index) {
                                final producto = _productosFiltrados[index];
                                return Card(
                                  elevation: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(4),
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.medication,
                                              size: 50,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              producto.nombre,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'S/ ${producto.precioVenta.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Stock: ${producto.stockActual}',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: producto.stockActual > 0
                                                    ? () => _agregarAlCarrito(producto)
                                                    : null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green.shade700,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: const Text('Agregar'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

