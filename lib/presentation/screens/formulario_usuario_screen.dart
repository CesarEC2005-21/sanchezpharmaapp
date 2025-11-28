import 'package:flutter/material.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/usuario_model.dart';
import '../../data/models/rol_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/role_constants.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../widgets/custom_modal_dialog.dart';

class FormularioUsuarioScreen extends StatefulWidget {
  final UsuarioModel? usuario;
  final List<RolModel> roles;

  const FormularioUsuarioScreen({
    super.key,
    this.usuario,
    required this.roles,
  });

  @override
  State<FormularioUsuarioScreen> createState() => _FormularioUsuarioScreenState();
}

class _FormularioUsuarioScreenState extends State<FormularioUsuarioScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  final _formKey = GlobalKey<FormState>();
  bool _isGuardando = false;

  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _edadController;
  
  String _sexoValue = 'M';
  int? _rolIdSeleccionado;
  int? _rolIdUsuarioActual;

  @override
  void initState() {
    super.initState();
    _cargarRolUsuarioActual();
    _usernameController = TextEditingController(text: widget.usuario?.username ?? '');
    _emailController = TextEditingController(text: widget.usuario?.email ?? '');
    _passwordController = TextEditingController();
    _nombreController = TextEditingController(text: widget.usuario?.nombre ?? '');
    _apellidoController = TextEditingController(text: widget.usuario?.apellido ?? '');
    _edadController = TextEditingController(text: widget.usuario?.edad.toString() ?? '');
    _sexoValue = widget.usuario?.sexo ?? 'M';
    _rolIdSeleccionado = widget.usuario?.rolId ?? (widget.roles.isNotEmpty ? widget.roles.first.id : 1);
  }

  Future<void> _cargarRolUsuarioActual() async {
    final rolId = await SharedPrefsHelper.getRolId();
    setState(() {
      _rolIdUsuarioActual = rolId;
      // Si el usuario actual no es Ingeniero y el rol seleccionado es Ingeniero,
      // cambiar a un rol válido
      if (rolId != RoleConstants.ROL_INGENIERO && 
          _rolIdSeleccionado == RoleConstants.ROL_INGENIERO) {
        // Filtrar roles excluyendo Ingeniero
        final rolesDisponibles = widget.roles
            .where((rol) => rol.id != RoleConstants.ROL_INGENIERO)
            .toList();
        if (rolesDisponibles.isNotEmpty) {
          _rolIdSeleccionado = rolesDisponibles.first.id;
        }
      }
    });
  }

  // Obtener roles disponibles (excluyendo Ingeniero si el usuario actual no es Ingeniero)
  List<RolModel> _getRolesDisponibles() {
    // Si el usuario actual es Ingeniero, puede ver todos los roles
    if (_rolIdUsuarioActual == RoleConstants.ROL_INGENIERO) {
      return widget.roles;
    }
    // Si no es Ingeniero, excluir el rol Ingeniero
    return widget.roles.where((rol) => rol.id != RoleConstants.ROL_INGENIERO).toList();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _edadController.dispose();
    super.dispose();
  }

  Future<void> _guardarUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_rolIdSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un rol'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validar que no se pueda crear/editar un usuario con rol Ingeniero si el usuario actual no es Ingeniero
    if (_rolIdSeleccionado == RoleConstants.ROL_INGENIERO && 
        _rolIdUsuarioActual != RoleConstants.ROL_INGENIERO) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tiene permisos para crear o asignar el rol de Ingeniero'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isGuardando = true;
    });

    try {
      final Map<String, dynamic> datos = {
        'username': _usernameController.text,
        'email': _emailController.text,
        'nombre': _nombreController.text,
        'apellido': _apellidoController.text,
        'edad': int.parse(_edadController.text),
        'sexo': _sexoValue,
        'rol_id': _rolIdSeleccionado!,
      };

      if (widget.usuario == null) {
        datos['password'] = _passwordController.text;
      } else if (_passwordController.text.isNotEmpty) {
        datos['password'] = _passwordController.text;
      }

      if (widget.usuario != null) {
        datos['id'] = widget.usuario!.id;
      }

      final response = widget.usuario == null
          ? await _apiService.registrarUsuario(datos)
          : await _apiService.editarUsuario(datos);

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
        title: Text(widget.usuario == null ? 'Registrar Usuario' : 'Editar Usuario'),
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
              ModalSectionBuilder.buildSectionTitle('Credenciales de Acceso', Icons.lock),
              ModalSectionBuilder.buildTextField(
                controller: _usernameController,
                label: 'Nombre de Usuario',
                icon: Icons.person,
                hint: 'Ingrese el username',
                required: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El username es requerido';
                  }
                  return null;
                },
              ),
              ModalSectionBuilder.buildTextField(
                controller: _emailController,
                label: 'Correo Electrónico',
                icon: Icons.email,
                hint: 'usuario@sanchez-pharma.com',
                keyboardType: TextInputType.emailAddress,
                required: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El email es requerido';
                  }
                  if (!value.contains('@')) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: widget.usuario == null ? 'Contraseña *' : 'Nueva Contraseña',
                    hintText: widget.usuario == null ? 'Ingrese una contraseña segura' : 'Dejar vacío para mantener la actual',
                    prefixIcon: const Icon(Icons.password, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
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
                  obscureText: true,
                  validator: (value) {
                    if (widget.usuario == null && (value == null || value.isEmpty)) {
                      return 'La contraseña es requerida';
                    }
                    return null;
                  },
                ),
              ),

              ModalSectionBuilder.buildSectionTitle('Información Personal', Icons.badge),
              Row(
                children: [
                  Expanded(
                    child: ModalSectionBuilder.buildTextField(
                      controller: _nombreController,
                      label: 'Nombre',
                      icon: Icons.person_outline,
                      required: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModalSectionBuilder.buildTextField(
                      controller: _apellidoController,
                      label: 'Apellido',
                      icon: Icons.person_outline,
                      required: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: ModalSectionBuilder.buildTextField(
                      controller: _edadController,
                      label: 'Edad',
                      icon: Icons.cake,
                      keyboardType: TextInputType.number,
                      required: true,
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
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<String>(
                        value: _sexoValue,
                        decoration: InputDecoration(
                          labelText: 'Sexo *',
                          prefixIcon: const Icon(Icons.wc, color: AppColors.primary),
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
                          DropdownMenuItem(value: 'M', child: Text('M')),
                          DropdownMenuItem(value: 'F', child: Text('F')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sexoValue = value ?? 'M';
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),

              ModalSectionBuilder.buildSectionTitle('Rol y Permisos', Icons.admin_panel_settings),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<int>(
                  value: _rolIdSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Rol del Usuario *',
                    prefixIcon: const Icon(Icons.security, color: AppColors.primary),
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
                  items: _getRolesDisponibles().map((rol) {
                    return DropdownMenuItem<int>(
                      value: rol.id,
                      child: Text(rol.nombre),
                    );
                  }).toList(),
                  onChanged: (value) {
                    // Si el usuario actual no es Ingeniero, no permitir seleccionar rol Ingeniero
                    if (value == RoleConstants.ROL_INGENIERO && 
                        _rolIdUsuarioActual != RoleConstants.ROL_INGENIERO) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No tiene permisos para asignar el rol de Ingeniero'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _rolIdSeleccionado = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'El rol es requerido';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGuardando ? null : _guardarUsuario,
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

