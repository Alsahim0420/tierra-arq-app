// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/user_entity.dart' as core;
import '../../../core/entities/obra_entity.dart';
import '../../app/app.dart';
import '../../bloc/obra/obra_bloc.dart';
import '../../bloc/obra/obra_event.dart';
import '../../bloc/obra/obra_state.dart';
import '../../utils/format_utils.dart';
import '../obra/obra_detail_screen.dart';
import '../obra/create_obra_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.user,
    required this.onLogout,
    this.onNavigateToObras,
  });

  final core.UserEntity user;
  final VoidCallback onLogout;
  final VoidCallback? onNavigateToObras;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar obras al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObraBloc>().add(const LoadObras());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ObraBloc>().add(const LoadObras());
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: false,
              pinned: true,
              backgroundColor: TierraApp.getAppBarColor(isDark),
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Dashboard',
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              ),
            ),
            SliverToBoxAdapter(
              child: BlocBuilder<ObraBloc, ObraState>(
                builder: (context, state) {
                  if (state is ObraLoading || state is ObrasActivasLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (state is ObraError) {
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.message,
                              style: textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final obras = state is ObraLoaded
                      ? state.obras
                      : <ObraEntity>[];

                  // Calcular estadísticas
                  final totalObras = obras.length;
                  final obrasActivas = obras
                      .where(
                        (o) =>
                            o.estado != 'finalizado' &&
                            o.estado != 'finalizada',
                      )
                      .length;
                  final obrasFinalizadas = obras
                      .where(
                        (o) =>
                            o.estado == 'finalizado' ||
                            o.estado == 'finalizada',
                      )
                      .length;

                  // Calcular estadísticas de tareas
                  int totalTareas = 0;
                  int tareasPendientes = 0;
                  int tareasEnProgreso = 0;
                  int tareasCompletadas = 0;
                  double costoTotal = 0.0;

                  for (final obra in obras) {
                    costoTotal += obra.costo;
                    totalTareas += obra.tareas.length;
                    for (final tarea in obra.tareas) {
                      final estado = tarea.state.toLowerCase();
                      if (estado == 'pendiente' || estado == 'pending') {
                        tareasPendientes++;
                      } else if (estado == 'en_proceso' ||
                          estado == 'en_progreso' ||
                          estado == 'en progreso') {
                        tareasEnProgreso++;
                      } else if (estado == 'finalizado' ||
                          estado == 'finalizada' ||
                          estado == 'completado' ||
                          estado == 'completada' ||
                          estado == 'completed') {
                        tareasCompletadas++;
                      }
                    }
                  }

                  // Obras recientes (primeras 5)
                  final obrasRecientes = obras.take(5).toList();

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Estadísticas de Obras
                        Text(
                          'Estadísticas de Obras',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.construction,
                                label: 'Total',
                                value: totalObras.toString(),
                                color: TierraApp.primary,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.work_outline,
                                label: 'Activas',
                                value: obrasActivas.toString(),
                                color: Colors.blue,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.check_circle_outline,
                                label: 'Finalizadas',
                                value: obrasFinalizadas.toString(),
                                color: Colors.green,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Estadísticas de Tareas
                        Text(
                          'Estadísticas de Tareas',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.task_alt,
                                label: 'Total',
                                value: totalTareas.toString(),
                                color: TierraApp.primary,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.pending_outlined,
                                label: 'Pendientes',
                                value: tareasPendientes.toString(),
                                color: Colors.orange,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.hourglass_bottom,
                                label: 'En Progreso',
                                value: tareasEnProgreso.toString(),
                                color: Colors.blue,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.check_circle,
                                label: 'Completadas',
                                value: tareasCompletadas.toString(),
                                color: Colors.green,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Costo Total
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: TierraApp.primary.withValues(
                                      alpha: isDark ? 0.2 : 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.attach_money,
                                    color: TierraApp.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Costo Total',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        FormatUtils.formatCurrency(costoTotal),
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: TierraApp.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Obras Recientes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Obras Recientes',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (obrasRecientes.isNotEmpty)
                              TextButton(
                                onPressed: widget.onNavigateToObras,
                                child: const Text('Ver todas'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (obrasRecientes.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.construction_outlined,
                                    size: 48,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No hay obras disponibles',
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CreateObraScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Crear Obra'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: TierraApp.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...obrasRecientes.map(
                            (obra) => _ObraCard(
                              obra: obra,
                              isDark: isDark,
                              textTheme: textTheme,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ObraDetailScreen(obra: obra),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateObraScreen()),
          );
        },
        backgroundColor: TierraApp.primary,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Obra'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObraCard extends StatelessWidget {
  const _ObraCard({
    required this.obra,
    required this.isDark,
    required this.textTheme,
    required this.onTap,
  });

  final ObraEntity obra;
  final bool isDark;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final estadoColor = FormatUtils.getStateColor(obra.estado);
    final estadoText = FormatUtils.formatStateText(obra.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          obra.title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (obra.location.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                obra.location,
                                style: textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: estadoColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      estadoText,
                      style: textTheme.bodySmall?.copyWith(
                        color: estadoColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.list_alt,
                    size: 16,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${obra.tareas.length} tareas',
                    style: textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    FormatUtils.formatCurrency(obra.costo),
                    style: textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
