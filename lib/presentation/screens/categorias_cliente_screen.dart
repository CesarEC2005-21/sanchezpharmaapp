import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/categoria_model.dart';
import '../../core/notifiers/cart_notifier.dart';
import 'carrito_screen.dart';
import 'productos_categoria_screen.dart';

class CategoriasClienteScreen extends StatefulWidget {
  final Function(int?)? onCategoriaSeleccionada;

  const CategoriasClienteScreen({
    super.key,
    this.onCategoriaSeleccionada,
  });

  @override
  State<CategoriasClienteScreen> createState() => _CategoriasClienteScreenState();
}

class _CategoriasClienteScreenState extends State<CategoriasClienteScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<CategoriaModel> _categorias = [];
  bool _isLoading = true;
  int _itemsEnCarrito = 0;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    _actualizarContadorCarrito();
  }

  Future<void> _cargarCategorias() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getCategorias();
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> categoriasJson = data['data'];
          setState(() {
            _categorias = categoriasJson
                .map((json) => CategoriaModel.fromJson(json))
                .where((c) => c.estado == 'activo')
                .toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error al cargar categorías: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _actualizarContadorCarrito() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final carrito = prefs.getStringList('carrito') ?? [];
      if (mounted) {
        setState(() {
          _itemsEnCarrito = carrito.length;
        });
      }
      CartNotifier.instance.updateCount(carrito.length);
    } catch (e) {
      print('Error al actualizar contador de carrito: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Categorías',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: CartNotifier.instance,
                    builder: (context, cartCount, _) {
                      return Stack(
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
                          if (cartCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
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
            ),

            // Lista de categorías
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _categorias.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No hay categorías disponibles',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarCategorias,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _categorias.length,
                            itemBuilder: (context, index) {
                              final categoria = _categorias[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
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
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(categoria.nombre),
                                      color: Colors.green.shade700,
                                      size: 28,
                                    ),
                                  ),
                                  title: Text(
                                    categoria.nombre,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  subtitle: categoria.descripcion != null
                                      ? Text(
                                          categoria.descripcion!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : null,
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey.shade400,
                                  ),
                                  onTap: () {
                                    if (categoria.id != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductosCategoriaScreen(
                                            categoriaId: categoria.id!,
                                            categoriaNombre: categoria.nombre,
                                          ),
                                        ),
                                      );
                                    }
                                    // También mantener el callback por si acaso
                                    if (widget.onCategoriaSeleccionada != null) {
                                      widget.onCategoriaSeleccionada!(categoria.id);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

