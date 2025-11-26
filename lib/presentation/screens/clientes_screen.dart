import 'package:flutter/material.dart';
import 'package:retrofit/retrofit.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/cliente_model.dart';
import '../../core/utils/shared_prefs_helper.dart';

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
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final keyboardHeight = mediaQuery.viewInsets.bottom;
        final screenHeight = mediaQuery.size.height;
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: mediaQuery.size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: (screenHeight * 0.8) - keyboardHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade600, Colors.purple.shade800],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        cliente == null ? Icons.person_add : Icons.edit,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cliente == null ? 'Registrar Cliente' : 'Editar Cliente',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: StatefulBuilder(
                    builder: (context, setState) => SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: nombreController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El nombre es requerido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: apellidoController,
                              decoration: const InputDecoration(
                                labelText: 'Apellido',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    value: tipoDocumentoValue,
                                    decoration: const InputDecoration(
                                      labelText: 'Tipo Doc.',
                                      border: OutlineInputBorder(),
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
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: documentoController,
                                    decoration: const InputDecoration(
                                      labelText: 'Número de Documento',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: telefonoController,
                              decoration: const InputDecoration(
                                labelText: 'Teléfono',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value != null && value.isNotEmpty && !value.contains('@')) {
                                  return 'Email inválido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: direccionController,
                              decoration: const InputDecoration(
                                labelText: 'Dirección',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: estadoValue,
                              decoration: const InputDecoration(
                                labelText: 'Estado',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'activo', child: Text('Activo')),
                                DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  estadoValue = value ?? 'activo';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Footer con botones
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancelar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
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
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

