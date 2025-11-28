import 'package:flutter/material.dart';
import 'package:retrofit/retrofit.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/cliente_model.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/utils/validators.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_modal_dialog.dart';
import 'formulario_cliente_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<ClienteModel> _clientes = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarClientes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await SharedPrefsHelper.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'No hay sesión activa. Por favor, inicie sesión nuevamente.';
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic>? query;
      if (_searchController.text.isNotEmpty) {
        query = {'q': _searchController.text};
      }

      final response = await _apiService.getClientes(query);

      if (response.response.statusCode == 200) {
        final data = response.data;

        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> clientesJson = data['data'];
          setState(() {
            _clientes = clientesJson
                .map((json) => ClienteModel.fromJson(json))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Error al cargar clientes';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error al conectar con el servidor';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _mostrarFormularioCliente({ClienteModel? cliente}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioClienteScreen(
          cliente: cliente,
        ),
      ),
    );

    if (result == true) {
      _cargarClientes();
    }
  }

  // Método antiguo mantenido para referencia pero no usado
  Future<void> _mostrarFormularioClienteAntiguo({ClienteModel? cliente}) async {
    final formKey = GlobalKey<FormState>();

    final nombreController = TextEditingController(text: cliente?.nombre ?? '');
    final apellidoController = TextEditingController(text: cliente?.apellido ?? '');
    final documentoController = TextEditingController(text: cliente?.documento ?? '');
    final telefonoController = TextEditingController(text: cliente?.telefono ?? '');
    final emailController = TextEditingController(text: cliente?.email ?? '');
    final direccionController = TextEditingController(text: cliente?.direccion ?? '');
    
    String tipoDocumentoValue = cliente?.tipoDocumento ?? 'DNI';
    String estadoValue = cliente?.estado ?? 'activo';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomModalDialog(
        title: cliente == null ? 'Registrar Cliente' : 'Editar Cliente',
        icon: cliente == null ? Icons.person_add : Icons.edit,
        content: StatefulBuilder(
          builder: (context, setState) => Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ModalSectionBuilder.buildSectionTitle('Información Personal', Icons.person),
                ModalSectionBuilder.buildTextField(
                  controller: nombreController,
                  label: 'Nombre',
                  icon: Icons.person_outline,
                  required: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                ModalSectionBuilder.buildTextField(
                  controller: apellidoController,
                  label: 'Apellido',
                  icon: Icons.person_outline,
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: DropdownButtonFormField<String>(
                          value: tipoDocumentoValue,
                          decoration: InputDecoration(
                            labelText: 'Tipo Doc.',
                            prefixIcon: const Icon(Icons.badge, color: AppColors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'DNI', child: Text('DNI')),
                            DropdownMenuItem(value: 'RUC', child: Text('RUC')),
                            DropdownMenuItem(value: 'PASAPORTE', child: Text('Pasaporte')),
                            DropdownMenuItem(value: 'OTRO', child: Text('Otro')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              tipoDocumentoValue = value ?? 'DNI';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: ModalSectionBuilder.buildTextField(
                        controller: documentoController,
                        label: 'Número de Documento',
                        icon: Icons.numbers,
                      ),
                    ),
                  ],
                ),
                
                ModalSectionBuilder.buildSectionTitle('Información de Contacto', Icons.contact_phone),
                ModalSectionBuilder.buildTextField(
                  controller: telefonoController,
                  label: 'Teléfono',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 9,
                  validator: Validators.validateTelefonoOpcional,
                ),
                ModalSectionBuilder.buildTextField(
                  controller: emailController,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && !value.contains('@')) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                ModalSectionBuilder.buildTextField(
                  controller: direccionController,
                  label: 'Dirección',
                  icon: Icons.location_on,
                  maxLines: 2,
                ),
                
                ModalSectionBuilder.buildSectionTitle('Estado', Icons.settings),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: estadoValue,
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      prefixIcon: Icon(
                        estadoValue == 'activo' ? Icons.check_circle : Icons.cancel,
                        color: estadoValue == 'activo' ? Colors.green : Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: estadoValue == 'activo' 
                          ? Colors.green.shade50 
                          : Colors.grey.shade100,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'activo',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text('Activo'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'inactivo',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text('Inactivo'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        estadoValue = value ?? 'activo';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ModalSectionBuilder.buildButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icons.close,
            isOutlined: true,
          ),
          const SizedBox(width: 12),
          ModalSectionBuilder.buildButton(
            label: 'Guardar',
            icon: Icons.save,
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _guardarCliente(
                  cliente: cliente,
                  nombre: nombreController.text,
                  apellido: apellidoController.text.isEmpty ? null : apellidoController.text,
                  documento: documentoController.text.isEmpty ? null : documentoController.text,
                  tipoDocumento: tipoDocumentoValue,
                  telefono: telefonoController.text.isEmpty ? null : telefonoController.text,
                  email: emailController.text.isEmpty ? null : emailController.text,
                  direccion: direccionController.text.isEmpty ? null : direccionController.text,
                  estado: estadoValue,
                );
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _guardarCliente({
    ClienteModel? cliente,
    required String nombre,
    String? apellido,
    String? documento,
    required String tipoDocumento,
    String? telefono,
    String? email,
    String? direccion,
    required String estado,
  }) async {
    try {
      final Map<String, dynamic> datos = {
        'nombre': nombre,
        'apellido': apellido,
        'documento': documento,
        'tipo_documento': tipoDocumento,
        'telefono': telefono,
        'email': email,
        'direccion': direccion,
        'estado': estado,
      };

      HttpResponse<dynamic> response;

      if (cliente == null) {
        response = await _apiService.registrarCliente(datos);
      } else {
        datos['id'] = cliente.id;
        response = await _apiService.editarCliente(datos);
      }

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Operación exitosa'),
                backgroundColor: Colors.green,
              ),
            );
          }
          _cargarClientes();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Error en la operación'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Clientes'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarClientes,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar clientes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _cargarClientes();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (_) => _cargarClientes(),
              onSubmitted: (_) => _cargarClientes(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _cargarClientes,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _clientes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No hay clientes registrados',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _cargarClientes,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _clientes.length,
                              itemBuilder: (context, index) {
                                final cliente = _clientes[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 8,
                                  ),
                                  elevation: 2,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: cliente.estado == 'activo'
                                          ? Colors.purple.shade700
                                          : Colors.grey,
                                      child: Text(
                                        cliente.nombre[0].toUpperCase(),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(
                                      cliente.nombreCompleto,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (cliente.documento != null)
                                          Text('${cliente.tipoDocumento}: ${cliente.documento}'),
                                        if (cliente.telefono != null)
                                          Text('Tel: ${cliente.telefono}'),
                                        if (cliente.email != null)
                                          Text('Email: ${cliente.email}'),
                                        if (cliente.direccion != null)
                                          Text('Dir: ${cliente.direccion}'),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: cliente.estado == 'activo'
                                                ? Colors.purple.shade100
                                                : Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            cliente.estado == 'activo' ? 'Activo' : 'Inactivo',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: cliente.estado == 'activo'
                                                  ? Colors.purple.shade700
                                                  : Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.green),
                                      onPressed: () => _mostrarFormularioCliente(cliente: cliente),
                                      tooltip: 'Editar',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioCliente(),
        backgroundColor: Colors.purple.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

