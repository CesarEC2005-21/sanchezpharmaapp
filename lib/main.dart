import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/utils/shared_prefs_helper.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/session_timeout_service.dart';
import 'core/notifiers/cart_notifier.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/home_cliente_screen.dart';

// NavigatorKey global para poder navegar desde cualquier parte de la app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Capturar errores no controlados de Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log del error para debugging
    print('❌ Error de Flutter no controlado:');
    print('   Error: ${details.exception}');
    print('   Stack: ${details.stack}');
    
    // En producción, podrías enviar esto a un servicio de logging
    // Por ahora, solo lo logueamos
    
    // Limpiar datos de autenticación cuando hay un error crítico
    SharedPrefsHelper.clearAuthData();
    
    // Redirigir directamente al login si hay un contexto disponible
    if (navigatorKey.currentContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          // Limpiar toda la pila y redirigir directamente al login
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (route) => false,
          );
        }
      });
    }
  };
  
  // Capturar errores de la zona de ejecución (async errors)
  PlatformDispatcher.instance.onError = (error, stack) {
    // Log del error para debugging
    print('❌ Error de zona no controlado:');
    print('   Error: $error');
    print('   Stack: $stack');
    
    // Retornar true indica que el error fue manejado
    return true;
  };
  
  // Inicializar servicio de notificaciones
  await LocalNotificationService().initialize();
  
  // Inicializar servicio de timeout de sesión
  SessionTimeoutService().initialize();
  
  // Inicializar contador del carrito desde SharedPreferences
  await _inicializarCarrito();
  
  runApp(const MyApp());
}

/// Inicializa el contador del carrito desde SharedPreferences
Future<void> _inicializarCarrito() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final carritoJson = prefs.getString('carrito_cliente');
    int totalItems = 0;
    
    if (carritoJson != null && carritoJson.isNotEmpty) {
      final items = carritoJson.split('|');
      for (var item in items) {
        if (item.isNotEmpty) {
          final parts = item.split(':');
          if (parts.length >= 4) {
            totalItems += int.tryParse(parts[3]) ?? 0;
          }
        }
      }
    }
    
    CartNotifier.instance.updateCount(totalItems);
    print('🛒 Carrito inicializado: $totalItems items');
  } catch (e) {
    print('❌ Error al inicializar carrito: $e');
    CartNotifier.instance.updateCount(0);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sánchez Pharma',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // Configurar localizaciones para Material widgets como DatePicker
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español de España
        Locale('es', 'MX'), // Español de México
        Locale('es', 'PE'), // Español de Perú
        Locale('en', 'US'), // Inglés como fallback
      ],
      locale: const Locale('es', 'ES'),
      // Capturar errores de renderizado y mostrarlos de forma amigable
      builder: (context, child) {
        // Configurar ErrorWidget.builder para mostrar errores amigables
        ErrorWidget.builder = (FlutterErrorDetails details) {
          // Log del error para debugging
          print('❌ Error de renderizado: ${details.exception}');
          print('Stack trace: ${details.stack}');
          
          // Limpiar datos de autenticación cuando hay un error crítico
          SharedPrefsHelper.clearAuthData();
          
          // Redirigir directamente al login después de un breve delay
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (navigatorKey.currentContext != null) {
              // Limpiar toda la pila de navegación y redirigir directamente al login
              Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
                (route) => false,
              );
            }
          });
          
          // Retornar un widget de error temporal mientras se redirige
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Oops! Algo salió mal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ocurrió un error inesperado. Redirigiendo...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          );
        };
        
        // Envolver todas las pantallas con el ActivityTracker
        return ActivityTracker(child: child ?? const SizedBox());
      },
      home: const SplashScreen(),
    );
  }
}

/// Widget que registra actividad del usuario para el servicio de timeout
class ActivityTracker extends StatefulWidget {
  final Widget child;
  
  const ActivityTracker({super.key, required this.child});

  @override
  State<ActivityTracker> createState() => _ActivityTrackerState();
}

class _ActivityTrackerState extends State<ActivityTracker> {
  final SessionTimeoutService _timeoutService = SessionTimeoutService();

  @override
  void initState() {
    super.initState();
    // Registrar actividad inicial
    _timeoutService.registerActivity();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // Registrar actividad cuando el usuario toca la pantalla
        _timeoutService.registerActivity();
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          // Registrar actividad cuando el usuario interactúa
          _timeoutService.registerActivity();
        },
        child: widget.child,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Esperar un momento para mostrar el splash
    await Future.delayed(const Duration(seconds: 2));

    // Verificar si el usuario está autenticado
    final isAuthenticated = await SharedPrefsHelper.isAuthenticated();

    if (mounted) {
      if (isAuthenticated) {
        // Verificar el tipo de usuario para redirigir correctamente
        final isCliente = await SharedPrefsHelper.isCliente();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => isCliente 
                ? const HomeClienteScreen() 
                : const DashboardScreen(),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade700,
              Colors.green.shade900,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/ddspLogo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.medication,
                          size: 100,
                          color: Colors.green,
                        );
                      },
                    ),
                  ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sánchez Pharma',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


