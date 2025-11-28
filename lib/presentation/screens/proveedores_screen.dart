import 'package:flutter/material.dart';
import 'package:retrofit/retrofit.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/proveedor_model.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/utils/validators.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_modal_dialog.dart';
import 'formulario_proveedor_screen.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<ProveedorModel> _proveedores = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarProveedores();
  }

  Future<void> _cargarProveedores() async {
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

      final response = await _apiService.getProveedores();

      if (response.response.statusCode == 200) {
        final data = response.data;

        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> proveedoresJson = data['data'];
          setState(() {
            _proveedores = proveedoresJson
                .map((json) => ProveedorModel.fromJson(json))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Error al cargar proveedores';
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
        Icon(icon, size: 20, color: Colors.orange.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(color: Colors.orange.shade200, thickness: 1),
        ),
      ],
    );
  }

  Future<void> _mostrarFormularioProveedor({ProveedorModel? proveedor}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioProveedorScreen(
          proveedor: proveedor,
        ),
      ),
    );

    if (result == true) {
      _cargarProveedores();
    }
  }

  // Método antiguo mantenido para referencia pero no usado
  Future<void> _mostrarFormularioProveedorAntiguo({ProveedorModel? proveedor}) async {
    final formKey = GlobalKey<FormState>();

    final nombreController = TextEditingController(text: proveedor?.nombre ?? '');
    final contactoController = TextEditingController(text: proveedor?.contacto ?? '');
    final telefonoController = TextEditingController(text: proveedor?.telefono ?? '');
    final emailController = TextEditingController(text: proveedor?.email ?? '');
    final direccionController = TextEditingController(text: proveedor?.direccion ?? '');
    String estadoValue = proveedor?.estado ?? 'activo';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomModalDialog(
        title: proveedor == null ? 'Registrar Proveedor' : 'Editar Proveedor',
        icon: proveedor == null ? Icons.add_business : Icons.edit,
        content: StatefulBuilder(
          builder: (context, setState) => Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ModalSectionBuilder.buildSectionTitle('Información del Proveedor', Icons.business),
                ModalSectionBuilder.buildTextField(
                  controller: nombreController,
                  label: 'Nombre del Proveedor',
                  icon: Icons.business_center,
                  required: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                ModalSectionBuilder.buildTextField(
                  controller: contactoController,
                  label: 'Persona de Contacto',
                  icon: Icons.person,
                  hint: 'Nombre del representante',
                ),
                
                ModalSectionBuilder.buildSectionTitle('Información de Contacto', Icons.contact_phone),
                ModalSectionBuilder.buildTextField(
                  controller: telefonoController,
                  label: 'Teléfono',
                  icon: Icons.phone,
                  hint: '987654321',
                  keyboardType: TextInputType.phone,
                  maxLength: 9,
                  inputFormatters: [Validators.telefonoFormatter],
                  validator: Validators.validateTelefonoOpcional,
                ),
                ModalSectionBuilder.buildTextField(
                  controller: emailController,
                  label: 'Email',
                  icon: Icons.email,
                  hint: 'proveedor@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && !value.contains('@')) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                ModalSectionBuilder.buildTextField(
                  controller: direccionController,
                  label: 'Dirección',
                  icon: Icons.location_on,
                  hint: 'Dirección completa del proveedor',
                  maxLines: 3,
                ),
                
                ModalSectionBuilder.buildSectionTitle('Estado', Icons.settings),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: estadoValue,
                    decoration: InputDecoration(
                      labelText: 'Estado del Proveedor',
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
                await _guardarProveedor(
                  proveedor: proveedor,
                  nombre: nombreController.text,
                  contacto: contactoController.text.isEmpty ? null : contactoController.text,
                  telefono: telefonoController.text.isEmpty ? null : telefonoController.text,
                  email: emailController.text.isEmpty ? null : emailController.text,
                  direccion: direccionController.text.isEmpty ? null : direccionController.text,
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

  Future<void> _guardarProveedor({
    ProveedorModel? proveedor,
    required String nombre,
    String? contacto,
    String? telefono,
    String? email,
    String? direccion,
    required String estado,
  }) async {
    try {
      final Map<String, dynamic> datos = {
        'nombre': nombre,
        'contacto': contacto,
        'telefono': telefono,
        'email': email,
        'direccion': direccion,
        'estado': estado,
      };

      HttpResponse<dynamic> response;

      if (proveedor == null) {
        response = await _apiService.registrarProveedor(datos);
      } else {
        datos['id'] = proveedor.id;
        response = await _apiService.editarProveedor(datos);
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
          _cargarProveedores();
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
        title: const Text('Gestión de Proveedores'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarProveedores,
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
                        onPressed: _cargarProveedores,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _proveedores.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay proveedores registrados',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarProveedores,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _proveedores.length,
                        itemBuilder: (context, index) {
                          final proveedor = _proveedores[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 8,
                            ),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: proveedor.estado == 'activo'
                                    ? Colors.orange.shade700
                                    : Colors.grey,
                                child: const Icon(Icons.local_shipping, color: Colors.white),
                              ),
                              title: Text(
                                proveedor.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (proveedor.contacto != null)
                                    Text('Contacto: ${proveedor.contacto}'),
                                  if (proveedor.telefono != null)
                                    Text('Tel: ${proveedor.telefono}'),
                                  if (proveedor.email != null)
                                    Text('Email: ${proveedor.email}'),
                                  if (proveedor.direccion != null)
                                    Text('Dirección: ${proveedor.direccion}'),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: proveedor.estado == 'activo'
                                              ? Colors.orange.shade100
                                              : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          proveedor.estado == 'activo' ? 'Activo' : 'Inactivo',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: proveedor.estado == 'activo'
                                                ? Colors.orange.shade700
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
                                onPressed: () => _mostrarFormularioProveedor(proveedor: proveedor),
                                tooltip: 'Editar',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioProveedor(),
        backgroundColor: Colors.orange.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

