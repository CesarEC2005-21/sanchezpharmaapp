import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/api/dio_client.dart';
import '../../core/utils/error_message_helper.dart';
import '../../core/utils/responsive_helper.dart';
import 'dart:async';

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({Key? key}) : super(key: key);

  @override
  State<RecuperarPasswordScreen> createState() => _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codigoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _codigoEnviado = false;
  bool _codigoVerificado = false;
  bool _obscurePassword = true;
  bool _obscureConfirmarPassword = true;
  
  int _countdown = 0;
  Timer? _timer;
  
  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }
  
  void _startCountdown() {
    setState(() {
      _countdown = 60; // 60 segundos
    });
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }
  
  Future<void> _enviarCodigo() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dio = DioClient.createDio();
      final response = await dio.post(
        '/enviar_codigo_recuperacion_sanchezpharma',
        data: {
          'email': _emailController.text.trim(),
        },
      );
      
      // Log para depuración
      print('📧 Respuesta del servidor: ${response.statusCode}');
      print('   Data: ${response.data}');
      print('   Code: ${response.data['code']}');
      print('   Message: ${response.data['message']}');
      
      if (response.data['code'] == 1) {
        setState(() {
          _codigoEnviado = true;
        });
        _startCountdown();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message']),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Error al enviar el código'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } on DioException catch (e) {
      String errorMessage = 'Error al enviar el código';
      
      // Intentar obtener el mensaje del servidor
      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        }
      }
      
      // Manejar diferentes tipos de errores de conexión
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Tiempo de espera agotado. Verifica tu conexión a internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Error de conexión. Verifica tu conexión a internet y que el servidor esté disponible.';
      } else if (e.message != null && e.message!.contains('Network is unreachable')) {
        errorMessage = 'No hay conexión a internet. Verifica tu conexión de red.';
      } else if (e.message != null && e.message!.contains('Failed host lookup')) {
        errorMessage = 'No se puede conectar al servidor. Verifica tu conexión a internet.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Error al enviar el código';
      
      if (e.toString().contains('Network is unreachable') || 
          e.toString().contains('Errno 101')) {
        errorMessage = 'No hay conexión a internet. Verifica tu conexión de red.';
      } else if (e.toString().contains('Failed host lookup')) {
        errorMessage = 'No se puede conectar al servidor. Verifica tu conexión a internet.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _verificarCodigo() async {
    if (_codigoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el código de 6 dígitos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dio = DioClient.createDio();
      final response = await dio.post(
        '/verificar_codigo_recuperacion_sanchezpharma',
        data: {
          'email': _emailController.text.trim(),
          'codigo': _codigoController.text.trim(),
        },
      );
      
      if (response.data['code'] == 1) {
        setState(() {
          _codigoVerificado = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message']),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on DioException catch (e) {
      String errorMessage = 'Error al verificar el código';
      
      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        }
      }
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        errorMessage = 'Error de conexión. Verifica tu conexión a internet.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessageHelper.getFriendlyErrorMessage(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _cambiarPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmarPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dio = DioClient.createDio();
      final response = await dio.post(
        '/cambiar_password_recuperacion_sanchezpharma',
        data: {
          'email': _emailController.text.trim(),
          'codigo': _codigoController.text.trim(),
          'nueva_password': _passwordController.text,
        },
      );
      
      if (response.data['code'] == 1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message']),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Esperar un momento y regresar al login
          await Future.delayed(const Duration(seconds: 2));
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on DioException catch (e) {
      String errorMessage = 'Error al cambiar la contraseña';
      
      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        }
      }
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        errorMessage = 'Error de conexión. Verifica tu conexión a internet.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessageHelper.getFriendlyErrorMessage(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
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
                SizedBox(height: ResponsiveHelper.verticalPadding(context)),
                
                // Icono
                Icon(
                  Icons.lock_reset,
                  size: ResponsiveHelper.isSmallScreen(context) ? 60 : 80,
                  color: Colors.green[700],
                ),
                
                SizedBox(height: ResponsiveHelper.spacing(context)),
                
                // Título
                Text(
                  !_codigoEnviado
                      ? 'Ingresa tu correo'
                      : !_codigoVerificado
                          ? 'Verifica tu código'
                          : 'Nueva contraseña',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.titleFontSize(context),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: ResponsiveHelper.spacing(context) / 2),
                
                // Descripción
                Text(
                  !_codigoEnviado
                      ? 'Te enviaremos un código de verificación a tu correo electrónico'
                      : !_codigoVerificado
                          ? 'Ingresa el código de 6 dígitos que enviamos a tu correo'
                          : 'Crea tu nueva contraseña',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.bodyFontSize(context),
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: ResponsiveHelper.spacing(context) * 2),
              
              // Campo Email
              if (!_codigoEnviado) ...[
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    labelStyle: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                    prefixIcon: Icon(Icons.email, size: ResponsiveHelper.iconSize(context)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu correo electrónico';
                    }
                    if (!value.contains('@')) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: ResponsiveHelper.formFieldSpacing(context)),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _enviarCodigo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.spacing(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Enviar Código',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.bodyFontSize(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
              
              // Campo Código
              if (_codigoEnviado && !_codigoVerificado) ...[
                TextFormField(
                  controller: _codigoController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.titleFontSize(context),
                    fontWeight: FontWeight.bold,
                    letterSpacing: ResponsiveHelper.isSmallScreen(context) ? 5 : 10,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Código de Verificación',
                    labelStyle: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                    hintText: '000000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    counterText: '',
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.spacing(context) / 2),
                
                // Temporizador y reenviar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_countdown > 0)
                      Text(
                        'Reenviar código en $_countdown s',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: ResponsiveHelper.bodyFontSize(context),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () {
                          _codigoController.clear();
                          setState(() {
                            _codigoEnviado = false;
                          });
                        },
                        child: Text(
                          'Reenviar código',
                          style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                        ),
                      ),
                  ],
                ),
                
                SizedBox(height: ResponsiveHelper.formFieldSpacing(context)),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _verificarCodigo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.spacing(context)),
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
                          'Verificar Código',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.bodyFontSize(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
              
              // Campos Nueva Contraseña
              if (_codigoVerificado) ...[
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    labelStyle: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                    prefixIcon: Icon(Icons.lock, size: ResponsiveHelper.iconSize(context)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        size: ResponsiveHelper.iconSize(context),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu nueva contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: ResponsiveHelper.formFieldSpacing(context)),
                
                TextFormField(
                  controller: _confirmarPasswordController,
                  obscureText: _obscureConfirmarPassword,
                  style: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    labelStyle: TextStyle(fontSize: ResponsiveHelper.bodyFontSize(context)),
                    prefixIcon: Icon(Icons.lock_outline, size: ResponsiveHelper.iconSize(context)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmarPassword ? Icons.visibility_off : Icons.visibility,
                        size: ResponsiveHelper.iconSize(context),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmarPassword = !_obscureConfirmarPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: ResponsiveHelper.formFieldSpacing(context)),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _cambiarPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.spacing(context)),
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
                          'Cambiar Contraseña',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.bodyFontSize(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
