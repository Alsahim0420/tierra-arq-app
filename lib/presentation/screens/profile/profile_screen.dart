import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/user_entity.dart' as core;
import '../../app/app.dart';
import '../../widgets/info_row.dart';
import '../../widgets/info_section.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_event.dart';
import '../../bloc/theme/theme_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

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
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.4,
          ),
        ),
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
                      color: TierraApp.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: TierraApp.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: TierraApp.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role == 'admin' ? 'Administrador' : 'Maestro',
                      style: textTheme.bodySmall?.copyWith(
                        color: isDark ? TierraApp.primary : const Color(0xFF8B5A3C),
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
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      title: Text(
                        'Tema',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        state.theme == AppTheme.light ? 'Claro' : 'Oscuro',
                        style: textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      trailing: Switch(
                        value: state.theme == AppTheme.light,
                        onChanged: (value) {
                          context.read<ThemeBloc>().add(
                                ChangeTheme(
                                  value ? AppTheme.light : AppTheme.dark,
                                ),
                              );
                        },
                        activeColor: TierraApp.primary,
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
