import 'package:flutter/material.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/categoria_model.dart';
import '../../data/models/proveedor_model.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_modal_dialog.dart';

class FormularioProductoScreen extends StatefulWidget {
  final ProductoModel? producto;
  final List<CategoriaModel> categorias;
  final List<ProveedorModel> proveedores;

  const FormularioProductoScreen({
    super.key,
    this.producto,
    required this.categorias,
    required this.proveedores,
  });

  @override
  State<FormularioProductoScreen> createState() => _FormularioProductoScreenState();
}

class _FormularioProductoScreenState extends State<FormularioProductoScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  final _formKey = GlobalKey<FormState>();
  bool _isGuardando = false;

  late final TextEditingController _codigoController;
  late final TextEditingController _codigoBarrasController;
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _precioCompraController;
  late final TextEditingController _precioVentaController;
  late final TextEditingController _stockActualController;
  late final TextEditingController _stockMinimoController;
  late final TextEditingController _unidadMedidaController;

  int? _categoriaIdSeleccionada;
  int? _proveedorIdSeleccionado;
  DateTime? _fechaVencimiento;
  String _estadoValue = 'activo';

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(text: widget.producto?.codigo ?? '');
    _codigoBarrasController = TextEditingController(text: widget.producto?.codigoBarras ?? '');
    _nombreController = TextEditingController(text: widget.producto?.nombre ?? '');
    _descripcionController = TextEditingController(text: widget.producto?.descripcion ?? '');
    _precioCompraController = TextEditingController(text: widget.producto?.precioCompra.toString() ?? '0.00');
    _precioVentaController = TextEditingController(text: widget.producto?.precioVenta.toString() ?? '0.00');
    _stockActualController = TextEditingController(text: widget.producto?.stockActual.toString() ?? '0');
    _stockMinimoController = TextEditingController(text: widget.producto?.stockMinimo.toString() ?? '0');
    _unidadMedidaController = TextEditingController(text: widget.producto?.unidadMedida ?? 'unidad');
    _categoriaIdSeleccionada = widget.producto?.categoriaId;
    _proveedorIdSeleccionado = widget.producto?.proveedorId;
    _fechaVencimiento = widget.producto?.fechaVencimiento;
    _estadoValue = widget.producto?.estado ?? 'activo';
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _codigoBarrasController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioCompraController.dispose();
    _precioVentaController.dispose();
    _stockActualController.dispose();
    _stockMinimoController.dispose();
    _unidadMedidaController.dispose();
    super.dispose();
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGuardando = true;
    });

    try {
      final Map<String, dynamic> datos = {
        'codigo': _codigoController.text.isEmpty ? null : _codigoController.text,
        'codigo_barras': _codigoBarrasController.text.isEmpty ? null : _codigoBarrasController.text,
        'nombre': _nombreController.text,
        'descripcion': _descripcionController.text.isEmpty ? null : _descripcionController.text,
        'categoria_id': _categoriaIdSeleccionada,
        'proveedor_id': _proveedorIdSeleccionado,
        'precio_compra': double.parse(_precioCompraController.text),
        'precio_venta': double.parse(_precioVentaController.text),
        'stock_actual': int.parse(_stockActualController.text),
        'stock_minimo': int.parse(_stockMinimoController.text),
        'unidad_medida': _unidadMedidaController.text,
        'fecha_vencimiento': _fechaVencimiento?.toIso8601String().split('T')[0],
        'estado': _estadoValue,
      };

      if (widget.producto != null) {
        datos['id'] = widget.producto!.id;
      }

      final response = widget.producto == null
          ? await _apiService.registrarProducto(datos)
          : await _apiService.editarProducto(datos);

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
            Navigator.of(context).pop(true);
          }
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
    } finally {
      if (mounted) {
        setState(() {
          _isGuardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.producto == null ? 'Registrar Producto' : 'Editar Producto'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isGuardando)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModalSectionBuilder.buildSectionTitle('Información Básica', Icons.info_outline),
              Row(
                children: [
                  Expanded(
                    child: ModalSectionBuilder.buildTextField(
                      controller: _codigoController,
                      label: 'Código',
                      icon: Icons.qr_code,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModalSectionBuilder.buildTextField(
                      controller: _codigoBarrasController,
                      label: 'Código de Barras',
                      icon: Icons.barcode_reader,
                    ),
                  ),
                ],
              ),
              ModalSectionBuilder.buildTextField(
                controller: _nombreController,
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
                controller: _descripcionController,
                label: 'Descripción',
                icon: Icons.description,
                maxLines: 3,
              ),
              
              ModalSectionBuilder.buildSectionTitle('Clasificación', Icons.category),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<int?>(
                  value: _categoriaIdSeleccionada,
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
                    ...widget.categorias.map((cat) => DropdownMenuItem<int?>(
                      value: cat.id,
                      child: Text(cat.nombre),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _categoriaIdSeleccionada = value;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<int?>(
                  value: _proveedorIdSeleccionado,
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
                    ...widget.proveedores.map((prov) => DropdownMenuItem<int?>(
                      value: prov.id,
                      child: Text(prov.nombre),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _proveedorIdSeleccionado = value;
                    });
                  },
                ),
              ),
              
              ModalSectionBuilder.buildSectionTitle('Precios', Icons.attach_money),
              Row(
                children: [
                  Expanded(
                    child: ModalSectionBuilder.buildTextField(
                      controller: _precioCompraController,
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
                      controller: _precioVentaController,
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
              
              ModalSectionBuilder.buildSectionTitle('Inventario', Icons.inventory),
              Row(
                children: [
                  Expanded(
                    child: ModalSectionBuilder.buildTextField(
                      controller: _stockActualController,
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
                      controller: _stockMinimoController,
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
                controller: _unidadMedidaController,
                label: 'Unidad de Medida',
                icon: Icons.straighten,
                hint: 'Ej: unidad, caja, kg, litro',
              ),
              
              ModalSectionBuilder.buildSectionTitle('Otros Datos', Icons.more_horiz),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _fechaVencimiento ?? DateTime.now().add(const Duration(days: 180)),
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
                      _fechaVencimiento = picked;
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
                        _fechaVencimiento != null
                            ? '${_fechaVencimiento!.day.toString().padLeft(2, '0')}/${_fechaVencimiento!.month.toString().padLeft(2, '0')}/${_fechaVencimiento!.year}'
                            : 'Seleccionar fecha (opcional)',
                        style: TextStyle(
                          color: _fechaVencimiento != null ? Colors.black : Colors.grey,
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
                  value: _estadoValue,
                  decoration: InputDecoration(
                    labelText: 'Estado del Producto',
                    prefixIcon: Icon(
                      _estadoValue == 'activo' 
                          ? Icons.check_circle 
                          : _estadoValue == 'inactivo' 
                              ? Icons.cancel 
                              : Icons.remove_circle,
                      color: _estadoValue == 'activo' 
                          ? Colors.green 
                          : _estadoValue == 'inactivo' 
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
                    fillColor: _estadoValue == 'activo' 
                        ? Colors.green.shade50
                        : _estadoValue == 'inactivo' 
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
                      _estadoValue = value ?? 'activo';
                    });
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGuardando ? null : _guardarProducto,
                  icon: const Icon(Icons.save),
                  label: Text(_isGuardando ? 'Guardando...' : 'Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

