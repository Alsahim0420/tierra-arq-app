import 'package:flutter/material.dart';
import '../../../core/entities/obra_entity.dart';
import '../../../core/entities/tarea_entity.dart';
import '../../utils/format_utils.dart';
import '../tarea/tarea_detail_modal.dart';
import '../../widgets/evidences_gallery.dart';

class ObraDetailScreen extends StatelessWidget {
  const ObraDetailScreen({super.key, required this.obra});

  final ObraEntity obra;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          obra.title,
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
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
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (obra.description.isNotEmpty) ...[
                      Text(
                        'Descripción',
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(obra.description, style: textTheme.bodyMedium),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 20,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${obra.city}, ${obra.location}',
                            style: textTheme.bodyMedium,
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
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Costo: ${FormatUtils.formatCurrency(obra.costo)}',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    if (obra.responsable.name.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.person, size: 20, color: Colors.white70),
                          const SizedBox(width: 8),
                          Text(
                            'Responsable: ${obra.responsable.fullName}',
                            style: textTheme.bodyMedium,
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
                  'Tareas (${obra.tareas.length})',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (obra.tareas.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 48,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay tareas asignadas',
                          style: textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...obra.tareas.map(
                (tarea) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _showTareaDetailModal(context, tarea, obra.id),
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
                                color: Colors.white70,
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
                          if (tarea.assignedTo != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: Colors.white54,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Asignado a: ${tarea.assignedTo!.fullName}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.white54,
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
  }

  void _showTareaDetailModal(
    BuildContext context,
    TareaEntity tarea,
    String obraId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: true,
      builder: (context) => TareaDetailModal(tarea: tarea, obraId: obraId),
    );
  }
}
