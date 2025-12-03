import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/utils/error_message_helper.dart';
import '../../core/utils/responsive_helper.dart';
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
        // Usar ErrorMessageHelper para obtener mensaje amigable
        // No mostrar si es error 401 (el interceptor ya lo maneja)
        final errorString = e.toString().toLowerCase();
        if (!errorString.contains('401') && 
            !errorString.contains('sesión expirada') &&
            !errorString.contains('unauthorized')) {
          ErrorMessageHelper.showErrorSnackBar(context, e);
        }
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
        padding: ResponsiveHelper.formPadding(context),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.maxContentWidth(context) ?? double.infinity,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: ResponsiveHelper.formPadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock, color: Colors.green.shade700, size: ResponsiveHelper.iconSize(context)),
                            SizedBox(width: ResponsiveHelper.spacing(context) / 2),
                            Text(
                              'Cambiar Contraseña',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.subtitleFontSize(context) + 4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: ResponsiveHelper.spacing(context)),
                      TextFormField(
                        controller: _passwordActualController,
                        obscureText: _obscurePasswordActual,
                        style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                        decoration: InputDecoration(
                          labelText: 'Contraseña Actual',
                          labelStyle: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                          prefixIcon: Icon(Icons.lock_outline, size: ResponsiveHelper.iconSize(context)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePasswordActual
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: ResponsiveHelper.iconSize(context),
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
                      SizedBox(height: ResponsiveHelper.formFieldSpacing(context)),
                      TextFormField(
                        controller: _passwordNuevaController,
                        obscureText: _obscurePasswordNueva,
                        style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                        decoration: InputDecoration(
                          labelText: 'Nueva Contraseña',
                          labelStyle: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                          prefixIcon: Icon(Icons.lock, size: ResponsiveHelper.iconSize(context)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePasswordNueva
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: ResponsiveHelper.iconSize(context),
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
                      SizedBox(height: ResponsiveHelper.formFieldSpacing(context)),
                      TextFormField(
                        controller: _passwordConfirmarController,
                        obscureText: _obscurePasswordConfirmar,
                        style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                        decoration: InputDecoration(
                          labelText: 'Confirmar Nueva Contraseña',
                          labelStyle: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                          prefixIcon: Icon(Icons.lock, size: ResponsiveHelper.iconSize(context)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePasswordConfirmar
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: ResponsiveHelper.iconSize(context),
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
                      SizedBox(height: ResponsiveHelper.spacing(context) * 1.5),
                      SizedBox(
                        width: double.infinity,
                        height: ResponsiveHelper.isSmallScreen(context) ? 45 : 50,
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
                              : Text(
                                  'Cambiar Contraseña',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.bodyFontSize(context),
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
    ),
    );
  }
}

