import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/producto_model.dart';
import '../../core/notifiers/cart_notifier.dart';
import 'carrito_screen.dart';
import 'productos_categoria_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductoModel producto;

  const ProductDetailScreen({
    super.key,
    required this.producto,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<ProductoModel> _sugerencias = [];
  bool _isLoadingSugerencias = true;
  bool _esFavorito = false;
  int _itemsEnCarrito = 0;
  late final PageController _pageController;
  late final List<String> _imageUrls;
  int _currentImageIndex = 0;
  Set<int> _favoritos = {}; // IDs de productos favoritos

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _imageUrls = _generateImageUrls();
    _cargarSugerencias();
    _verificarFavorito();
    _actualizarContadorCarrito();
    _cargarFavoritos();
    
    // Escuchar cambios en el carrito global
    CartNotifier.instance.addListener(_onCartChanged);
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
  
  bool _esFavoritoProducto(int? productoId) {
    if (productoId == null) return false;
    return _favoritos.contains(productoId);
  }
  
  Future<void> _toggleFavoritoProducto(ProductoModel producto) async {
    if (producto.id == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final favoritosJson = prefs.getString('favoritos_cliente') ?? '';
    final ids = favoritosJson.split(',').where((id) => id.isNotEmpty).toSet();
    
    if (_favoritos.contains(producto.id)) {
      ids.remove(producto.id.toString());
      _favoritos.remove(producto.id);
    } else {
      ids.add(producto.id.toString());
      _favoritos.add(producto.id!);
    }
    
    await prefs.setString('favoritos_cliente', ids.join(','));
    setState(() {});
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_favoritos.contains(producto.id)
              ? '${producto.nombre} agregado a favoritos'
              : '${producto.nombre} eliminado de favoritos'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    CartNotifier.instance.removeListener(_onCartChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    // Actualizar el contador local cuando cambie el carrito global
    if (mounted) {
      setState(() {
        _itemsEnCarrito = CartNotifier.instance.value;
      });
    }
  }

  Future<void> _cargarSugerencias() async {
    try {
      final response = await _apiService.getProductos();
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> productosJson = data['data'];
          final productos = productosJson
              .map((json) => ProductoModel.fromJson(json))
              .where((p) =>
                  p.estado == 'activo' &&
                  p.stockActual > 0 &&
                  p.id != widget.producto.id &&
                  p.categoriaId == widget.producto.categoriaId)
              .toList();
          setState(() {
            _sugerencias = productos.take(6).toList();
            _isLoadingSugerencias = false;
          });
        }
      }
    } catch (e) {
      print('Error al cargar sugerencias: $e');
      setState(() => _isLoadingSugerencias = false);
    }
  }

  Future<void> _verificarFavorito() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritos = prefs.getString('favoritos_cliente') ?? '';
    final ids = favoritos.split(',').where((id) => id.isNotEmpty).toList();
    if (widget.producto.id != null) {
      setState(() {
        _esFavorito = ids.contains(widget.producto.id.toString());
      });
    }
  }

  Future<void> _toggleFavorito() async {
    if (widget.producto.id == null) return;

    final prefs = await SharedPreferences.getInstance();
    final favoritos = prefs.getString('favoritos_cliente') ?? '';
    final ids = favoritos.split(',').where((id) => id.isNotEmpty).toList();

    if (_esFavorito) {
      ids.remove(widget.producto.id.toString());
    } else {
      ids.add(widget.producto.id.toString());
    }

    await prefs.setString('favoritos_cliente', ids.join(','));
    setState(() {
      _esFavorito = !_esFavorito;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_esFavorito
              ? '${widget.producto.nombre} agregado a favoritos'
              : '${widget.producto.nombre} eliminado de favoritos'),
          duration: const Duration(seconds: 2),
        ),
      );
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
      setState(() {
        _itemsEnCarrito = total;
      });
      CartNotifier.instance.updateCount(total);
    } else {
      setState(() => _itemsEnCarrito = 0);
      CartNotifier.instance.updateCount(0);
    }
  }

  Future<void> _agregarAlCarrito(ProductoModel producto) async {
    final prefs = await SharedPreferences.getInstance();
    final carritoJson = prefs.getString('carrito_cliente');
    List<Map<String, dynamic>> carrito = [];

    if (carritoJson != null && carritoJson.isNotEmpty) {
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
    }

    final index = carrito.indexWhere((item) => item['id'] == producto.id);
    if (index >= 0) {
      final cantidadActual = carrito[index]['cantidad'] as int;
      if (cantidadActual < producto.stockActual) {
        carrito[index]['cantidad'] = cantidadActual + 1;
        // Actualizar imagen si no existe o está vacía
        if (carrito[index]['imagen_url'] == null || (carrito[index]['imagen_url'] as String).isEmpty) {
          final imagenUrl = producto.imagenUrl ?? (producto.imagenes != null && producto.imagenes!.isNotEmpty ? producto.imagenes!.first : null);
          carrito[index]['imagen_url'] = imagenUrl;
        }
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
      final imagenUrl = producto.imagenUrl ?? (producto.imagenes != null && producto.imagenes!.isNotEmpty ? producto.imagenes!.first : null);
      carrito.add({
        'id': producto.id,
        'nombre': producto.nombre,
        'precio': producto.precioConDescuento, // Usar precio con descuento si aplica
        'cantidad': 1,
        'stock': producto.stockActual,
        'imagen_url': imagenUrl,
      });
    }

    final carritoString = carrito.map((item) {
      final base = '${item['id']}:${item['nombre']}:${item['precio']}:${item['cantidad']}:${item['stock']}';
      final imagenUrl = item['imagen_url'] as String?;
      return imagenUrl != null && imagenUrl.isNotEmpty ? '$base||$imagenUrl' : base;
    }).join('|');
    await prefs.setString('carrito_cliente', carritoString);

    setState(() {
      _itemsEnCarrito =
          carrito.fold(0, (sum, item) => sum + (item['cantidad'] as int));
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

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;
    final regular = producto.precioVenta; // Precio original sin descuento

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _cargarSugerencias,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageGallery(),
                      _buildPriceSection(producto, regular),
                      _buildDetailSection(producto),
                      _buildSugerenciasSection(
                        titulo: 'Compara y decide',
                        productos: _sugerencias,
                      ),
                      _buildSugerenciasSection(
                        titulo: 'Comprados juntos habitualmente',
                        productos: _sugerencias.reversed.toList(),
                      ),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(producto),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 12),
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Buscar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Corazón de favoritos
          IconButton(
            icon: Icon(
              _esFavorito ? Icons.favorite : Icons.favorite_border,
              color: _esFavorito ? Colors.red : Colors.grey.shade600,
            ),
            onPressed: _toggleFavorito,
          ),
          const SizedBox(width: 4),
          ValueListenableBuilder<int>(
            valueListenable: CartNotifier.instance,
            builder: (context, cartCount, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
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
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          cartCount > 9 ? '9+' : '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    final producto = widget.producto;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${producto.unidadMedida.toUpperCase()} • ${producto.stockActual} disponibles',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            producto.nombre,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemCount: _imageUrls.length,
                    itemBuilder: (_, index) {
                      final url = _imageUrls[index];
                      return GestureDetector(
                        onTap: () => _openImagePreview(index),
                        child: Hero(
                          tag: '${producto.id}_$index',
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.local_pharmacy,
                              size: 120,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.zoom_out_map, color: Colors.white),
                        onPressed: () => _openImagePreview(_currentImageIndex),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _imageUrls.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentImageIndex == index ? 20 : 8,
                decoration: BoxDecoration(
                  color: _currentImageIndex == index
                      ? Colors.green.shade600
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imageUrls.length,
              itemBuilder: (_, index) {
                final url = _imageUrls[index];
                final isSelected = index == _currentImageIndex;
                return GestureDetector(
                  onTap: () => _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  ),
                  child: Container(
                    width: 64,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.green.shade600
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.local_pharmacy,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _generateImageUrls() {
    // Usar todas las imágenes disponibles del producto
    List<String> imagenes = widget.producto.todasLasImagenes;
    
    if (imagenes.isNotEmpty) {
      return imagenes;
    }
    
    // Si no hay imágenes, generar placeholders
    final encodedName = Uri.encodeComponent(widget.producto.nombre);
    return List.generate(
      3,
      (index) =>
          'https://placehold.co/600x600?text=$encodedName+${index + 1}',
    );
  }

  void _openImagePreview(int initialIndex) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = PageController(initialPage: initialIndex);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: PageView.builder(
                  controller: controller,
                  itemCount: _imageUrls.length,
                  onPageChanged: (index) {
                    setState(() => _currentImageIndex = index);
                  },
                  itemBuilder: (_, index) {
                    final url = _imageUrls[index];
                    return InteractiveViewer(
                      child: Hero(
                        tag: '${widget.producto.id}_$index',
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.local_pharmacy,
                            color: Colors.white,
                            size: 120,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceSection(ProductoModel producto, double regular) {
    // Usar el descuento real del producto si existe
    final tieneDescuento = producto.tieneDescuento;
    final precioConDescuento = producto.precioConDescuento;
    final precioOriginal = producto.precioVenta;
    final porcentajeDescuento = producto.descuentoPorcentaje.round();
    final ahorro = tieneDescuento ? (precioOriginal - precioConDescuento) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: tieneDescuento 
              ? [Colors.red.shade50, Colors.white]
              : [Colors.green.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: tieneDescuento 
              ? Colors.red.shade200 
              : Colors.green.shade200,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tieneDescuento) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'OFERTA ESPECIAL',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'S/',
                          style: TextStyle(
                            color: tieneDescuento 
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tieneDescuento 
                              ? precioConDescuento.toStringAsFixed(2)
                              : precioOriginal.toStringAsFixed(2),
                          style: TextStyle(
                            color: tieneDescuento 
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        if (tieneDescuento) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.shade300,
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Text(
                              '-$porcentajeDescuento%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (tieneDescuento) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'Precio regular: ',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'S/ ${precioOriginal.toStringAsFixed(2)}',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.savings,
                              color: Colors.green.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ahorras',
                                    style: TextStyle(
                                      color: Colors.green.shade900,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'S/ ${ahorro.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Precio regular',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildDetailSection(ProductoModel producto) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Detalle del producto',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Text(
              producto.descripcion ??
                  'Producto farmacéutico de alta calidad para tu bienestar. Certificado y aprobado por las autoridades sanitarias correspondientes.',
              style: TextStyle(
                color: Colors.grey.shade800,
                height: 1.6,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Información adicional del producto
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  Icons.inventory_2,
                  'Stock',
                  '${producto.stockActual} disponibles',
                  Colors.blue.shade700,
                  Colors.blue.shade50,
                  Colors.blue.shade200,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoChip(
                  Icons.straighten,
                  'Unidad',
                  producto.unidadMedida.toUpperCase(),
                  Colors.green.shade700,
                  Colors.green.shade50,
                  Colors.green.shade200,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value, Color color, Color backgroundColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSugerenciasSection({
    required String titulo,
    required List<ProductoModel> productos,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!_isLoadingSugerencias)
                TextButton(
                  onPressed: () {
                    if (widget.producto.categoriaId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductosCategoriaScreen(
                            categoriaId: widget.producto.categoriaId!,
                            categoriaNombre:
                                widget.producto.categoriaNombre ?? 'Productos',
                          ),
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Mostrar más'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _isLoadingSugerencias
              ? const Center(child: CircularProgressIndicator())
              : productos.isEmpty
                  ? Text(
                      'No encontramos productos similares por ahora.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    )
                  : SizedBox(
                      height: 240,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: productos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, index) =>
                            _buildSuggestionCard(productos[index]),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(ProductoModel producto) {
    // Usar primera imagen disponible, si no usar placeholder
    final imagenes = producto.todasLasImagenes;
    final thumbUrl = imagenes.isNotEmpty
        ? imagenes[0]
        : 'https://placehold.co/400x400?text=${Uri.encodeComponent(producto.nombre)}';
    final esFavorito = _esFavoritoProducto(producto.id);
    
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
        width: 190,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 85,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F5E9), Color(0xFFFFFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        thumbUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.local_pharmacy,
                          color: Colors.green.shade700,
                          size: 48,
                        ),
                      ),
                    ),
                    // Botón de favoritos (corazón)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: esFavorito ? Colors.red.shade300 : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: esFavorito ? Colors.red.shade50 : Colors.white,
                        ),
                        child: IconButton(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          icon: Icon(
                            esFavorito ? Icons.favorite : Icons.favorite_border,
                            color: esFavorito ? Colors.red.shade600 : Colors.grey.shade600,
                            size: 18,
                          ),
                          onPressed: () {
                            _toggleFavoritoProducto(producto);
                          },
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          producto.tieneDescuento
                              ? 'S/ ${producto.precioConDescuento.toStringAsFixed(2)}'
                              : 'S/ ${producto.precioVenta.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                producto.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Botón agregar al carrito
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: producto.stockActual > 0
                    ? () => _agregarAlCarrito(producto)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                  minimumSize: const Size(0, 28),
                ),
                child: const Text(
                  'Agregar',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(ProductoModel producto) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: producto.stockActual > 0
                ? () => _agregarAlCarrito(producto)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Agregar al carrito',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

