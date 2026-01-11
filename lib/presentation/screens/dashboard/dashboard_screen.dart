// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/user_entity.dart' as core;
import '../../../core/entities/obra_entity.dart';
import '../../../core/entities/tarea_entity.dart';
import '../../app/app.dart';
import '../../bloc/obra/obra_bloc.dart';
import '../../bloc/obra/obra_event.dart';
import '../../bloc/obra/obra_state.dart';
import '../../utils/format_utils.dart';
import '../obra/obra_detail_screen.dart';
import '../obra/create_obra_screen.dart';
import '../tarea/tarea_detail_modal.dart';

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

                  // Calcular información financiera
                  double presupuestoProyectado = 0.0;
                  double presupuestoEjecutado = 0.0;

                  // Calcular estadísticas de fechas
                  int obrasATiempo = 0;
                  int obrasRetrasadas = 0;
                  int obrasAdelantadas = 0;
                  final fechaActual = DateTime.now();

                  for (final obra in obras) {
                    presupuestoProyectado += obra.costo;
                    // Presupuesto ejecutado: costo de obras finalizadas
                    if (obra.estado == 'finalizado' ||
                        obra.estado == 'finalizada') {
                      presupuestoEjecutado += obra.costo;
                    }

                    // Calcular estado de fechas (solo para obras no finalizadas)
                    if (obra.estado != 'finalizado' &&
                        obra.estado != 'finalizada') {
                      final fechaEntrega = obra.fechaEntrega ?? obra.fechaFin;
                      if (fechaEntrega != null) {
                        final diferencia = fechaEntrega
                            .difference(fechaActual)
                            .inDays;
                        if (diferencia < 0) {
                          // Fecha de entrega ya pasó y no está finalizada = retrasada
                          obrasRetrasadas++;
                        } else if (diferencia <= 7) {
                          // Dentro de 7 días = a tiempo (o cerca del deadline)
                          obrasATiempo++;
                        } else if (diferencia > 7) {
                          // Más de 7 días por delante = adelantada (en buen camino)
                          obrasAdelantadas++;
                        }
                      }
                    }

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
                                onTap: () => _showObrasModal(
                                  context,
                                  obras,
                                  'Total',
                                  null,
                                  isDark,
                                  textTheme,
                                ),
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
                                onTap: () => _showObrasModal(
                                  context,
                                  obras,
                                  'Activas',
                                  'activas',
                                  isDark,
                                  textTheme,
                                ),
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
                                onTap: () => _showObrasModal(
                                  context,
                                  obras,
                                  'Finalizadas',
                                  'finalizadas',
                                  isDark,
                                  textTheme,
                                ),
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
                                onTap: () => _showTareasModal(
                                  context,
                                  obras,
                                  'Total',
                                  null,
                                  isDark,
                                  textTheme,
                                ),
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
                                onTap: () => _showTareasModal(
                                  context,
                                  obras,
                                  'Pendientes',
                                  'pendiente',
                                  isDark,
                                  textTheme,
                                ),
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
                                onTap: () => _showTareasModal(
                                  context,
                                  obras,
                                  'En Progreso',
                                  'en_proceso',
                                  isDark,
                                  textTheme,
                                ),
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
                                onTap: () => _showTareasModal(
                                  context,
                                  obras,
                                  'Completadas',
                                  'finalizado',
                                  isDark,
                                  textTheme,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Información Financiera
                        Text(
                          'Resumen Financiero',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withValues(
                                                alpha: isDark ? 0.2 : 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons
                                                  .account_balance_wallet_outlined,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Presupuesto Proyectado',
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: isDark
                                                        ? Colors.white54
                                                        : Colors.black54,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        FormatUtils.formatCurrency(
                                          presupuestoProyectado,
                                        ),
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(
                                                alpha: isDark ? 0.2 : 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.check_circle_outline,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Presupuesto Ejecutado',
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: isDark
                                                        ? Colors.white54
                                                        : Colors.black54,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        FormatUtils.formatCurrency(
                                          presupuestoEjecutado,
                                        ),
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            (presupuestoProyectado -
                                                            presupuestoEjecutado >=
                                                        0
                                                    ? Colors.orange
                                                    : Colors.red)
                                                .withValues(
                                                  alpha: isDark ? 0.2 : 0.1,
                                                ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        presupuestoProyectado -
                                                    presupuestoEjecutado >=
                                                0
                                            ? Icons.trending_up
                                            : Icons.trending_down,
                                        color:
                                            presupuestoProyectado -
                                                    presupuestoEjecutado >=
                                                0
                                            ? Colors.orange
                                            : Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Varianza Presupuestaria',
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.black54,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            FormatUtils.formatCurrency(
                                              presupuestoProyectado -
                                                  presupuestoEjecutado,
                                            ),
                                            style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  presupuestoProyectado -
                                                          presupuestoEjecutado >=
                                                      0
                                                  ? Colors.orange
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (presupuestoProyectado > 0
                                                    ? ((presupuestoEjecutado /
                                                                      presupuestoProyectado) *
                                                                  100 >=
                                                              100
                                                          ? Colors.red
                                                          : (presupuestoEjecutado /
                                                                        presupuestoProyectado) *
                                                                    100 >=
                                                                80
                                                          ? Colors.orange
                                                          : Colors.green)
                                                    : Colors.grey)
                                                .withValues(
                                                  alpha: isDark ? 0.15 : 0.1,
                                                ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        presupuestoProyectado > 0
                                            ? '${((presupuestoEjecutado / presupuestoProyectado) * 100).toStringAsFixed(1)}%'
                                            : '0%',
                                        style: textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: presupuestoProyectado > 0
                                              ? ((presupuestoEjecutado /
                                                                presupuestoProyectado) *
                                                            100 >=
                                                        100
                                                    ? Colors.red
                                                    : (presupuestoEjecutado /
                                                                  presupuestoProyectado) *
                                                              100 >=
                                                          80
                                                    ? Colors.orange
                                                    : Colors.green)
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Estado de Fechas de Proyectos
                        Text(
                          'Cronograma de Proyectos',
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
                                icon: Icons.schedule,
                                label: 'A Tiempo',
                                value: obrasATiempo.toString(),
                                color: Colors.green,
                                isDark: isDark,
                                onTap: () => _showObrasModal(
                                  context,
                                  obras.where((o) {
                                    if (o.estado == 'finalizado' ||
                                        o.estado == 'finalizada')
                                      return false;
                                    final fechaEntrega =
                                        o.fechaEntrega ?? o.fechaFin;
                                    if (fechaEntrega == null) return false;
                                    final diferencia = fechaEntrega
                                        .difference(DateTime.now())
                                        .inDays;
                                    return diferencia >= 0 && diferencia <= 7;
                                  }).toList(),
                                  'Proyectos a Tiempo',
                                  null,
                                  isDark,
                                  textTheme,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.warning_amber_rounded,
                                label: 'Retrasadas',
                                value: obrasRetrasadas.toString(),
                                color: Colors.red,
                                isDark: isDark,
                                onTap: () => _showObrasModal(
                                  context,
                                  obras.where((o) {
                                    if (o.estado == 'finalizado' ||
                                        o.estado == 'finalizada')
                                      return false;
                                    final fechaEntrega =
                                        o.fechaEntrega ?? o.fechaFin;
                                    if (fechaEntrega == null) return false;
                                    return fechaEntrega
                                            .difference(DateTime.now())
                                            .inDays <
                                        0;
                                  }).toList(),
                                  'Proyectos Retrasados',
                                  null,
                                  isDark,
                                  textTheme,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.trending_up,
                                label: 'Adelantadas',
                                value: obrasAdelantadas.toString(),
                                color: Colors.blue,
                                isDark: isDark,
                                onTap: () => _showObrasModal(
                                  context,
                                  obras.where((o) {
                                    if (o.estado == 'finalizado' ||
                                        o.estado == 'finalizada')
                                      return false;
                                    final fechaEntrega =
                                        o.fechaEntrega ?? o.fechaFin;
                                    if (fechaEntrega == null) return false;
                                    return fechaEntrega
                                            .difference(DateTime.now())
                                            .inDays >
                                        7;
                                  }).toList(),
                                  'Proyectos Adelantados',
                                  null,
                                  isDark,
                                  textTheme,
                                ),
                              ),
                            ),
                          ],
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

  // Función para mostrar modal con lista de tareas
  void _showTareasModal(
    BuildContext context,
    List<ObraEntity> obras,
    String title,
    String? estadoFiltro,
    bool isDark,
    TextTheme textTheme,
  ) {
    // Recopilar todas las tareas de todas las obras
    List<({TareaEntity tarea, String obraId, String obraTitle})> tareasConObra =
        [];

    for (final obra in obras) {
      for (final tarea in obra.tareas) {
        // Filtrar según el estado si se especifica
        if (estadoFiltro == null) {
          // Mostrar todas las tareas
          tareasConObra.add((
            tarea: tarea,
            obraId: obra.id,
            obraTitle: obra.title,
          ));
        } else {
          // Filtrar por estado
          final estadoNormalizado = tarea.state.toLowerCase();
          final filtroNormalizado = estadoFiltro.toLowerCase();

          bool coincide = false;
          if (filtroNormalizado == 'pendiente' ||
              filtroNormalizado == 'pending') {
            coincide =
                estadoNormalizado == 'pendiente' ||
                estadoNormalizado == 'pending';
          } else if (filtroNormalizado == 'en_proceso' ||
              filtroNormalizado == 'en progreso' ||
              filtroNormalizado == 'en_progreso') {
            coincide =
                estadoNormalizado == 'en_proceso' ||
                estadoNormalizado == 'en progreso' ||
                estadoNormalizado == 'en_progreso';
          } else if (filtroNormalizado == 'finalizado' ||
              filtroNormalizado == 'completado' ||
              filtroNormalizado == 'completada' ||
              filtroNormalizado == 'completed') {
            coincide =
                estadoNormalizado == 'finalizado' ||
                estadoNormalizado == 'finalizada' ||
                estadoNormalizado == 'completado' ||
                estadoNormalizado == 'completada' ||
                estadoNormalizado == 'completed';
          }

          if (coincide) {
            tareasConObra.add((
              tarea: tarea,
              obraId: obra.id,
              obraTitle: obra.title,
            ));
          }
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? TierraApp.card : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Lista de tareas
            Expanded(
              child: tareasConObra.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_outlined,
                            size: 64,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay tareas',
                            style: textTheme.titleMedium?.copyWith(
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tareasConObra.length,
                      itemBuilder: (context, index) {
                        final item = tareasConObra[index];
                        final tarea = item.tarea;
                        final estadoColor = FormatUtils.getStateColor(
                          tarea.state,
                        );
                        final estadoText = FormatUtils.formatStateText(
                          tarea.state,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (modalContext) => TareaDetailModal(
                                  tarea: tarea,
                                  obraId: item.obraId,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tarea.name,
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black87,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Obra: ${item.obraTitle}',
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: isDark
                                                        ? Colors.white54
                                                        : Colors.black54,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: estadoColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: estadoColor.withValues(
                                              alpha: 0.3,
                                            ),
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
                                  if (tarea.description.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      tarea.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      if (tarea.duration > 0) ...[
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${tarea.duration} días',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                      ],
                                      if (tarea.evidences.isNotEmpty) ...[
                                        Icon(
                                          Icons.image,
                                          size: 16,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${tarea.evidences.length} evidencia${tarea.evidences.length > 1 ? 's' : ''}',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Función para mostrar modal con lista de obras
  void _showObrasModal(
    BuildContext context,
    List<ObraEntity> obras,
    String title,
    String? tipoFiltro,
    bool isDark,
    TextTheme textTheme,
  ) {
    // Filtrar obras según el tipo
    List<ObraEntity> obrasFiltradas = [];

    if (tipoFiltro == null) {
      // Mostrar todas las obras
      obrasFiltradas = obras;
    } else if (tipoFiltro == 'activas') {
      // Filtrar obras activas (no finalizadas)
      obrasFiltradas = obras
          .where((o) => o.estado != 'finalizado' && o.estado != 'finalizada')
          .toList();
    } else if (tipoFiltro == 'finalizadas') {
      // Filtrar obras finalizadas
      obrasFiltradas = obras
          .where((o) => o.estado == 'finalizado' || o.estado == 'finalizada')
          .toList();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? TierraApp.card : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Lista de obras
            Expanded(
              child: obrasFiltradas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.construction_outlined,
                            size: 64,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay obras',
                            style: textTheme.titleMedium?.copyWith(
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: obrasFiltradas.length,
                      itemBuilder: (context, index) {
                        final obra = obrasFiltradas[index];
                        return _ObraCard(
                          obra: obra,
                          isDark: isDark,
                          textTheme: textTheme,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ObraDetailScreen(obra: obra),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
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
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
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
