import 'package:flutter/material.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/services/reniec_service.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/responsive_helper.dart';
import 'home_cliente_screen.dart';

class CompletarDatosGoogleScreen extends StatefulWidget {
  final String email;
  final String nombre;
  final String? fotoUrl;
  final String googleId;

  const CompletarDatosGoogleScreen({
    super.key,
    required this.email,
    required this.nombre,
    this.fotoUrl,
    required this.googleId,
  });

  @override
  State<CompletarDatosGoogleScreen> createState() => _CompletarDatosGoogleScreenState();
}

class _CompletarDatosGoogleScreenState extends State<CompletarDatosGoogleScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _documentoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  
  bool _isLoading = false;
  String _tipoDocumento = 'DNI';
  bool _verificandoDNI = false;
  String? _mensajeVerificacionDNI;
  bool? _dniValido;
  bool _camposBloqueados = true; // Bloqueados desde el inicio hasta verificar DNI
  final ReniecService _reniecService = ReniecService();

  @override
  void initState() {
    super.initState();
    // No prellenar el nombre desde Google - se autocompletará desde RENIEC al verificar el DNI
    // _nombreController se mantiene vacío hasta que se verifique el DNI
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _documentoController.dispose();
    _telefonoController.dispose();
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
        
        // Autocompletar nombres, apellido paterno y apellido materno desde RENIEC
        // Siempre sobrescribir con los datos de RENIEC para asegurar que sean correctos
        if (datos['nombre'] != null) {
          _nombreController.text = datos['nombre'].toString();
        }
        if (datos['apellido_paterno'] != null) {
          _apellidoPaternoController.text = datos['apellido_paterno'].toString();
        }
        if (datos['apellido_materno'] != null) {
          _apellidoMaternoController.text = datos['apellido_materno'].toString();
        }
        
        // Bloquear los campos una vez que se autocompletan desde RENIEC
        setState(() {
          _camposBloqueados = true;
        });
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

  Future<void> _completarRegistro() async {
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
        'nombres': _nombreController.text.trim(),
        'apellido_paterno': _apellidoPaternoController.text.trim(),
        'apellido_materno': _apellidoMaternoController.text.trim(),
        'documento': _documentoController.text.trim(),
        'tipo_documento': _tipoDocumento,
        'telefono': _telefonoController.text.trim(),
        'email': widget.email,
        'google_id': widget.googleId,
        'foto_url': widget.fotoUrl,
        'direccion': _direccionController.text.trim(),
      };

      final response = await apiService.registrarClienteGoogle(datosCliente);

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          // Guardar datos de autenticación
          final nombreCompleto =
              '${_nombreController.text.trim()} ${_apellidoPaternoController.text.trim()} ${_apellidoMaternoController.text.trim()}'.trim();

          await SharedPrefsHelper.saveAuthData(
            token: data['token'],
            userId: data['cliente_id'],
            // Mostrar el nombre completo en la app, no el correo
            username: nombreCompleto.isNotEmpty ? nombreCompleto : widget.email,
            userType: 'cliente',
            clienteId: data['cliente_id'],
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registro completado exitosamente'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HomeClienteScreen(),
              ),
            );
          }
        } else {
          if (mounted) {
            String errorMsg = _getRegistroErrorMessage(data['message'] ?? 'Error al completar registro');
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

  // Método para obtener mensajes de error personalizados
  String _getRegistroErrorMessage(String message) {
    String lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('documento') && 
        (lowerMessage.contains('en uso') || lowerMessage.contains('registrado') || lowerMessage.contains('existe'))) {
      return '🆔 Documento ya registrado\n\nEste número de documento ya está registrado. Por favor, verifica el número ingresado.';
    } else if (lowerMessage.contains('requerido') || lowerMessage.contains('obligatorio') || lowerMessage.contains('faltan')) {
      return '⚠️ Campos incompletos\n\nPor favor, completa todos los campos requeridos marcados con (*).';
    } else {
      return '❌ Error al completar registro\n\n$message';
    }
  }

  // Método para obtener mensajes de error de red personalizados
  String _getNetworkErrorMessage(String error) {
    if (error.contains('SocketException') || error.contains('Failed host lookup')) {
      return '🌐 Sin conexión a Internet\n\nNo se pudo conectar al servidor. Verifica tu conexión a Internet e intenta nuevamente.';
    } else if (error.contains('TimeoutException') || error.contains('timeout')) {
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
        title: const Text('Completar Datos'),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: ResponsiveHelper.formPadding(context),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: ResponsiveHelper.spacing(context)),
                          // Avatar de Google si está disponible
                          if (widget.fotoUrl != null)
                            CircleAvatar(
                              radius: ResponsiveHelper.isSmallScreen(context) ? 40 : 50,
                              backgroundImage: NetworkImage(widget.fotoUrl!),
                            )
                          else
                            CircleAvatar(
                              radius: ResponsiveHelper.isSmallScreen(context) ? 40 : 50,
                              backgroundColor: Colors.green.shade700,
                              child: Text(
                                widget.nombre[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.isSmallScreen(context) ? 32 : 40,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          SizedBox(height: ResponsiveHelper.spacing(context)),
                          Text(
                            '¡Bienvenido, ${widget.nombre}!',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.titleFontSize(context),
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: ResponsiveHelper.spacing(context) * 0.5),
                          Text(
                            widget.email,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.subtitleFontSize(context),
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: ResponsiveHelper.spacing(context) * 1.5),
                          Text(
                            'Completa los siguientes datos para finalizar tu registro',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.subtitleFontSize(context),
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: ResponsiveHelper.spacing(context) * 1.5),
                  
                          // Nombre
                  TextFormField(
                    controller: _nombreController,
                    readOnly: _camposBloqueados,
                    decoration: InputDecoration(
                      labelText: 'Nombre *',
                      prefixIcon: const Icon(Icons.person),
                      suffixIcon: _camposBloqueados 
                          ? const Icon(Icons.lock, color: Colors.green, size: 20)
                          : null,
                      border: const OutlineInputBorder(),
                      filled: _camposBloqueados,
                      fillColor: _camposBloqueados ? Colors.grey.shade100 : null,
                      hintText: _camposBloqueados ? 'Verificado desde RENIEC' : null,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es requerido';
                      }
                      return null;
                    },
                  ),
                          SizedBox(height: ResponsiveHelper.formFieldSpacing(context)),
                  
                          // Apellido Paterno
                  TextFormField(
                    controller: _apellidoPaternoController,
                    readOnly: _camposBloqueados,
                    decoration: InputDecoration(
                      labelText: 'Apellido Paterno *',
                      prefixIcon: const Icon(Icons.person_outline),
                      suffixIcon: _camposBloqueados 
                          ? const Icon(Icons.lock, color: Colors.green, size: 20)
                          : null,
                      border: const OutlineInputBorder(),
                      filled: _camposBloqueados,
                      fillColor: _camposBloqueados ? Colors.grey.shade100 : null,
                      hintText: _camposBloqueados ? 'Verificado desde RENIEC' : null,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El apellido paterno es requerido';
                      }
                      return null;
                    },
                  ),
                          SizedBox(height: ResponsiveHelper.formFieldSpacing(context)),
                  
                          // Apellido Materno
                  TextFormField(
                    controller: _apellidoMaternoController,
                    readOnly: _camposBloqueados,
                    decoration: InputDecoration(
                      labelText: 'Apellido Materno',
                      prefixIcon: const Icon(Icons.person_outline),
                      suffixIcon: _camposBloqueados 
                          ? const Icon(Icons.lock, color: Colors.green, size: 20)
                          : null,
                      border: const OutlineInputBorder(),
                      filled: _camposBloqueados,
                      fillColor: _camposBloqueados ? Colors.grey.shade100 : null,
                      hintText: _camposBloqueados ? 'Verificado desde RENIEC' : null,
                    ),
                  ),
                          SizedBox(height: ResponsiveHelper.formFieldSpacing(context)),
                  
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
                                ? 'Máximo 8 dígitos, solo números'
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
                          maxLength: _tipoDocumento == 'DNI' ? 8 : null,
                          inputFormatters: _tipoDocumento == 'DNI' 
                              ? [Validators.dniFormatter]
                              : null,
                          onChanged: (value) {
                            setState(() {
                              _dniValido = null;
                              _mensajeVerificacionDNI = null;
                              _camposBloqueados = false; // Desbloquear campos si se cambia el DNI
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
                          SizedBox(height: ResponsiveHelper.formFieldSpacing(context)),
                  
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
                          SizedBox(height: ResponsiveHelper.formFieldSpacing(context)),
                  
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
                          SizedBox(height: ResponsiveHelper.spacing(context) * 1.5),
                  
                          // Botón de completar registro
                          SizedBox(
                            width: double.infinity,
                            height: ResponsiveHelper.isSmallScreen(context) ? 45 : 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _completarRegistro,
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
                          : Text(
                              'Completar Registro',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.bodyFontSize(context) + 2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

