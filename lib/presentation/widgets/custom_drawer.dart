import 'package:flutter/material.dart';
import '../screens/usuarios_screen.dart';
import '../screens/productos_screen.dart';
import '../screens/categorias_screen.dart';
import '../screens/proveedores_screen.dart';
import '../screens/ventas_screen.dart';
import '../screens/clientes_screen.dart';
import '../screens/envios_screen.dart';
import '../screens/reportes_screen.dart';
import '../screens/backups_screen.dart';
import '../screens/dashboard_screen.dart';
import '../../core/constants/role_constants.dart';
import '../../core/services/app_update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/services/app_update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CustomDrawer extends StatelessWidget {
  final String username;
  final VoidCallback onLogout;
  final int? rolId;

  const CustomDrawer({
    super.key,
    required this.username,
    required this.onLogout,
    this.rolId,
  });

  @override
  Widget build(BuildContext context) {
    // Si rolId es null, usar Admin (1) por defecto
    final efectiveRolId = rolId ?? 1;
    final nombreRol = RoleConstants.getNombreRol(efectiveRolId);
    final colorRol = RoleConstants.getColorRol(efectiveRolId);
    final iconoRol = RoleConstants.getIconoRol(efectiveRolId);
    
    print('═══════════════════════════════════════════════════');
    print('🎨 CustomDrawer construido para: $username');
    print('   📍 Rol ID recibido: ${rolId ?? "NULL"}');
    print('   📍 Rol Efectivo: $efectiveRolId ($nombreRol)');
    print('   📍 Puede ver Envíos: ${RoleConstants.tieneAccesoAEnvios(efectiveRolId)}');
    print('   📍 Puede ver Ventas: ${RoleConstants.tieneAccesoAVentas(efectiveRolId)}');
    print('═══════════════════════════════════════════════════');

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header del drawer con badge de rol
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
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        iconoRol,
                        size: 45,
                        color: colorRol,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Badge de rol
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorRol,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            iconoRol,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            nombreRol,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sánchez Pharma',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Opciones del menú filtradas por rol
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Dashboard (visible para todos)
                  _buildDrawerItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  
                  // === USUARIOS (Solo Admin) ===
                  if (RoleConstants.tieneAccesoAUsuarios(efectiveRolId)) ...[
                    _buildDrawerItem(
                      icon: Icons.people,
                      title: 'Usuarios',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UsuariosScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                  ],
                  
                  // === INVENTARIO (Admin y Almacén) ===
                  if (RoleConstants.tieneAccesoAInventario(efectiveRolId))
                    ExpansionTile(
                      leading: const Icon(Icons.inventory, color: Colors.blue),
                      title: const Text(
                        'Inventario',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      children: [
                        _buildSubDrawerItem(
                          icon: Icons.inventory_2,
                          title: 'Productos',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProductosScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSubDrawerItem(
                          icon: Icons.category,
                          title: 'Categorías',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CategoriasScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSubDrawerItem(
                          icon: Icons.local_shipping_outlined,
                          title: 'Proveedores',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProveedoresScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  
                  // === VENTAS (Admin y Vendedor) ===
                  if (RoleConstants.tieneAccesoAVentas(efectiveRolId))
                    ExpansionTile(
                      leading: const Icon(Icons.shopping_cart, color: Colors.orange),
                      title: const Text(
                        'Ventas',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      children: [
                        _buildSubDrawerItem(
                          icon: Icons.point_of_sale,
                          title: 'Registrar Venta',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VentasScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSubDrawerItem(
                          icon: Icons.people_outline,
                          title: 'Clientes',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ClientesScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  
                  // === ENVÍOS (Admin, Vendedor y Repartidor) ===
                  if (RoleConstants.tieneAccesoAEnvios(efectiveRolId)) ...[
                    _buildDrawerItem(
                      icon: Icons.local_shipping,
                      title: 'Seguimiento de Envíos',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EnviosScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  
                  // === REPORTES (Admin e Ingeniero) ===
                  if (RoleConstants.tieneAccesoAReportes(efectiveRolId)) ...[
                    _buildDrawerItem(
                      icon: Icons.assessment,
                      title: 'Reportes',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReportesScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  
                  // === BACKUPS (Solo Ingeniero) ===
                  if (RoleConstants.tieneAccesoABackups(efectiveRolId)) ...[
                    _buildDrawerItem(
                      icon: Icons.backup,
                      title: 'Backups',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BackupsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  
                  const Divider(),
                  
                  // Configuración (visible para todos)
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'Configuración',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Configuración - Próximamente'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  
                  // Acerca de (visible para todos)
                  _buildDrawerItem(
                    icon: Icons.info,
                    title: 'Acerca de',
                    onTap: () {
                      Navigator.pop(context);
                      showAboutDialog(
                        context: context,
                        applicationName: 'Sánchez Pharma',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(
                          Icons.medication,
                          size: 50,
                          color: Colors.green,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              children: [
                                const Text(
                                  'Sistema de gestión farmacéutica para el control de inventario, ventas y envíos.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorRol,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Rol: $nombreRol',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Botón de actualizar app
            const Divider(),
            _UpdateAppButton(),
            const Divider(),
            
            // Botón de cerrar sesión
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Cerrar Sesión',
              onTap: onLogout,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
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
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSubDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: const SizedBox(width: 16),
      title: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ],
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

