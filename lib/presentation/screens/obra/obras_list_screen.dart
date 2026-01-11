import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/user_entity.dart' as core;
import '../../bloc/obra/obra_bloc.dart';
import '../../bloc/obra/obra_event.dart';
import '../../bloc/obra/obra_state.dart';
import '../../bloc/tarea/tarea_bloc.dart';
import '../../app/app.dart';
import '../../utils/user_role_utils.dart';
// COMENTADO: Imports de navegación movidos al BottomNavigationBar
// import '../profile/profile_screen.dart';
// import '../user/users_list_screen.dart';
import 'obra_detail_screen.dart';
import 'create_obra_screen.dart';

class ObrasListScreen extends StatefulWidget {
  const ObrasListScreen({
    super.key,
    required this.user,
    required this.onLogout,
    this.showFAB = false,
  });

  final core.UserEntity user;
  final VoidCallback onLogout;
  final bool showFAB; // Control para mostrar el FAB "Nueva Obra"

  @override
  State<ObrasListScreen> createState() => _ObrasListScreenState();
}

class _ObrasListScreenState extends State<ObrasListScreen> {
  bool _hasLoaded = false;
  ObraState?
  _lastValidState; // Mantener el último estado válido de obras activas

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Solo cargar si realmente necesitamos datos
    final currentState = context.read<ObraBloc>().state;

    // Si el estado actual es ObraLoaded, guardarlo como válido
    if (currentState is ObraLoaded) {
      _hasLoaded = true;
      _lastValidState = currentState;
    } else if (currentState is ObraInitial && !_hasLoaded) {
      // Solo cargar si es el estado inicial y no hemos cargado aún
      _loadObrasActivas();
    }
  }

  void _loadObrasActivas() {
    if (!_hasLoaded && mounted) {
      // NO marcar _hasLoaded aquí - solo se marca cuando se recibe ObraLoaded exitosamente
      context.read<ObraBloc>().add(const LoadObras());
    }
  }

  // Función helper para obtener el color según el estado
  static Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'en_proceso':
        return Colors.blue;
      case 'finalizado':
        return Colors.green;
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
        return 'En Proceso';
      case 'finalizado':
        return 'Finalizado';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isMaster = UserRoleUtils.isMaster(widget.user);

    final roleDisplayName = UserRoleUtils.getRoleDisplayName(widget.user);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Mis Obras',
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),

        backgroundColor: isDark ? const Color(0xFF1B1B1B) : TierraApp.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Badge del rol a la derecha (más grande, al menos el doble)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: TierraApp.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: TierraApp.primary.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMaster
                          ? Icons.construction
                          : Icons.admin_panel_settings,
                      size: 20,
                      color: TierraApp.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      roleDisplayName,
                      style: textTheme.bodyMedium?.copyWith(
                        color: TierraApp.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<ObraBloc, ObraState>(
        listener: (context, state) {
          // Guardar el estado válido de obras activas
          if (state is ObraLoaded) {
            _hasLoaded = true;
            _lastValidState = state;
          }
        },
        builder: (context, state) {
          // Determinar qué estado renderizar
          ObraState stateToRender = state;

          // Si el estado es de obras finalizadas u otros tipos, usar el último estado válido de activas
          if (state is ObrasFinalizadasLoaded ||
              state is ObrasFinalizadasLoading) {
            // Si tenemos un estado válido previo, usarlo
            if (_lastValidState is ObraLoaded) {
              stateToRender = _lastValidState!;
            } else {
              // Si no hay estado previo, cargar obras activas
              if (!_hasLoaded) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_hasLoaded) {
                    _loadObrasActivas();
                  }
                });
              }
              return const Center(child: CircularProgressIndicator());
            }
          }

          // Cargar obras activas cuando la pantalla se construye por primera vez
          if (!_hasLoaded &&
              stateToRender is! ObraLoaded &&
              stateToRender is! ObrasActivasLoading &&
              stateToRender is! ObraError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_hasLoaded) {
                _loadObrasActivas();
              }
            });
            return const Center(child: CircularProgressIndicator());
          }

          // Mostrar loading solo para obras activas
          if (stateToRender is ObrasActivasLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (stateToRender is ObraLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (stateToRender is ObraError) {
            final errorState = stateToRender; // Cast para acceso directo
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
                    errorState.message,
                    style: textTheme.bodyLarge?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      _hasLoaded = false;
                      context.read<ObraBloc>().add(const LoadObras());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (stateToRender is ObraLoaded) {
            final obrasLoaded = stateToRender; // Cast para acceso directo
            if (obrasLoaded.obras.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.construction_outlined,
                      size: 64,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isMaster
                          ? 'No hay obras registradas'
                          : 'No tienes obras asignadas',
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
                context.read<ObraBloc>().add(const LoadObras());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: obrasLoaded.obras.length,
                itemBuilder: (context, index) {
                  final obra = obrasLoaded.obras[index];
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
                                      color: TierraApp.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.construction,
                                      color: TierraApp.primary,
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

          // Estado inicial o desconocido: mostrar loading
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton:
          (widget.showFAB && UserRoleUtils.isAdmin(widget.user))
          ? FloatingActionButton.extended(
              heroTag:
                  'fab_nueva_obra', // Tag único para evitar conflictos de Hero
              onPressed: () async {
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<ObraBloc>()),
                        BlocProvider.value(value: context.read<TareaBloc>()),
                      ],
                      child: const CreateObraScreen(),
                    ),
                  ),
                );
                // La obra ya se refrescó en la pantalla
              },
              icon: const Icon(Icons.add),
              label: const Text('Nueva Obra'),
              backgroundColor: TierraApp.primary,
            )
          : null,
    );
  }
}
