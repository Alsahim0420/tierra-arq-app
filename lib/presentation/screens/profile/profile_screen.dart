// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/user_entity.dart' as core;
import '../../../core/theme/app_colors.dart';
import '../../widgets/info_row.dart';
import '../../widgets/info_section.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_event.dart';
import '../../bloc/theme/theme_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.user, required this.onLogout});

  final core.UserEntity user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Perfil',
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: AppColors.appBarColor(isDark),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? null : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role == 'admin' ? 'Administrador' : 'Maestro',
                      style: textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.primary
                            : Colors.brown.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            InfoSection(
              title: 'Configuración',
              children: [
                BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, state) {
                    return ListTile(
                      leading: Icon(
                        state.theme == AppTheme.light
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      title: Text(
                        'Tema',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDark ? null : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        state.theme == AppTheme.light
                            ? 'Claro'
                            : state.theme == AppTheme.dark
                                ? 'Oscuro'
                                : 'Sistema',
                        style: textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white54 : Colors.black87,
                        ),
                      ),
                      trailing: PopupMenuButton<AppTheme>(
                        initialValue: state.theme,
                        onSelected: (theme) {
                          context.read<ThemeBloc>().add(ChangeTheme(theme));
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: AppTheme.light,
                            child: ListTile(
                              leading: Icon(Icons.light_mode),
                              title: Text('Claro'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: AppTheme.system,
                            child: ListTile(
                              leading: Icon(Icons.brightness_auto),
                              title: Text('Sistema'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: AppTheme.dark,
                            child: ListTile(
                              leading: Icon(Icons.dark_mode),
                              title: Text('Oscuro'),
                            ),
                          ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            state.theme == AppTheme.light
                                ? 'Claro'
                                : state.theme == AppTheme.dark
                                    ? 'Oscuro'
                                    : 'Sistema',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            InfoSection(
              title: 'Información de contacto',
              children: [
                InfoRow(icon: Icons.email, label: 'Email', value: user.email),
                if (user.phone != null)
                  InfoRow(
                    icon: Icons.phone,
                    label: 'Teléfono',
                    value: '+57 ${user.phone}',
                  ),
                if (user.city.isNotEmpty)
                  InfoRow(
                    icon: Icons.location_on,
                    label: 'Ciudad',
                    value: user.city,
                  ),
              ],
            ),
            if (user.dni != null)
              InfoSection(
                title: 'Información personal',
                children: [
                  InfoRow(
                    icon: Icons.badge,
                    label: 'DNI',
                    value: user.dni.toString(),
                  ),
                ],
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  onLogout();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
