// ignore_for_file: deprecated_member_use

// COMENTADO: Pantalla de listado de tareas independientes (sin obraId)
// Esta funcionalidad ha sido deshabilitada - las tareas deben estar asociadas a una obra

/*
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/tarea_entity.dart';
import '../../bloc/tarea/tarea_bloc.dart';
import '../../bloc/tarea/tarea_event.dart';
import '../../bloc/tarea/tarea_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../utils/format_utils.dart';
import '../../utils/user_role_utils.dart';
import '../../widgets/evidences_gallery.dart';
import '../../../core/theme/app_colors.dart';
import 'tarea_detail_modal.dart';
import 'create_tarea_modal.dart';

class TareasListScreen extends StatefulWidget {
  const TareasListScreen({super.key});

  @override
  State<TareasListScreen> createState() => _TareasListScreenState();
}

class _TareasListScreenState extends State<TareasListScreen> {
  int _currentPage = 1;
  final int _limit = 10;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    // Cargar tareas al iniciar
    context.read<TareaBloc>().add(LoadTareas(page: _currentPage, limit: _limit));
  }

  void _loadMore() {
    if (_hasMore) {
      setState(() {
        _currentPage++;
      });
      context.read<TareaBloc>().add(LoadTareas(page: _currentPage, limit: _limit));
    }
  }

  void _refresh() {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
    });
    context.read<TareaBloc>().add(LoadTareas(page: 1, limit: _limit));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Todas las Tareas',
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
      ),
      floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticated &&
              UserRoleUtils.isAdmin(authState.user)) {
            return FloatingActionButton.extended(
              heroTag: 'fab_nueva_tarea',
              onPressed: () {
                _showCreateTareaModal(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Nueva Tarea'),
              backgroundColor: AppColors.primary,
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: BlocBuilder<TareaBloc, TareaState>(
        builder: (context, state) {
          if (state is TareaLoading && _currentPage == 1) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TareaError) {
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
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is TareaLoaded) {
            final tareas = state.tareas;

            // Actualizar _hasMore basado en la cantidad de tareas recibidas
            if (tareas.length < _limit) {
              _hasMore = false;
            }

            if (tareas.isEmpty && _currentPage == 1) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: Colors.white30,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay tareas registradas',
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
                _refresh();
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tareas.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == tareas.length) {
                    // Botón para cargar más
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: FilledButton.icon(
                          onPressed: _loadMore,
                          icon: const Icon(Icons.expand_more),
                          label: const Text('Cargar más'),
                        ),
                      ),
                    );
                  }

                  final tarea = tareas[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _showTareaDetail(context, tarea),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    tarea.name,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                // Botón de editar (solo admin)
                                BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, authState) {
                                    if (authState is AuthAuthenticated &&
                                        UserRoleUtils.isAdmin(authState.user)) {
                                      return IconButton(
                                        icon: const Icon(Icons.edit),
                                        color: AppColors.primary,
                                        onPressed: () {
                                          _showEditTareaModal(context, tarea);
                                        },
                                        tooltip: 'Editar tarea',
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                            if (tarea.description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                tarea.description,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (tarea.duration > 0) ...[
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.white54,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${tarea.duration} días',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.white54,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                if (tarea.evidences.isNotEmpty) ...[
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EvidencesGallery(
                                            evidences: tarea.evidences,
                                            title: tarea.name,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.image,
                                          size: 16,
                                          color: Colors.white54,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${tarea.evidences.length} evidencia${tarea.evidences.length > 1 ? 's' : ''}',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: Colors.white54,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                          color: Colors.white54,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            // Mostrar observación si la tarea está finalizada
                            if (FormatUtils.formatStateText(tarea.state) == 'finalizado' &&
                                tarea.observation != null &&
                                tarea.observation!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.note,
                                      size: 18,
                                      color: Colors.green.withValues(alpha: 0.8),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Observación',
                                            style: textTheme.labelSmall?.copyWith(
                                              color: Colors.green.withValues(alpha: 0.9),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            tarea.observation!,
                                            style: textTheme.bodySmall?.copyWith(
                                              color: Colors.white70,
                                              height: 1.4,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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

  void _showTareaDetail(BuildContext context, TareaEntity tarea) async {
    // Guardar referencias antes de async - usar Navigator para contexto estable
    if (!mounted) return;
    
    // Guardar el Navigator antes del await para tener un contexto estable
    final navigator = Navigator.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    final tareaBloc = context.read<TareaBloc>();
    final tareaId = tarea.id; // Guardar el ID de la tarea seleccionada
    
    // Mostrar diálogo de carga primero
    showDialog(
      context: navigator.context,
      barrierDismissible: false,
      builder: (loadingContext) => WillPopScope(
        onWillPop: () async => false, // Prevenir cerrar durante la carga
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B1B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cargando tarea...',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    // Siempre cargar la tarea por ID para obtener los datos más actualizados
    tareaBloc.add(LoadTareaById(tareaId));
    
    // Esperar a que se cargue la tarea
    TareaEntity? loadedTarea;
    try {
      // Esperar un momento para que el BLoC procese el evento
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Intentar obtener el estado del stream con timeout
      try {
        await tareaBloc.stream
            .where((state) => state is! TareaLoading)
            .skip(1) // Skip el estado inicial de loading
            .timeout(const Duration(seconds: 3))
            .first
            .then((state) {
          if (state is TareaLoaded) {
            // Verificar que la tarea cargada sea la correcta
            if (state.selectedTarea != null && state.selectedTarea!.id == tareaId) {
              loadedTarea = state.selectedTarea;
            } else if (state.tareas.isNotEmpty) {
              // Si no hay selectedTarea, buscar en la lista
              final found = state.tareas.firstWhere(
                (t) => t.id == tareaId,
                orElse: () => tarea, // Fallback a la tarea original
              );
              loadedTarea = found;
            } else {
              loadedTarea = tarea; // Fallback a la tarea original
            }
          } else {
            loadedTarea = tarea; // Fallback a la tarea original
          }
        });
      } catch (e) {
        // Si hay timeout, verificar el estado actual del BLoC
        final currentState = tareaBloc.state;
        if (currentState is TareaLoaded) {
          if (currentState.selectedTarea != null && currentState.selectedTarea!.id == tareaId) {
            loadedTarea = currentState.selectedTarea;
          } else if (currentState.tareas.isNotEmpty) {
            final found = currentState.tareas.firstWhere(
              (t) => t.id == tareaId,
              orElse: () => tarea,
            );
            loadedTarea = found;
          } else {
            loadedTarea = tarea;
          }
        } else {
          loadedTarea = tarea;
        }
      }
    } catch (e) {
      loadedTarea = tarea; // Fallback a la tarea original
    }

    // Cerrar el diálogo de carga
    if (mounted) {
      Navigator.of(navigator.context).pop(); // Cerrar diálogo de carga
    }

    // Verificar que el widget sigue montado antes de mostrar el diálogo
    if (!mounted || loadedTarea == null) return;
    
    // Guardar referencia a la tarea final para evitar problemas de null
    final finalTarea = loadedTarea!;
    
    // Mostrar diálogo con los datos usando el contexto del Navigator guardado
    showDialog(
      context: navigator.context,
      builder: (dialogContext) => AlertDialog(
        title: Text(finalTarea.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (finalTarea.description.isNotEmpty) ...[
                Text(
                  'Descripción',
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(finalTarea.description),
                const SizedBox(height: 16),
              ],
              // Estado comentado según solicitud del usuario
              // Row(
              //   children: [
              //     Text(
              //       'Estado: ',
              //       style: textTheme.titleSmall,
              //     ),
              //     Container(
              //       padding: const EdgeInsets.symmetric(
              //         horizontal: 8,
              //         vertical: 4,
              //       ),
              //       decoration: BoxDecoration(
              //         color: FormatUtils.getStateColor(finalTarea.state)
              //             .withValues(alpha: 0.2),
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //       child: Text(
              //         FormatUtils.formatStateText(finalTarea.state),
              //         style: TextStyle(
              //           color: FormatUtils.getStateColor(finalTarea.state),
              //           fontWeight: FontWeight.w600,
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              if (finalTarea.duration > 0) ...[
                const SizedBox(height: 8),
                Text('Duración: ${finalTarea.duration} días'),
              ],
              if (finalTarea.evidences.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Evidencias: ${finalTarea.evidences.length}'),
              ],
              // Observación comentada según solicitud del usuario
              // if (finalTarea.observation != null && finalTarea.observation!.isNotEmpty) ...[
              //   const SizedBox(height: 16),
              //   Container(
              //     padding: const EdgeInsets.all(12),
              //     decoration: BoxDecoration(
              //       color: Colors.green.withValues(alpha: 0.1),
              //       borderRadius: BorderRadius.circular(8),
              //       border: Border.all(
              //         color: Colors.green.withValues(alpha: 0.3),
              //       ),
              //     ),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Text(
              //           'Observación',
              //           style: textTheme.labelSmall?.copyWith(
              //             color: Colors.green.withValues(alpha: 0.9),
              //             fontWeight: FontWeight.w600,
              //           ),
              //         ),
              //         const SizedBox(height: 4),
              //         Text(
              //           finalTarea.observation!,
              //           style: textTheme.bodySmall?.copyWith(
              //             color: Colors.white70,
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Recargar las tareas después de cerrar el diálogo para restaurar la lista
              if (mounted) {
                _refresh();
              }
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // COMENTADO: Método para editar tareas independientes - funcionalidad deshabilitada
  /*
  void _showEditTareaModal(BuildContext context, TareaEntity tarea) {
    // Esta pantalla es solo para admin, así que siempre es admin
    final authState = context.read<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated &&
        UserRoleUtils.isAdmin(authState.user);
    final isMaster = authState is AuthAuthenticated &&
        UserRoleUtils.isMaster(authState.user);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => TareaDetailModal(
        tarea: tarea,
        obraId: null, // Sin obraId para tareas sueltas
        isAdmin: isAdmin,
        isMaster: isMaster,
      ),
    );
  }
  */

  // COMENTADO: Método para crear tareas independientes - funcionalidad deshabilitada
  /*
  void _showCreateTareaModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => const CreateTareaModal(
        obraId: null, // Sin obraId para tareas sueltas
      ),
    ).then((created) {
      // Refrescar la lista después de crear
      if (created == true && mounted) {
        _refresh();
      }
    });
  }
  */
}
*/
