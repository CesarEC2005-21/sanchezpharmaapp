import 'package:flutter/material.dart';
import 'package:retrofit/retrofit.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../data/models/envio_model.dart';
import '../../data/models/usuario_model.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/constants/role_constants.dart';
import 'seguimiento_envio_screen.dart';
import 'escanner_qr_screen.dart';

class EnviosScreen extends StatefulWidget {
  const EnviosScreen({super.key});

  @override
  State<EnviosScreen> createState() => _EnviosScreenState();
}

class _EnviosScreenState extends State<EnviosScreen> {
  final ApiService _apiService = ApiService(DioClient.createDio());
  List<EnvioModel> _envios = [];
  List<UsuarioModel> _repartidores = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _filtroEstado;
  int? _rolId; // ✨ Para controlar permisos

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    // Cargar el rol del usuario PRIMERO
    _rolId = await SharedPrefsHelper.getRolId();
    print('🔐 EnviosScreen - Rol ID cargado: ${_rolId ?? "NULL"}');
    
    if (_rolId != null) {
      print('✅ Rol ID es ${_rolId}');
      print('✅ Es Admin: ${RoleConstants.esAdministrador(_rolId)}');
      print('✅ Es Vendedor: ${RoleConstants.esVendedor(_rolId)}');
      print('✅ Puede asignar repartidor: ${RoleConstants.puedeAsignarRepartidor(_rolId)}');
    } else {
      print('❌ ERROR: _rolId es NULL - el usuario debe cerrar sesión y volver a iniciar');
    }
    
    // Actualizar UI para reflejar el rol
    setState(() {});
    
