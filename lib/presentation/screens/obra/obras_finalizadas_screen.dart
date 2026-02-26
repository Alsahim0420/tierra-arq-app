import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/user_entity.dart' as core;
import '../../bloc/obra/obra_bloc.dart';
import '../../bloc/obra/obra_event.dart';
import '../../bloc/obra/obra_state.dart';
import '../../../core/theme/app_colors.dart';
import 'obra_detail_screen.dart';

class ObrasFinalizadasScreen extends StatefulWidget {
  const ObrasFinalizadasScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  final core.UserEntity user;
  final VoidCallback onLogout;

  @override
  State<ObrasFinalizadasScreen> createState() => _ObrasFinalizadasScreenState();
}

class _ObrasFinalizadasScreenState extends State<ObrasFinalizadasScreen> {
  bool _hasLoaded = false;
  ObraState?
  _lastValidState; // Mantener el último estado válido de obras finalizadas

  @override
  void initState() {
    super.initState();
  }

  void _loadObrasFinalizadas() {
    if (!_hasLoaded && mounted) {
      _hasLoaded = true;
      context.read<ObraBloc>().add(const LoadObrasFinalizadas());
    }
  }

  // Función helper para obtener el color según el estado
  static Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'en_proceso':
      case 'en progreso':
        return Colors.blue;
      case 'finalizado':
        return Colors.green;
      case 'estancado':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  // Función helper para obtener el nombre a mostrar según el estado
  static String _getEstadoDisplayName(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_proceso':
      case 'en progreso':
        return 'En Proceso';
      case 'finalizado':
        return 'Finalizado';
      case 'estancado':
        return 'Estancado';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Obras Finalizadas',
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: AppColors.appBarColor(isDark),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocConsumer<ObraBloc, ObraState>(
        listener: (context, state) {
          // Guardar el estado válido de obras finalizadas
          if (state is ObrasFinalizadasLoaded) {
            _hasLoaded = true;
            _lastValidState = state;
          }
        },
        builder: (context, state) {
          // Determinar qué estado renderizar
          ObraState stateToRender = state;

          // Si el estado es de obras activas u otro tipo, usar el último estado válido de finalizadas
          if (state is ObrasActivasLoading ||
              state is ObraLoaded ||
              state is ObraInitial) {
            // Si tenemos un estado válido previo, usarlo
            if (_lastValidState is ObrasFinalizadasLoaded) {
              stateToRender = _lastValidState!;
            } else {
              // Si no hay estado previo, cargar obras finalizadas
              if (!_hasLoaded) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_hasLoaded) {
                    _loadObrasFinalizadas();
                  }
                });
              }
              return const Center(child: CircularProgressIndicator());
            }
          }

          // Cargar obras finalizadas cuando la pantalla se construye por primera vez
          if (!_hasLoaded &&
              stateToRender is! ObrasFinalizadasLoaded &&
              stateToRender is! ObrasFinalizadasLoading &&
              stateToRender is! ObraError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_hasLoaded) {
                _loadObrasFinalizadas();
              }
            });
            return const Center(child: CircularProgressIndicator());
          }

          // Mostrar loading solo para obras finalizadas
          if (stateToRender is ObrasFinalizadasLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (stateToRender is ObraLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (stateToRender is ObraError) {
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
                    stateToRender.message,
                    style: textTheme.bodyLarge?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      _hasLoaded = false;
                      context.read<ObraBloc>().add(
                        const LoadObrasFinalizadas(),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (stateToRender is ObrasFinalizadasLoaded) {
            final obrasFinalizadas = stateToRender;
            if (obrasFinalizadas.obras.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay obras finalizadas',
                      style: textTheme.titleMedium?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _hasLoaded = false;
                context.read<ObraBloc>().add(const LoadObrasFinalizadas());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: obrasFinalizadas.obras.length,
                itemBuilder: (context, index) {
                  final obra = obrasFinalizadas.obras[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ObraDetailScreen(obra: obra),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Leading: Icono y Estado
                            SizedBox(
                              width: 80,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 70,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getEstadoColor(
                                        obra.estado,
                                      ).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _getEstadoColor(
                                          obra.estado,
                                        ).withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _getEstadoDisplayName(obra.estado),
                                        style: textTheme.bodySmall?.copyWith(
                                          color: _getEstadoColor(obra.estado),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,
                                          height: 1.0,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Contenido principal
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    obra.title,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (obra.description.isNotEmpty)
                                    Text(
                                      obra.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${obra.city}, ${obra.location}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
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
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${obra.tareas.length} tarea${obra.tareas.length > 1 ? 's' : ''}',
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
                            const SizedBox(width: 8),
                            // Trailing: Chevron
                            Icon(
                              Icons.chevron_right,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }

          // Estado inicial: mostrar loading mientras se carga
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
