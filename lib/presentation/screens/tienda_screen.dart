import 'package:flutter/material.dart';
import 'package:retrofit/retrofit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/categoria_model.dart';
import '../../data/models/banner_model.dart';
import '../../core/utils/shared_prefs_helper.dart';
import 'carrito_screen.dart';
import 'login_screen.dart';
import 'productos_categoria_screen.dart';
import 'mis_direcciones_screen.dart';
import 'dart:async';

class TiendaScreen extends StatefulWidget {
  final bool showBottomNav;
  final int? categoriaIdInicial;

  const TiendaScreen({
    super.key,
    this.showBottomNav = true,
    this.categoriaIdInicial,
  });

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<ProductoModel> _productos = [];
  List<CategoriaModel> _categorias = [];
  List<ProductoModel> _productosFiltrados = [];
  List<BannerModel> _banners = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String? _categoriaSeleccionada;
  int _itemsEnCarrito = 0;
  String _username = '';
  String _ordenSeleccionado = 'relevancia'; // relevancia, precio_asc, precio_desc, nombre_asc
  Set<int> _favoritos = {}; // IDs de productos favoritos
  final PageController _bannerPageController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _cargarFavoritos();
    _cargarDatosIniciales(); // Cargar categorías y banners
    _actualizarContadorCarrito();
    _searchController.addListener(_aplicarFiltros);
    _iniciarCarruselAutomatico();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _isLoading = true;
    });
    
    await Future.wait([
      _cargarCategorias(),
      _cargarBanners(),
    ]);
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadUserData() async {
    final username = await SharedPrefsHelper.getUsername();
    setState(() {
      _username = username ?? 'Cliente';
    });
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

  @override
  void dispose() {
    _searchController.dispose();
    _bannerPageController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    // Cargar productos solo cuando se necesiten (búsqueda o categoría seleccionada)
    await _cargarCategorias();
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

  Future<void> _cargarBanners() async {
    try {
      print('🎯 Iniciando carga de banners...');
      final response = await _apiService.getBannersActivos();
      print('📡 Respuesta recibida: ${response.response.statusCode}');
      
      if (response.response.statusCode == 200) {
        final data = response.data;
        print('📦 Data: $data');
        
        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> bannersJson = data['data'];
          print('🎨 Banners JSON count: ${bannersJson.length}');
          
          final List<BannerModel> bannersList = [];
          for (var json in bannersJson) {
            try {
              final banner = BannerModel.fromJson(json);
              if (banner.estaActivo) {
                bannersList.add(banner);
              }
            } catch (e) {
              print('❌ Error parseando banner individual: $e');
              print('   JSON: $json');
            }
          }
          
          setState(() {
            _banners = bannersList;
            _banners.sort((a, b) => a.orden.compareTo(b.orden));
          });
          
          print('✅ Banners cargados exitosamente: ${_banners.length}');
        } else {
          print('⚠️ Respuesta sin banners o código != 1');
        }
      } else {
        print('❌ Error HTTP: ${response.response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Error al cargar banners: $e');
      print('Stack trace: $stackTrace');
      // No mostramos error al usuario, simplemente no mostramos banners
      setState(() {
        _banners = []; // Asegurar que esté vacío si hay error
      });
    }
  }

  void _iniciarCarruselAutomatico() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_banners.isEmpty || !_bannerPageController.hasClients) return;
      
      if (_currentBannerIndex < _banners.length - 1) {
        _currentBannerIndex++;
      } else {
        _currentBannerIndex = 0;
      }
      
      _bannerPageController.animateToPage(
        _currentBannerIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
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
    // Si hay texto de búsqueda y no se han cargado productos, cargarlos
    if (_searchController.text.isNotEmpty && _productos.isEmpty) {
      _cargarProductos();
      return;
    }

    setState(() {
      List<ProductoModel> productosFiltrados = _productos.where((producto) {
        final coincideBusqueda = _searchController.text.isEmpty ||
            producto.nombre.toLowerCase().contains(_searchController.text.toLowerCase());
        final coincideCategoria = _categoriaSeleccionada == null ||
            producto.categoriaId.toString() == _categoriaSeleccionada;
        return coincideBusqueda && coincideCategoria;
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

  Widget _buildFilterChip(String emoji, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Implementar filtros específicos
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Filtro: $label')),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriasGrid() {
    if (_categorias.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.category_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'No hay categorías disponibles',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _categorias.where((c) => c.estado == 'activo').length,
      itemBuilder: (context, index) {
        final categoria = _categorias.where((c) => c.estado == 'activo').toList()[index];
        return _buildCategoriaCard(categoria);
      },
    );
  }

  Widget _buildCategoriaCard(CategoriaModel categoria) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductosCategoriaScreen(
                categoriaId: categoria.id!,
                categoriaNombre: categoria.nombre,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade50,
                Colors.green.shade100,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getCategoryIcon(categoria.nombre),
                size: 40,
                color: Colors.green.shade700,
              ),
              const SizedBox(height: 8),
              Text(
                categoria.nombre,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade900,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? categoria) {
    if (categoria == null) return Icons.category;
    
    final catLower = categoria.toLowerCase();
    if (catLower.contains('farmacia') || catLower.contains('medicamento')) {
      return Icons.medication;
    } else if (catLower.contains('salud') || catLower.contains('health')) {
      return Icons.health_and_safety;
    } else if (catLower.contains('bebé') || catLower.contains('mama')) {
      return Icons.child_care;
    } else if (catLower.contains('nutrición') || catLower.contains('vitamina')) {
      return Icons.restaurant;
    } else if (catLower.contains('dermato') || catLower.contains('cosmét')) {
      return Icons.face;
    } else if (catLower.contains('personal') || catLower.contains('cuidado')) {
      return Icons.spa;
    } else if (catLower.contains('precio') || catLower.contains('oferta')) {
      return Icons.local_offer;
    } else if (catLower.contains('pack')) {
      return Icons.inventory_2;
    } else {
      return Icons.category;
    }
  }

  Widget _buildBannerCard(BannerModel banner) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen del banner
            Image.network(
              banner.imagenUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.green.shade700,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported, size: 50, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          banner.titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (banner.descripcion != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              banner.descripcion!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            ),
            // Overlay interactivo
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (banner.enlace != null && banner.enlace!.isNotEmpty) {
                    // TODO: Navegar al enlace del banner
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Banner: ${banner.titulo}')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header con dirección y carrito
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
                  // Información de ubicación (clickeable)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        // Abrir selector de direcciones
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MisDireccionesScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'Ingresa tu dirección de entrega',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Carrito
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.shopping_cart, color: Colors.blue.shade700),
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
                      if (_itemsEnCarrito > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              '$_itemsEnCarrito',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
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

            // Barra de búsqueda mejorada
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '¿Qué buscaremos hoy?',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

            // Chips de filtros rápidos
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip('🔴', 'Últimas unidades'),
                  const SizedBox(width: 8),
                  _buildFilterChip('🎫', 'Sorteo Casa Millón'),
                  const SizedBox(width: 8),
                  _buildFilterChip('🏷️', 'Ofertas'),
                  const SizedBox(width: 8),
                  _buildFilterChip('⭐', 'Populares'),
                ],
              ),
            ),

            // Carrusel de banners
            if (_banners.isNotEmpty)
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _bannerPageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentBannerIndex = index;
                        });
                      },
                      itemCount: _banners.length,
                      itemBuilder: (context, index) {
                        final banner = _banners[index];
                        return _buildBannerCard(banner);
                      },
                    ),
                    // Indicadores de página
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _banners.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentBannerIndex == index
                                  ? Colors.green.shade700
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Texto de advertencia médica
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Todos los productos farmacéuticos y dispositivos médicos son distribuidos por Sánchez Pharma (Ley 32033)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

            // Sección de Categorías
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
                      : _searchController.text.isNotEmpty
                          // Si hay búsqueda activa, mostrar resultados de productos
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Resultados: ${_productosFiltrados.length}",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: _mostrarDialogoOrdenar,
                                        icon: const Icon(Icons.sort, size: 20),
                                        label: const Text('Ordenar'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: _productosFiltrados.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                                              const SizedBox(height: 16),
                                              const Text(
                                                'No se encontraron productos',
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
                            )
                          // Si NO hay búsqueda, mostrar solo categorías (sin productos)
                          : RefreshIndicator(
                              onRefresh: _cargarDatos,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Título de sección
                                    const Text(
                                      '¿Qué estás buscando?',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Grid de categorías
                                    _buildCategoriasGrid(),
                                    
                                    const SizedBox(height: 24),
                                    
                                    // Mensaje para buscar productos
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.green.shade200),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.search,
                                            size: 48,
                                            color: Colors.green.shade700,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            '¡Encuentra lo que necesitas!',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade900,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Selecciona una categoría o usa el buscador para ver nuestros productos',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductoCard(ProductoModel producto) {
    final stockBajo = producto.stockActual <= producto.stockMinimo;
    
    return Container(
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
                              Icon(Icons.store, size: 14, color: Colors.blue.shade700),
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
    );
  }
}

