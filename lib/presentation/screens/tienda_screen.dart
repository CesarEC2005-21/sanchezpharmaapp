import 'package:flutter/material.dart';
import 'package:retrofit/retrofit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/categoria_model.dart';
import '../../data/models/banner_model.dart';
import 'package:dio/dio.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/utils/error_message_helper.dart';
import '../../core/notifiers/cart_notifier.dart';
import 'carrito_screen.dart';
import 'login_screen.dart';
import 'productos_categoria_screen.dart';
import 'mis_direcciones_screen.dart';
import 'product_detail_screen.dart';
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
  
  // Listas para productos destacados
  List<ProductoModel> _productosEnOferta = [];
  List<ProductoModel> _productosPopulares = [];
  List<ProductoModel> _productosUltimasUnidades = [];
  
  // Estado del filtro seleccionado
  String? _filtroSeleccionado; // 'ultimas_unidades', 'ofertas', 'populares', 'sorteo'

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _cargarFavoritos();
    _cargarDatosIniciales(); // Cargar categorías y banners
    _actualizarContadorCarrito();
    _searchController.addListener(_aplicarFiltros);
    _iniciarCarruselAutomatico();
    
    // Escuchar cambios en el carrito global
    CartNotifier.instance.addListener(_onCartChanged);
  }


  void _onCartChanged() {
    // Actualizar el contador local cuando cambie el carrito global
    if (mounted) {
      setState(() {
        _itemsEnCarrito = CartNotifier.instance.value;
      });
    }
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _isLoading = true;
    });
    
    await Future.wait([
      _cargarCategorias(),
      _cargarBanners(),
      _cargarProductos(), // Cargar productos al inicio para mostrar destacados
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
    CartNotifier.instance.removeListener(_onCartChanged);
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
      // Manejar errores silenciosamente para categorías (no crítico)
      print('Error al cargar categorías: $e');
      // No mostrar error al usuario, simplemente no mostrar categorías
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
          final productosCargados = productosJson
              .map((json) => ProductoModel.fromJson(json))
              .where((p) => p.estado == 'activo' && p.stockActual > 0)
              .toList();
          
          setState(() {
            _productos = productosCargados;
            
            // Productos en oferta (con descuento)
            _productosEnOferta = productosCargados
                .where((p) => p.tieneDescuento)
                .take(10)
                .toList();
            
            // Productos populares (más vendidos o con mejor precio)
            _productosPopulares = productosCargados
                .where((p) => !p.tieneDescuento)
                .take(10)
                .toList();
            
            // Últimas unidades (stock bajo)
            _productosUltimasUnidades = productosCargados
                .where((p) => p.stockActual <= p.stockMinimo && p.stockActual > 0)
                .take(10)
                .toList();
            
            _aplicarFiltros();
            _isLoading = false;
          });
        } else {
          // Usar mensaje del servidor o mensaje amigable por defecto
          final serverMessage = data['message'] ?? 'Error al cargar productos';
          setState(() {
            _errorMessage = serverMessage;
            _isLoading = false;
          });
        }
      } else {
        // Si el status code no es 200, usar mensaje amigable
        final friendlyMessage = ErrorMessageHelper.getFriendlyErrorMessage(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.badResponse,
            response: response.response,
          ),
        );
        setState(() {
          _errorMessage = friendlyMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      // IMPORTANTE: El interceptor ya debería haber convertido el error en uno amigable
      // Pero por si acaso, usar helper para obtener mensaje amigable
      final friendlyMessage = ErrorMessageHelper.getFriendlyErrorMessage(e);
      setState(() {
        _errorMessage = friendlyMessage;
        _isLoading = false;
      });
      
      // Solo mostrar SnackBar si NO es un error 401 (el interceptor ya lo maneja)
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
    // Si hay texto de búsqueda y no se han cargado productos, cargarlos
    if (_searchController.text.isNotEmpty && _productos.isEmpty) {
      _cargarProductos();
      return;
    }

    setState(() {
      // Si hay un filtro seleccionado, aplicar ese filtro primero
      List<ProductoModel> productosBase = _productos;
      
      if (_filtroSeleccionado == 'ultimas_unidades') {
        productosBase = _productosUltimasUnidades;
      } else if (_filtroSeleccionado == 'ofertas') {
        productosBase = _productosEnOferta;
      } else if (_filtroSeleccionado == 'populares') {
        productosBase = _productosPopulares;
      }
      
      List<ProductoModel> productosFiltrados = productosBase.where((producto) {
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
        'precio': producto.precioConDescuento, // Usar precio con descuento si aplica
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

  void _mostrarDialogoOrdenar() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ResponsiveHelper.spacing(context))),
      ),
      builder: (context) => Container(
        padding: ResponsiveHelper.formPadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ordenar por',
              style: TextStyle(
                fontSize: ResponsiveHelper.subtitleFontSize(context) + 4,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.spacing(context)),
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
      leading: Icon(
        icono,
        color: estaSeleccionado ? Colors.green.shade700 : Colors.grey,
        size: ResponsiveHelper.iconSize(context),
      ),
      title: Text(
        titulo,
        style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
      ),
      trailing: estaSeleccionado
          ? Icon(Icons.check, color: Colors.green.shade700, size: ResponsiveHelper.iconSize(context))
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
    String? filtroKey;
    if (label == 'Últimas unidades') {
      filtroKey = 'ultimas_unidades';
    } else if (label == 'Ofertas') {
      filtroKey = 'ofertas';
    } else if (label == 'Populares') {
      filtroKey = 'populares';
    } else if (label == 'Sorteo Casa Millón') {
      filtroKey = 'sorteo';
    }
    
    final isSelected = _filtroSeleccionado == filtroKey;
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade600 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? Colors.green.shade300.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 8 : 2,
            offset: Offset(0, isSelected ? 3 : 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              // Establecer filtro seleccionado
              if (_filtroSeleccionado == filtroKey) {
                _filtroSeleccionado = null; // Deseleccionar si ya está seleccionado
                _productosFiltrados = _productos;
              } else {
                _filtroSeleccionado = filtroKey;
                
                // Filtrar productos según el chip seleccionado
                if (label == 'Últimas unidades') {
                  _productosFiltrados = _productosUltimasUnidades;
                } else if (label == 'Ofertas') {
                  _productosFiltrados = _productosEnOferta;
                } else if (label == 'Populares') {
                  _productosFiltrados = _productosPopulares;
                } else if (label == 'Sorteo Casa Millón') {
                  // Mostrar mensaje del sorteo
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Próximamente! Participa en nuestro sorteo especial'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return; // No cambiar productos
                }
                
                _categoriaSeleccionada = null;
              }
              
              // Si hay búsqueda activa, mantenerla
              if (_searchController.text.isNotEmpty) {
                _aplicarFiltros();
              }
            });
            
            // Mostrar productos si no hay búsqueda activa
            if (_searchController.text.isEmpty && _productos.isEmpty) {
              _cargarProductos();
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.spacing(context),
              vertical: ResponsiveHelper.spacing(context) / 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji, 
                  style: TextStyle(
                    fontSize: ResponsiveHelper.bodyFontSize(context),
                    color: isSelected ? Colors.white : null,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.spacing(context) / 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.bodyFontSize(context) - 1,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
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
        padding: ResponsiveHelper.formPadding(context),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.category_outlined,
                size: ResponsiveHelper.isSmallScreen(context) ? 40 : 48,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: ResponsiveHelper.spacing(context) / 2),
              Text(
                'No hay categorías disponibles',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: ResponsiveHelper.bodyFontSize(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.gridCrossAxisCount(context),
        childAspectRatio: ResponsiveHelper.isSmallScreen(context) ? 1.2 : 1.35,
        crossAxisSpacing: ResponsiveHelper.spacing(context) / 2,
        mainAxisSpacing: ResponsiveHelper.spacing(context) / 2,
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
          padding: EdgeInsets.all(
            ResponsiveHelper.isSmallScreen(context)
              ? ResponsiveHelper.spacing(context) / 3
              : ResponsiveHelper.spacing(context) / 2
          ),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Icon(
                  _getCategoryIcon(categoria.nombre),
                  size: ResponsiveHelper.isSmallScreen(context) 
                    ? ResponsiveHelper.iconSize(context) - 4
                    : ResponsiveHelper.iconSize(context) + 8,
                  color: Colors.green.shade700,
                ),
              ),
              SizedBox(
                height: ResponsiveHelper.isSmallScreen(context)
                  ? ResponsiveHelper.spacing(context) / 4
                  : ResponsiveHelper.spacing(context) / 3
              ),
              Flexible(
                child: Text(
                  categoria.nombre,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.isSmallScreen(context)
                      ? ResponsiveHelper.bodyFontSize(context) - 2
                      : ResponsiveHelper.bodyFontSize(context),
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade900,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
      margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.spacing(context) / 4),
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
                            padding: EdgeInsets.all(ResponsiveHelper.spacing(context) / 2),
                            child: Text(
                              banner.descripcion!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveHelper.bodyFontSize(context),
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
        title: Text(
          'Cerrar Sesión',
          style: TextStyle(fontSize: ResponsiveHelper.subtitleFontSize(context) + 4),
        ),
        content: Text(
          '¿Está seguro que desea cerrar sesión?',
          style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Sí, cerrar sesión',
              style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
            ),
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
            // Header con dirección y carrito (FIJOS)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.horizontalPadding(context),
                vertical: ResponsiveHelper.spacing(context) / 2,
              ),
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
                          Icon(
                            Icons.location_on,
                            color: Colors.orange.shade700,
                            size: ResponsiveHelper.iconSize(context) - 4,
                          ),
                          SizedBox(width: ResponsiveHelper.spacing(context) / 4),
                          Expanded(
                            child: Text(
                              'Ingresa tu dirección de entrega',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.bodyFontSize(context),
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey.shade600,
                            size: ResponsiveHelper.iconSize(context) - 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.spacing(context) / 2),
                  // Carrito
                  ValueListenableBuilder<int>(
                    valueListenable: CartNotifier.instance,
                    builder: (context, cartCount, _) {
                      return Stack(
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
                          if (cartCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: EdgeInsets.all(ResponsiveHelper.spacing(context) / 3),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                constraints: BoxConstraints(
                                  minWidth: ResponsiveHelper.isSmallScreen(context) ? 18 : 20,
                                  minHeight: ResponsiveHelper.isSmallScreen(context) ? 18 : 20,
                                ),
                                child: Text(
                                  cartCount > 99 ? '99+' : '$cartCount',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: ResponsiveHelper.bodyFontSize(context) - 3,
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
            ),

            // Barra de búsqueda mejorada (FIJOS)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.horizontalPadding(context),
                vertical: ResponsiveHelper.spacing(context) / 2,
              ),
              child: Container(
                height: ResponsiveHelper.isSmallScreen(context) ? 44 : 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                  decoration: InputDecoration(
                    hintText: '¿Qué buscaremos hoy?',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: ResponsiveHelper.bodyFontSize(context),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey.shade600,
                      size: ResponsiveHelper.iconSize(context),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: ResponsiveHelper.iconSize(context) - 4,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.spacing(context),
                      vertical: ResponsiveHelper.spacing(context) / 2,
                    ),
                  ),
                ),
              ),
            ),

            // Chips de filtros rápidos (FIJOS)
            Container(
              height: ResponsiveHelper.isSmallScreen(context) ? 45 : 50,
              padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.spacing(context) / 4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding(context)),
                children: [
                  _buildFilterChip('🔴', 'Últimas unidades'),
                  SizedBox(width: ResponsiveHelper.spacing(context) / 2),
                  _buildFilterChip('🎫', 'Sorteo Casa Millón'),
                  SizedBox(width: ResponsiveHelper.spacing(context) / 2),
                  _buildFilterChip('🏷️', 'Ofertas'),
                  SizedBox(width: ResponsiveHelper.spacing(context) / 2),
                  _buildFilterChip('⭐', 'Populares'),
                ],
              ),
            ),

            // Contenido scrolleable (incluyendo banners, texto y categorías/productos)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: ResponsiveHelper.isSmallScreen(context) ? 48 : 64,
                                color: Colors.red.shade300,
                              ),
                              SizedBox(height: ResponsiveHelper.spacing(context)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding(context)),
                                child: Text(
                                  // Asegurar que el mensaje sea amigable (sin detalles técnicos)
                                  ErrorMessageHelper.getFriendlyErrorMessage(_errorMessage!),
                                  style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: ResponsiveHelper.spacing(context)),
                              ElevatedButton(
                                onPressed: _cargarProductos,
                                child: Text(
                                  'Reintentar',
                                  style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                                ),
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
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveHelper.horizontalPadding(context),
                                    vertical: ResponsiveHelper.spacing(context) / 2,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Resultados: ${_productosFiltrados.length}",
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper.subtitleFontSize(context) + 2,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: _mostrarDialogoOrdenar,
                                        icon: Icon(
                                          Icons.sort,
                                          size: ResponsiveHelper.iconSize(context) - 4,
                                        ),
                                        label: Text(
                                          'Ordenar',
                                          style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                                        ),
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
                                              Icon(
                                                Icons.search_off,
                                                size: ResponsiveHelper.isSmallScreen(context) ? 48 : 64,
                                                color: Colors.grey.shade400,
                                              ),
                                              SizedBox(height: ResponsiveHelper.spacing(context)),
                                              Text(
                                                'No se encontraron productos',
                                                style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                                              ),
                                            ],
                                          ),
                                        )
                                      : RefreshIndicator(
                                          onRefresh: _cargarProductos,
                                          child: ListView.builder(
                                            padding: ResponsiveHelper.formPadding(context),
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
                          // Si NO hay búsqueda, mostrar banners, texto y categorías
                          : RefreshIndicator(
                              onRefresh: _cargarDatos,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(top: 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Carrusel de banners (AHORA SE MUEVE CON EL SCROLL)
                                    if (_banners.isNotEmpty)
                                      Container(
                                        height: ResponsiveHelper.isSmallScreen(context) ? 160 : 200,
                                        margin: EdgeInsets.symmetric(
                                          horizontal: ResponsiveHelper.horizontalPadding(context),
                                          vertical: ResponsiveHelper.spacing(context) / 2,
                                        ),
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
                                                    width: ResponsiveHelper.isSmallScreen(context) ? 6 : 8,
                                                    height: ResponsiveHelper.isSmallScreen(context) ? 6 : 8,
                                                    margin: EdgeInsets.symmetric(
                                                      horizontal: ResponsiveHelper.spacing(context) / 4,
                                                    ),
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
                                      padding: EdgeInsets.symmetric(
                                        horizontal: ResponsiveHelper.horizontalPadding(context),
                                        vertical: ResponsiveHelper.spacing(context) / 2,
                                      ),
                                      child: Text(
                                        'Todos los productos farmacéuticos y dispositivos médicos son distribuidos por Sánchez Pharma (Ley 32033)',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper.bodyFontSize(context) - 3,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),

                                    // SECCIÓN: Productos en Oferta
                                    if (_productosEnOferta.isNotEmpty) ...[
                                      Container(
                                        margin: EdgeInsets.fromLTRB(
                                          ResponsiveHelper.horizontalPadding(context),
                                          ResponsiveHelper.spacing(context) * 1.25,
                                          ResponsiveHelper.horizontalPadding(context),
                                          ResponsiveHelper.spacing(context) / 2,
                                        ),
                                        padding: ResponsiveHelper.formPadding(context),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.red.shade50,
                                              Colors.orange.shade50,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.red.shade200,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.shade200.withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Flexible(
                                                  flex: 3,
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets.all(
                                                          ResponsiveHelper.isSmallScreen(context) 
                                                            ? ResponsiveHelper.spacing(context) / 3 
                                                            : ResponsiveHelper.spacing(context) / 2
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
                                                        child: Icon(
                                                          Icons.local_offer,
                                                          color: Colors.white,
                                                          size: ResponsiveHelper.isSmallScreen(context)
                                                            ? ResponsiveHelper.iconSize(context) - 4
                                                            : ResponsiveHelper.iconSize(context),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: ResponsiveHelper.isSmallScreen(context)
                                                          ? ResponsiveHelper.spacing(context) / 3
                                                          : ResponsiveHelper.spacing(context) / 2
                                                      ),
                                                      Flexible(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              '🔥 OFERTAS ESPECIALES',
                                                              style: TextStyle(
                                                                fontSize: ResponsiveHelper.isSmallScreen(context)
                                                                  ? ResponsiveHelper.subtitleFontSize(context)
                                                                  : ResponsiveHelper.subtitleFontSize(context) + 2,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.black87,
                                                                letterSpacing: 0.5,
                                                              ),
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            if (!ResponsiveHelper.isSmallScreen(context))
                                                              Text(
                                                                'Descuentos increíbles',
                                                                style: TextStyle(
                                                                  fontSize: ResponsiveHelper.bodyFontSize(context) - 2,
                                                                  color: Colors.black54,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(width: ResponsiveHelper.spacing(context) / 4),
                                                Flexible(
                                                  flex: 1,
                                                  child: ResponsiveHelper.isSmallScreen(context)
                                                    ? IconButton(
                                                        onPressed: () {
                                                          setState(() {
                                                            _filtroSeleccionado = 'ofertas';
                                                            _productosFiltrados = _productosEnOferta;
                                                            _categoriaSeleccionada = null;
                                                            _searchController.clear();
                                                          });
                                                          if (_productos.isEmpty) _cargarProductos();
                                                        },
                                                        icon: Icon(
                                                          Icons.arrow_forward,
                                                          size: ResponsiveHelper.iconSize(context) - 6,
                                                          color: Colors.red.shade700,
                                                        ),
                                                        tooltip: 'Ver todas',
                                                      )
                                                    : TextButton.icon(
                                                        onPressed: () {
                                                          setState(() {
                                                            _filtroSeleccionado = 'ofertas';
                                                            _productosFiltrados = _productosEnOferta;
                                                            _categoriaSeleccionada = null;
                                                            _searchController.clear();
                                                          });
                                                          if (_productos.isEmpty) _cargarProductos();
                                                        },
                                                        icon: Icon(
                                                          Icons.arrow_forward,
                                                          size: ResponsiveHelper.iconSize(context) - 6,
                                                        ),
                                                        label: Text(
                                                          'Ver todas',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: ResponsiveHelper.bodyFontSize(context),
                                                          ),
                                                        ),
                                                        style: TextButton.styleFrom(
                                                          foregroundColor: Colors.red.shade700,
                                                          padding: EdgeInsets.symmetric(
                                                            horizontal: ResponsiveHelper.spacing(context) / 2,
                                                            vertical: ResponsiveHelper.spacing(context) / 4,
                                                          ),
                                                        ),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: ResponsiveHelper.isSmallScreen(context) ? 220 : 240,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding(context)),
                                          itemCount: _productosEnOferta.take(10).length,
                                          itemBuilder: (context, index) {
                                            return _buildProductoCardHorizontal(_productosEnOferta[index]);
                                          },
                                        ),
                                      ),
                                      SizedBox(height: ResponsiveHelper.spacing(context)),
                                    ],

                                    // SECCIÓN: Últimas Unidades
                                    if (_productosUltimasUnidades.isNotEmpty) ...[
                                      Container(
                                        margin: EdgeInsets.fromLTRB(
                                          ResponsiveHelper.horizontalPadding(context),
                                          ResponsiveHelper.spacing(context),
                                          ResponsiveHelper.horizontalPadding(context),
                                          ResponsiveHelper.spacing(context) / 2,
                                        ),
                                        padding: ResponsiveHelper.formPadding(context),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.orange.shade50,
                                              Colors.amber.shade50,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.orange.shade300,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.orange.shade200.withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.all(ResponsiveHelper.spacing(context) / 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.orange.shade700,
                                                        borderRadius: BorderRadius.circular(12),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.orange.shade300,
                                                            blurRadius: 8,
                                                            spreadRadius: 1,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Icon(
                                                        Icons.warning_amber_rounded,
                                                        color: Colors.white,
                                                        size: ResponsiveHelper.iconSize(context),
                                                      ),
                                                    ),
                                                    SizedBox(width: ResponsiveHelper.spacing(context) / 2),
                                                    const Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          '⏰ ÚLTIMAS UNIDADES',
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.black87,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                        Text(
                                                          '¡Apúrate! Stock limitado',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.black54,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                TextButton.icon(
                                                  onPressed: () {
                                                    setState(() {
                                                      _filtroSeleccionado = 'ultimas_unidades';
                                                      _productosFiltrados = _productosUltimasUnidades;
                                                      _categoriaSeleccionada = null;
                                                      _searchController.clear();
                                                    });
                                                    if (_productos.isEmpty) _cargarProductos();
                                                  },
                                                  icon: Icon(
                                                    Icons.arrow_forward,
                                                    size: ResponsiveHelper.iconSize(context) - 6,
                                                  ),
                                                  label: Text(
                                                    'Ver todas',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: ResponsiveHelper.bodyFontSize(context),
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.orange.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: ResponsiveHelper.isSmallScreen(context) ? 220 : 240,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding(context)),
                                          itemCount: _productosUltimasUnidades.take(10).length,
                                          itemBuilder: (context, index) {
                                            return _buildProductoCardHorizontal(_productosUltimasUnidades[index]);
                                          },
                                        ),
                                      ),
                                      SizedBox(height: ResponsiveHelper.spacing(context)),
                                    ],

                                    // SECCIÓN: Productos Populares
                                    if (_productosPopulares.isNotEmpty) ...[
                                      Container(
                                        margin: EdgeInsets.fromLTRB(
                                          ResponsiveHelper.horizontalPadding(context),
                                          ResponsiveHelper.spacing(context),
                                          ResponsiveHelper.horizontalPadding(context),
                                          ResponsiveHelper.spacing(context) / 2,
                                        ),
                                        padding: ResponsiveHelper.formPadding(context),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.green.shade50,
                                              Colors.teal.shade50,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.green.shade300,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.green.shade200.withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(ResponsiveHelper.spacing(context) / 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade700,
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green.shade300,
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.star,
                                                color: Colors.white,
                                                size: ResponsiveHelper.iconSize(context),
                                              ),
                                            ),
                                            SizedBox(width: ResponsiveHelper.spacing(context) / 2),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '⭐ MÁS POPULARES',
                                                    style: TextStyle(
                                                      fontSize: ResponsiveHelper.subtitleFontSize(context) + 2,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black87,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Los favoritos de nuestros clientes',
                                                    style: TextStyle(
                                                      fontSize: ResponsiveHelper.bodyFontSize(context) - 2,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: ResponsiveHelper.isSmallScreen(context) ? 220 : 240,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding(context)),
                                          itemCount: _productosPopulares.take(10).length,
                                          itemBuilder: (context, index) {
                                            return _buildProductoCardHorizontal(_productosPopulares[index]);
                                          },
                                        ),
                                      ),
                                      SizedBox(height: ResponsiveHelper.spacing(context)),
                                    ],

                                    // Título de sección
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding(context)),
                                      child: Text(
                                        '¿Qué estás buscando?',
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper.titleFontSize(context),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveHelper.spacing(context)),
                                    
                                    // Grid de categorías
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding(context)),
                                      child: _buildCategoriasGrid(),
                                    ),
                                    
                                    SizedBox(height: ResponsiveHelper.spacing(context) * 1.5),
                                    
                                    // Mensaje para buscar productos
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding(context)),
                                      child: Container(
                                        padding: ResponsiveHelper.formPadding(context),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.green.shade200),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.search,
                                              size: ResponsiveHelper.isSmallScreen(context) ? 40 : 48,
                                              color: Colors.green.shade700,
                                            ),
                                            SizedBox(height: ResponsiveHelper.spacing(context) / 2),
                                            Text(
                                              '¡Encuentra lo que necesitas!',
                                              style: TextStyle(
                                                fontSize: ResponsiveHelper.subtitleFontSize(context) + 2,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade900,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: ResponsiveHelper.spacing(context) / 2),
                                            Text(
                                              'Selecciona una categoría o usa el buscador para ver nuestros productos',
                                              style: TextStyle(
                                                fontSize: ResponsiveHelper.bodyFontSize(context),
                                                color: Colors.grey.shade700,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveHelper.spacing(context)),
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
          // Banner de descuento
          if (producto.tieneDescuento)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveHelper.spacing(context) / 3,
                horizontal: ResponsiveHelper.spacing(context) / 2,
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer,
                    size: ResponsiveHelper.iconSize(context) - 8,
                    color: Colors.red.shade900,
                  ),
                  SizedBox(width: ResponsiveHelper.spacing(context) / 3),
                  Text(
                    '¡${producto.descuentoPorcentaje.toStringAsFixed(0)}% DE DESCUENTO!',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontSize: ResponsiveHelper.bodyFontSize(context) - 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          // Banner de stock bajo
          if (stockBajo && producto.stockActual > 0)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveHelper.spacing(context) / 3,
                horizontal: ResponsiveHelper.spacing(context) / 2,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.vertical(
                  top: producto.tieneDescuento ? Radius.zero : const Radius.circular(12),
                ),
              ),
              child: Text(
                'Quedan ${producto.stockActual} en stock',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontSize: ResponsiveHelper.bodyFontSize(context) - 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          
          // Contenido del producto
          Padding(
            padding: EdgeInsets.all(ResponsiveHelper.spacing(context) / 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del producto
                Container(
                  width: ResponsiveHelper.isSmallScreen(context) ? 80 : 100,
                  height: ResponsiveHelper.isSmallScreen(context) ? 80 : 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildProductoImagen(producto),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.spacing(context) / 2),
                
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
                            fontSize: ResponsiveHelper.bodyFontSize(context) - 2,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      SizedBox(height: ResponsiveHelper.spacing(context) / 4),
                      
                      // Nombre del producto
                      Text(
                        producto.nombre,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.bodyFontSize(context) + 1,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: ResponsiveHelper.spacing(context) / 3),
                      
                      // Vendedor/Proveedor
                      if (producto.proveedorNombre != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.spacing(context) / 2,
                            vertical: ResponsiveHelper.spacing(context) / 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.store,
                                size: ResponsiveHelper.iconSize(context) - 10,
                                color: Colors.blue.shade700,
                              ),
                              SizedBox(width: ResponsiveHelper.spacing(context) / 4),
                              Flexible(
                                child: Text(
                                  producto.proveedorNombre!,
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.bodyFontSize(context) - 3,
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
                      SizedBox(height: ResponsiveHelper.spacing(context) / 2),
                      
                      // Precio
                      if (producto.tieneDescuento) ...[
                        Row(
                          children: [
                            Text(
                              'S/ ${producto.precioConDescuento.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.subtitleFontSize(context) + 4,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                            SizedBox(width: ResponsiveHelper.spacing(context) / 2),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveHelper.spacing(context) / 2,
                                vertical: ResponsiveHelper.spacing(context) / 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '-${producto.descuentoPorcentaje.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.bodyFontSize(context) - 2,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: ResponsiveHelper.spacing(context) / 4),
                        Text(
                          'S/ ${producto.precioVenta.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.bodyFontSize(context),
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Text(
                              'S/ ${producto.precioVenta.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.subtitleFontSize(context) + 2,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            SizedBox(width: ResponsiveHelper.spacing(context) / 2),
                            Text(
                              'Precio regular',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.bodyFontSize(context) - 2,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Botones de acción
          Padding(
            padding: EdgeInsets.fromLTRB(
              ResponsiveHelper.spacing(context) / 2,
              0,
              ResponsiveHelper.spacing(context) / 2,
              ResponsiveHelper.spacing(context) / 2,
            ),
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
                      padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.spacing(context) / 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Agregar al carrito',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.bodyFontSize(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.spacing(context) / 2),
                IconButton(
                  icon: Icon(
                    _esFavorito(producto.id) ? Icons.favorite : Icons.favorite_border,
                    color: _esFavorito(producto.id) ? Colors.red : Colors.grey.shade600,
                    size: ResponsiveHelper.iconSize(context),
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

  Widget _buildProductoCardHorizontal(ProductoModel producto) {
    final imagenes = producto.todasLasImagenes;
    final thumbUrl = imagenes.isNotEmpty
        ? imagenes[0]
        : 'https://placehold.co/400x400?text=${Uri.encodeComponent(producto.nombre)}';
    
    return Container(
      width: ResponsiveHelper.isSmallScreen(context) ? 150 : 170,
      height: ResponsiveHelper.isSmallScreen(context) ? 220 : 240,
      margin: EdgeInsets.only(right: ResponsiveHelper.spacing(context) / 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(producto: producto),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Imagen del producto
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    height: ResponsiveHelper.isSmallScreen(context) ? 90 : 110,
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: Image.network(
                      thumbUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.local_pharmacy,
                        color: Colors.green.shade700,
                        size: ResponsiveHelper.isSmallScreen(context) ? 40 : 48,
                      ),
                    ),
                  ),
                ),
                // Badge de descuento
                if (producto.tieneDescuento)
                  Positioned(
                    top: ResponsiveHelper.spacing(context) / 2,
                    left: ResponsiveHelper.spacing(context) / 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.spacing(context) / 2,
                        vertical: ResponsiveHelper.spacing(context) / 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '-${producto.descuentoPorcentaje.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveHelper.bodyFontSize(context) - 3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Botón de favorito
                Positioned(
                  top: ResponsiveHelper.spacing(context) / 2,
                  right: ResponsiveHelper.spacing(context) / 2,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _toggleFavorito(producto),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.all(ResponsiveHelper.spacing(context) / 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _esFavorito(producto.id) ? Icons.favorite : Icons.favorite_border,
                          color: _esFavorito(producto.id) ? Colors.red : Colors.white,
                          size: ResponsiveHelper.iconSize(context) - 6,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Información del producto
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(
                  ResponsiveHelper.isSmallScreen(context)
                    ? ResponsiveHelper.spacing(context) / 3
                    : ResponsiveHelper.spacing(context) / 2
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        producto.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.isSmallScreen(context)
                            ? ResponsiveHelper.bodyFontSize(context) - 2
                            : ResponsiveHelper.bodyFontSize(context) - 1,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.isSmallScreen(context)
                        ? ResponsiveHelper.spacing(context) / 4
                        : ResponsiveHelper.spacing(context) / 3
                    ),
                    // Precio
                    if (producto.tieneDescuento) ...[
                      Text(
                        'S/ ${producto.precioConDescuento.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.isSmallScreen(context)
                            ? ResponsiveHelper.bodyFontSize(context)
                            : ResponsiveHelper.bodyFontSize(context) + 1,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'S/ ${producto.precioVenta.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.isSmallScreen(context)
                            ? ResponsiveHelper.bodyFontSize(context) - 5
                            : ResponsiveHelper.bodyFontSize(context) - 4,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                      Text(
                        'S/ ${producto.precioVenta.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.isSmallScreen(context)
                            ? ResponsiveHelper.bodyFontSize(context)
                            : ResponsiveHelper.bodyFontSize(context) + 1,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    Flexible(
                      child: SizedBox(height: ResponsiveHelper.spacing(context) / 4),
                    ),
                    // Botones de acción
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botón de favoritos
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _esFavorito(producto.id) 
                                  ? Colors.red.shade300 
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: _esFavorito(producto.id) 
                                ? Colors.red.shade50 
                                : Colors.white,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.all(
                              ResponsiveHelper.isSmallScreen(context)
                                ? ResponsiveHelper.spacing(context) / 4
                                : ResponsiveHelper.spacing(context) / 3
                            ),
                            constraints: BoxConstraints(
                              minWidth: ResponsiveHelper.isSmallScreen(context) ? 28 : 32,
                              minHeight: ResponsiveHelper.isSmallScreen(context) ? 28 : 32,
                            ),
                            icon: Icon(
                              _esFavorito(producto.id) 
                                  ? Icons.favorite 
                                  : Icons.favorite_border,
                              color: _esFavorito(producto.id) 
                                  ? Colors.red.shade600 
                                  : Colors.grey.shade600,
                              size: ResponsiveHelper.isSmallScreen(context)
                                ? ResponsiveHelper.iconSize(context) - 10
                                : ResponsiveHelper.iconSize(context) - 8,
                            ),
                            onPressed: () => _toggleFavorito(producto),
                          ),
                        ),
                        SizedBox(
                          width: ResponsiveHelper.isSmallScreen(context)
                            ? ResponsiveHelper.spacing(context) / 4
                            : ResponsiveHelper.spacing(context) / 3
                        ),
                        // Botón de agregar al carrito
                        Expanded(
                          child: ElevatedButton(
                            onPressed: producto.stockActual > 0
                                ? () => _agregarAlCarrito(producto)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: ResponsiveHelper.isSmallScreen(context)
                                  ? ResponsiveHelper.spacing(context) / 3
                                  : ResponsiveHelper.spacing(context) / 2
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                              minimumSize: Size(0, ResponsiveHelper.isSmallScreen(context) ? 28 : 32),
                            ),
                            child: Text(
                              'Agregar',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.isSmallScreen(context)
                                  ? ResponsiveHelper.bodyFontSize(context) - 4
                                  : ResponsiveHelper.bodyFontSize(context) - 3,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

