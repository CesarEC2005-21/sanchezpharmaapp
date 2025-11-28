import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/categoria_model.dart';
import '../../data/models/proveedor_model.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_modal_dialog.dart';
import '../../core/utils/shared_prefs_helper.dart';

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
  late final TextEditingController _descuentoPorcentajeController;
  late final TextEditingController _stockActualController;
  late final TextEditingController _stockMinimoController;
  late final TextEditingController _unidadMedidaController;

  int? _categoriaIdSeleccionada;
  int? _proveedorIdSeleccionado;
  DateTime? _fechaVencimiento;
  String _estadoValue = 'activo';
  List<File> _imagenesSeleccionadas = [];
  List<String> _imagenesUrlsActuales = [];

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(text: widget.producto?.codigo ?? '');
    _codigoBarrasController = TextEditingController(text: widget.producto?.codigoBarras ?? '');
    _nombreController = TextEditingController(text: widget.producto?.nombre ?? '');
    _descripcionController = TextEditingController(text: widget.producto?.descripcion ?? '');
    _precioCompraController = TextEditingController(text: widget.producto?.precioCompra.toString() ?? '0.00');
    _precioVentaController = TextEditingController(text: widget.producto?.precioVenta.toString() ?? '0.00');
    _descuentoPorcentajeController = TextEditingController(text: widget.producto?.descuentoPorcentaje.toString() ?? '0.00');
    _stockActualController = TextEditingController(text: widget.producto?.stockActual.toString() ?? '0');
    _stockMinimoController = TextEditingController(text: widget.producto?.stockMinimo.toString() ?? '0');
    _unidadMedidaController = TextEditingController(text: widget.producto?.unidadMedida ?? 'unidad');
    _categoriaIdSeleccionada = widget.producto?.categoriaId;
    _proveedorIdSeleccionado = widget.producto?.proveedorId;
    _fechaVencimiento = widget.producto?.fechaVencimiento;
    _estadoValue = widget.producto?.estado ?? 'activo';
    // Cargar imágenes existentes
    if (widget.producto?.imagenes != null && widget.producto!.imagenes!.isNotEmpty) {
      _imagenesUrlsActuales = List<String>.from(widget.producto!.imagenes!);
    } else if (widget.producto?.imagenUrl != null && widget.producto!.imagenUrl!.isNotEmpty) {
      _imagenesUrlsActuales = [widget.producto!.imagenUrl!];
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _codigoBarrasController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioCompraController.dispose();
    _precioVentaController.dispose();
    _descuentoPorcentajeController.dispose();
    _stockActualController.dispose();
    _stockMinimoController.dispose();
    _unidadMedidaController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagenes() async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Agregar desde Galería'),
                onTap: () async {
                  Navigator.pop(context);
                  final List<XFile> images = await picker.pickMultiImage(
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 85,
                  );
                  if (images.isNotEmpty) {
                    setState(() {
                      _imagenesSeleccionadas.addAll(images.map((img) => File(img.path)));
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar Foto'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    setState(() {
                      _imagenesSeleccionadas.add(File(image.path));
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _eliminarImagen(int index, bool esUrl) {
    setState(() {
      if (esUrl) {
        _imagenesUrlsActuales.removeAt(index);
      } else {
        _imagenesSeleccionadas.removeAt(index);
      }
    });
  }

  Future<List<String>> _subirImagenes() async {
    if (_imagenesSeleccionadas.isEmpty) {
      return [];
    }

    try {
      // Usar el mismo Dio con el interceptor que maneja el token automáticamente
      final dio = DioClient.createDio();
      
      // Actualizar timeouts para subida de archivos
      dio.options.connectTimeout = const Duration(seconds: 60);
      dio.options.receiveTimeout = const Duration(seconds: 60);
      
      final formData = FormData();
      
      // Agregar todas las imágenes al FormData
      for (var imagen in _imagenesSeleccionadas) {
        String fileName = imagen.path.split('/').last;
        formData.files.add(MapEntry(
          'imagenes',
          await MultipartFile.fromFile(
            imagen.path,
            filename: fileName,
          ),
        ));
      }

      // Obtener token de autenticación usando el helper
      final token = await SharedPrefsHelper.getToken();
      
      if (token == null || token.isEmpty) {
        throw Exception('No se encontró token de autenticación. Por favor, inicia sesión nuevamente.');
      }
      
      print('📤 Subiendo ${_imagenesSeleccionadas.length} imagen(es)...');
      print('   URL: ${ApiConstants.baseUrl}${ApiConstants.subirImagenesProducto}');
      print('   Token (primeros 50 chars): ${token.substring(0, token.length > 50 ? 50 : token.length)}...');
      
      final response = await dio.post(
        ApiConstants.subirImagenesProducto,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${token.trim()}',
            // No establecer Content-Type, Dio lo hace automáticamente para FormData
          },
        ),
      );

      print('📥 Respuesta de subida: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['urls'] != null) {
          final urls = List<String>.from(data['urls']);
          print('✅ ${urls.length} imagen(es) subida(s) correctamente');
          print('   URLs: $urls');
          return urls;
        } else {
          throw Exception(data['message'] ?? 'Error al subir imágenes');
        }
      } else {
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al subir imágenes: $e');
      if (e is DioException) {
        print('   Status: ${e.response?.statusCode}');
        print('   Message: ${e.message}');
        print('   Response: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGuardando = true;
    });

    try {
      // Primero subir las imágenes nuevas si hay
      List<String> urlsImagenesNuevas = [];
      if (_imagenesSeleccionadas.isNotEmpty) {
        try {
          urlsImagenesNuevas = await _subirImagenes();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${urlsImagenesNuevas.length} imagen(es) subida(s) correctamente'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al subir imágenes: ${e.toString()}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          // Continuar guardando el producto aunque falle la subida de imágenes
        }
      }

      // Preparar lista de todas las imágenes (URLs existentes + nuevas subidas)
      List<String> todasLasImagenes = [];
      todasLasImagenes.addAll(_imagenesUrlsActuales);
      todasLasImagenes.addAll(urlsImagenesNuevas);

      final Map<String, dynamic> datos = {
        'codigo': _codigoController.text.isEmpty ? null : _codigoController.text,
        'codigo_barras': _codigoBarrasController.text.isEmpty ? null : _codigoBarrasController.text,
        'nombre': _nombreController.text,
        'descripcion': _descripcionController.text.isEmpty ? null : _descripcionController.text,
        'categoria_id': _categoriaIdSeleccionada,
        'proveedor_id': _proveedorIdSeleccionado,
        'precio_compra': double.parse(_precioCompraController.text),
        'precio_venta': double.parse(_precioVentaController.text),
        'descuento_porcentaje': _descuentoPorcentajeController.text.isEmpty 
            ? 0.0 
            : double.parse(_descuentoPorcentajeController.text),
        'stock_actual': int.parse(_stockActualController.text),
        'stock_minimo': int.parse(_stockMinimoController.text),
        'unidad_medida': _unidadMedidaController.text,
        'fecha_vencimiento': _fechaVencimiento?.toIso8601String().split('T')[0],
        'estado': _estadoValue,
      };

      // Establecer imagen_url principal (primera imagen disponible)
      if (todasLasImagenes.isNotEmpty) {
        datos['imagen_url'] = todasLasImagenes[0];
        print('📸 Imagen principal: ${todasLasImagenes[0]}');
      }
      
      // Enviar lista de todas las imágenes
      if (todasLasImagenes.isNotEmpty) {
        datos['imagenes'] = todasLasImagenes;
        print('📸 Total de imágenes a guardar: ${todasLasImagenes.length}');
        print('   URLs: $todasLasImagenes');
      } else {
        print('⚠️ No hay imágenes para guardar');
      }

      if (widget.producto != null) {
        datos['id'] = widget.producto!.id;
      }

      print('💾 Guardando producto con datos:');
      print('   Nombre: ${datos['nombre']}');
      print('   imagen_url: ${datos['imagen_url']}');
      print('   imagenes: ${datos['imagenes']}');

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
              ModalSectionBuilder.buildSectionTitle('Imágenes del Producto', Icons.photo_library),
              
              // Botón para agregar imágenes
              ElevatedButton.icon(
                onPressed: _seleccionarImagenes,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Agregar Imágenes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
              const SizedBox(height: 16),
              
              // Mostrar imágenes existentes (URLs)
              if (_imagenesUrlsActuales.isNotEmpty)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(_imagenesUrlsActuales.length, (index) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _imagenesUrlsActuales[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.broken_image, size: 50, color: Colors.grey.shade400);
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _eliminarImagen(index, true),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              
              // Mostrar imágenes seleccionadas (archivos locales)
              if (_imagenesSeleccionadas.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(_imagenesSeleccionadas.length, (index) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _imagenesSeleccionadas[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _eliminarImagen(index, false),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
              
              if (_imagenesUrlsActuales.isEmpty && _imagenesSeleccionadas.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No hay imágenes. Presiona "Agregar Imágenes" para seleccionar.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              
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
              const SizedBox(height: 16),
              ModalSectionBuilder.buildTextField(
                controller: _descuentoPorcentajeController,
                label: 'Descuento (%)',
                icon: Icons.local_offer,
                hint: 'Ej: 10 para 10% de descuento',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final descuento = double.tryParse(value);
                    if (descuento == null) {
                      return 'Número inválido';
                    }
                    if (descuento < 0 || descuento > 100) {
                      return 'Debe estar entre 0 y 100';
                    }
                  }
                  return null;
                },
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

