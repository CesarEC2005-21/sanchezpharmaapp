import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/api/dio_client.dart';
import 'package:dio/dio.dart';
import '../../data/api/api_service.dart';
import '../../data/models/login_request.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/utils/responsive_helper.dart';
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
    // Forzar que siempre muestre el selector de cuentas
    forceCodeForRefreshToken: true,
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
            print('═══════════════════════════════════════════════════');
            print('✅ LOGIN EXITOSO - Usuario Interno');
            print('═══════════════════════════════════════════════════');
            print('📋 Datos del usuario:');
            print('   - ID: ${response.user!.id}');
            print('   - Username: ${response.user!.username}');
            print('   - Rol ID: ${response.user!.rolId ?? "❌ NULL - Usando Admin (1) por defecto"}');
            print('   - User Type: usuario');
            print('═══════════════════════════════════════════════════');
            
            final rolParaGuardar = response.user!.rolId ?? 1;
            print('💾 Guardando en SharedPreferences:');
            print('   - Rol ID a guardar: $rolParaGuardar');
            
            await SharedPrefsHelper.saveAuthData(
              token: response.token!,
              userId: response.user!.id,
              username: response.user!.username,
              userType: 'usuario',
              rolId: rolParaGuardar, // ✨ Si no hay rol, usar Admin (1) por defecto
            );
            
            print('✅ Datos guardados correctamente');
            print('═══════════════════════════════════════════════════');
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
      // Verificar si hay una sesión activa y cerrarla para forzar selección de cuenta
      try {
        final currentUser = await _googleSignIn.signInSilently();
        if (currentUser != null) {
          // Hay una sesión activa, cerrarla para mostrar el selector
          await _googleSignIn.signOut();
          // Esperar un momento para asegurar que la sesión se cerró completamente
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        // No hay sesión activa o hubo un error, continuar
        print('No hay sesión activa de Google: $e');
      }
      
      // Cerrar sesión explícitamente para asegurar que no hay sesión activa
      await _googleSignIn.signOut();
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Iniciar sesión con Google - esto mostrará el selector de cuentas
      // Si hay múltiples cuentas en el dispositivo, el usuario podrá elegir
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
        // Log del error completo para debugging
        print('❌ Error en Google Sign-In: $e');
        print('Tipo de error: ${e.runtimeType}');
        
        // Verificar si es un error de conexión (DioException)
        // Si es error de conexión, el interceptor ya mostró el diálogo, no mostrar otro
        if (e is DioException) {
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.connectionError) {
            // El interceptor ya mostró el diálogo de "sin conexión", no mostrar otro
            print('⚠️ Error de conexión detectado - El interceptor ya mostró el diálogo');
            return;
          }
        }
        
        // Verificar si el mensaje contiene errores de conexión
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('socketexception') ||
            errorString.contains('failed host lookup') ||
            errorString.contains('connection error') ||
            errorString.contains('network is unreachable') ||
            errorString.contains('connection refused')) {
          // El interceptor ya mostró el diálogo de "sin conexión", no mostrar otro
          print('⚠️ Error de conexión detectado en el mensaje - El interceptor ya mostró el diálogo');
          return;
        }
        
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
    String lowerError = error.toLowerCase();
    
    // Error ApiException: 7 - NETWORK_ERROR o SIGN_IN_REQUIRED
    if (lowerError.contains('apiexception') && lowerError.contains('7')) {
      return '⚠️ Error de configuración de Google Sign-In\n\n'
          'El error ApiException: 7 generalmente indica un problema de configuración.\n\n'
          'Posibles soluciones:\n'
          '1. Verifica tu conexión a Internet\n'
          '2. Asegúrate de que Google Play Services esté actualizado\n'
          '3. Verifica que el SHA-1 esté configurado en Google Cloud Console\n'
          '4. Confirma que el package name coincida con el configurado\n\n'
          'Si el problema persiste, contacta con soporte técnico.';
    } else if (lowerError.contains('platformexception') && lowerError.contains('sign_in_failed')) {
      return '🔐 Error de autenticación con Google\n\nNo se pudo completar el inicio de sesión. Asegúrate de tener Google Sign-In configurado correctamente.';
    } else if (lowerError.contains('apiexception: 10')) {
      return '⚙️ Error de configuración\n\nHay un problema con la configuración de Google Sign-In. Por favor, contacta con soporte.';
    } else if (lowerError.contains('network_error') || lowerError.contains('networkerror')) {
      return '🌐 Error de red\n\nNo se pudo conectar con los servicios de Google. Verifica tu conexión a Internet e intenta nuevamente.';
    } else if (error.contains('No se pudo obtener el token')) {
      return '🔑 Error al obtener token\n\nNo se pudo obtener el token de autenticación de Google. Por favor, intenta nuevamente.';
    } else if (lowerError.contains('socketexception') ||
               lowerError.contains('connection error') ||
               lowerError.contains('failed host lookup') ||
               lowerError.contains('network is unreachable') ||
               lowerError.contains('connection refused')) {
      // Error de conexión - el interceptor ya mostró el diálogo
      return '🌐 Sin conexión a Internet\n\nNo se pudo conectar. Verifica tu conexión a Internet e intenta nuevamente.';
    } else if (lowerError.contains('dioexception')) {
      // Si es DioException pero no es de conexión, mostrar mensaje genérico sin detalle técnico
      return '❌ Error con Google Sign-In\n\nOcurrió un error al iniciar sesión con Google. Por favor, intenta nuevamente.';
    } else {
      // Para otros errores, mostrar mensaje amigable sin el detalle técnico
      return '❌ Error con Google Sign-In\n\nOcurrió un error al iniciar sesión con Google. Por favor, intenta nuevamente.';
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
            style: TextStyle(
              fontSize: ResponsiveHelper.bodyFontSize(context),
              height: 1.5,
            ),
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
            child: Text(
              'Entendido',
              style: TextStyle(
                fontSize: ResponsiveHelper.bodyFontSize(context),
                fontWeight: FontWeight.bold,
              ),
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
              padding: ResponsiveHelper.formPadding(context),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveHelper.maxContentWidth(context) ?? double.infinity,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    // Logo
                    Container(
                      width: ResponsiveHelper.isSmallScreen(context) ? 120 : 150,
                      height: ResponsiveHelper.isSmallScreen(context) ? 120 : 150,
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
                      padding: EdgeInsets.all(ResponsiveHelper.isSmallScreen(context) ? 12 : 15),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/ddspLogo.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.medication,
                              size: ResponsiveHelper.isSmallScreen(context) ? 60 : 80,
                              color: Colors.green,
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.spacing(context)),

                    // Título
                    Text(
                      'Sánchez Pharma',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.titleFontSize(context) + 4,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.spacing(context) / 2),
                    Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.subtitleFontSize(context) + 2,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.spacing(context) * 2),

                    // Campo de usuario
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: ResponsiveHelper.formPadding(context),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                              decoration: InputDecoration(
                                labelText: 'Usuario',
                                labelStyle: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                                prefixIcon: Icon(Icons.person, size: ResponsiveHelper.iconSize(context)),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese su usuario';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: ResponsiveHelper.formFieldSpacing(context)),

                            // Campo de contraseña
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                labelStyle: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                                prefixIcon: Icon(Icons.lock, size: ResponsiveHelper.iconSize(context)),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    size: ResponsiveHelper.iconSize(context),
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
                                child: Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: ResponsiveHelper.bodyFontSize(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.formFieldSpacing(context)),

                            // Botón de login
                            SizedBox(
                              width: double.infinity,
                              height: ResponsiveHelper.isSmallScreen(context) ? 45 : 50,
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
                                    : Text(
                                        'Ingresar',
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper.bodyFontSize(context) + 2,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.formFieldSpacing(context)),
                            
                            // Divider con "O"
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.shade400)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.spacing(context)),
                                  child: Text(
                                    'O',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: ResponsiveHelper.bodyFontSize(context),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white70)),
                              ],
                            ),
                            SizedBox(height: ResponsiveHelper.formFieldSpacing(context)),
                            
                            // Botón de Google Sign In
                            SizedBox(
                              width: double.infinity,
                              height: ResponsiveHelper.isSmallScreen(context) ? 45 : 50,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _handleGoogleSignIn,
                                icon: Icon(Icons.g_mobiledata, size: ResponsiveHelper.iconSize(context)),
                                label: Text(
                                  'Continuar con Google',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.bodyFontSize(context),
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
                            SizedBox(height: ResponsiveHelper.spacing(context)),
                            
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
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: ResponsiveHelper.bodyFontSize(context),
                                  ),
                                  children: [
                                    const TextSpan(text: '¿No tienes cuenta? '),
                                    TextSpan(
                                      text: 'Regístrate aquí',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        fontSize: ResponsiveHelper.bodyFontSize(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.9),
                                padding: EdgeInsets.symmetric(
                                  vertical: ResponsiveHelper.spacing(context) / 2,
                                  horizontal: ResponsiveHelper.spacing(context),
                                ),
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
    ),
    );
  }
}

