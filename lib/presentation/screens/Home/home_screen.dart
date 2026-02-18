// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/user_entity.dart' as core;
import '../../../core/theme/app_colors.dart';
import '../../utils/user_role_utils.dart';
import '../../bloc/obra/obra_bloc.dart';
import '../../bloc/obra/obra_event.dart';
import '../dashboard/dashboard_screen.dart';
import '../obra/obras_list_screen.dart';
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
  int? _previousIndex; // Track del índice anterior

  // Callback para cambiar a la vista de obras desde el dashboard
  void _navigateToObras() {
    setState(() {
      // Si es admin, el índice de Obras es 1, si no es admin es 0
      _currentIndex = UserRoleUtils.isAdmin(widget.user) ? 1 : 0;
    });
  }

  // Obtener el índice de la pantalla de obras
  int get _obrasIndex {
    return UserRoleUtils.isAdmin(widget.user) ? 1 : 0;
  }

  // Obtener el índice del dashboard (solo para admin)
  int? get _dashboardIndex {
    return UserRoleUtils.isAdmin(widget.user) ? 0 : null;
  }

  // Lista de pantallas disponibles según el rol del usuario
  List<Widget> get _screens {
    final screens = <Widget>[];

    // Índice 0: Dashboard (solo para administrador)
    if (UserRoleUtils.isAdmin(widget.user)) {
      screens.add(
        DashboardScreen(
          user: widget.user,
          onLogout: widget.onLogout,
          onNavigateToObras: _navigateToObras,
        ),
      );
    }

    // Obras Activas (siempre visible)
    // Índice 0 si no es admin, índice 1 si es admin
    screens.add(
      ObrasListScreen(
        user: widget.user,
        onLogout: widget.onLogout,
        showFAB: true, // FAB solo en obras activas
      ),
    );

    // Gestión de Maestros (solo para administrador)
    if (UserRoleUtils.isAdmin(widget.user)) {
      screens.add(const UsersListScreen());
    }

    // Perfil (siempre visible)
    screens.add(ProfileScreen(user: widget.user, onLogout: widget.onLogout));

    return screens;
  }

  // Lista de items de navegación según el rol
  List<_NavItem> get _navItems {
    final items = <_NavItem>[];

    // Dashboard (solo para administrador)
    if (UserRoleUtils.isAdmin(widget.user)) {
      items.add(
        const _NavItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
          label: 'Inicio',
        ),
      );
    }

    // Obras Activas (siempre visible)
    items.add(
      const _NavItem(
        icon: Icons.construction_outlined,
        activeIcon: Icons.construction,
        label: 'Obras',
      ),
    );

    // Gestión de Maestros (solo para administrador)
    if (UserRoleUtils.isAdmin(widget.user)) {
      items.add(
        const _NavItem(
          icon: Icons.people_outline,
          activeIcon: Icons.people,
          label: 'Maestros',
        ),
      );
    }

    // Perfil (siempre visible)
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

    // Asegurar que el índice esté dentro del rango válido
    final validIndex = _currentIndex < _screens.length ? _currentIndex : 0;

    // Detectar cuando se cambia a la pantalla de obras o dashboard por primera vez o desde otra pantalla
    if ((validIndex == _obrasIndex || validIndex == _dashboardIndex) && 
        _previousIndex != validIndex) {
      _previousIndex = validIndex;
      // Usar post frame callback para asegurar que el contexto esté disponible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ObraBloc>().add(const UpdateObrasEstados());
        }
      });
    } else if (_previousIndex == null) {
      // Primera vez que se construye, establecer el índice anterior
      _previousIndex = validIndex;
      // Si la primera pantalla es obras o dashboard, actualizar estados
      if (validIndex == _obrasIndex || validIndex == _dashboardIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<ObraBloc>().add(const UpdateObrasEstados());
          }
        });
      }
    }

    return Scaffold(
      body: IndexedStack(index: validIndex, children: _screens),
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
              final previousIndex = _currentIndex;
              _currentIndex = index;
              
              // Si cambiamos a la pantalla de obras o dashboard, actualizar estados
              if ((index == _obrasIndex || index == _dashboardIndex) && 
                  previousIndex != index) {
                // Usar un post frame callback para asegurar que el contexto esté disponible
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.read<ObraBloc>().add(const UpdateObrasEstados());
                  }
                });
              }
            });
          },
          borderRadius: BorderRadius.circular(24),
          splashColor: AppColors.primary.withValues(alpha: 0.1),
          highlightColor: AppColors.primary.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
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
                    key: ValueKey('${item.label}_$isActive'),
                    size: isActive ? 26 : 22,
                    color: isActive
                        ? AppColors.primary
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
                        ? AppColors.primary
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
