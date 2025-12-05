import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../utils/shared_prefs_helper.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';

/// Servicio para manejar la renovación automática de tokens JWT
class TokenRefreshService {
  static final TokenRefreshService _instance = TokenRefreshService._internal();
  factory TokenRefreshService() => _instance;
  TokenRefreshService._internal();

  // Tiempo antes de la expiración para renovar (7 días = renovar cuando queden 7 días)
  static const int diasAntesDeRenovar = 7;
  
  // Evitar múltiples renovaciones simultáneas
  bool _isRefreshing = false;
  DateTime? _lastRefreshAttempt;

  /// Verifica si el token necesita renovación y lo renueva automáticamente
  /// Retorna true si el token fue renovado, false si no era necesario o falló
  Future<bool> renovarSiEsNecesario() async {
    try {
      // Evitar múltiples intentos simultáneos
      if (_isRefreshing) {
        print('🔄 Renovación de token ya en progreso, esperando...');
        return false;
      }

      // Evitar intentos muy frecuentes (máximo 1 cada 5 minutos)
      if (_lastRefreshAttempt != null) {
        final diferencia = DateTime.now().difference(_lastRefreshAttempt!);
        if (diferencia.inMinutes < 5) {
          print('⏱️ Renovación reciente, esperando...');
          return false;
        }
      }

      final token = await SharedPrefsHelper.getToken();
      if (token == null || token.isEmpty) {
        print('⚠️ No hay token para renovar');
        return false;
      }

      // Verificar si el token está cerca de expirar
      if (!_necesitaRenovacion(token)) {
        print('✅ Token aún válido, no necesita renovación');
        return false;
      }

      print('🔄 Token cerca de expirar, iniciando renovación automática...');
      _isRefreshing = true;
      _lastRefreshAttempt = DateTime.now();

      // Renovar el token
      final dio = DioClient.createDio();
      final apiService = ApiService(dio);
      
      final response = await apiService.renovarToken();
      
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 1 && data['token'] != null) {
          final nuevoToken = data['token'] as String;
          
          // Guardar el nuevo token
          await SharedPrefsHelper.saveToken(nuevoToken);
          
          print('✅ Token renovado exitosamente');
          _isRefreshing = false;
          return true;
        } else {
          print('⚠️ Error al renovar token: ${data['message'] ?? 'Error desconocido'}');
          _isRefreshing = false;
          return false;
        }
      } else {
        print('⚠️ Error HTTP al renovar token: ${response.response.statusCode}');
        _isRefreshing = false;
        return false;
      }
    } catch (e) {
      print('❌ Error al renovar token: $e');
      _isRefreshing = false;
      return false;
    }
  }

  /// Verifica si el token necesita renovación
  /// Retorna true si el token expira en menos de [diasAntesDeRenovar] días
  bool _necesitaRenovacion(String token) {
    try {
      // Decodificar el token para obtener la fecha de expiración
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      
      // Obtener la fecha de expiración (exp está en segundos desde epoch)
      final exp = decodedToken['exp'];
      if (exp == null) {
        // Si no tiene expiración, no necesita renovación
        print('ℹ️ Token sin fecha de expiración');
        return false;
      }

      final fechaExpiracion = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final ahora = DateTime.now();
      final diasRestantes = fechaExpiracion.difference(ahora).inDays;

      print('📅 Token expira en $diasRestantes días');

      // Renovar si quedan menos de [diasAntesDeRenovar] días
      if (diasRestantes <= diasAntesDeRenovar) {
        print('🔄 Token necesita renovación (quedan $diasRestantes días)');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Error al verificar expiración del token: $e');
      // Si hay error al decodificar, intentar renovar por seguridad
      return true;
    }
  }

  /// Fuerza la renovación del token (útil para testing o renovación manual)
  Future<bool> forzarRenovacion() async {
    _isRefreshing = false;
    _lastRefreshAttempt = null;
    return await renovarSiEsNecesario();
  }

  /// Obtiene los días restantes hasta la expiración del token
  Future<int?> obtenerDiasRestantes() async {
    try {
      final token = await SharedPrefsHelper.getToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final exp = decodedToken['exp'];
      if (exp == null) {
        return null;
      }

      final fechaExpiracion = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final ahora = DateTime.now();
      return fechaExpiracion.difference(ahora).inDays;
    } catch (e) {
      print('❌ Error al obtener días restantes: $e');
      return null;
    }
  }
}