    // Luego cargar datos
    _cargarEnvios();
    _cargarRepartidores();
  }

  Future<void> _cargarRepartidores() async {
    try {
      print('🔄 Cargando repartidores...');
      // ✨ Usar el nuevo endpoint que solo devuelve repartidores (rol_id = 4)
      final response = await _apiService.getRepartidores();
      print('📡 Respuesta del servidor: ${response.response.statusCode}');
      
      if (response.response.statusCode == 200) {
        final data = response.data;
        print('📦 Data recibida: $data');
        
        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> usuariosJson = data['data'];
          setState(() {
            _repartidores = usuariosJson
                .map((json) => UsuarioModel.fromJson(json))
                .toList();
          });
          print('✅ Repartidores cargados: ${_repartidores.length}');
          
          if (_repartidores.isEmpty) {
            print('⚠️ ADVERTENCIA: No hay repartidores (usuarios con rol_id = 4) en la base de datos');
          } else {
            for (var rep in _repartidores) {
              print('   - ${rep.nombre} ${rep.apellido} (${rep.email})');
            }
          }
        } else {
          print('⚠️ Respuesta sin datos: ${data['message']}');
        }
      } else {
        print('❌ Error HTTP: ${response.response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Error al cargar repartidores: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _cargarEnvios() async {
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
      if (_filtroEstado != null) {
        query = {'estado': _filtroEstado};
      }

      final response = await _apiService.getEnvios(query);

      if (response.response.statusCode == 200) {
        final data = response.data;

        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> enviosJson = data['data'];
          setState(() {
            _envios = enviosJson
                .map((json) => EnvioModel.fromJson(json))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Error al cargar envíos';
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

  Future<void> _actualizarEstadoEnvio(EnvioModel envio, String nuevoEstado) async {
    if (envio.id == null) return;

    // Si el nuevo estado es "en_camino" y no hay repartidor asignado, pedir asignar uno primero
    if (nuevoEstado == 'en_camino' && (envio.conductorRepartidor == null || envio.conductorRepartidor!.isEmpty)) {
      final repartidorAsignado = await _mostrarDialogoAsignarRepartidor(envio);
      if (repartidorAsignado == null) {
        // El usuario canceló, no actualizar estado
        return;
      }
    }

    try {
      final usuarioId = await SharedPrefsHelper.getUserId();
      
      final response = await _apiService.actualizarEstadoEnvio(
        envio.id!,
        {
          'estado': nuevoEstado,
          'usuario_id': usuarioId,
        },
      );

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Estado actualizado correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
          _cargarEnvios();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Error al actualizar estado'),
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

  Future<String?> _mostrarDialogoAsignarRepartidor(EnvioModel envio) async {
    print('🚀 Iniciando proceso de asignación de repartidor...');
    print('   - Repartidores en memoria: ${_repartidores.length}');
    
    if (_repartidores.isEmpty) {
      print('⚠️ No hay repartidores en memoria, cargando...');
      await _cargarRepartidores();
    }

    if (_repartidores.isEmpty) {
      print('❌ ERROR: No hay repartidores disponibles después de cargar');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay repartidores disponibles. Asegúrate de tener usuarios con rol "Repartidor" en el sistema.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return null;
    }
    
    print('✅ Mostrando diálogo con ${_repartidores.length} repartidores');

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Asignar Repartidor - ${envio.numeroSeguimiento ?? "Envío #${envio.id}"}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _repartidores.length,
            itemBuilder: (context, index) {
              final repartidor = _repartidores[index];
              final nombreCompleto = '${repartidor.nombre} ${repartidor.apellido}';
              final isAsignado = envio.conductorRepartidor == nombreCompleto;
              
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    repartidor.nombre[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(nombreCompleto),
                subtitle: Text(repartidor.email),
                trailing: isAsignado
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                selected: isAsignado,
                onTap: () {
                  Navigator.of(context).pop(nombreCompleto);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _asignarRepartidor(EnvioModel envio, String nombreRepartidor) async {
    if (envio.id == null) return;

    try {
      final response = await _apiService.actualizarEnvio(
        envio.id!,
        {
          'conductor_repartidor': nombreRepartidor,
        },
      );

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Repartidor asignado: $nombreRepartidor'),
                backgroundColor: Colors.green,
              ),
            );
          }
          _cargarEnvios();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Error al asignar repartidor'),
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

  /// Verificar si el usuario actual puede asignar repartidores
  /// Solo Admin (1) y Vendedor (3) tienen este permiso
  bool _puedeAsignarRepartidor() {
    if (_rolId == null) {
      print('⚠️ _rolId es NULL en _puedeAsignarRepartidor()');
      return false; // Si no hay rol, no permitir
    }
    final puedeAsignar = RoleConstants.puedeAsignarRepartidor(_rolId);
    print('🔑 _puedeAsignarRepartidor() → rolId: $_rolId, puede: $puedeAsignar');
    return puedeAsignar;
  }

  Future<void> _mostrarOpcionesEstado(EnvioModel envio) async {
    final estados = _obtenerEstadosSiguientes(envio.estado);
    
    if (estados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este envío ya está en su estado final'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Actualizar Estado - ${envio.numeroSeguimiento ?? "Envío #${envio.id}"}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: estados.map((estado) {
            return ListTile(
              title: Text(_getEstadoTexto(estado)),
              leading: Icon(_getEstadoIcon(estado), color: _getEstadoColor(estado)),
              onTap: () {
                Navigator.of(context).pop();
                _actualizarEstadoEnvio(envio, estado);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  List<String> _obtenerEstadosSiguientes(String estadoActual) {
    switch (estadoActual) {
      case 'pendiente':
        return ['preparando', 'cancelado'];
      case 'preparando':
        return ['en_camino', 'cancelado'];
      case 'en_camino':
        return ['entregado', 'cancelado'];
      case 'entregado':
      case 'cancelado':
        return [];
      default:
        return [];
    }
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'preparando':
        return 'Preparando';
      case 'en_camino':
        return 'En Camino';
      case 'entregado':
        return 'Entregado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estado;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.pending;
      case 'preparando':
        return Icons.inventory_2;
      case 'en_camino':
        return Icons.local_shipping;
      case 'entregado':
        return Icons.check_circle;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'preparando':
        return Colors.green;
      case 'en_camino':
        return Colors.purple;
      case 'entregado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildIndicadorProgreso(EnvioModel envio) {
    final estados = ['pendiente', 'preparando', 'en_camino', 'entregado'];
    final estadoActual = envio.estado;
    final indiceActual = estados.indexOf(estadoActual);

    return Row(
      children: estados.asMap().entries.map((entry) {
        final index = entry.key;
        final estado = entry.value;
        final isCompletado = index <= indiceActual;
        final isActual = index == indiceActual;

        return Expanded(
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompletado
                      ? (isActual ? _getEstadoColor(estado) : Colors.green)
                      : Colors.grey.shade300,
                ),
                child: Icon(
                  _getEstadoIcon(estado),
                  color: isCompletado ? Colors.white : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getEstadoTexto(estado),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActual ? FontWeight.bold : FontWeight.normal,
                  color: isCompletado ? Colors.black87 : Colors.grey,
                ),
              ),
              if (index < estados.length - 1)
                Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: index < indiceActual ? Colors.green : Colors.grey.shade300,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _verDetalleEnvio(EnvioModel envio) async {
    if (envio.id == null) return;

    try {
      final response = await _apiService.getEnvio(envio.id!);

      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['data'] != null) {
          final envioCompleto = EnvioModel.fromJson(data['data']);

          if (mounted) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Envío ${envioCompleto.numeroSeguimiento ?? "#${envioCompleto.id}"}'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Venta: ${envioCompleto.numeroVenta ?? "N/A"}'),
                      Text('Cliente: ${envioCompleto.clienteNombre ?? "N/A"}'),
                      Text('Teléfono: ${envioCompleto.clienteTelefono ?? "N/A"}'),
                      const Divider(),
                      Text('Destinatario: ${envioCompleto.nombreDestinatario}'),
                      Text('Dirección: ${envioCompleto.direccionEntrega}'),
                      if (envioCompleto.referenciaDireccion != null)
                        Text('Referencia: ${envioCompleto.referenciaDireccion}'),
                      Text('Teléfono: ${envioCompleto.telefonoContacto}'),
                      if (envioCompleto.conductorRepartidor != null)
                        Text('Conductor: ${envioCompleto.conductorRepartidor}'),
                      const Divider(),
                      Text('Estado: ${envioCompleto.estadoTexto}'),
                      if (envioCompleto.fechaEstimadaEntrega != null)
                        Text('Fecha Estimada: ${envioCompleto.fechaEstimadaEntrega!.day}/${envioCompleto.fechaEstimadaEntrega!.month}/${envioCompleto.fechaEstimadaEntrega!.year}'),
                      if (envioCompleto.fechaRealEntrega != null)
                        Text('Fecha Entrega: ${envioCompleto.fechaRealEntrega!.day}/${envioCompleto.fechaRealEntrega!.month}/${envioCompleto.fechaRealEntrega!.year}'),
                      if (envioCompleto.historialEstados != null && envioCompleto.historialEstados!.isNotEmpty) ...[
                        const Divider(),
                        const Text('Historial:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...envioCompleto.historialEstados!.map((historial) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${historial.fechaCambio != null ? "${historial.fechaCambio!.day}/${historial.fechaCambio!.month}/${historial.fechaCambio!.year} ${historial.fechaCambio!.hour}:${historial.fechaCambio!.minute.toString().padLeft(2, '0')}" : "N/A"} - ${_getEstadoTexto(historial.estadoNuevo)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
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
        title: const Text('Seguimiento de Envíos'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filtroEstado = value == 'todos' ? null : value;
              });
              _cargarEnvios();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'todos', child: Text('Todos')),
              const PopupMenuItem(value: 'pendiente', child: Text('Pendientes')),
              const PopupMenuItem(value: 'preparando', child: Text('Preparando')),
              const PopupMenuItem(value: 'en_camino', child: Text('En Camino')),
              const PopupMenuItem(value: 'entregado', child: Text('Entregados')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEnvios,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
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
                        onPressed: _cargarEnvios,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _envios.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay envíos pendientes',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarEnvios,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _envios.length,
                        itemBuilder: (context, index) {
                          final envio = _envios[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            elevation: 3,
                            child: Column(
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getEstadoColor(envio.estado),
                                    child: Icon(
                                      _getEstadoIcon(envio.estado),
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    envio.numeroSeguimiento ?? 'Envío #${envio.id}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Venta: ${envio.numeroVenta ?? "N/A"}'),
                                      Text('Cliente: ${envio.clienteNombre ?? "N/A"}'),
                                      Text('Destinatario: ${envio.nombreDestinatario}'),
                                      Text('Dirección: ${envio.direccionEntrega}'),
                                      if (envio.conductorRepartidor != null && envio.conductorRepartidor!.isNotEmpty)
                                        Row(
                                          children: [
                                            Icon(Icons.person, size: 16, color: Colors.green.shade700),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Repartidor: ${envio.conductorRepartidor}',
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (envio.fechaEstimadaEntrega != null)
                                        Text('Fecha Estimada: ${envio.fechaEstimadaEntrega!.day}/${envio.fechaEstimadaEntrega!.month}/${envio.fechaEstimadaEntrega!.year}'),
                                    ],
                                  ),
                                    trailing: PopupMenuButton(
                                    icon: const Icon(Icons.more_vert),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'ver',
                                        child: Row(
                                          children: [
                                            Icon(Icons.visibility, size: 20),
                                            SizedBox(width: 8),
                                            Text('Ver Detalle'),
                                          ],
                                        ),
                                      ),
                                      if (envio.estado == 'en_camino' || envio.estado == 'preparando')
                                        const PopupMenuItem(
                                          value: 'mapa',
                                          child: Row(
                                            children: [
                                              Icon(Icons.map, size: 20),
                                              SizedBox(width: 8),
                                              Text('Ver en Mapa'),
                                            ],
                                          ),
                                        ),
                                      if (_puedeAsignarRepartidor() &&
                                          (envio.estado == 'pendiente' || envio.estado == 'preparando') && 
                                          (envio.conductorRepartidor == null || envio.conductorRepartidor!.isEmpty))
                                        const PopupMenuItem(
                                          value: 'asignar',
                                          child: Row(
                                            children: [
                                              Icon(Icons.person_add, size: 20),
                                              SizedBox(width: 8),
                                              Text('Asignar Repartidor'),
                                            ],
                                          ),
                                        ),
                                      const PopupMenuItem(
                                        value: 'actualizar',
                                        child: Row(
                                          children: [
                                            Icon(Icons.update, size: 20),
                                            SizedBox(width: 8),
                                            Text('Actualizar Estado'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) async {
                                      if (value == 'ver') {
                                        _verDetalleEnvio(envio);
                                      } else if (value == 'mapa') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SeguimientoEnvioScreen(envio: envio),
                                          ),
                                        );
                                      } else if (value == 'asignar') {
                                        final repartidor = await _mostrarDialogoAsignarRepartidor(envio);
                                        if (repartidor != null) {
                                          await _asignarRepartidor(envio, repartidor);
                                        }
                                      } else if (value == 'actualizar') {
                                        _mostrarOpcionesEstado(envio);
                                      }
                                    },
                                  ),
                                ),
                                // Indicador de progreso
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: _buildIndicadorProgreso(envio),
                                ),
                                // Botones de acción
                                if (envio.estado != 'entregado' && envio.estado != 'cancelado')
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Column(
                                      children: [
                                        // ✨ Solo Admin y Vendedor pueden asignar repartidor
                                        Builder(
                                          builder: (context) {
                                            final puedeAsignar = _puedeAsignarRepartidor();
                                            final estadoCorrecto = (envio.estado == 'pendiente' || envio.estado == 'preparando');
                                            final sinRepartidor = (envio.conductorRepartidor == null || envio.conductorRepartidor!.isEmpty);
                                            
                                            print('🔍 Envío ${envio.id}:');
                                            print('   - puedeAsignar: $puedeAsignar (rolId: $_rolId)');
                                            print('   - estadoCorrecto: $estadoCorrecto (estado: ${envio.estado})');
                                            print('   - sinRepartidor: $sinRepartidor (repartidor: ${envio.conductorRepartidor})');
                                            print('   - MOSTRAR BOTÓN: ${puedeAsignar && estadoCorrecto && sinRepartidor}');
                                            
                                            if (puedeAsignar && estadoCorrecto && sinRepartidor) {
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 8),
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton.icon(
                                                    onPressed: () async {
                                                      final repartidor = await _mostrarDialogoAsignarRepartidor(envio);
                                                      if (repartidor != null) {
                                                        await _asignarRepartidor(envio, repartidor);
                                                      }
                                                    },
                                                    icon: const Icon(Icons.person_add),
                                                    label: const Text('Asignar Repartidor'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.blue.shade700,
                                                      foregroundColor: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink(); // No mostrar nada si no cumple condiciones
                                          },
                                        ),
                                        // Botón para escanear QR cuando está en camino
                                        if (envio.estado == 'en_camino')
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed: () async {
                                                  final resultado = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => const EscannerQrScreen(
                                                        titulo: 'Escanear QR de Entrega',
                                                        mensajeAyuda: 'Escanea el código QR del pedido para marcarlo como entregado',
                                                      ),
                                                    ),
                                                  );
                                                  if (resultado == true) {
                                                    // Recargar envíos después de escanear exitosamente
                                                    _cargarEnvios();
                                                  }
                                                },
                                                icon: const Icon(Icons.qr_code_scanner),
                                                label: const Text('Escanear QR para Entregar'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.orange.shade700,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                              ),
                                            ),
                                          ),
                                        Row(
                                          children: [
                                            if (envio.estado == 'en_camino' || envio.estado == 'preparando')
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => SeguimientoEnvioScreen(envio: envio),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.map),
                                                  label: const Text('Ver en Mapa'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green.shade700,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            if (envio.estado == 'en_camino' || envio.estado == 'preparando')
                                              const SizedBox(width: 8),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => _mostrarOpcionesEstado(envio),
                                                icon: const Icon(Icons.arrow_forward),
                                                label: Text('Avanzar a ${_obtenerEstadosSiguientes(envio.estado).isNotEmpty ? _getEstadoTexto(_obtenerEstadosSiguientes(envio.estado)[0]) : "Siguiente"}'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: _getEstadoColor(envio.estado),
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

