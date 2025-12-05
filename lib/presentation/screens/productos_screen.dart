import 'package:flutter/material.dart';
import 'package:retrofit/retrofit.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/categoria_model.dart';
import '../../data/models/proveedor_model.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_modal_dialog.dart';
import 'categorias_screen.dart';
import 'proveedores_screen.dart';
import 'formulario_producto_screen.dart';

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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(color: Colors.blue.shade200, thickness: 1),
        ),
      ],
    );
  }

  Future<void> _mostrarFormularioProducto({ProductoModel? producto}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioProductoScreen(
          producto: producto,
          categorias: _categorias,
          proveedores: _proveedores,
        ),
      ),
    );

    if (result == true) {
      _cargarProductos();
    }
  }

  // Método antiguo mantenido para referencia pero no usado
  Future<void> _mostrarFormularioProductoAntiguo({ProductoModel? producto}) async {
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
      barrierDismissible: false,
      builder: (context) => CustomModalDialog(
        title: producto == null ? 'Registrar Producto' : 'Editar Producto',
        icon: producto == null ? Icons.add_shopping_cart : Icons.edit,
        content: StatefulBuilder(
          builder: (context, setState) => Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sección: Información Básica
                ModalSectionBuilder.buildSectionTitle('Información Básica', Icons.info_outline),
                Row(
                  children: [
                    Expanded(
                      child: ModalSectionBuilder.buildTextField(
                        controller: codigoController,
                        label: 'Código',
                        icon: Icons.qr_code,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ModalSectionBuilder.buildTextField(
                        controller: codigoBarrasController,
                        label: 'Código de Barras',
                        icon: Icons.barcode_reader,
                      ),
                    ),
                  ],
                ),
                ModalSectionBuilder.buildTextField(
                  controller: nombreController,
                  label: 'Nombre del Producto',
                  icon: Icons.shopping_bag,
                  required: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                ModalSectionBuilder.buildTextField(
                  controller: descripcionController,
                  label: 'Descripción',
                  icon: Icons.description,
                  maxLines: 3,
                ),
                
                // Sección: Categoría y Proveedor
                ModalSectionBuilder.buildSectionTitle('Clasificación', Icons.category),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<int?>(
                    value: categoriaIdSeleccionada,
                    decoration: InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: const Icon(Icons.category, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
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
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<int?>(
                    value: proveedorIdSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Proveedor',
                      prefixIcon: const Icon(Icons.local_shipping, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
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
                ),
                
                // Sección: Precios
                ModalSectionBuilder.buildSectionTitle('Precios', Icons.attach_money),
                Row(
                  children: [
                    Expanded(
                      child: ModalSectionBuilder.buildTextField(
                        controller: precioCompraController,
                        label: 'Precio Compra',
                        icon: Icons.shopping_cart,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        required: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ModalSectionBuilder.buildTextField(
                        controller: precioVentaController,
                        label: 'Precio Venta',
                        icon: Icons.point_of_sale,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        required: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                
                // Sección: Inventario
                ModalSectionBuilder.buildSectionTitle('Inventario', Icons.inventory),
                Row(
                  children: [
                    Expanded(
                      child: ModalSectionBuilder.buildTextField(
                        controller: stockActualController,
                        label: 'Stock Actual',
                        icon: Icons.inventory_2,
                        keyboardType: TextInputType.number,
                        required: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ModalSectionBuilder.buildTextField(
                        controller: stockMinimoController,
                        label: 'Stock Mínimo',
                        icon: Icons.warning_amber,
                        keyboardType: TextInputType.number,
                        required: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                ModalSectionBuilder.buildTextField(
                  controller: unidadMedidaController,
                  label: 'Unidad de Medida',
                  icon: Icons.straighten,
                  hint: 'Ej: unidad, caja, kg, litro',
                ),
                
                // Sección: Otros Datos
                ModalSectionBuilder.buildSectionTitle('Otros Datos', Icons.more_horiz),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: fechaVencimiento ?? DateTime.now().add(const Duration(days: 180)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: AppColors.primary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        fechaVencimiento = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Fecha de Vencimiento',
                      prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          fechaVencimiento != null
                              ? '${fechaVencimiento!.day.toString().padLeft(2, '0')}/${fechaVencimiento!.month.toString().padLeft(2, '0')}/${fechaVencimiento!.year}'
                              : 'Seleccionar fecha (opcional)',
                          style: TextStyle(
                            color: fechaVencimiento != null ? Colors.black : Colors.grey,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: estadoValue,
                    decoration: InputDecoration(
                      labelText: 'Estado del Producto',
                      prefixIcon: Icon(
                        estadoValue == 'activo' 
                            ? Icons.check_circle 
                            : estadoValue == 'inactivo' 
                                ? Icons.cancel 
                                : Icons.remove_circle,
                        color: estadoValue == 'activo' 
                            ? Colors.green 
                            : estadoValue == 'inactivo' 
                                ? Colors.grey 
                                : Colors.red,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: estadoValue == 'activo' 
                          ? Colors.green.shade50
                          : estadoValue == 'inactivo' 
                              ? Colors.grey.shade100 
                              : Colors.red.shade50,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'activo',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text('Activo'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'inactivo',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text('Inactivo'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'agotado',
                        child: Row(
                          children: [
                            Icon(Icons.remove_circle, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Agotado'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        estadoValue = value ?? 'activo';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ModalSectionBuilder.buildButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icons.close,
            isOutlined: true,
          ),
          const SizedBox(width: 12),
          ModalSectionBuilder.buildButton(
            label: 'Guardar',
            icon: Icons.save,
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

  Future<void> _incrementarStock(ProductoModel producto) async {
    if (producto.id == null) return;

    final cantidadController = TextEditingController();
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Incrementar Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Producto: ${producto.nombre}'),
            const SizedBox(height: 8),
            Text('Stock actual: ${producto.stockActual}'),
            const SizedBox(height: 16),
            TextField(
              controller: cantidadController,
              decoration: const InputDecoration(
                labelText: 'Cantidad a agregar',
                hintText: 'Ingrese la cantidad',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final cantidad = int.tryParse(cantidadController.text);
              if (cantidad != null && cantidad > 0) {
                Navigator.of(context).pop({'cantidad': cantidad});
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingrese una cantidad válida mayor a 0'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (result == null || result['cantidad'] == null) return;

    final cantidad = result['cantidad'] as int;

    try {
      final response = await _apiService.incrementarStockProducto({
        'producto_id': producto.id,
        'cantidad': cantidad,
      });

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Stock incrementado correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
          _cargarProductos();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Error al incrementar stock'),
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
                                          icon: const Icon(Icons.add_circle, color: Colors.blue),
                                          onPressed: () => _incrementarStock(producto),
                                          tooltip: 'Agregar Stock',
                                        ),
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

