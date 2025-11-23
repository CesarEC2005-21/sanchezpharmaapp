import 'package:flutter/material.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../core/utils/shared_prefs_helper.dart';
import 'tienda_screen.dart';

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
  final _apellidoController = TextEditingController();
  final _documentoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  
  bool _isLoading = false;
  String _tipoDocumento = 'DNI';

  @override
  void dispose() {
    _apellidoController.dispose();
    _documentoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _completarRegistro() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = DioClient.createDio();
      final apiService = ApiService(dio);

      final datosCliente = {
        'nombre': widget.nombre,
        'apellido': _apellidoController.text.trim(),
        'documento': _documentoController.text.trim(),
        'tipo_documento': _tipoDocumento,
        'telefono': _telefonoController.text.trim(),
        'email': widget.email,
        'google_id': widget.googleId,
        'direccion': _direccionController.text.trim(),
      };

      final response = await apiService.registrarClienteGoogle(datosCliente);

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          // Guardar datos de autenticación
          await SharedPrefsHelper.saveAuthData(
            token: data['token'],
            userId: data['cliente_id'],
            username: widget.email,
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
                builder: (context) => const TiendaScreen(),
              ),
            );
          }
        } else {
          if (mounted) {
            _showErrorDialog(data['message'] ?? 'Error al completar registro');
          }
        }
      } else {
        if (mounted) {
          _showErrorDialog('Error de conexión con el servidor');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error: ${e.toString()}');
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Avatar de Google si está disponible
                  if (widget.fotoUrl != null)
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(widget.fotoUrl!),
                    )
                  else
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.green.shade700,
                      child: Text(
                        widget.nombre[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    '¡Bienvenido, ${widget.nombre}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Completa los siguientes datos para finalizar tu registro',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
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
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _documentoController,
                          decoration: const InputDecoration(
                            labelText: 'Número de Documento *',
                            border: OutlineInputBorder(),
                            helperText: 'El documento debe ser único',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El documento es requerido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Teléfono
                  TextFormField(
                    controller: _telefonoController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
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
                  
                  // Botón de completar registro
                  SizedBox(
                    width: double.infinity,
                    height: 50,
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
                          : const Text(
                              'Completar Registro',
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
        ),
      ),
    );
  }
}

