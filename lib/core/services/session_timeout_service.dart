import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/shared_prefs_helper.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../presentation/screens/login_screen.dart';
import '../../main.dart';

/// Servicio para manejar el timeout de sesión de usuarios administrativos
/// Después de 1 hora de inactividad, muestra un diálogo preguntando si desea continuar
class SessionTimeoutService with WidgetsBindingObserver {
  static final SessionTimeoutService _instance = SessionTimeoutService._internal();
  factory SessionTimeoutService() => _instance;
  SessionTimeoutService._internal();

  Timer? _timeoutTimer;
  DateTime? _lastActivityTime;
  bool _isDialogShowing = false;
  static const Duration _timeoutDuration = Duration(hours: 1);

  /// Inicializar el servicio
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    _resetTimer();
  }

  /// Limpiar recursos
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// Registrar actividad del usuario (llamar cuando hay interacción)
  void registerActivity() {
    _lastActivityTime = DateTime.now();
    _resetTimer();
  }

  /// Reiniciar el timer
  void _resetTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_timeoutDuration, () {
      _checkTimeout();
    });
  }

  /// Verificar si ha pasado el timeout
  Future<void> _checkTimeout() async {
    // Solo aplicar timeout a usuarios administrativos
    final isCliente = await SharedPrefsHelper.isCliente();
    if (isCliente) {
      // Los clientes no tienen timeout, reiniciar el timer
      _resetTimer();
      return;
    }

    // Verificar si el usuario es administrativo
    final isUsuarioInterno = await SharedPrefsHelper.isUsuarioInterno();
    if (!isUsuarioInterno) {
      return;
    }

    // Verificar si ya hay un diálogo mostrándose
    if (_isDialogShowing) {
      return;
    }

    // Mostrar diálogo de confirmación
    _showTimeoutDialog();
  }

  /// Mostrar diálogo de timeout
  void _showTimeoutDialog() {
    if (_isDialogShowing) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(
              Icons.access_time,
              color: Colors.orange.shade700,
              size: 28,
            ),
            const SizedBox(width: 10),
            const Text(
              'Sesión Inactiva',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Has estado inactivo por más de 1 hora.\n\n¿Deseas continuar?',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isDialogShowing = false;
              Navigator.of(context).pop();
              _handleLogout(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
            ),
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _isDialogShowing = false;
              Navigator.of(context).pop();
              // Registrar actividad y continuar
              registerActivity();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Continuar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
      ),
    );
  }

  /// Manejar logout
  Future<void> _handleLogout(BuildContext context) async {
    try {
      final dio = DioClient.createDio();
      final apiService = ApiService(dio);
      await apiService.logout();
    } catch (e) {
      print('Error al cerrar sesión en el servidor: $e');
    }

    await SharedPrefsHelper.clearAuthData();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App volvió al primer plano
        registerActivity();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App fue a segundo plano o está inactiva
        // El timer seguirá corriendo
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
}

