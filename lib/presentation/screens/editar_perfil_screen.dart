import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/api/dio_client.dart';
import '../../core/utils/shared_prefs_helper.dart';
import 'package:intl/intl.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({Key? key}) : super(key: key);

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nombreController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _emailController = TextEditingController();
  final _documentoController = TextEditingController();
  final _telefonoController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingData = true;
  int? _clienteId;
  
  // Datos seleccionables
  String _tipoDocumento = 'DNI';
  String? _genero;
  DateTime? _fechaNacimiento;
  
  final List<String> _tiposDocumento = ['DNI', 'Pasaporte', 'Carnet de extranjería'];
  final List<String> _generos = ['Masculino', 'Femenino', 'Otro'];
  
  @override
  void initState() {
    super.initState();
    _cargarDatosCliente();
  }
  
  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _emailController.dispose();
    _documentoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }
  
  Future<void> _cargarDatosCliente() async {
    setState(() {
      _isLoadingData = true;
    });
    
    try {
      // Obtener ID del cliente del token
      _clienteId = await SharedPrefsHelper.getUserId();
      
      if (_clienteId == null) {
        throw Exception('No se pudo obtener el ID del cliente');
      }
      
      // Obtener datos del cliente desde el servidor
      final dio = DioClient.createDio();
      final response = await dio.get('/clientes_sanchezpharma');
      
      if (response.data['code'] == 1) {
        final clientes = response.data['data'] as List;
        final clienteActual = clientes.firstWhere(
          (c) => c['id'] == _clienteId,
          orElse: () => null,
        );
        
        if (clienteActual != null) {
          setState(() {
            // Separar nombre completo si viene junto
            final nombreCompleto = clienteActual['nombre'] ?? '';
            final partes = nombreCompleto.split(' ');
            
            _nombreController.text = partes.isNotEmpty ? partes[0] : '';
            _apellidoPaternoController.text = clienteActual['apellido'] ?? '';
            _apellidoMaternoController.text = ''; // Si tienes este campo en BD
            _emailController.text = clienteActual['email'] ?? '';
            _documentoController.text = clienteActual['documento'] ?? '';
            _telefonoController.text = clienteActual['telefono'] ?? '';
            _tipoDocumento = clienteActual['tipo_documento'] ?? 'DNI';
            
            // Género - normalizar valores
            final generoDb = clienteActual['genero'];
            if (generoDb != null) {
              _genero = generoDb;
            }
            
            // Fecha de nacimiento
            if (clienteActual['fecha_nacimiento'] != null) {
              try {
                _fechaNacimiento = DateTime.parse(clienteActual['fecha_nacimiento']);
              } catch (e) {
                print('Error al parsear fecha: $e');
              }
            }
          });
        }
      }
    } catch (e) {
      print('Error al cargar datos del cliente: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }
  
  Future<void> _seleccionarFecha() async {
    final fechaInicial = _fechaNacimiento ?? DateTime.now().subtract(const Duration(days: 365 * 25));
    
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (fechaSeleccionada != null) {
      setState(() {
        _fechaNacimiento = fechaSeleccionada;
      });
    }
  }
  
  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo identificar al cliente'),
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
      
      // Preparar datos para enviar
      final data = {
        'id': _clienteId,
        'nombre': _nombreController.text.trim(),
        'apellido': '${_apellidoPaternoController.text.trim()} ${_apellidoMaternoController.text.trim()}'.trim(),
        'email': _emailController.text.trim(),
        'documento': _documentoController.text.trim(),
        'tipo_documento': _tipoDocumento,
        'telefono': _telefonoController.text.trim(),
        'estado': 'activo',
      };
      
      // Agregar género si está seleccionado
      if (_genero != null) {
        data['genero'] = _genero;
      }
      
      // Agregar fecha de nacimiento si está seleccionada
      if (_fechaNacimiento != null) {
        data['fecha_nacimiento'] = DateFormat('yyyy-MM-dd').format(_fechaNacimiento!);
      }
      
      final response = await dio.put(
        '/editar_cliente_sanchezpharma',
        data: data,
      );
      
      if (response.data['code'] == 1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Perfil actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Regresar a la pantalla anterior
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Error al actualizar perfil'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error al guardar cambios: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
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
        title: const Text('Mi perfil'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Encabezado
                    const Text(
                      'Editar perfil',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Actualiza tus datos personales',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Foto de perfil
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[300],
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey[600],
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                // Funcionalidad para cambiar foto (opcional)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Funcionalidad de foto en desarrollo'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green[700],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombres',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Apellidos
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _apellidoPaternoController,
                            decoration: InputDecoration(
                              labelText: 'Apellido paterno',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _apellidoMaternoController,
                            decoration: InputDecoration(
                              labelText: 'Apellido materno',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu correo';
                        }
                        if (!value.contains('@')) {
                          return 'Ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Tipo de documento
                    DropdownButtonFormField<String>(
                      value: _tipoDocumento,
                      decoration: InputDecoration(
                        labelText: 'Tipo de documento',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      items: _tiposDocumento.map((tipo) {
                        return DropdownMenuItem(
                          value: tipo,
                          child: Text(tipo),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _tipoDocumento = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Número de documento
                    TextFormField(
                      controller: _documentoController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Número de documento',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu número de documento';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Fecha de nacimiento
                    GestureDetector(
                      onTap: _seleccionarFecha,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Fecha de nacimiento',
                            hintText: _fechaNacimiento == null
                                ? 'Selecciona una fecha'
                                : DateFormat('dd/MM/yyyy').format(_fechaNacimiento!),
                            suffixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Género
                    DropdownButtonFormField<String>(
                      value: _genero,
                      decoration: InputDecoration(
                        labelText: 'Género',
                        hintText: 'Selecciona tu género',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      items: _generos.map((genero) {
                        return DropdownMenuItem(
                          value: genero,
                          child: Text(genero),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _genero = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Teléfono - CAMPO IMPORTANTE
                    TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Número de celular',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu número de celular';
                        }
                        if (value.length < 9) {
                          return 'Ingresa un número válido';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Botón Guardar
                    ElevatedButton(
                      onPressed: _isLoading ? null : _guardarCambios,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
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
                              'Guardar cambios',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}

