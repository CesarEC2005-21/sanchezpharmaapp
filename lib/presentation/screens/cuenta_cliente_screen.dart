import 'package:flutter/material.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/utils/responsive_helper.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../../core/constants/documentos_legales.dart';
import '../../core/services/notificacion_service.dart';
import 'pedidos_cliente_screen.dart';
import 'configuracion_cliente_screen.dart';
import 'editar_perfil_screen.dart';
import 'login_screen.dart';
import 'favoritos_cliente_screen.dart';
import 'mis_direcciones_screen.dart';
import 'documento_legal_screen.dart';
import 'atencion_cliente_screen.dart';
import 'notificaciones_screen.dart';
import 'dart:async';

class CuentaClienteScreen extends StatefulWidget {
  const CuentaClienteScreen({super.key});

  @override
  State<CuentaClienteScreen> createState() => _CuentaClienteScreenState();
}

class _CuentaClienteScreenState extends State<CuentaClienteScreen> {
  String _username = '';
  String _email = '';
  int _notificacionesNoLeidas = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _cargarContadorNotificaciones();
    // Actualizar contador cada 30 segundos
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _cargarContadorNotificaciones();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargarContadorNotificaciones() async {
    final clienteId = await SharedPrefsHelper.getClienteId();
    if (clienteId != null) {
      final count = await NotificacionService().contarNoLeidas(clienteId);
      if (mounted) {
        setState(() {
          _notificacionesNoLeidas = count;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    final username = await SharedPrefsHelper.getUsername();
    setState(() {
      _username = username ?? 'Cliente';
      // El email podría guardarse también, por ahora usamos username
      _email = '';
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final dio = DioClient.createDio();
      final apiService = ApiService(dio);
      await apiService.logout();
    } catch (e) {
      print('Error al cerrar sesión en el servidor: $e');
    }

    await SharedPrefsHelper.clearAuthData();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.maxContentWidth(context) ?? double.infinity,
            ),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveHelper.verticalPadding(context),
                    horizontal: ResponsiveHelper.horizontalPadding(context),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Mi cuenta',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.titleFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: ResponsiveHelper.spacing(context)),

                // Información del usuario
                Container(
                  margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding(context)),
                  padding: ResponsiveHelper.formPadding(context),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: ResponsiveHelper.isSmallScreen(context) ? 30 : 35,
                      backgroundColor: Colors.green.shade700,
                      child: Text(
                        _username.isNotEmpty ? _username[0].toUpperCase() : 'C',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveHelper.isSmallScreen(context) ? 24 : 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.spacing(context)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _username,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.subtitleFontSize(context) + 4,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (_email.isNotEmpty)
                            Text(
                              _email,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.bodyFontSize(context),
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: ResponsiveHelper.spacing(context)),

              // Opciones principales
              Container(
                margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding(context)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      title: 'Mi perfil',
                      onTap: () async {
                        // Navegar a pantalla de editar perfil
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditarPerfilScreen(),
                          ),
                        );
                        
                        // Si se actualizó el perfil, recargar datos
                        if (resultado == true) {
                          _loadUserData();
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Mis pedidos',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PedidosClienteScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(
                      icon: Icons.favorite_outline,
                      title: 'Mis favoritos',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FavoritosClienteScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notificaciones',
                      badge: _notificacionesNoLeidas > 0 ? _notificacionesNoLeidas : null,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificacionesScreen(),
                          ),
                        );
                        _cargarContadorNotificaciones();
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: ResponsiveHelper.spacing(context)),

              // Opciones adicionales
              Container(
                margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding(context)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.location_on_outlined,
                      title: 'Mis direcciones',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MisDireccionesScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: ResponsiveHelper.spacing(context)),

              // Opciones legales
              Container(
                margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding(context)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.description_outlined,
                      title: 'Legales',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DocumentoLegalScreen(
                              titulo: 'Información Legal',
                              contenido: DocumentosLegales.legales,
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Políticas de privacidad',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DocumentoLegalScreen(
                              titulo: 'Políticas de Privacidad',
                              contenido: DocumentosLegales.politicasPrivacidad,
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(
                      icon: Icons.article_outlined,
                      title: 'Términos y condiciones',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DocumentoLegalScreen(
                              titulo: 'Términos y Condiciones',
                              contenido: DocumentosLegales.terminosCondiciones,
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(
                      icon: Icons.lock_outline,
                      title: 'Cambiar contraseña',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ConfiguracionClienteScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: ResponsiveHelper.spacing(context)),

              // Soporte
              Container(
                margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding(context)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildMenuItem(
                  icon: Icons.headset_mic_outlined,
                  title: 'Atención al cliente',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AtencionClienteScreen(),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: ResponsiveHelper.spacing(context)),

              // Botón Cerrar Sesión
              Container(
                margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding(context)),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.spacing(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.bodyFontSize(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: ResponsiveHelper.verticalPadding(context) * 2),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int? badge,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.green.shade700,
        size: ResponsiveHelper.iconSize(context),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveHelper.bodyFontSize(context),
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null && badge > 0)
            Container(
              margin: EdgeInsets.only(right: ResponsiveHelper.spacing(context) / 2),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.spacing(context) / 2,
                vertical: ResponsiveHelper.spacing(context) / 4,
              ),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge > 99 ? '99+' : badge.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveHelper.bodyFontSize(context) - 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
            size: ResponsiveHelper.iconSize(context),
          ),
        ],
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.spacing(context),
        vertical: ResponsiveHelper.spacing(context) / 2,
      ),
    );
  }
}

