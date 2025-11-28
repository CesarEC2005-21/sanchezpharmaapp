import 'package:flutter/material.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/services/reniec_service.dart';
import '../../core/utils/validators.dart';
import 'login_screen.dart';

class RegistroClienteScreen extends StatefulWidget {
  const RegistroClienteScreen({super.key});

  @override
  State<RegistroClienteScreen> createState() => _RegistroClienteScreenState();
}

class _RegistroClienteScreenState extends State<RegistroClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _documentoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _direccionController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _tipoDocumento = 'DNI';
  bool _verificandoDNI = false;
  String? _mensajeVerificacionDNI;
  bool? _dniValido;
  final ReniecService _reniecService = ReniecService();

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _documentoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

    if (_tipoDocumento != 'DNI') {
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
      final resultado = await _reniecService.verificarDNI(dni, tipoDocumento: _tipoDocumento);

      setState(() {
        _dniValido = resultado['valido'] as bool;
        _mensajeVerificacionDNI = resultado['mensaje'] as String;
      });

      if (resultado['valido'] == true && resultado['datos'] != null) {
        final datos = resultado['datos'] as Map<String, dynamic>;
        
        // Prellenar nombre y apellido si están disponibles
        if (datos['nombre'] != null && _nombreController.text.isEmpty) {
          _nombreController.text = datos['nombre'].toString();
        }
        if (datos['apellido_paterno'] != null && _apellidoController.text.isEmpty) {
          _apellidoController.text = datos['apellido_paterno'].toString();
        }
      } else if (mostrarDialogo && mounted) {
        // Solo mostrar diálogo si se solicita explícitamente
        _showErrorDialog(
          '❌ ${resultado['mensaje']}',
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    } catch (e) {
      setState(() {
        _dniValido = false;
        _mensajeVerificacionDNI = 'Error al verificar el DNI';
      });
      if (mostrarDialogo && mounted) {
        _showErrorDialog(
          '❌ Error al verificar el DNI\n\n${e.toString()}',
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    } finally {
      setState(() {
        _verificandoDNI = false;
      });
    }
  }

  Future<void> _handleRegistro() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Si es DNI, verificar que esté validado antes de continuar
    if (_tipoDocumento == 'DNI') {
      final dni = _documentoController.text.trim();
      final dniLimpio = dni.replaceAll(RegExp(r'[^0-9]'), '');
      
      // Si no se ha verificado o está verificando, hacerlo ahora
      if (_dniValido == null || _verificandoDNI) {
        await _verificarDNI(mostrarDialogo: true);
      }
      
      // Si el DNI no es válido, bloquear el registro
      if (_dniValido != true) {
        if (mounted) {
          _showErrorDialog(
            '❌ No se puede completar el registro\n\n${_mensajeVerificacionDNI ?? "El DNI debe ser verificado antes de continuar. Por favor, verifique que el número sea correcto."}',
            icon: Icons.error_outline,
            iconColor: Colors.red,
          );
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = DioClient.createDio();
      final apiService = ApiService(dio);

      final datosCliente = {
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'documento': _documentoController.text.trim(),
        'tipo_documento': _tipoDocumento,
        'telefono': _telefonoController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'direccion': _direccionController.text.trim(),
      };

      final response = await apiService.registrarClientePublico(datosCliente);

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Registro exitoso'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Esperar un momento y luego volver al login
            await Future.delayed(const Duration(seconds: 1));
            
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            String errorMsg = _getRegistroErrorMessage(data['message'] ?? 'Error al registrar');
            _showErrorDialog(
              errorMsg,
              icon: Icons.error_outline,
              iconColor: Colors.red,
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
        String errorMsg = _getNetworkErrorMessage(e.toString());
        _showErrorDialog(
          errorMsg,
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

  // Método para obtener mensajes de error personalizados de registro
  String _getRegistroErrorMessage(String message) {
    String lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('correo') && 
        (lowerMessage.contains('en uso') || lowerMessage.contains('registrado') || lowerMessage.contains('existe'))) {
      return '📧 Correo ya registrado\n\nEste correo electrónico ya está en uso. Por favor, usa otro correo o intenta iniciar sesión.';
    } else if (lowerMessage.contains('documento') && 
               (lowerMessage.contains('en uso') || lowerMessage.contains('registrado') || lowerMessage.contains('existe'))) {
      return '🆔 Documento ya registrado\n\nEste número de documento ya está registrado. Por favor, verifica el número ingresado.';
    } else if (lowerMessage.contains('requerido') || lowerMessage.contains('obligatorio') || lowerMessage.contains('faltan')) {
      return '⚠️ Campos incompletos\n\nPor favor, completa todos los campos requeridos marcados con (*).';
    } else if (lowerMessage.contains('contraseña') && lowerMessage.contains('débil')) {
      return '🔒 Contraseña muy débil\n\nLa contraseña debe tener al menos 6 caracteres. Por favor, elige una contraseña más segura.';
    } else {
      return '❌ Error al registrar\n\n$message';
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
    } else if (error.contains('500')) {
      return '⚙️ Error del servidor\n\nHubo un problema en el servidor. Por favor, intenta más tarde.';
    } else {
      return '❌ Error de conexión\n\nOcurrió un error al conectar con el servidor.\n\nDetalle: $error';
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
      appBar: AppBar(
        title: const Text('Registro de Cliente'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Crear Cuenta',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Completa tus datos para registrarte',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
                  // Nombre
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El nombre es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Apellido
                  TextFormField(
                    controller: _apellidoController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tipo de documento y documento
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _tipoDocumento,
                          decoration: const InputDecoration(
                            labelText: 'Tipo Doc. *',
                            prefixIcon: Icon(Icons.badge),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'DNI', child: Text('DNI')),
                            DropdownMenuItem(value: 'CE', child: Text('CE')),
                            DropdownMenuItem(value: 'RUC', child: Text('RUC')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _tipoDocumento = value ?? 'DNI';
                              _dniValido = null;
                              _mensajeVerificacionDNI = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _documentoController,
                          decoration: InputDecoration(
                            labelText: 'Número de Documento *',
                            border: const OutlineInputBorder(),
                            helperText: _tipoDocumento == 'DNI' 
                                ? 'El documento debe ser único'
                                : 'El documento debe ser único',
                            suffixIcon: _tipoDocumento == 'DNI'
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
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _dniValido = null;
                              _mensajeVerificacionDNI = null;
                            });
                            
                            // Verificar automáticamente después de un breve delay
                            if (_tipoDocumento == 'DNI' && value.trim().length >= 8) {
                              Future.delayed(const Duration(milliseconds: 800), () {
                                if (mounted && _documentoController.text.trim() == value.trim()) {
                                  _verificarDNI();
                                }
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El documento es requerido';
                            }
                            // Si es DNI, verificar que esté validado
                            if (_tipoDocumento == 'DNI' && _dniValido != true) {
                              return 'El DNI debe ser verificado';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  // Mensaje de verificación de DNI
                  if (_tipoDocumento == 'DNI' && _mensajeVerificacionDNI != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
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
                  if (_tipoDocumento == 'DNI' && _mensajeVerificacionDNI == null && !_verificandoDNI)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
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
                              'El DNI se verificará automáticamente al ingresar 8 dígitos',
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
                  
                  // Teléfono
                  TextFormField(
                    controller: _telefonoController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                      helperText: 'Máximo 9 dígitos, solo números',
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 9,
                    inputFormatters: [Validators.telefonoFormatter],
                    validator: Validators.validateTelefonoOpcional,
                  ),
                  const SizedBox(height: 16),
                  
                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                      helperText: 'El email debe ser único',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El email es requerido';
                      }
                      if (!value.contains('@')) {
                        return 'Ingrese un email válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña *',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
                        return 'La contraseña es requerida';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Confirmar contraseña
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña *',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirme su contraseña';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Dirección
                  TextFormField(
                    controller: _direccionController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 30),
                  
                  // Botón de registro
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegistro,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Registrarse',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Link para volver al login
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.grey),
                        children: [
                          TextSpan(text: '¿Ya tienes cuenta? '),
                          TextSpan(
                            text: 'Inicia sesión',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
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
    );
  }
}

