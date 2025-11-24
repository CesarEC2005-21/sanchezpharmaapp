import 'package:flutter/material.dart';
import 'tienda_screen.dart';
import 'categorias_cliente_screen.dart';
import 'cuenta_cliente_screen.dart';

class HomeClienteScreen extends StatefulWidget {
  final int initialIndex;

  const HomeClienteScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<HomeClienteScreen> createState() => _HomeClienteScreenState();
}

class _HomeClienteScreenState extends State<HomeClienteScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const TiendaScreen(showBottomNav: false),
      CategoriasClienteScreen(
        onCategoriaSeleccionada: (categoriaId) {
          // Cambiar a la pestaña de inicio con la categoría seleccionada
          setState(() {
            _selectedIndex = 0;
          });
          // Aquí podrías pasar el ID de categoría a TiendaScreen
        },
      ),
      const CuentaClienteScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.green.shade700,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
          ),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 26),
              activeIcon: Icon(Icons.home, size: 26),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined, size: 26),
              activeIcon: Icon(Icons.grid_view, size: 26),
              label: 'Categorías',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 26),
              activeIcon: Icon(Icons.person, size: 26),
              label: 'Cuenta',
            ),
          ],
        ),
      ),
    );
  }
}

