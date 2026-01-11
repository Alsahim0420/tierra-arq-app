// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../../core/entities/user_entity.dart' as core;
import '../../app/app.dart';
import '../../utils/user_role_utils.dart';
import '../obra/obras_list_screen.dart';
import '../obra/obras_finalizadas_screen.dart';
import '../user/users_list_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  final core.UserEntity user;
  final VoidCallback onLogout;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Lista de pantallas disponibles según el rol del usuario
  List<Widget> get _screens {
    final screens = <Widget>[
      // Índice 0: Obras Activas (siempre visible)
      ObrasListScreen(
        user: widget.user,
        onLogout: widget.onLogout,
        showFAB: true, // FAB solo en obras activas
      ),
      // Índice 1: Obras Finalizadas (siempre visible)
      ObrasFinalizadasScreen(
        user: widget.user,
        onLogout: widget.onLogout,
      ),
    ];

    // Índice 2: Gestión de Maestros (solo para administrador)
    if (UserRoleUtils.isAdmin(widget.user)) {
      screens.add(
        const UsersListScreen(),
      );
    }

    // Índice 3 o 2 (dependiendo si es admin): Perfil (siempre visible)
    screens.add(
      ProfileScreen(
        user: widget.user,
        onLogout: widget.onLogout,
      ),
    );

    return screens;
  }

  // Lista de items del BottomNavigationBar según el rol
  List<BottomNavigationBarItem> get _bottomNavItems {
    final items = <BottomNavigationBarItem>[
      // Índice 0: Obras Activas
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        activeIcon: Icon(Icons.home),
        label: 'Obras',
      ),
      // Índice 1: Obras Finalizadas
      const BottomNavigationBarItem(
        icon: Icon(Icons.assignment_turned_in_outlined),
        activeIcon: Icon(Icons.assignment_turned_in),
        label: 'Finalizadas',
      ),
    ];

    // Índice 2: Gestión de Maestros (solo para administrador)
    if (UserRoleUtils.isAdmin(widget.user)) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Maestros',
        ),
      );
    }

    // Último índice: Perfil
    items.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
    );

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1B1B) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
              // Cuando volvemos a la pestaña 0 (Obras Activas), forzar rebuild
              if (index == 0) {
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? const Color(0xFF1B1B1B) : Colors.white,
            selectedItemColor: TierraApp.primary,
            unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
            items: _bottomNavItems,
          ),
        ),
      ),
    );
  }
}

