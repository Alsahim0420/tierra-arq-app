import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/tarea_entity.dart';
import '../../bloc/tarea/tarea_bloc.dart';
import '../../bloc/tarea/tarea_event.dart';
import '../../bloc/obra/obra_bloc.dart';
import '../../bloc/obra/obra_event.dart';
import '../../app/app.dart';
import '../../utils/format_utils.dart';
import '../../widgets/tarea_info_row.dart';
import '../../widgets/evidences_gallery.dart';

class TareaDetailModal extends StatefulWidget {
  const TareaDetailModal({
    super.key,
    required this.tarea,
    required this.obraId,
  });

  final TareaEntity tarea;
  final String obraId;

  @override
  State<TareaDetailModal> createState() => _TareaDetailModalState();
}

class _TareaDetailModalState extends State<TareaDetailModal> {
  late String _selectedState;
  final List<String> _estados = ['pendiente', 'en progreso', 'completada'];

  String _normalizeState(String state) {
    // Normalizar diferentes formatos de estado a nuestro formato estándar
    final normalized = state.toLowerCase().trim();
    if (normalized == 'en_proceso' || normalized == 'en_progreso') {
      return 'en progreso';
    }
    if (normalized == 'pendiente' || normalized == 'pending') {
      return 'pendiente';
    }
    if (normalized == 'completada' ||
        normalized == 'completado' ||
        normalized == 'completed') {
      return 'completada';
    }
    // Si no coincide, devolver el valor normalizado tal cual
    return normalized;
  }

  @override
  void initState() {
    super.initState();
    _selectedState = _normalizeState(widget.tarea.state);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tarea = widget.tarea;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF1B1B1B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            top: 12,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tarea.name,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Estado',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2B2B2B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedState,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  dropdownColor: const Color(0xFF2B2B2B),
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white70,
                  ),
                  selectedItemBuilder: (BuildContext context) {
                    return _estados.map((estado) {
                      final stateColor = FormatUtils.getStateColor(estado);
                      return Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: stateColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            estado,
                            style: textTheme.bodyLarge?.copyWith(
                              color: stateColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                  items: _estados.map((estado) {
                    final stateColor = FormatUtils.getStateColor(estado);
                    return DropdownMenuItem<String>(
                      value: estado,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: stateColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            estado,
                            style: textTheme.bodyLarge?.copyWith(
                              color: stateColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedState = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 32),
              if (tarea.description.isNotEmpty) ...[
                Text(
                  'Descripción',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B2B2B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    tarea.description,
                    style: textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
                const SizedBox(height: 32),
              ],
              Text(
                'Información',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: const Color(0xFF2B2B2B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (tarea.duration > 0) ...[
                        TareaInfoRow(
                          icon: Icons.access_time,
                          label: 'Duración',
                          value: '${tarea.duration} días',
                        ),
                        if (tarea.evidences.isNotEmpty ||
                            tarea.assignedTo != null)
                          const SizedBox(height: 16),
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
                            children: [
                              Expanded(
                                child: TareaInfoRow(
                                  icon: Icons.image,
                                  label: 'Evidencias',
                                  value: '${tarea.evidences.length}',
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.white54,
                              ),
                            ],
                          ),
                        ),
                        if (tarea.assignedTo != null)
                          const SizedBox(height: 16),
                      ],
                      if (tarea.assignedTo != null)
                        TareaInfoRow(
                          icon: Icons.person,
                          label: 'Asignado a',
                          value: tarea.assignedTo!.fullName,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedState != widget.tarea.state
                      ? () => _saveState(context)
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _selectedState != widget.tarea.state
                        ? TierraApp.primary
                        : Colors.white.withValues(alpha: 0.1),
                    foregroundColor: _selectedState != widget.tarea.state
                        ? Colors.black
                        : Colors.white54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Guardar cambios',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveState(BuildContext context) {
    if (_selectedState == widget.tarea.state) return;

    final updatedTarea = TareaEntity(
      id: widget.tarea.id,
      name: widget.tarea.name,
      description: widget.tarea.description,
      evidences: widget.tarea.evidences,
      state: _selectedState,
      duration: widget.tarea.duration,
      assignedTo: widget.tarea.assignedTo,
    );

    context.read<TareaBloc>().add(UpdateTarea(updatedTarea, widget.obraId));

    Navigator.pop(context);
    context.read<ObraBloc>().add(const LoadObras());
  }
}
