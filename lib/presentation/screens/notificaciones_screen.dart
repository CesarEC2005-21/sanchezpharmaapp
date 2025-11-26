import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/api/api_service.dart';
import '../../data/api/dio_client.dart';
import '../../data/models/notificacion_model.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/services/notificacion_service.dart';
import '../widgets/cliente_bottom_nav.dart';
import 'package:intl/intl.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  late final ApiService _apiService;
  List<NotificacionModel> _notificaciones = [];
  bool _isLoading = true;
  int? _clienteId;

  @override
  void initState() {
    super.initState();
    final dio = DioClient.createDio();
    _apiService = ApiService(dio);
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _clienteId = await SharedPrefsHelper.getClienteId();
      if (_clienteId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await _apiService.getNotificacionesCliente(_clienteId!, null);
      
      if (response.response.statusCode == 200 && response.data['code'] == 1) {
        final List<dynamic> data = response.data['data'] ?? [];
        setState(() {
          _notificaciones = data.map((json) => NotificacionModel.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar notificaciones: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _marcarComoLeida(NotificacionModel notificacion) async {
    if (notificacion.leida) return;

    try {
      await NotificacionService().marcarComoLeida(notificacion.id);
      setState(() {
        final index = _notificaciones.indexWhere((n) => n.id == notificacion.id);
        if (index != -1) {
          _notificaciones[index] = NotificacionModel(
            id: notificacion.id,
            clienteId: notificacion.clienteId,
            titulo: notificacion.titulo,
            cuerpo: notificacion.cuerpo,
            tipo: notificacion.tipo,
            relacionId: notificacion.relacionId,
            leida: true,
            fechaCreacion: notificacion.fechaCreacion,
            fechaLeida: DateTime.now().toIso8601String(),
          );
        }
      });
    } catch (e) {
      print('Error al marcar como leída: $e');
    }
  }

  Future<void> _marcarTodasComoLeidas() async {
    if (_clienteId == null) return;

    try {
      await NotificacionService().marcarTodasComoLeidas(_clienteId!);
      await _cargarNotificaciones();
    } catch (e) {
      print('Error al marcar todas como leídas: $e');
    }
  }

  String _formatearFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Hace unos momentos';
          }
          return 'Hace ${difference.inMinutes} min';
        }
        return 'Hace ${difference.inHours} h';
      } else if (difference.inDays == 1) {
        return 'Ayer';
      } else if (difference.inDays < 7) {
        return 'Hace ${difference.inDays} días';
      } else {
        return DateFormat('dd/MM/yyyy').format(dateTime);
      }
    } catch (e) {
      return fecha;
    }
  }

  IconData _getIconoTipo(String tipo) {
    switch (tipo) {
      case 'estado_pedido':
        return Icons.local_shipping;
      case 'promocion':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorTipo(String tipo) {
    switch (tipo) {
      case 'estado_pedido':
        return Colors.blue;
      case 'promocion':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_notificaciones.any((n) => !n.leida))
            TextButton(
              onPressed: _marcarTodasComoLeidas,
              child: const Text(
                'Marcar todas',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const ClienteBottomNav(currentIndex: 2),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notificaciones.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes notificaciones',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarNotificaciones,
                  child: ListView.builder(
                    itemCount: _notificaciones.length,
                    itemBuilder: (context, index) {
                      final notificacion = _notificaciones[index];
                      return InkWell(
                        onTap: () => _marcarComoLeida(notificacion),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: notificacion.leida ? Colors.white : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: notificacion.leida 
                                  ? Colors.grey.shade200 
                                  : Colors.green.shade200,
                              width: notificacion.leida ? 1 : 2,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getColorTipo(notificacion.tipo).withOpacity(0.2),
                              child: Icon(
                                _getIconoTipo(notificacion.tipo),
                                color: _getColorTipo(notificacion.tipo),
                              ),
                            ),
                            title: Text(
                              notificacion.titulo,
                              style: TextStyle(
                                fontWeight: notificacion.leida ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(notificacion.cuerpo),
                                const SizedBox(height: 4),
                                Text(
                                  _formatearFecha(notificacion.fechaCreacion),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            trailing: notificacion.leida
                                ? null
                                : Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade700,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

