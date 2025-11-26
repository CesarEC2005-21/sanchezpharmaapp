import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/constants/api_constants.dart';
import '../widgets/cliente_bottom_nav.dart';
import 'login_screen.dart';

class ConfiguracionClienteScreen extends StatefulWidget {
  const ConfiguracionClienteScreen({super.key});

  @override
  State<ConfiguracionClienteScreen> createState() => _ConfiguracionClienteScreenState();
}

class _ConfiguracionClienteScreenState extends State<ConfiguracionClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordActualController = TextEditingController();
  final _passwordNuevaController = TextEditingController();
  final _passwordConfirmarController = TextEditingController();
  bool _obscurePasswordActual = true;
  bool _obscurePasswordNueva = true;
  bool _obscurePasswordConfirmar = true;
  bool _isGuardando = false;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _passwordActualController.dispose();
    _passwordNuevaController.dispose();
    _passwordConfirmarController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final username = await SharedPrefsHelper.getUsername();
    setState(() {
      _username = username ?? 'Cliente';
    });
  }

  Future<void> _cambiarContrasena() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isGuardando = true;
    });

    try {
      final dio = DioClient.createDio();
      final clienteId = await SharedPrefsHelper.getClienteId();
      
      if (clienteId == null) {
        throw Exception('No se pudo identificar al cliente');
      }

      // Llamar al endpoint para cambiar contraseña
      final response = await dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.cambiarPasswordCliente}',
        data: {
          'cliente_id': clienteId,
          'password_actual': _passwordActualController.text,
          'password_nueva': _passwordNuevaController.text,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Contraseña Actualizada'),
                content: const Text('Su contraseña ha sido actualizada exitosamente.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _passwordActualController.clear();
                      _passwordNuevaController.clear();
                      _passwordConfirmarController.clear();
                    },
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'Error al cambiar la contraseña');
        }
      } else {
        throw Exception('Error de conexión');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error al cambiar la contraseña';
        if (e is DioException) {
          if (e.response != null) {
            final data = e.response!.data;
            errorMessage = data['message'] ?? errorMessage;
          } else {
            errorMessage = 'Error de conexión. Verifique su internet.';
          }
        } else {
          errorMessage = e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final dio = DioClient.createDio();
      final apiService = ApiService(dio);
      await apiService.logout();
    } catch (e) {
      print('Error al cerrar sesión en el servidor: $e');
    }

    await SharedPrefsHelper.clearAuthData();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bottomNavigationBar: const ClienteBottomNav(currentIndex: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Cambiar Contraseña',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordActualController,
                        obscureText: _obscurePasswordActual,
                        decoration: InputDecoration(
                          labelText: 'Contraseña Actual',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePasswordActual
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePasswordActual = !_obscurePasswordActual;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese su contraseña actual';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordNuevaController,
                        obscureText: _obscurePasswordNueva,
                        decoration: InputDecoration(
                          labelText: 'Nueva Contraseña',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePasswordNueva
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePasswordNueva = !_obscurePasswordNueva;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese una nueva contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordConfirmarController,
                        obscureText: _obscurePasswordConfirmar,
                        decoration: InputDecoration(
                          labelText: 'Confirmar Nueva Contraseña',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePasswordConfirmar
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePasswordConfirmar = !_obscurePasswordConfirmar;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor confirme su nueva contraseña';
                          }
                          if (value != _passwordNuevaController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isGuardando ? null : _cambiarContrasena,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isGuardando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Cambiar Contraseña',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
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

