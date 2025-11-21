import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/login_request.dart';
import '../../core/utils/shared_prefs_helper.dart';
import 'dashboard_screen.dart';
import 'tienda_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = DioClient.createDio();
      final apiService = ApiService(dio);

      final loginRequest = LoginRequest(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      final response = await apiService.login(loginRequest);

      if (response.code == 1 && response.token != null) {
        print('🎉 Login exitoso! Respuesta del servidor:');
        print('   - Code: ${response.code}');
        print('   - Message: ${response.message}');
        print('   - Token recibido: ${response.token!.substring(0, 20)}...');
        print('   - User Type: ${response.userType ?? 'usuario'}');
        
        // Guardar datos de autenticación
        if (response.isCliente) {
          // Login de cliente
          await SharedPrefsHelper.saveAuthData(
            token: response.token!,
            userId: response.clienteId ?? 0,
            username: response.user?.username ?? 'Cliente',
            userType: 'cliente',
            clienteId: response.clienteId,
          );
        } else {
          // Login de usuario interno
          if (response.user != null) {
            await SharedPrefsHelper.saveAuthData(
              token: response.token!,
              userId: response.user!.id,
              username: response.user!.username,
              userType: 'usuario',
            );
          }
        }

        if (mounted) {
          // Redirigir según el tipo de usuario
          if (response.isCliente) {
            // Navegar a la tienda para clientes
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const TiendaScreen(),
              ),
            );
          } else {
            // Navegar al Dashboard para usuarios internos
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const DashboardScreen(),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          _showErrorDialog(response.message);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error al conectar con el servidor: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade700,
              Colors.green.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(15),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/ddspLogo.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.medication,
                              size: 80,
                              color: Colors.green,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Título
                    const Text(
                      'Sánchez Pharma',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Campo de usuario
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Usuario',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese su usuario';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Campo de contraseña
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese su contraseña';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 30),

                            // Botón de login
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SpinKitThreeBounce(
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : const Text(
                                        'Ingresar',
                                        style: TextStyle(
                                          fontSize: 18,
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
        ),
      ),
    );
  }
}

