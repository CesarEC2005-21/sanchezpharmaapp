import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/categoria_model.dart';
import '../../core/utils/error_message_helper.dart';
import '../widgets/cliente_bottom_nav.dart';
import 'carrito_screen.dart';
import 'product_detail_screen.dart';

class ProductosCategoriaScreen extends StatefulWidget {
  final int categoriaId;
  final String categoriaNombre;

  const ProductosCategoriaScreen({
    super.key,
    required this.categoriaId,
    required this.categoriaNombre,
  });

  @override
  State<ProductosCategoriaScreen> createState() => _ProductosCategoriaScreenState();
}

class _ProductosCategoriaScreenState extends State<ProductosCategoriaScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<ProductoModel> _productos = [];
  List<ProductoModel> _productosFiltrados = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  int _itemsEnCarrito = 0;
  String _ordenSeleccionado = 'relevancia'; // relevancia, precio_asc, precio_desc, nombre_asc
  Set<int> _favoritos = {}; // IDs de productos favoritos

  @override
  void initState() {
    super.initState();
    _cargarFavoritos();
    _cargarProductos();
    _actualizarContadorCarrito();
    _searchController.addListener(_aplicarFiltros);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarFavoritos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritosJson = prefs.getString('favoritos_cliente');
      if (favoritosJson != null && favoritosJson.isNotEmpty) {
        final ids = favoritosJson.split(',').where((id) => id.isNotEmpty).map((id) => int.tryParse(id)).whereType<int>().toSet();
        setState(() {
          _favoritos = ids;
        });
      }
    } catch (e) {
      print('Error al cargar favoritos: $e');
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
          
          // Debug: imprimir información de categoría
          print('🔍 Buscando productos de categoría ID: ${widget.categoriaId}');
          print('📦 Total de productos recibidos: ${productosJson.length}');
          
          final todosProductos = productosJson.map((json) => ProductoModel.fromJson(json)).toList();
          
          // Debug: mostrar algunos productos y sus categorías
          if (todosProductos.isNotEmpty) {
            print('📋 Primeros productos y sus categorías:');
            for (var i = 0; i < (todosProductos.length > 5 ? 5 : todosProductos.length); i++) {
              final p = todosProductos[i];
              print('   - ${p.nombre}: categoriaId=${p.categoriaId}, estado=${p.estado}, stock=${p.stockActual}');
            }
          }
          
          setState(() {
            _productos = todosProductos.where((p) {
              final esActivo = p.estado == 'activo';
              final tieneStock = p.stockActual > 0;
              final categoriaCoincide = p.categoriaId != null && p.categoriaId == widget.categoriaId;
              
              return esActivo && tieneStock && categoriaCoincide;
            }).toList();
            
            print('✅ Productos filtrados para categoría ${widget.categoriaId}: ${_productos.length}');
            
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

  void _aplicarFiltros() {
    setState(() {
      List<ProductoModel> productosFiltrados = _productos.where((producto) {
        final coincideBusqueda = _searchController.text.isEmpty ||
            producto.nombre.toLowerCase().contains(_searchController.text.toLowerCase());
        return coincideBusqueda;
      }).toList();

      // Aplicar ordenamiento
      switch (_ordenSeleccionado) {
        case 'precio_asc':
          productosFiltrados.sort((a, b) => a.precioVenta.compareTo(b.precioVenta));
          break;
        case 'precio_desc':
          productosFiltrados.sort((a, b) => b.precioVenta.compareTo(a.precioVenta));
          break;
        case 'nombre_asc':
          productosFiltrados.sort((a, b) => a.nombre.compareTo(b.nombre));
          break;
        default: // relevancia
          // Mantener orden original
          break;
      }

      _productosFiltrados = productosFiltrados;
    });
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
      } else {
        if (mounted) {
          setState(() {
            _itemsEnCarrito = 0;
          });
        }
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
        'precio': producto.precioConDescuento, // Usar precio con descuento si aplica
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

  void _mostrarDialogoOrdenar() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ordenar por',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildOpcionOrden('relevancia', 'Relevancia', Icons.star),
            _buildOpcionOrden('precio_asc', 'Precio: Menor a Mayor', Icons.arrow_upward),
            _buildOpcionOrden('precio_desc', 'Precio: Mayor a Menor', Icons.arrow_downward),
            _buildOpcionOrden('nombre_asc', 'Nombre: A-Z', Icons.sort_by_alpha),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcionOrden(String valor, String titulo, IconData icono) {
    final estaSeleccionado = _ordenSeleccionado == valor;
    return ListTile(
      leading: Icon(icono, color: estaSeleccionado ? Colors.green.shade700 : Colors.grey),
      title: Text(titulo),
      trailing: estaSeleccionado
          ? Icon(Icons.check, color: Colors.green.shade700)
          : null,
      onTap: () {
        setState(() {
          _ordenSeleccionado = valor;
        });
        _aplicarFiltros();
        Navigator.pop(context);
      },
    );
  }

  String _obtenerTextoOrden() {
    switch (_ordenSeleccionado) {
      case 'precio_asc':
        return 'Precio: Menor a Mayor';
      case 'precio_desc':
        return 'Precio: Mayor a Menor';
      case 'nombre_asc':
        return 'Nombre: A-Z';
      default:
        return 'Relevancia';
    }
  }

  Future<void> _toggleFavorito(ProductoModel producto) async {
    if (producto.id == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final esFavorito = _favoritos.contains(producto.id);

      if (esFavorito) {
        _favoritos.remove(producto.id);
      } else {
        _favoritos.add(producto.id!);
      }

      // Guardar favoritos
      final favoritosString = _favoritos.map((id) => id.toString()).join(',');
      await prefs.setString('favoritos_cliente', favoritosString);

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(esFavorito 
                ? '${producto.nombre} eliminado de favoritos' 
                : '${producto.nombre} agregado a favoritos'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error al guardar favorito: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar favoritos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _esFavorito(int? productoId) {
    if (productoId == null) return false;
    return _favoritos.contains(productoId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: ClienteBottomNav(currentIndex: 1),
      body: SafeArea(
        child: Column(
          children: [
            // Header con barra de búsqueda y carrito
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.black87,
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar',
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 20, color: Colors.grey.shade600),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.shopping_cart, color: Colors.green.shade700),
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
                            decoration: const BoxDecoration(
                              color: Colors.blue,
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
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Botones de Filtrar y Ordenar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implementar filtros avanzados
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Funcionalidad de filtros próximamente')),
                        );
                      },
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('Filtrar por'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        side: BorderSide(color: Colors.green.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _mostrarDialogoOrdenar,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Ordenar por'),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Resumen de resultados
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                "Encontramos ${_productosFiltrados.length} productos para '${widget.categoriaNombre}'",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
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
                              Text(ErrorMessageHelper.getFriendlyErrorMessage(_errorMessage!)),
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
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _productosFiltrados.length,
                                itemBuilder: (context, index) {
                                  final producto = _productosFiltrados[index];
                                  return _buildProductoCard(producto);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductoImagen(ProductoModel producto) {
    final imagenes = producto.todasLasImagenes;
    if (imagenes.isNotEmpty) {
      return Image.network(
        imagenes[0],
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.medication,
            size: 50,
            color: Colors.green.shade700,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }
    return Icon(
      Icons.medication,
      size: 50,
      color: Colors.green.shade700,
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
                    child: _buildProductoImagen(producto),
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
                            children: [
                              Icon(Icons.add, size: 14, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  producto.proveedorNombre!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                  icon: Icon(
                    _esFavorito(producto.id) ? Icons.favorite : Icons.favorite_border,
                    color: _esFavorito(producto.id) ? Colors.red : Colors.grey.shade600,
                  ),
                  onPressed: () => _toggleFavorito(producto),
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

