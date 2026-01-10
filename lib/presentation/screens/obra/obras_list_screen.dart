import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/user_entity.dart' as core;
import '../../bloc/obra/obra_bloc.dart';
import '../../bloc/obra/obra_event.dart';
import '../../bloc/obra/obra_state.dart';
import '../../app/app.dart';
import '../profile/profile_screen.dart';
import 'obra_detail_screen.dart';

class ObrasListScreen extends StatelessWidget {
  const ObrasListScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  final core.UserEntity user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis Obras',
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(user: user, onLogout: onLogout),
                ),
              );
            },
            tooltip: 'Perfil',
          ),
        ],
      ),
      body: BlocBuilder<ObraBloc, ObraState>(
        builder: (context, state) {
          if (state is ObraLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ObraError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      context.read<ObraBloc>().add(const LoadObras());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is ObraLoaded) {
            if (state.obras.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.construction_outlined,
                      size: 64,
                      color: Colors.white30,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tienes obras asignadas',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ObraBloc>().add(const LoadObras());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.obras.length,
                itemBuilder: (context, index) {
                  final obra = state.obras[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: TierraApp.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.construction,
                          color: TierraApp.primary,
                        ),
                      ),
                      title: Text(
                        obra.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          if (obra.description.isNotEmpty)
                            Text(
                              obra.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.white54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${obra.city}, ${obra.location}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          if (obra.tareas.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.assignment,
                                  size: 16,
                                  color: Colors.white54,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${obra.tareas.length} tarea${obra.tareas.length > 1 ? 's' : ''}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Colors.white54,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ObraDetailScreen(obra: obra),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

