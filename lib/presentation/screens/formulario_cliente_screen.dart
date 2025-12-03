import 'package:flutter/material.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/cliente_model.dart';
import '../../data/services/reniec_service.dart';
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
  final ReniecService _reniecService = ReniecService();
  final _formKey = GlobalKey<FormState>();
  bool _isGuardando = false;

  late final TextEditingController _nombresController;
  late final TextEditingController _apellidoPaternoController;
  late final TextEditingController _apellidoMaternoController;
  late final TextEditingController _documentoController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _emailController;
  late final TextEditingController _direccionController;
  
  String _tipoDocumentoValue = 'DNI';
  String _estadoValue = 'activo';
  bool _verificandoDNI = false;
  String? _mensajeVerificacionDNI;
  bool? _dniValido;
  bool _camposBloqueados = false; // Controla si los campos están bloqueados

  @override
  void initState() {
    super.initState();
    _nombresController = TextEditingController(text: widget.cliente?.nombres ?? '');
    _apellidoPaternoController = TextEditingController(text: widget.cliente?.apellidoPaterno ?? '');
    _apellidoMaternoController = TextEditingController(text: widget.cliente?.apellidoMaterno ?? '');
    _documentoController = TextEditingController(text: widget.cliente?.documento ?? '');
    _telefonoController = TextEditingController(text: widget.cliente?.telefono ?? '');
    _emailController = TextEditingController(text: widget.cliente?.email ?? '');
    _direccionController = TextEditingController(text: widget.cliente?.direccion ?? '');
    _tipoDocumentoValue = widget.cliente?.tipoDocumento ?? 'DNI';
    _estadoValue = widget.cliente?.estado ?? 'activo';
    
    // Si es un cliente nuevo (sin datos), bloquear campos desde el inicio
    // Si es edición y tiene DNI, permitir edición manual
    if (widget.cliente == null) {
      _camposBloqueados = true; // Bloquear desde el inicio para nuevos clientes
    } else if (widget.cliente!.documento != null && widget.cliente!.documento!.isNotEmpty) {
      _camposBloqueados = false; // Permitir edición si ya tiene datos
    } else {
      _camposBloqueados = true; // Bloquear si no tiene documento
    }
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _documentoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _verificarDNI({bool mostrarDialogo = false}) async {
    final dni = _documentoController.text.trim();
    
    if (dni.isEmpty) {
      setState(() {
        _dniValido = null;
        _mensajeVerificacionDNI = null;
        _verificandoDNI = false;
      });
      return;
    }

    if (_tipoDocumentoValue != 'DNI') {
      setState(() {
        _dniValido = null;
        _mensajeVerificacionDNI = null;
        _verificandoDNI = false;
      });
      return;
    }

    // Validar formato básico
    final dniLimpio = dni.replaceAll(RegExp(r'[^0-9]'), '');
    if (dniLimpio.length < 8) {
      setState(() {
        _dniValido = null;
        _mensajeVerificacionDNI = null;
        _verificandoDNI = false;
      });
      return;
    }

    setState(() {
      _verificandoDNI = true;
      _mensajeVerificacionDNI = null;
      _dniValido = null;
    });

    try {
      final resultado = await _reniecService.verificarDNI(dni, tipoDocumento: _tipoDocumentoValue);

      setState(() {
        _dniValido = resultado['valido'] as bool;
        _mensajeVerificacionDNI = resultado['mensaje'] as String;
      });

      if (resultado['valido'] == true && resultado['datos'] != null) {
        final datos = resultado['datos'] as Map<String, dynamic>;
        
        // Prellenar nombres, apellido paterno y apellido materno si están disponibles
        // Solo autocompletar si el campo está vacío (para no sobrescribir datos ya ingresados)
        if (datos['nombre'] != null && _nombresController.text.trim().isEmpty) {
          _nombresController.text = datos['nombre'].toString();
        }
        if (datos['apellido_paterno'] != null && _apellidoPaternoController.text.trim().isEmpty) {
          _apellidoPaternoController.text = datos['apellido_paterno'].toString();
        }
        if (datos['apellido_materno'] != null && _apellidoMaternoController.text.trim().isEmpty) {
          _apellidoMaternoController.text = datos['apellido_materno'].toString();
        }
        
        // Bloquear los campos una vez que se autocompletan desde RENIEC
        setState(() {
          _camposBloqueados = true;
        });
      } else if (mostrarDialogo && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${resultado['mensaje']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _dniValido = false;
        _mensajeVerificacionDNI = 'Error al verificar el DNI';
      });
      if (mostrarDialogo && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al verificar el DNI\n\n${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _verificandoDNI = false;
      });
    }
  }

  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGuardando = true;
    });

    try {
      final Map<String, dynamic> datos = {
        'nombres': _nombresController.text,
        'apellido_paterno': _apellidoPaternoController.text.isEmpty ? null : _apellidoPaternoController.text,
        'apellido_materno': _apellidoMaternoController.text.isEmpty ? null : _apellidoMaternoController.text,
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
              // Tipo de documento y documento (PRIMERO)
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
                            _dniValido = null;
                            _mensajeVerificacionDNI = null;
                            _camposBloqueados = true; // Bloquear campos al cambiar tipo de documento
                            // Limpiar campos si no es DNI
                            if (value != 'DNI') {
                              _nombresController.clear();
                              _apellidoPaternoController.clear();
                              _apellidoMaternoController.clear();
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _documentoController,
                      decoration: InputDecoration(
                        labelText: 'Número de Documento *',
                        prefixIcon: const Icon(Icons.numbers),
                        suffixIcon: _tipoDocumentoValue == 'DNI'
                            ? _verificandoDNI
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    _dniValido == true
                                        ? Icons.check_circle
                                        : _dniValido == false
                                            ? Icons.error
                                            : Icons.verified_user,
                                    color: _dniValido == true
                                        ? Colors.green
                                        : _dniValido == false
                                            ? Colors.red
                                            : Colors.grey,
                                  )
                            : null,
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
                        helperText: _tipoDocumentoValue == 'DNI' 
                            ? 'Máximo 8 dígitos, solo números. Se verificará automáticamente'
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: _tipoDocumentoValue == 'DNI' ? 8 : null,
                      inputFormatters: _tipoDocumentoValue == 'DNI' 
                          ? [Validators.dniFormatter]
                          : null,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El documento es requerido';
                        }
                        if (_tipoDocumentoValue == 'DNI' && _dniValido != true && widget.cliente == null) {
                          return 'El DNI debe ser verificado';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _dniValido = null;
                          _mensajeVerificacionDNI = null;
                          _camposBloqueados = true; // Mantener bloqueados hasta verificar
                          // Limpiar campos cuando se cambia el DNI
                          if (_tipoDocumentoValue == 'DNI') {
                            _nombresController.clear();
                            _apellidoPaternoController.clear();
                            _apellidoMaternoController.clear();
                          }
                        });
                        
                        // Verificar automáticamente después de un breve delay
                        if (_tipoDocumentoValue == 'DNI' && value.trim().length >= 8) {
                          Future.delayed(const Duration(milliseconds: 800), () {
                            if (mounted && _documentoController.text.trim() == value.trim()) {
                              _verificarDNI();
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              // Mensaje de verificación de DNI
              if (_tipoDocumentoValue == 'DNI' && _mensajeVerificacionDNI != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                  child: Row(
                    children: [
                      Icon(
                        _dniValido == true
                            ? Icons.check_circle
                            : Icons.error,
                        color: _dniValido == true
                            ? Colors.green
                            : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _mensajeVerificacionDNI!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _dniValido == true
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_tipoDocumentoValue == 'DNI' && _mensajeVerificacionDNI == null && !_verificandoDNI && _documentoController.text.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ingrese el DNI para autocompletar los datos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              // Nombres (BLOQUEADO hasta verificar DNI)
              TextFormField(
                controller: _nombresController,
                readOnly: _camposBloqueados || (_tipoDocumentoValue == 'DNI' && _dniValido != true),
                decoration: InputDecoration(
                  labelText: 'Nombres *',
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: (_camposBloqueados || (_tipoDocumentoValue == 'DNI' && _dniValido != true))
                      ? const Icon(Icons.lock, color: Colors.orange, size: 20)
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: (_camposBloqueados || (_tipoDocumentoValue == 'DNI' && _dniValido != true)) 
                      ? Colors.grey.shade100 
                      : Colors.grey.shade50,
                  hintText: (_tipoDocumentoValue == 'DNI' && _dniValido != true)
                      ? 'Verifique el DNI primero'
                      : _camposBloqueados 
                          ? 'Verificado desde RENIEC' 
                          : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Los nombres son requeridos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Apellido Paterno (BLOQUEADO hasta verificar DNI)
              TextFormField(
                controller: _apellidoPaternoController,
                readOnly: _camposBloqueados || (_tipoDocumentoValue == 'DNI' && _dniValido != true),
                decoration: InputDecoration(
                  labelText: 'Apellido Paterno *',
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: (_camposBloqueados || (_tipoDocumentoValue == 'DNI' && _dniValido != true))
                      ? const Icon(Icons.lock, color: Colors.orange, size: 20)
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: (_camposBloqueados || (_tipoDocumentoValue == 'DNI' && _dniValido != true)) 
                      ? Colors.grey.shade100 
                      : Colors.grey.shade50,
                  hintText: (_tipoDocumentoValue == 'DNI' && _dniValido != true)
                      ? 'Verifique el DNI primero'
                      : _camposBloqueados 
                          ? 'Verificado desde RENIEC' 
                          : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El apellido paterno es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Apellido Materno (BLOQUEADO hasta verificar DNI)
              TextFormField(
                controller: _apellidoMaternoController,
                readOnly: _camposBloqueados || (_tipoDocumentoValue == 'DNI' && _dniValido != true),
                decoration: InputDecoration(
                  labelText: 'Apellido Materno',
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: (_camposBloqueados || (_tipoDocumentoValue == 'DNI' && _dniValido != true))
                      ? const Icon(Icons.lock, color: Colors.orange, size: 20)
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: (_camposBloqueados || (_tipoDocumentoValue == 'DNI' && _dniValido != true)) 
                      ? Colors.grey.shade100 
                      : Colors.grey.shade50,
                  hintText: (_tipoDocumentoValue == 'DNI' && _dniValido != true)
                      ? 'Verifique el DNI primero'
                      : _camposBloqueados 
                          ? 'Verificado desde RENIEC' 
                          : null,
                ),
              ),
              const SizedBox(height: 16              ),
              
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

