// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../../core/entities/user_entity.dart' as core;
import '../../app/app.dart';
import '../../utils/user_role_utils.dart';
import '../obra/obras_list_screen.dart';
import '../obra/obras_finalizadas_screen.dart';
import '../user/users_list_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user, required this.onLogout});

  final core.UserEntity user;
  final VoidCallback onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      ObrasFinalizadasScreen(user: widget.user, onLogout: widget.onLogout),
    ];

    // Índice 2: Gestión de Maestros (solo para administrador)
    if (UserRoleUtils.isAdmin(widget.user)) {
      screens.add(const UsersListScreen());
    }

    // Índice 3 o 2 (dependiendo si es admin): Perfil (siempre visible)
    screens.add(ProfileScreen(user: widget.user, onLogout: widget.onLogout));

    return screens;
  }

  // Lista de items de navegación según el rol
  List<_NavItem> get _navItems {
    final items = <_NavItem>[
      // Índice 0: Obras Activas
      const _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Obras',
      ),
      // Índice 1: Obras Finalizadas
      const _NavItem(
        icon: Icons.assignment_turned_in_outlined,
        activeIcon: Icons.assignment_turned_in,
        label: 'Finalizadas',
      ),
    ];

    // Índice 2: Gestión de Maestros (solo para administrador)
    if (UserRoleUtils.isAdmin(widget.user)) {
      items.add(
        const _NavItem(
          icon: Icons.people_outline,
          activeIcon: Icons.people,
          label: 'Maestros',
        ),
      );
    }

    // Último índice: Perfil
    items.add(
      const _NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Perfil',
      ),
    );

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1B1B) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, -6),
              spreadRadius: 0,
            ),
          ],
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                _navItems.length,
                (index) => _buildNavButton(
                  context: context,
                  item: _navItems[index],
                  index: index,
                  isActive: _currentIndex == index,
                  isDark: isDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required _NavItem item,
    required int index,
    required bool isActive,
    required bool isDark,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(24),
          splashColor: TierraApp.primary.withValues(alpha: 0.1),
          highlightColor: TierraApp.primary.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isActive
                  ? TierraApp.primary.withValues(alpha: isDark ? 0.3 : 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: TierraApp.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    key: ValueKey('${item.label}_${isActive}'),
                    size: isActive ? 26 : 22,
                    color: isActive
                        ? TierraApp.primary
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.65)
                              : Colors.black.withValues(alpha: 0.55)),
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: isActive ? 12 : 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? TierraApp.primary
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.65)
                              : Colors.black.withValues(alpha: 0.55)),
                    letterSpacing: isActive ? 0.3 : 0.2,
                    height: 1.1,
                  ),
                  child: Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
