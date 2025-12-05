import 'package:flutter/material.dart';
import '../screens/pedidos_cliente_screen.dart';
import '../screens/configuracion_cliente_screen.dart';
import '../screens/home_cliente_screen.dart';
import '../screens/login_screen.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../core/services/app_update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ClienteDrawer extends StatelessWidget {
  final String username;
  final Future<void> Function() onLogout;

  const ClienteDrawer({
    super.key,
    required this.username,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header del drawer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade900],
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Cliente',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Opciones del menú
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.store,
                    title: 'Tienda',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeClienteScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  
                  _buildDrawerItem(
                    icon: Icons.shopping_bag,
                    title: 'Mis Pedidos',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PedidosClienteScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const Divider(),
                  
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'Configuración',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConfiguracionClienteScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const Divider(),
                  
                  _UpdateAppButton(),
                  
                  const Divider(),
                  
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Cerrar Sesión',
                    onTap: () async {
                      Navigator.pop(context);
                      await onLogout();
                    },
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.green.shade700),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }
}

// Widget para el botón de actualizar app
class _UpdateAppButton extends StatefulWidget {
  @override
  State<_UpdateAppButton> createState() => _UpdateAppButtonState();
}

class _UpdateAppButtonState extends State<_UpdateAppButton> {
  final AppUpdateService _updateService = AppUpdateService();
  bool _isChecking = false;
  bool _hasUpdate = false;
  String _currentVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
    _checkForUpdates();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _currentVersion = packageInfo.version;
      });
    } catch (e) {
      debugPrint('Error al obtener versión: $e');
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final updateInfo = await _updateService.checkForUpdates();
      if (updateInfo != null && updateInfo['needs_update'] == true) {
        setState(() {
          _hasUpdate = true;
        });
      }
    } catch (e) {
      debugPrint('Error al verificar actualización: $e');
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  Future<void> _handleUpdateTap() async {
    // Verificar actualización nuevamente
    final updateInfo = await _updateService.checkForUpdates();
    
    if (updateInfo == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo verificar actualizaciones. Intenta más tarde.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!updateInfo['needs_update']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya tienes la última versión instalada.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return;
    }

    // Mostrar diálogo de actualización
    if (mounted) {
      Navigator.pop(context); // Cerrar drawer
      AppUpdateService.showUpdateDialog(
        context,
        updateInfo: updateInfo,
        onDownload: () => _downloadAndInstall(updateInfo),
      );
    }
  }

  Future<void> _downloadAndInstall(Map<String, dynamic> updateInfo) async {
    final apkUrl = updateInfo['apk_url'] as String?;
    if (apkUrl == null || apkUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL de descarga no disponible.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Mostrar diálogo de progreso
    if (mounted) {
      AppUpdateService.showDownloadProgressDialog(
        context,
        onCancel: () {},
      );
    }

    // Descargar e instalar
    final success = await _updateService.downloadAndInstallApk(
      apkUrl: apkUrl,
      onProgress: (received, total) {
        // Actualizar progreso (se puede mejorar con un StatefulBuilder)
        debugPrint('Descargando: ${(received / total * 100).toStringAsFixed(1)}%');
      },
      onError: (error) {
        if (mounted) {
          Navigator.pop(context); // Cerrar diálogo de progreso
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    if (mounted) {
      Navigator.pop(context); // Cerrar diálogo de progreso
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actualización descargada. Por favor instala el APK.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          Icon(
            Icons.system_update,
            color: Colors.blue.shade700,
          ),
          if (_hasUpdate)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'Actualizar App',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_isChecking)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              ),
            )
          else if (_currentVersion.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'v$_currentVersion',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
        ],
      ),
      onTap: _handleUpdateTap,
    );
  }
}

