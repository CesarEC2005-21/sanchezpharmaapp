import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api/api_service.dart';
import '../../data/api/dio_client.dart';
import '../../core/services/local_notification_service.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../data/models/notificacion_model.dart';
import 'package:dio/dio.dart';

class NotificacionService {
  static final NotificacionService _instance = NotificacionService._internal();
  factory NotificacionService() => _instance;
  NotificacionService._internal();

  ApiService? _apiService;
  Timer? _timer;
  int _ultimaNotificacionId = 0;

  void _inicializarApiService() {
    if (_apiService != null) {
      return; // Ya está inicializado
    }
    try {
      final dio = DioClient.createDio();
      _apiService = ApiService(dio);
      print('✅ ApiService inicializado correctamente');
    } catch (e) {
      print('❌ Error al inicializar ApiService: $e');
      rethrow;
    }
  }

  Future<void> iniciarVerificacionPeriodica() async {
    print('🔔 Iniciando verificación periódica de notificaciones...');
    
    // Inicializar ApiService
    try {
      _inicializarApiService();
    } catch (e) {
      print('❌ Error al inicializar ApiService: $e');
      return;
    }
    
    // Inicializar _ultimaNotificacionId con el máximo ID existente
    await _inicializarUltimaNotificacionId();
    
    // Verificar cada 30 segundos
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await verificarNuevasNotificaciones();
    });
    
    print('✅ Verificación periódica iniciada (cada 30 segundos)');
    
    // Verificar inmediatamente
    await verificarNuevasNotificaciones();
  }

  Future<void> _inicializarUltimaNotificacionId() async {
    try {
      final isCliente = await SharedPrefsHelper.isCliente();
      if (!isCliente) return;

      final clienteId = await SharedPrefsHelper.getClienteId();
      if (clienteId == null) return;

      // Obtener todas las notificaciones para encontrar el máximo ID
      final response = await _apiService!.getNotificacionesCliente(clienteId, null);
      if (response.response.statusCode == 200 && response.data['code'] == 1) {
        final List<dynamic> notificacionesData = response.data['data'] ?? [];
        if (notificacionesData.isNotEmpty) {
          int maxId = 0;
          for (var notifData in notificacionesData) {
            try {
              final id = (notifData['id'] as num).toInt();
              if (id > maxId) maxId = id;
            } catch (e) {
              // Ignorar errores al parsear
            }
          }
          _ultimaNotificacionId = maxId;
          print('📌 Última notificación ID inicializada: $_ultimaNotificacionId');
        }
      }
    } catch (e) {
      print('⚠️ Error al inicializar última notificación ID: $e');
      // Continuar con _ultimaNotificacionId = 0
    }
  }

  Future<void> detenerVerificacion() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> verificarNuevasNotificaciones() async {
    try {
      final isCliente = await SharedPrefsHelper.isCliente();
      if (!isCliente) {
        print('⚠️ No es cliente, no se verifican notificaciones');
        return;
      }

      final clienteId = await SharedPrefsHelper.getClienteId();
      if (clienteId == null) {
        print('⚠️ No se encontró cliente_id');
        return;
      }

      print('🔔 Verificando notificaciones para cliente_id: $clienteId');
      
      // Inicializar ApiService si no está inicializado
      try {
        _inicializarApiService();
      } catch (e) {
        print('Error al inicializar ApiService: $e');
        return;
      }

      final response = await _apiService!.getNotificacionesCliente(clienteId, 'false');
      
      print('📥 Respuesta de notificaciones: ${response.response.statusCode}');
      print('   Data: ${response.data}');
      
      if (response.response.statusCode == 200 && response.data['code'] == 1) {
        final List<dynamic> notificacionesData = response.data['data'] ?? [];
        print('📬 Notificaciones encontradas: ${notificacionesData.length}');
        
        for (var notifData in notificacionesData) {
          try {
            final notificacion = NotificacionModel.fromJson(notifData);
            print('   - Notificación ID: ${notificacion.id}, Leída: ${notificacion.leida}, Última ID: $_ultimaNotificacionId');
            
            // Solo mostrar notificaciones nuevas (no leídas y con ID mayor al último)
            if (!notificacion.leida && notificacion.id > _ultimaNotificacionId) {
              print('🔔 Mostrando notificación: ${notificacion.titulo}');
              await LocalNotificationService().mostrarNotificacion(
                id: notificacion.id,
                titulo: notificacion.titulo,
                cuerpo: notificacion.cuerpo,
                payload: notificacion.id.toString(),
              );
              
              _ultimaNotificacionId = notificacion.id;
            }
          } catch (e) {
            print('❌ Error al procesar notificación: $e');
            print('   Stack trace: ${StackTrace.current}');
          }
        }
      } else {
        print('⚠️ Error en respuesta: ${response.data}');
      }
    } catch (e) {
      print('❌ Error al verificar notificaciones: $e');
      print('   Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> marcarComoLeida(int notificacionId) async {
    try {
      _inicializarApiService();
      await _apiService!.marcarNotificacionLeida(notificacionId);
    } catch (e) {
      print('Error al marcar notificación como leída: $e');
    }
  }

  Future<void> marcarTodasComoLeidas(int clienteId) async {
    try {
      _inicializarApiService();
      await _apiService!.marcarTodasNotificacionesLeidas(clienteId);
    } catch (e) {
      print('Error al marcar todas las notificaciones como leídas: $e');
    }
  }

  Future<int> contarNoLeidas(int clienteId) async {
    try {
      _inicializarApiService();
      final response = await _apiService!.contarNotificacionesNoLeidas(clienteId);
      if (response.response.statusCode == 200 && response.data['code'] == 1) {
        return response.data['data']['total'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error al contar notificaciones no leídas: $e');
      return 0;
    }
  }
}

