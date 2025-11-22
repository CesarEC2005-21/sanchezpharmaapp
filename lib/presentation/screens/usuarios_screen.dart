import 'package:flutter/material.dart';
import 'package:retrofit/retrofit.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/usuario_model.dart';
import '../../data/models/rol_model.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_modal_dialog.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<UsuarioModel> _usuarios = [];
  List<UsuarioModel> _usuariosFiltrados = [];
  List<RolModel> _roles = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _rolFiltroSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
    _cargarRoles();
  }

  Future<void> _cargarRoles() async {
    try {
      final response = await _apiService.getRoles();
      
      if (response.response.statusCode == 200) {
        final data = response.data;
        
        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> rolesJson = data['data'];
          setState(() {
            _roles = rolesJson
                .map((json) => RolModel.fromJson(json))
                .toList();
          });
        } else {
          // Si no hay roles en el servidor, usar roles por defecto
          _roles = _getRolesPorDefecto();
        }
      } else {
        // Si falla la petición, usar roles por defecto
        _roles = _getRolesPorDefecto();
      }
    } catch (e) {
      // Si hay error, usar roles por defecto
      print('Error al cargar roles: $e');
      _roles = _getRolesPorDefecto();
    }
  }

  List<RolModel> _getRolesPorDefecto() {
    // Roles comunes por defecto si no hay endpoint o falla
    return [
      RolModel(id: 1, nombre: 'Administrador', descripcion: 'Rol de administrador'),
      RolModel(id: 2, nombre: 'Usuario', descripcion: 'Rol de usuario estándar'),
      RolModel(id: 3, nombre: 'Empleado', descripcion: 'Rol de empleado'),
      RolModel(id: 4, nombre: 'Cliente', descripcion: 'Rol de cliente'),
    ];
  }

  void _aplicarFiltro() {
    if (_rolFiltroSeleccionado == null) {
      _usuariosFiltrados = List.from(_usuarios);
    } else {
      _usuariosFiltrados = _usuarios
          .where((usuario) => usuario.rolId == _rolFiltroSeleccionado)
          .toList();
    }
  }

  Future<void> _cargarUsuarios() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verificar que el token esté disponible antes de hacer la petición
      final token = await SharedPrefsHelper.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'No hay sesión activa. Por favor, inicie sesión nuevamente.';
          _isLoading = false;
        });
        return;
      }

      final response = await _apiService.getUsuarios();
      
      if (response.response.statusCode == 200) {
        final data = response.data;
        
        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> usuariosJson = data['data'];
          setState(() {
            _usuarios = usuariosJson
                .map((json) => UsuarioModel.fromJson(json))
                .toList();
            _aplicarFiltro();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Error al cargar usuarios';
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

  Future<void> _mostrarFormularioUsuario({UsuarioModel? usuario}) async {
    final formKey = GlobalKey<FormState>();
    
    final usernameController = TextEditingController(text: usuario?.username ?? '');
    final emailController = TextEditingController(text: usuario?.email ?? '');
    final passwordController = TextEditingController();
    final nombreController = TextEditingController(text: usuario?.nombre ?? '');
    final apellidoController = TextEditingController(text: usuario?.apellido ?? '');
    final edadController = TextEditingController(text: usuario?.edad.toString() ?? '');
    String sexoValue = usuario?.sexo ?? 'M';
    int? rolIdSeleccionado = usuario?.rolId ?? (_roles.isNotEmpty ? _roles.first.id : 1);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomModalDialog(
        title: usuario == null ? 'Registrar Usuario' : 'Editar Usuario',
        icon: usuario == null ? Icons.person_add : Icons.edit,
        content: StatefulBuilder(
          builder: (context, setState) => Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sección: Credenciales
                ModalSectionBuilder.buildSectionTitle('Credenciales de Acceso', Icons.lock),
                ModalSectionBuilder.buildTextField(
                  controller: usernameController,
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
                  controller: emailController,
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
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: usuario == null ? 'Contraseña *' : 'Nueva Contraseña',
                      hintText: usuario == null ? 'Ingrese una contraseña segura' : 'Dejar vacío para mantener la actual',
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
                      if (usuario == null && (value == null || value.isEmpty)) {
                        return 'La contraseña es requerida';
                      }
                      return null;
                    },
                  ),
                ),

                // Sección: Información Personal
                ModalSectionBuilder.buildSectionTitle('Información Personal', Icons.badge),
                Row(
                  children: [
                    Expanded(
                      child: ModalSectionBuilder.buildTextField(
                        controller: nombreController,
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
                        controller: apellidoController,
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
                        controller: edadController,
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
                          value: sexoValue,
                          decoration: InputDecoration(
                            labelText: 'Sexo *',
                            prefixIcon: const Icon(Icons.wc, color: AppColors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'M', child: Text('Masculino')),
                            DropdownMenuItem(value: 'F', child: Text('Femenino')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              sexoValue = value ?? 'M';
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

                // Sección: Rol y Permisos
                ModalSectionBuilder.buildSectionTitle('Rol y Permisos', Icons.admin_panel_settings),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<int>(
                    value: rolIdSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Rol del Usuario *',
                      prefixIcon: const Icon(Icons.security, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: _roles.map((rol) {
                      return DropdownMenuItem<int>(
                        value: rol.id,
                        child: Text(rol.nombre),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        rolIdSeleccionado = value;
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
            icon: Icons.check,
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                if (rolIdSeleccionado == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor seleccione un rol'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                await _guardarUsuario(
                  usuario: usuario,
                  username: usernameController.text,
                  email: emailController.text,
                  password: passwordController.text,
                  nombre: nombreController.text,
                  apellido: apellidoController.text,
                  edad: int.parse(edadController.text),
                  sexo: sexoValue,
                  rolId: rolIdSeleccionado!,
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

  Future<void> _guardarUsuario({
    UsuarioModel? usuario,
    required String username,
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required int edad,
    required String sexo,
    required int rolId,
  }) async {
    try {
      final Map<String, dynamic> datos = {
        'username': username,
        'email': email,
        'nombre': nombre,
        'apellido': apellido,
        'edad': edad,
        'sexo': sexo,
        'rol_id': rolId,
      };

      HttpResponse<dynamic> response;

      if (usuario == null) {
        // Registrar nuevo usuario
        datos['password'] = password;
        response = await _apiService.registrarUsuario(datos);
      } else {
        // Editar usuario existente
        datos['id'] = usuario.id;
        if (password.isNotEmpty) {
          datos['password'] = password;
        }
        response = await _apiService.editarUsuario(datos);
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
          _cargarUsuarios();
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

  Future<void> _eliminarUsuario(UsuarioModel usuario) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Está seguro que desea eliminar al usuario ${usuario.username}?'),
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

    if (confirmado != true || usuario.id == null) return;

    try {
      final response = await _apiService.eliminarUsuario(usuario.id!);

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usuario eliminado correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
          _cargarUsuarios();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarUsuarios,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro por rol
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _rolFiltroSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por rol',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todos los roles'),
                      ),
                      ..._roles.map((rol) => DropdownMenuItem<int?>(
                        value: rol.id,
                        child: Text(rol.nombre),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _rolFiltroSeleccionado = value;
                        _aplicarFiltro();
                      });
                    },
                  ),
                ),
                if (_rolFiltroSeleccionado != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _rolFiltroSeleccionado = null;
                        _aplicarFiltro();
                      });
                    },
                    tooltip: 'Limpiar filtro',
                  ),
                ],
              ],
            ),
          ),
          // Lista de usuarios
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
                        onPressed: _cargarUsuarios,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _usuariosFiltrados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _rolFiltroSeleccionado == null
                                ? 'No hay usuarios registrados'
                                : 'No hay usuarios con el rol seleccionado',
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarUsuarios,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _usuariosFiltrados.length,
                        itemBuilder: (context, index) {
                          final usuario = _usuariosFiltrados[index];
                          final rol = _roles.firstWhere(
                            (r) => r.id == usuario.rolId,
                            orElse: () => RolModel(id: 0, nombre: 'Sin rol', descripcion: ''),
                          );
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 8,
                            ),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade700,
                                child: Text(
                                  usuario.nombre[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                '${usuario.nombre} ${usuario.apellido}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Usuario: ${usuario.username}'),
                                  Text('Email: ${usuario.email}'),
                                  Text('Edad: ${usuario.edad} | Sexo: ${usuario.sexo}'),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '🎭 ${rol.nombre}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.green),
                                    onPressed: () => _mostrarFormularioUsuario(usuario: usuario),
                                    tooltip: 'Editar',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarUsuario(usuario),
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
        onPressed: () => _mostrarFormularioUsuario(),
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

