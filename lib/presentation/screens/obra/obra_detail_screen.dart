import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/obra_entity.dart';
import '../../../core/entities/tarea_entity.dart';
import '../../../core/entities/user_entity.dart' as core;
import '../../utils/format_utils.dart';
import '../tarea/tarea_detail_screen.dart';
import '../../widgets/evidences_gallery.dart';
import '../../bloc/obra/obra_bloc.dart';
import '../../bloc/obra/obra_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';

class ObraDetailScreen extends StatelessWidget {
  const ObraDetailScreen({super.key, required this.obra});

  final ObraEntity obra;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ObraBloc, ObraState>(
      builder: (context, state) {
        // Obtener la obra actualizada del BLoC si existe, o usar la recibida como parámetro
        final ObraEntity currentObra;
        if (state is ObraLoaded) {
          // Buscar la obra actualizada en la lista del BLoC
          final updatedObra = state.obras.firstWhere(
            (o) => o.id == obra.id,
            orElse: () => obra,
          );
          currentObra = updatedObra;
        } else {
          // Si el BLoC no tiene datos cargados, usar la obra recibida como parámetro
          currentObra = obra;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              currentObra.title,
              style: textTheme.headlineSmall?.copyWith(
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.4,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información de la obra',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (currentObra.description.isNotEmpty) ...[
                          Text(
                            'Descripción',
                            style: textTheme.labelLarge?.copyWith(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentObra.description,
                            style: textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 20,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${currentObra.city}, ${currentObra.location}',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 20,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Costo: ${FormatUtils.formatCurrency(currentObra.costo)}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        if (currentObra.responsable.name.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 20,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Responsable: ${currentObra.responsable.fullName}',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'Tareas (${currentObra.tareas.length})',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (currentObra.tareas.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 48,
                              color: isDark ? Colors.white54 : Colors.black26,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay tareas asignadas',
                              style: textTheme.bodyLarge?.copyWith(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...currentObra.tareas.map(
                    (tarea) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _showTareaDetailModal(
                          context,
                          tarea,
                          currentObra.id,
                        ),
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
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: FormatUtils.getStateColor(
                                        tarea.state,
                                      ).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: FormatUtils.getStateColor(
                                          tarea.state,
                                        ).withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Text(
                                      FormatUtils.formatStateText(tarea.state),
                                      style: textTheme.labelSmall?.copyWith(
                                        color: FormatUtils.getStateColor(
                                          tarea.state,
                                        ),
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
                                  style: textTheme.bodyMedium?.copyWith(
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
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${tarea.evidences.length} evidencia${tarea.evidences.length > 1 ? 's' : ''}',
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.black54,
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              // Mostrar observación si la tarea está finalizada y tiene observación
                              if (FormatUtils.formatStateText(tarea.state) ==
                                      'finalizado' &&
                                  tarea.observation != null &&
                                  tarea.observation!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.note,
                                        size: 18,
                                        color: Colors.green.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Observación',
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: Colors.green
                                                        .withValues(alpha: 0.9),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              tarea.observation!,
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: isDark
                                                        ? Colors.white70
                                                        : Colors.black87,
                                                    height: 1.4,
                                                  ),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (tarea.assignedTo != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 16,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Asignado a: ${tarea.assignedTo!.fullName}',
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
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTareaDetailModal(
    BuildContext context,
    TareaEntity tarea,
    String obraId,
  ) {
    // Obtener el usuario desde el AuthBloc si está disponible
    core.UserEntity? user;
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        user = authState.user;
      }
    } catch (e) {
      // Si no hay AuthBloc disponible, user será null
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TareaDetailScreen(tarea: tarea, obraId: obraId, user: user),
      ),
    );
  }
}
