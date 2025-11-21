import 'package:flutter/material.dart';
import 'package:retrofit/retrofit.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/categoria_model.dart';
import '../../data/models/proveedor_model.dart';
import '../../core/utils/shared_prefs_helper.dart';
import 'categorias_screen.dart';
import 'proveedores_screen.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<ProductoModel> _productos = [];
  List<CategoriaModel> _categorias = [];
  List<ProveedorModel> _proveedores = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _filtroBusqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    _cargarCategorias();
    _cargarProveedores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _cargarProveedores() async {
    try {
      final response = await _apiService.getProveedores();
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> proveedoresJson = data['data'];
          setState(() {
            _proveedores = proveedoresJson
                .map((json) => ProveedorModel.fromJson(json))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error al cargar proveedores: $e');
    }
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await SharedPrefsHelper.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'No hay sesión activa. Por favor, inicie sesión nuevamente.';
          _isLoading = false;
        });
        return;
      }

      HttpResponse<dynamic> response;
      
      if (_filtroBusqueda.isNotEmpty) {
        response = await _apiService.buscarProductos({'q': _filtroBusqueda});
      } else {
        response = await _apiService.getProductos();
      }

      if (response.response.statusCode == 200) {
        final data = response.data;

        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> productosJson = data['data'];
          setState(() {
            _productos = productosJson
                .map((json) => ProductoModel.fromJson(json))
                .toList();
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
          _errorMessage = 'Error al conectar con el servidor';
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

  Future<void> _mostrarFormularioProducto({ProductoModel? producto}) async {
    final formKey = GlobalKey<FormState>();

    final codigoController = TextEditingController(text: producto?.codigo ?? '');
    final codigoBarrasController = TextEditingController(text: producto?.codigoBarras ?? '');
    final nombreController = TextEditingController(text: producto?.nombre ?? '');
    final descripcionController = TextEditingController(text: producto?.descripcion ?? '');
    final precioCompraController = TextEditingController(text: producto?.precioCompra.toString() ?? '0.00');
    final precioVentaController = TextEditingController(text: producto?.precioVenta.toString() ?? '0.00');
    final stockActualController = TextEditingController(text: producto?.stockActual.toString() ?? '0');
    final stockMinimoController = TextEditingController(text: producto?.stockMinimo.toString() ?? '0');
    final unidadMedidaController = TextEditingController(text: producto?.unidadMedida ?? 'unidad');
    
    int? categoriaIdSeleccionada = producto?.categoriaId;
    int? proveedorIdSeleccionado = producto?.proveedorId;
    DateTime? fechaVencimiento = producto?.fechaVencimiento;
    String estadoValue = producto?.estado ?? 'activo';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(producto == null ? 'Registrar Producto' : 'Editar Producto'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: codigoController,
                    decoration: const InputDecoration(
                      labelText: 'Código',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: codigoBarrasController,
                    decoration: const InputDecoration(
                      labelText: 'Código de Barras',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El nombre es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: categoriaIdSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Sin categoría')),
                      ..._categorias.map((cat) => DropdownMenuItem<int?>(
                        value: cat.id,
                        child: Text(cat.nombre),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        categoriaIdSeleccionada = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: proveedorIdSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Proveedor',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Sin proveedor')),
                      ..._proveedores.map((prov) => DropdownMenuItem<int?>(
                        value: prov.id,
                        child: Text(prov.nombre),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        proveedorIdSeleccionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: precioCompraController,
                          decoration: const InputDecoration(
                            labelText: 'Precio Compra *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requerido';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Debe ser un número';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: precioVentaController,
                          decoration: const InputDecoration(
                            labelText: 'Precio Venta *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requerido';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Debe ser un número';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: stockActualController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Actual *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requerido';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Debe ser un número';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: stockMinimoController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Mínimo *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requerido';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Debe ser un número';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: unidadMedidaController,
                    decoration: const InputDecoration(
                      labelText: 'Unidad de Medida',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fechaVencimiento ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) {
                        setState(() {
                          fechaVencimiento = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Vencimiento',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        fechaVencimiento != null
                            ? '${fechaVencimiento!.day}/${fechaVencimiento!.month}/${fechaVencimiento!.year}'
                            : 'Seleccionar fecha',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: estadoValue,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'activo', child: Text('Activo')),
                      DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
                      DropdownMenuItem(value: 'agotado', child: Text('Agotado')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        estadoValue = value ?? 'activo';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _guardarProducto(
                  producto: producto,
                  codigo: codigoController.text.isEmpty ? null : codigoController.text,
                  codigoBarras: codigoBarrasController.text.isEmpty ? null : codigoBarrasController.text,
                  nombre: nombreController.text,
                  descripcion: descripcionController.text.isEmpty ? null : descripcionController.text,
                  categoriaId: categoriaIdSeleccionada,
                  proveedorId: proveedorIdSeleccionado,
                  precioCompra: double.parse(precioCompraController.text),
                  precioVenta: double.parse(precioVentaController.text),
                  stockActual: int.parse(stockActualController.text),
                  stockMinimo: int.parse(stockMinimoController.text),
                  unidadMedida: unidadMedidaController.text,
                  fechaVencimiento: fechaVencimiento,
                  estado: estadoValue,
                );
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarProducto({
    ProductoModel? producto,
    String? codigo,
    String? codigoBarras,
    required String nombre,
    String? descripcion,
    int? categoriaId,
    int? proveedorId,
    required double precioCompra,
    required double precioVenta,
    required int stockActual,
    required int stockMinimo,
    required String unidadMedida,
    DateTime? fechaVencimiento,
    required String estado,
  }) async {
    try {
      final Map<String, dynamic> datos = {
        'codigo': codigo,
        'codigo_barras': codigoBarras,
        'nombre': nombre,
        'descripcion': descripcion,
        'categoria_id': categoriaId,
        'proveedor_id': proveedorId,
        'precio_compra': precioCompra,
        'precio_venta': precioVenta,
        'stock_actual': stockActual,
        'stock_minimo': stockMinimo,
        'unidad_medida': unidadMedida,
        'fecha_vencimiento': fechaVencimiento?.toIso8601String().split('T')[0],
        'estado': estado,
      };

      HttpResponse<dynamic> response;

      if (producto == null) {
        response = await _apiService.registrarProducto(datos);
      } else {
        datos['id'] = producto.id;
        response = await _apiService.editarProducto(datos);
      }

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Operación exitosa'),
                backgroundColor: Colors.green,
              ),
            );
          }
          _cargarProductos();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Error en la operación'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
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
    }
  }

  Future<void> _eliminarProducto(ProductoModel producto) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Está seguro que desea eliminar el producto ${producto.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true || producto.id == null) return;

    try {
      final response = await _apiService.eliminarProducto(producto.id!);

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto eliminado correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
          _cargarProductos();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Error al eliminar'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
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
    }
  }

  Color _getStockColor(ProductoModel producto) {
    if (producto.stockActual <= 0) return Colors.red;
    if (producto.stockActual <= producto.stockMinimo) return Colors.orange;
    return Colors.green;
  }

  IconData _getStockIcon(ProductoModel producto) {
    if (producto.stockActual <= 0) return Icons.error;
    if (producto.stockActual <= producto.stockMinimo) return Icons.warning;
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario de Productos'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'categorias') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoriasScreen(),
                  ),
                ).then((_) => _cargarCategorias());
              } else if (value == 'proveedores') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProveedoresScreen(),
                  ),
                ).then((_) => _cargarProveedores());
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'categorias',
                child: Row(
                  children: [
                    Icon(Icons.category, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Gestionar Categorías'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'proveedores',
                child: Row(
                  children: [
                    Icon(Icons.local_shipping, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Gestionar Proveedores'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _cargarProductos();
              _cargarCategorias();
              _cargarProveedores();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
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
                          setState(() {
                            _filtroBusqueda = '';
                          });
                          _cargarProductos();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _filtroBusqueda = value;
                });
              },
              onSubmitted: (_) {
                _cargarProductos();
              },
            ),
          ),
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
                              size: 64,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _cargarProductos,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _productos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No hay productos registrados',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _cargarProductos,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _productos.length,
                              itemBuilder: (context, index) {
                                final producto = _productos[index];
                                final stockColor = _getStockColor(producto);
                                final stockIcon = _getStockIcon(producto);

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 8,
                                  ),
                                  elevation: 2,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: stockColor,
                                      child: Icon(stockIcon, color: Colors.white),
                                    ),
                                    title: Text(
                                      producto.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (producto.codigo != null)
                                          Text('Código: ${producto.codigo}'),
                                        Text('Stock: ${producto.stockActual} / Mín: ${producto.stockMinimo}'),
                                        Text('Precio: \$${producto.precioVenta.toStringAsFixed(2)}'),
                                        if (producto.categoriaNombre != null)
                                          Text('Categoría: ${producto.categoriaNombre}'),
                                        if (producto.fechaVencimiento != null)
                                          Text(
                                            'Vence: ${producto.fechaVencimiento!.day}/${producto.fechaVencimiento!.month}/${producto.fechaVencimiento!.year}',
                                            style: TextStyle(
                                              color: producto.fechaVencimiento!.isBefore(DateTime.now())
                                                  ? Colors.red
                                                  : producto.fechaVencimiento!.isBefore(DateTime.now().add(const Duration(days: 30)))
                                                      ? Colors.orange
                                                      : Colors.black,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.green),
                                          onPressed: () => _mostrarFormularioProducto(producto: producto),
                                          tooltip: 'Editar',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _eliminarProducto(producto),
                                          tooltip: 'Eliminar',
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioProducto(),
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

