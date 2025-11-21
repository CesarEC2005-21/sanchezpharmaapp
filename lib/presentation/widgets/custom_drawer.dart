import 'package:flutter/material.dart';
import '../screens/usuarios_screen.dart';
import '../screens/productos_screen.dart';
import '../screens/categorias_screen.dart';
import '../screens/proveedores_screen.dart';
import '../screens/ventas_screen.dart';
import '../screens/clientes_screen.dart';
import '../screens/envios_screen.dart';
import '../screens/reportes_screen.dart';
import '../screens/dashboard_screen.dart';

class CustomDrawer extends StatelessWidget {
  final String username;
  final VoidCallback onLogout;

  const CustomDrawer({
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
                      'Sánchez Pharma',
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
                  
                  // Usuarios
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
                  
                  // Inventario - Expandible
                  ExpansionTile(
                    leading: const Icon(Icons.inventory, color: Colors.green),
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
                  
                  // Ventas - Expandible
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
                  
                  // Envíos
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
                  
                  // Reportes
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
                  
                  const Divider(),
                  
                  // Configuración
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
                  
                  // Acerca de
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
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text(
                              'Sistema de gestión farmacéutica para el control de inventario, ventas y envíos.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Botón de cerrar sesión
            const Divider(),
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

