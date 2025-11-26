import 'package:flutter/material.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/proveedor_model.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_modal_dialog.dart';

class FormularioProveedorScreen extends StatefulWidget {
  final ProveedorModel? proveedor;

  const FormularioProveedorScreen({
    super.key,
    this.proveedor,
  });

  @override
  State<FormularioProveedorScreen> createState() => _FormularioProveedorScreenState();
}

class _FormularioProveedorScreenState extends State<FormularioProveedorScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  final _formKey = GlobalKey<FormState>();
  bool _isGuardando = false;

  late final TextEditingController _nombreController;
  late final TextEditingController _contactoController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _emailController;
  late final TextEditingController _direccionController;
  String _estadoValue = 'activo';

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.proveedor?.nombre ?? '');
    _contactoController = TextEditingController(text: widget.proveedor?.contacto ?? '');
    _telefonoController = TextEditingController(text: widget.proveedor?.telefono ?? '');
    _emailController = TextEditingController(text: widget.proveedor?.email ?? '');
    _direccionController = TextEditingController(text: widget.proveedor?.direccion ?? '');
    _estadoValue = widget.proveedor?.estado ?? 'activo';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _contactoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _guardarProveedor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGuardando = true;
    });

    try {
      final Map<String, dynamic> datos = {
        'nombre': _nombreController.text,
        'contacto': _contactoController.text.isEmpty ? null : _contactoController.text,
        'telefono': _telefonoController.text.isEmpty ? null : _telefonoController.text,
        'email': _emailController.text.isEmpty ? null : _emailController.text,
        'direccion': _direccionController.text.isEmpty ? null : _direccionController.text,
        'estado': _estadoValue,
      };

      if (widget.proveedor != null) {
        datos['id'] = widget.proveedor!.id;
      }

      final response = widget.proveedor == null
          ? await _apiService.registrarProveedor(datos)
          : await _apiService.editarProveedor(datos);

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
        title: Text(widget.proveedor == null ? 'Registrar Proveedor' : 'Editar Proveedor'),
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
              ModalSectionBuilder.buildSectionTitle('Información del Proveedor', Icons.business),
              ModalSectionBuilder.buildTextField(
                controller: _nombreController,
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
                controller: _contactoController,
                label: 'Persona de Contacto',
                icon: Icons.person,
                hint: 'Nombre del representante',
              ),
              
              ModalSectionBuilder.buildSectionTitle('Información de Contacto', Icons.contact_phone),
              ModalSectionBuilder.buildTextField(
                controller: _telefonoController,
                label: 'Teléfono',
                icon: Icons.phone,
                hint: '999 999 999',
                keyboardType: TextInputType.phone,
              ),
              ModalSectionBuilder.buildTextField(
                controller: _emailController,
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
                controller: _direccionController,
                label: 'Dirección',
                icon: Icons.location_on,
                hint: 'Dirección completa del proveedor',
                maxLines: 3,
              ),
              
              ModalSectionBuilder.buildSectionTitle('Estado', Icons.settings),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  value: _estadoValue,
                  decoration: InputDecoration(
                    labelText: 'Estado del Proveedor',
                    prefixIcon: Icon(
                      _estadoValue == 'activo' ? Icons.check_circle : Icons.cancel,
                      color: _estadoValue == 'activo' ? Colors.green : Colors.grey,
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
                      _estadoValue = value ?? 'activo';
                    });
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGuardando ? null : _guardarProveedor,
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

