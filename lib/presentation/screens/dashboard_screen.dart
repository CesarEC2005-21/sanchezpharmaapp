import 'package:flutter/material.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/constants/role_constants.dart';
import '../../data/api/dio_client.dart';
import '../../data/api/api_service.dart';
import '../widgets/custom_drawer.dart';
import 'login_screen.dart';
import 'usuarios_screen.dart';
import 'productos_screen.dart';
import 'ventas_screen.dart';
import 'envios_screen.dart';
import 'reportes_screen.dart';
import 'clientes_screen.dart';
import 'categorias_screen.dart';
import 'proveedores_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _username = '';
  int? _rolId;
  String _nombreRol = '';
  Color _colorRol = Colors.grey;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final username = await SharedPrefsHelper.getUsername();
    final rolId = await SharedPrefsHelper.getRolId();
    
    print('📊 Dashboard - Datos cargados:');
    print('   - Username: $username');
    print('   - Rol ID: ${rolId ?? "NULL - usando Admin por defecto"}');
    
    setState(() {
      _username = username ?? 'Usuario';
      // Si rolId es null, usar Admin (1) por defecto para que se muestren todas las opciones
      _rolId = rolId ?? 1;
      _nombreRol = RoleConstants.getNombreRol(_rolId);
      _colorRol = RoleConstants.getColorRol(_rolId);
    });
  }

  Future<void> _handleLogout() async {
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Llamar al endpoint de logout
      final dio = DioClient.createDio();
      final apiService = ApiService(dio);
      await apiService.logout();
    } catch (e) {
      print('Error al cerrar sesión en el servidor: $e');
    }

    // Limpiar datos locales
    await SharedPrefsHelper.clearAuthData();

    if (mounted) {
      // Navegar al login
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
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      drawer: CustomDrawer(
        username: _username,
        onLogout: _handleLogout,
        rolId: _rolId,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bienvenida
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade900],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '¡Bienvenido!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _username,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Badge de rol
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _colorRol,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  RoleConstants.getIconoRol(_rolId),
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _nombreRol,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Título de sección
              const Text(
                'Accesos Rápidos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Grid de opciones filtradas por rol
              Expanded(
                child: _rolId == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Cargando...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: _buildDashboardCards(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construir las cards del dashboard según el rol
  List<Widget> _buildDashboardCards() {
    List<Widget> cards = [];
    
    // Usar rol efectivo (si es null, usar Admin)
    final efectiveRolId = _rolId ?? 1;
    
    print('🎯 Building Dashboard Cards con Rol ID: $efectiveRolId');

    // === USUARIOS (Solo Admin) ===
    if (RoleConstants.tieneAccesoAUsuarios(efectiveRolId)) {
      cards.add(_buildDashboardCard(
        icon: Icons.people,
        title: 'Usuarios',
        color: Colors.red,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UsuariosScreen(),
            ),
          );
        },
      ));
    }

    // === INVENTARIO (Admin y Almacén) ===
    if (RoleConstants.tieneAccesoAInventario(efectiveRolId)) {
      cards.add(_buildDashboardCard(
        icon: Icons.inventory_2,
        title: 'Productos',
        color: Colors.blue,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductosScreen(),
            ),
          );
        },
      ));
      cards.add(_buildDashboardCard(
        icon: Icons.category,
        title: 'Categorías',
        color: Colors.indigo,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CategoriasScreen(),
            ),
          );
        },
      ));
      cards.add(_buildDashboardCard(
        icon: Icons.local_shipping_outlined,
        title: 'Proveedores',
        color: Colors.cyan,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProveedoresScreen(),
            ),
          );
        },
      ));
    }

    // === VENTAS (Admin y Vendedor) ===
    if (RoleConstants.tieneAccesoAVentas(efectiveRolId)) {
      cards.add(_buildDashboardCard(
        icon: Icons.point_of_sale,
        title: 'Ventas',
        color: Colors.orange,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VentasScreen(),
            ),
          );
        },
      ));
      cards.add(_buildDashboardCard(
        icon: Icons.people_outline,
        title: 'Clientes',
        color: Colors.deepOrange,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ClientesScreen(),
            ),
          );
        },
      ));
    }

    // === ENVÍOS (Admin y Repartidor) ===
    if (RoleConstants.tieneAccesoAEnvios(efectiveRolId)) {
      cards.add(_buildDashboardCard(
        icon: Icons.local_shipping,
        title: 'Envíos',
        color: Colors.purple,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EnviosScreen(),
            ),
          );
        },
      ));
    }

    // === REPORTES (Admin) ===
    if (RoleConstants.tieneAccesoAReportes(efectiveRolId)) {
      cards.add(_buildDashboardCard(
        icon: Icons.assessment,
        title: 'Reportes',
        color: Colors.teal,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReportesScreen(),
            ),
          );
        },
      ));
    }
    
    print('✅ Total de cards generadas: ${cards.length}');
    
    // Si no hay cards (no debería pasar con el fallback), al menos mostrar un mensaje
    if (cards.isEmpty) {
      print('⚠️ ADVERTENCIA: No se generaron cards!');
    }

    return cards;
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.shade400,
                color.shade700,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.shade300.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

