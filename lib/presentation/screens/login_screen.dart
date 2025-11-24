import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/login_request.dart';
import '../../core/utils/shared_prefs_helper.dart';
import 'dashboard_screen.dart';
import 'home_cliente_screen.dart';
import 'registro_cliente_screen.dart';
import 'completar_datos_google_screen.dart';
import 'recuperar_password_screen.dart';

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
  // Para Android: normalmente NO es necesario pasar clientId aquí.
  // Solo asegúrate de tener creado en Google Cloud un cliente OAuth 2.0 de tipo Android
  // con el mismo package name y SHA-1 que tu app.
  // Para Web: Configura el Client ID en web/index.html
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

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
                builder: (context) => const HomeClienteScreen(),
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
          // Mensajes de error específicos
          String errorMessage = _getErrorMessage(response.message);
          _showErrorDialog(
            errorMessage,
            icon: Icons.error_outline,
            iconColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = _getNetworkErrorMessage(e.toString());
        _showErrorDialog(
          errorMessage,
          icon: Icons.wifi_off,
          iconColor: Colors.orange,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Método para obtener mensajes de error personalizados
  String _getErrorMessage(String message) {
    String lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('credenciales incorrectas') || 
        lowerMessage.contains('incorrecta') ||
        lowerMessage.contains('incorrect')) {
      return '❌ Usuario o contraseña incorrectos\n\nPor favor, verifica tus credenciales e intenta nuevamente.';
    } else if (lowerMessage.contains('no existe') || 
               lowerMessage.contains('not found') ||
               lowerMessage.contains('no encontrado')) {
      return '❌ Usuario no encontrado\n\nEl usuario ingresado no está registrado. ¿Deseas crear una cuenta?';
    } else if (lowerMessage.contains('inactivo') || 
               lowerMessage.contains('bloqueado') ||
               lowerMessage.contains('deshabilitado')) {
      return '⚠️ Cuenta inactiva\n\nTu cuenta está deshabilitada. Contacta con soporte para más información.';
    } else if (lowerMessage.contains('requerido') || 
               lowerMessage.contains('obligatorio')) {
      return '⚠️ Campos incompletos\n\nPor favor, completa todos los campos requeridos.';
    } else {
      return '❌ Error al iniciar sesión\n\n$message';
    }
  }

  // Método para obtener mensajes de error de red personalizados
  String _getNetworkErrorMessage(String error) {
    if (error.contains('SocketException') || 
        error.contains('Failed host lookup')) {
      return '🌐 Sin conexión a Internet\n\nNo se pudo conectar al servidor. Verifica tu conexión a Internet e intenta nuevamente.';
    } else if (error.contains('TimeoutException') || 
               error.contains('timeout')) {
      return '⏱️ Tiempo de espera agotado\n\nLa conexión está tardando demasiado. Por favor, intenta nuevamente.';
    } else if (error.contains('Connection refused')) {
      return '🔌 Servidor no disponible\n\nNo se pudo conectar al servidor. Por favor, intenta más tarde.';
    } else if (error.contains('401') || error.contains('Unauthorized')) {
      return '🔒 No autorizado\n\nTus credenciales no son válidas. Por favor, verifica tu usuario y contraseña.';
    } else if (error.contains('500')) {
      return '⚙️ Error del servidor\n\nHubo un problema en el servidor. Por favor, intenta más tarde.';
    } else {
      return '❌ Error de conexión\n\nOcurrió un error al conectar con el servidor. Por favor, intenta nuevamente.\n\nDetalle: $error';
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Iniciar sesión con Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // El usuario canceló el login
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Obtener información del usuario
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Obtener el token de acceso (este es el token de OAuth, diferente al de Google Maps)
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw Exception('No se pudo obtener el token de Google');
      }

      // Enviar datos al backend para login/registro
      final dio = DioClient.createDio();
      final apiService = ApiService(dio);

      final datosGoogle = {
        'email': googleUser.email,
        'nombre': googleUser.displayName ?? '',
        'google_id': googleUser.id,
        'foto_url': googleUser.photoUrl,
        'access_token': accessToken,
        'id_token': idToken,
      };

      final response = await apiService.loginGoogle(datosGoogle);

      if (response.response.statusCode == 200) {
        final data = response.data;
        
        if (data['code'] == 1) {
          // Si necesita completar datos
          if (data['necesita_completar_datos'] == true) {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompletarDatosGoogleScreen(
                    email: googleUser.email,
                    nombre: googleUser.displayName ?? 'Usuario',
                    fotoUrl: googleUser.photoUrl,
                    googleId: googleUser.id,
                  ),
                ),
              );
            }
          } else {
            // Login exitoso, guardar datos y redirigir
            final displayName = (googleUser.displayName ?? '').trim();
            final usernameToSave =
                displayName.isNotEmpty ? displayName : googleUser.email;

            await SharedPrefsHelper.saveAuthData(
              token: data['token'],
              userId: data['cliente_id'],
              // Guardar el nombre visible del cliente en lugar del correo
              username: usernameToSave,
              userType: 'cliente',
              clienteId: data['cliente_id'],
            );

            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const HomeClienteScreen(),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            _showErrorDialog(
              _getErrorMessage(data['message'] ?? 'Error al iniciar sesión con Google'),
              icon: Icons.login,
              iconColor: Colors.blue,
            );
          }
        }
      } else {
        if (mounted) {
          _showErrorDialog(
            '🌐 Error de conexión\n\nNo se pudo conectar con el servidor. Verifica tu conexión a Internet.',
            icon: Icons.wifi_off,
            iconColor: Colors.orange,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = _getGoogleErrorMessage(e.toString());
        _showErrorDialog(
          errorMsg,
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Método para obtener mensajes de error específicos de Google Sign-In
  String _getGoogleErrorMessage(String error) {
    if (error.contains('PlatformException') && error.contains('sign_in_failed')) {
      return '🔐 Error de autenticación con Google\n\nNo se pudo completar el inicio de sesión. Asegúrate de tener Google Sign-In configurado correctamente.';
    } else if (error.contains('ApiException: 10')) {
      return '⚙️ Error de configuración\n\nHay un problema con la configuración de Google Sign-In. Por favor, contacta con soporte.';
    } else if (error.contains('No se pudo obtener el token')) {
      return '🔑 Error al obtener token\n\nNo se pudo obtener el token de autenticación de Google. Por favor, intenta nuevamente.';
    } else if (error.contains('SocketException')) {
      return '🌐 Sin conexión a Internet\n\nNo se pudo conectar. Verifica tu conexión a Internet e intenta nuevamente.';
    } else {
      return '❌ Error con Google Sign-In\n\nOcurrió un error al iniciar sesión con Google.\n\nDetalle: $error';
    }
  }

  void _showErrorDialog(
    String message, {
    IconData icon = Icons.error_outline,
    Color iconColor = Colors.red,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 10),
            const Text(
              'Atención',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Entendido',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
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
                            
                            // Botón "Olvidé mi contraseña"
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RecuperarPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

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
                            const SizedBox(height: 20),
                            
                            // Divider con "O"
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white70)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'O',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white70)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Botón de Google Sign In
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _handleGoogleSignIn,
                                icon: const Icon(Icons.g_mobiledata, size: 24),
                                label: const Text(
                                  'Continuar con Google',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  side: BorderSide(color: Colors.white70),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Link para registrarse
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegistroClienteScreen(),
                                  ),
                                );
                              },
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                  ),
                                  children: [
                                    TextSpan(text: '¿No tienes cuenta? '),
                                    TextSpan(
                                      text: 'Regístrate aquí',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.9),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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

