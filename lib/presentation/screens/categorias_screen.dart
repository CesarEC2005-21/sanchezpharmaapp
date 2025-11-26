import 'package:flutter/material.dart';
import 'package:retrofit/retrofit.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/categoria_model.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_modal_dialog.dart';
import 'formulario_categoria_screen.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<CategoriaModel> _categorias = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
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

      final response = await _apiService.getCategorias();

      if (response.response.statusCode == 200) {
        final data = response.data;

        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> categoriasJson = data['data'];
          setState(() {
            _categorias = categoriasJson
                .map((json) => CategoriaModel.fromJson(json))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Error al cargar categorías';
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
        Icon(icon, size: 20, color: Colors.purple.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.purple.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(color: Colors.purple.shade200, thickness: 1),
        ),
      ],
    );
  }

  Future<void> _mostrarFormularioCategoria({CategoriaModel? categoria}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioCategoriaScreen(
          categoria: categoria,
        ),
      ),
    );

    if (result == true) {
      _cargarCategorias();
    }
  }

  // Método antiguo mantenido para referencia pero no usado
  Future<void> _mostrarFormularioCategoriaAntiguo({CategoriaModel? categoria}) async {
    final formKey = GlobalKey<FormState>();

    final nombreController = TextEditingController(text: categoria?.nombre ?? '');
    final descripcionController = TextEditingController(text: categoria?.descripcion ?? '');
    String estadoValue = categoria?.estado ?? 'activo';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomModalDialog(
        title: categoria == null ? 'Registrar Categoría' : 'Editar Categoría',
        icon: categoria == null ? Icons.add_box : Icons.edit,
        content: StatefulBuilder(
          builder: (context, setState) => Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ModalSectionBuilder.buildSectionTitle('Información de la Categoría', Icons.label),
                ModalSectionBuilder.buildTextField(
                  controller: nombreController,
                  label: 'Nombre de la Categoría',
                  icon: Icons.category,
                  hint: 'Ej: Medicamentos, Suplementos, etc.',
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
                  hint: 'Describe esta categoría de productos',
                  maxLines: 4,
                ),
                
                ModalSectionBuilder.buildSectionTitle('Estado', Icons.settings),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: estadoValue,
                    decoration: InputDecoration(
                      labelText: 'Estado de la Categoría',
                      prefixIcon: Icon(
                        estadoValue == 'activo' ? Icons.check_circle : Icons.cancel,
                        color: estadoValue == 'activo' ? Colors.green : Colors.grey,
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
                          : Colors.grey.shade100,
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
                await _guardarCategoria(
                  categoria: categoria,
                  nombre: nombreController.text,
                  descripcion: descripcionController.text.isEmpty ? null : descripcionController.text,
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

  Future<void> _guardarCategoria({
    CategoriaModel? categoria,
    required String nombre,
    String? descripcion,
    required String estado,
  }) async {
    try {
      final Map<String, dynamic> datos = {
        'nombre': nombre,
        'descripcion': descripcion,
        'estado': estado,
      };

      HttpResponse<dynamic> response;

      if (categoria == null) {
        response = await _apiService.registrarCategoria(datos);
      } else {
        datos['id'] = categoria.id;
        response = await _apiService.editarCategoria(datos);
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
          _cargarCategorias();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Categorías'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarCategorias,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
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
                        onPressed: _cargarCategorias,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
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
                            'No hay categorías registradas',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarCategorias,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _categorias.length,
                        itemBuilder: (context, index) {
                          final categoria = _categorias[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 8,
                            ),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: categoria.estado == 'activo'
                                    ? Colors.green.shade700
                                    : Colors.grey,
                                child: const Icon(Icons.category, color: Colors.white),
                              ),
                              title: Text(
                                categoria.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (categoria.descripcion != null)
                                    Text(categoria.descripcion!),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: categoria.estado == 'activo'
                                              ? Colors.green.shade100
                                              : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          categoria.estado == 'activo' ? 'Activo' : 'Inactivo',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: categoria.estado == 'activo'
                                                ? Colors.green.shade700
                                                : Colors.grey.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.green),
                                onPressed: () => _mostrarFormularioCategoria(categoria: categoria),
                                tooltip: 'Editar',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioCategoria(),
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

