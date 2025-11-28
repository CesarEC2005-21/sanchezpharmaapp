import 'package:flutter/material.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/cliente_model.dart';
import '../../core/utils/validators.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_modal_dialog.dart';

class FormularioClienteScreen extends StatefulWidget {
  final ClienteModel? cliente;

  const FormularioClienteScreen({
    super.key,
    this.cliente,
  });

  @override
  State<FormularioClienteScreen> createState() => _FormularioClienteScreenState();
}

class _FormularioClienteScreenState extends State<FormularioClienteScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  final _formKey = GlobalKey<FormState>();
  bool _isGuardando = false;

  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _documentoController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _emailController;
  late final TextEditingController _direccionController;
  
  String _tipoDocumentoValue = 'DNI';
  String _estadoValue = 'activo';

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cliente?.nombre ?? '');
    _apellidoController = TextEditingController(text: widget.cliente?.apellido ?? '');
    _documentoController = TextEditingController(text: widget.cliente?.documento ?? '');
    _telefonoController = TextEditingController(text: widget.cliente?.telefono ?? '');
    _emailController = TextEditingController(text: widget.cliente?.email ?? '');
    _direccionController = TextEditingController(text: widget.cliente?.direccion ?? '');
    _tipoDocumentoValue = widget.cliente?.tipoDocumento ?? 'DNI';
    _estadoValue = widget.cliente?.estado ?? 'activo';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _documentoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGuardando = true;
    });

    try {
      final Map<String, dynamic> datos = {
        'nombre': _nombreController.text,
        'apellido': _apellidoController.text.isEmpty ? null : _apellidoController.text,
        'documento': _documentoController.text.isEmpty ? null : _documentoController.text,
        'tipo_documento': _tipoDocumentoValue,
        'telefono': _telefonoController.text.isEmpty ? null : _telefonoController.text,
        'email': _emailController.text.isEmpty ? null : _emailController.text,
        'direccion': _direccionController.text.isEmpty ? null : _direccionController.text,
        'estado': _estadoValue,
      };

      if (widget.cliente != null) {
        datos['id'] = widget.cliente!.id;
      }

      final response = widget.cliente == null
          ? await _apiService.registrarCliente(datos)
          : await _apiService.editarCliente(datos);

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
        title: Text(widget.cliente == null ? 'Registrar Cliente' : 'Editar Cliente'),
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
              ModalSectionBuilder.buildSectionTitle('Información Personal', Icons.person),
              ModalSectionBuilder.buildTextField(
                controller: _nombreController,
                label: 'Nombre',
                icon: Icons.person_outline,
                required: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              ModalSectionBuilder.buildTextField(
                controller: _apellidoController,
                label: 'Apellido',
                icon: Icons.person_outline,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<String>(
                        value: _tipoDocumentoValue,
                        decoration: InputDecoration(
                          labelText: 'Tipo Doc.',
                          prefixIcon: const Icon(Icons.badge, color: AppColors.primary),
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
                        items: const [
                          DropdownMenuItem(value: 'DNI', child: Text('DNI')),
                          DropdownMenuItem(value: 'RUC', child: Text('RUC')),
                          DropdownMenuItem(value: 'PASAPORTE', child: Text('Pasaporte')),
                          DropdownMenuItem(value: 'OTRO', child: Text('Otro')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _tipoDocumentoValue = value ?? 'DNI';
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: ModalSectionBuilder.buildTextField(
                      controller: _documentoController,
                      label: 'Número de Documento',
                      icon: Icons.numbers,
                    ),
                  ),
                ],
              ),
              
              ModalSectionBuilder.buildSectionTitle('Información de Contacto', Icons.contact_phone),
              ModalSectionBuilder.buildTextField(
                controller: _telefonoController,
                label: 'Teléfono',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                maxLength: 9,
                inputFormatters: [Validators.telefonoFormatter],
                validator: Validators.validateTelefonoOpcional,
              ),
              ModalSectionBuilder.buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
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
                maxLines: 2,
              ),
              
              ModalSectionBuilder.buildSectionTitle('Estado', Icons.settings),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  value: _estadoValue,
                  decoration: InputDecoration(
                    labelText: 'Estado',
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
                  onPressed: _isGuardando ? null : _guardarCliente,
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

