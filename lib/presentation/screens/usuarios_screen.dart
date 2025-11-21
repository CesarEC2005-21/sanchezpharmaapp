import 'package:flutter/material.dart';
import 'package:retrofit/retrofit.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/usuario_model.dart';
import '../../data/models/rol_model.dart';
import '../../core/utils/shared_prefs_helper.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<UsuarioModel> _usuarios = [];
  List<RolModel> _roles = [];
  bool _isLoading = true;
  String? _errorMessage;

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
      builder: (context) => AlertDialog(
        title: Text(usuario == null ? 'Registrar Usuario' : 'Editar Usuario'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El username es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: usuario == null ? 'Password *' : 'Password (dejar vacío para mantener)',
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (usuario == null && (value == null || value.isEmpty)) {
                      return 'El password es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: apellidoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El apellido es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: edadController,
                  decoration: const InputDecoration(
                    labelText: 'Edad',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La edad es requerida';
                    }
                    if (int.tryParse(value) == null) {
                      return 'La edad debe ser un número';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: sexoValue,
                  decoration: const InputDecoration(
                    labelText: 'Sexo',
                    border: OutlineInputBorder(),
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
                      return 'El sexo es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: rolIdSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
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
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                if (rolIdSeleccionado == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor seleccione un rol'),
                      backgroundColor: Colors.red,
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
            child: const Text('Guardar'),
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
                        onPressed: _cargarUsuarios,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _usuarios.isEmpty
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
                          const Text(
                            'No hay usuarios registrados',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarUsuarios,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _usuarios.length,
                        itemBuilder: (context, index) {
                          final usuario = _usuarios[index];
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioUsuario(),
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

