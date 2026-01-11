// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/entities/tarea_entity.dart';
import '../../../core/entities/user_entity.dart' as core;
import '../../../core/services/cloudinary_service.dart';
import '../../bloc/tarea/tarea_bloc.dart';
import '../../bloc/tarea/tarea_event.dart';
import '../../bloc/tarea/tarea_state.dart';
import '../../bloc/obra/obra_bloc.dart';
import '../../bloc/obra/obra_event.dart';
import '../../bloc/obra/obra_state.dart';
import '../../app/app.dart';
import '../../utils/format_utils.dart';
import '../../utils/user_role_utils.dart';
import '../../widgets/tarea_info_row.dart';
import '../../widgets/evidences_gallery.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/injection/injection_container.dart' as di;
import 'observation_modal.dart';

class TareaDetailScreen extends StatefulWidget {
  const TareaDetailScreen({
    super.key,
    required this.tarea,
    required this.obraId,
    this.user,
  });

  final TareaEntity tarea;
  final String obraId;
  final core.UserEntity? user;

  @override
  State<TareaDetailScreen> createState() => _TareaDetailScreenState();
}

class _TareaDetailScreenState extends State<TareaDetailScreen> {
  late String _selectedState;
  final List<String> _estados = ['pendiente', 'en progreso', 'finalizado'];
  final ImagePicker _imagePicker = ImagePicker();
  CloudinaryService get _cloudinaryService => di.getIt<CloudinaryService>();
  List<String> _pendingEvidences = [];
  bool _isUploading = false;
  bool _userModifiedState = false;
  String? _lastKnownTareaState;
  bool _isUserSelecting = false;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;

  bool get isAdmin {
    if (widget.user != null) {
      return UserRoleUtils.isAdmin(widget.user!);
    }
    return false;
  }

  bool get isMaster {
    if (widget.user != null) {
      return UserRoleUtils.isMaster(widget.user!);
    }
    return false;
  }

  String _normalizeState(String state) {
    final normalized = state.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final cleanNormalized = normalized.replaceAll(' ', '');

    if (cleanNormalized == 'en_proceso' ||
        cleanNormalized == 'en_progreso' ||
        normalized == 'en progreso') {
      return 'en progreso';
    }
    if (cleanNormalized == 'pendiente' ||
        cleanNormalized == 'pending' ||
        normalized == 'pendiente') {
      return 'pendiente';
    }
    if (cleanNormalized == 'finalizado' ||
        cleanNormalized == 'finalizada' ||
        cleanNormalized == 'completada' ||
        cleanNormalized == 'completado' ||
        cleanNormalized == 'completed' ||
        normalized == 'finalizado') {
      return 'finalizado';
    }
    return 'pendiente';
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tarea.name);
    _descriptionController = TextEditingController(
      text: widget.tarea.description,
    );
    _durationController = TextEditingController(
      text: widget.tarea.duration.toString(),
    );

    final normalizedState = _normalizeState(widget.tarea.state);
    _selectedState = normalizedState;
    _lastKnownTareaState = normalizedState;
    _pendingEvidences = List.from(widget.tarea.evidences);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  TareaEntity _getUpdatedTarea(BuildContext context) {
    try {
      final obraState = context.read<ObraBloc>().state;
      if (obraState is ObraLoaded) {
        for (final obra in obraState.obras) {
          if (obra.id == widget.obraId) {
            final tareaIndex = obra.tareas.indexWhere(
              (t) => t.id == widget.tarea.id,
            );
            if (tareaIndex >= 0) {
              return obra.tareas[tareaIndex];
            }
          }
        }
      }
    } catch (e) {
      // Si hay error, usar la tarea original
    }
    return widget.tarea;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: isDark ? TierraApp.dark : TierraApp.lightBackground,
      appBar: AppBar(
        title: Text(
          widget.tarea.name,
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            letterSpacing: -0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: TierraApp.getAppBarColor(isDark),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: BlocBuilder<ObraBloc, ObraState>(
        builder: (context, obraState) {
          final tarea = _getUpdatedTarea(context);
          final normalizedState = _normalizeState(tarea.state);

          // Actualizar estado si cambió desde el backend
          if (!_userModifiedState && !_isUserSelecting) {
            if (_estados.contains(normalizedState) &&
                normalizedState != _lastKnownTareaState &&
                normalizedState != _selectedState) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_userModifiedState && !_isUserSelecting) {
                  setState(() {
                    _selectedState = normalizedState;
                    _lastKnownTareaState = normalizedState;
                    _pendingEvidences = List<String>.from(tarea.evidences);
                  });
                }
              });
            } else if (_lastKnownTareaState == null) {
              _lastKnownTareaState = normalizedState;
            }
          }

          // Actualizar controladores si es admin
          if (isAdmin && widget.obraId.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  tarea.description != _descriptionController.text &&
                  _descriptionController.text == widget.tarea.description) {
                setState(() {
                  _descriptionController.text = tarea.description;
                });
              }
              if (mounted &&
                  tarea.duration.toString() != _durationController.text &&
                  _durationController.text ==
                      widget.tarea.duration.toString()) {
                setState(() {
                  _durationController.text = tarea.duration.toString();
                });
              }
            });
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ObraBloc>().add(const LoadObras());
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estado de la tarea - Card destacado
                  _buildStatusCard(context, tarea, isDark, textTheme),
                  const SizedBox(height: 24),

                  // Descripción
                  _buildDescriptionSection(context, tarea, isDark, textTheme),
                  const SizedBox(height: 24),

                  // Información de la tarea
                  _buildInfoCard(context, tarea, isDark, textTheme),
                  const SizedBox(height: 24),

                  // Observaciones
                  _buildObservationSection(context, tarea, isDark, textTheme),
                  const SizedBox(height: 24),

                  // Evidencias
                  if (isAdmin || _selectedState == 'finalizado')
                    _buildEvidencesSection(context, tarea, isDark, textTheme),

                  const SizedBox(height: 24),

                  // Botón guardar
                  _buildSaveButton(context, tarea, isDark, textTheme),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    TareaEntity tarea,
    bool isDark,
    TextTheme textTheme,
  ) {
    final estadoColor = FormatUtils.getStateColor(_selectedState);
    final estadoText = FormatUtils.formatStateText(_selectedState);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: estadoColor.withValues(alpha: 0.3), width: 2),
      ),
      color: estadoColor.withValues(alpha: isDark ? 0.15 : 0.08),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado',
                      style: textTheme.labelLarge?.copyWith(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: estadoColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          estadoText,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: estadoColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              child: _buildStateDropdown(context, tarea, isDark, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateDropdown(
    BuildContext context,
    TareaEntity tarea,
    bool isDark,
    TextTheme textTheme,
  ) {
    final normalizedSelected = _normalizeState(_selectedState);
    String? validValue;

    for (final estado in _estados) {
      if (estado == normalizedSelected) {
        validValue = estado;
        break;
      }
    }
    validValue ??= 'pendiente';

    return DropdownButtonFormField<String>(
      key: ValueKey('dropdown_$validValue'),
      value: validValue,
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
      dropdownColor: isDark ? const Color(0xFF2B2B2B) : Colors.white,
      style: textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : Colors.black87,
      ),
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: isDark ? Colors.white70 : Colors.black54,
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
          key: ValueKey(estado),
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
                style: textTheme.bodyLarge?.copyWith(color: stateColor),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          _isUserSelecting = true;
          setState(() {
            _selectedState = value;
            _userModifiedState = true;
            _lastKnownTareaState = value;
          });
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _isUserSelecting = false;
              });
            }
          });
        }
      },
    );
  }

  Widget _buildDescriptionSection(
    BuildContext context,
    TareaEntity tarea,
    bool isDark,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (isAdmin)
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            style: textTheme.bodyLarge?.copyWith(
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Descripción de la tarea',
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF2B2B2B) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: TierraApp.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          )
        else
          Card(
            elevation: 0,
            color: isDark ? const Color(0xFF2B2B2B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                tarea.description.isNotEmpty
                    ? tarea.description
                    : 'Sin descripción',
                style: textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    TareaEntity tarea,
    bool isDark,
    TextTheme textTheme,
  ) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF2B2B2B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            // Duración
            if (isAdmin) ...[
              Text(
                'Duración (días)',
                style: textTheme.labelMedium?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                style: textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: '5',
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1B1B1B)
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: TierraApp.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ] else if (tarea.duration > 0) ...[
              TareaInfoRow(
                icon: Icons.access_time,
                label: 'Duración',
                value: '${tarea.duration} días',
              ),
            ],
            if ((isAdmin || tarea.duration > 0) &&
                (tarea.evidences.isNotEmpty || tarea.assignedTo != null))
              const Divider(height: 32),
            // Evidencias
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
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
              if (tarea.assignedTo != null) const Divider(height: 32),
            ],
            // Asignado a
            if (tarea.assignedTo != null)
              TareaInfoRow(
                icon: Icons.person,
                label: 'Asignado a',
                value: tarea.assignedTo!.fullName,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservationSection(
    BuildContext context,
    TareaEntity tarea,
    bool isDark,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Observaciones',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            TextButton.icon(
              onPressed: () => _openObservationModal(context, tarea),
              icon: Icon(
                tarea.observation != null && tarea.observation!.isNotEmpty
                    ? Icons.edit
                    : Icons.add,
                size: 18,
              ),
              label: Text(
                tarea.observation != null && tarea.observation!.isNotEmpty
                    ? 'Editar'
                    : 'Agregar',
              ),
              style: TextButton.styleFrom(foregroundColor: TierraApp.primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: isDark ? const Color(0xFF2B2B2B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => _openObservationModal(context, tarea),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: tarea.observation != null && tarea.observation!.isNotEmpty
                  ? Text(
                      tarea.observation!,
                      style: textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    )
                  : Row(
                      children: [
                        Icon(
                          Icons.note_add_outlined,
                          size: 20,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.black.withValues(alpha: 0.3),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Toca para agregar observaciones',
                          style: textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.black.withValues(alpha: 0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEvidencesSection(
    BuildContext context,
    TareaEntity tarea,
    bool isDark,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Evidencias',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (_pendingEvidences.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: TierraApp.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_pendingEvidences.length}',
                  style: textTheme.labelMedium?.copyWith(
                    color: TierraApp.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_pendingEvidences.isNotEmpty) ...[
          Card(
            elevation: 0,
            color: isDark ? const Color(0xFF2B2B2B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _pendingEvidences.length,
                itemBuilder: (context, index) {
                  final evidenceUrl = _pendingEvidences[index];
                  final isNew = index >= tarea.evidences.length;
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: evidenceUrl.startsWith('http')
                            ? Image.network(
                                evidenceUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade300,
                                    child: Icon(
                                      Icons.broken_image,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                  );
                                },
                              )
                            : Image.file(
                                File(evidenceUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade300,
                                    child: Icon(
                                      Icons.broken_image,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (isNew)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _pendingEvidences.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploading
                    ? null
                    : () => _pickImageFromGallery(context),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galería'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.2),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploading ? null : () => _takePicture(context),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Cámara'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.2),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_isUploading) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 8),
          Text(
            'Subiendo evidencias...',
            style: textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildSaveButton(
    BuildContext context,
    TareaEntity tarea,
    bool isDark,
    TextTheme textTheme,
  ) {
    final hasChanges = _hasChanges(tarea);
    final hasEvidenceChanges = _hasEvidenceChanges(tarea);
    final validPendingEvidences = _pendingEvidences
        .where((e) => e.startsWith('http'))
        .toList();
    final hasNewEvidences =
        validPendingEvidences.length > tarea.evidences.length ||
        validPendingEvidences.any((e) => !tarea.evidences.contains(e));

    final hasDescriptionChanges =
        isAdmin && _descriptionController.text.trim() != tarea.description;
    final hasDurationChanges =
        isAdmin &&
        (int.tryParse(_durationController.text.trim()) ?? 0) != tarea.duration;

    final canSave =
        (hasChanges ||
            hasEvidenceChanges ||
            hasNewEvidences ||
            hasDescriptionChanges ||
            hasDurationChanges) &&
        !_isUploading;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: canSave ? () => _saveChanges(context) : null,
        icon: const Icon(Icons.save),
        label: Text(
          'Guardar cambios',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: canSave
              ? TierraApp.primary
              : (isDark ? const Color(0xFF2B2B2B) : Colors.grey.shade300),
          foregroundColor: canSave
              ? Colors.black
              : (isDark ? Colors.white54 : Colors.black54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: canSave ? 2 : 0,
        ),
      ),
    );
  }

  void _openObservationModal(BuildContext context, TareaEntity tarea) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: true,
      builder: (context) => BlocBuilder<ObraBloc, ObraState>(
        builder: (context, obraState) {
          final updatedTarea = _getUpdatedTarea(context);
          return ObservationModal(tarea: updatedTarea, obraId: widget.obraId);
        },
      ),
    ).then((saved) {
      if (saved == true && mounted) {
        context.read<ObraBloc>().add(const LoadObras());
      }
    });
  }

  bool _hasChanges(TareaEntity tarea) {
    return _selectedState != _normalizeState(tarea.state);
  }

  bool _hasEvidenceChanges(TareaEntity tarea) {
    final currentEvidences = tarea.evidences;
    if (_pendingEvidences.length != currentEvidences.length) {
      return true;
    }
    final validPendingEvidences = _pendingEvidences
        .where((e) => e.startsWith('http'))
        .toList();
    final newUrls = validPendingEvidences
        .where((e) => !currentEvidences.contains(e))
        .toList();
    return newUrls.isNotEmpty;
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    try {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        if (mounted) {
          CustomSnackBar.showError(
            context,
            message: 'Se necesita permiso para acceder a la galería',
          );
        }
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          message: 'Error al seleccionar imagen: $e',
        );
      }
    }
  }

  Future<void> _takePicture(BuildContext context) async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          CustomSnackBar.showError(
            context,
            message: 'Se necesita permiso para acceder a la cámara',
          );
        }
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, message: 'Error al tomar foto: $e');
      }
    }
  }

  Future<void> _uploadImage(String imagePath) async {
    setState(() {
      _isUploading = true;
      // Agregar la imagen local a la lista (para preview)
      _pendingEvidences.add(imagePath);
    });

    try {
      final imageFile = File(imagePath);
      final cloudinaryUrl = await _cloudinaryService.uploadImage(
        imageFile,
        folder: 'evidencias',
      );

      // Reemplazar la ruta local con la URL de Cloudinary
      if (mounted) {
        setState(() {
          final index = _pendingEvidences.indexOf(imagePath);
          if (index != -1) {
            _pendingEvidences[index] = cloudinaryUrl;
          }
          _isUploading = false;
        });
        CustomSnackBar.showSuccess(
          context,
          message: 'Imagen subida correctamente',
        );
      }
    } catch (e) {
      // Remover la imagen si falla la subida
      if (mounted) {
        setState(() {
          _pendingEvidences.remove(imagePath);
          _isUploading = false;
        });
        CustomSnackBar.showError(context, message: 'Error al subir imagen: $e');
      }
    }
  }

  Future<void> _saveChanges(BuildContext context) async {
    if (!mounted) return;

    final tareaBloc = context.read<TareaBloc>();
    final obraBloc = context.read<ObraBloc>();
    final obraId = widget.obraId;

    final tarea = _getUpdatedTarea(context);
    final stateChanged = _selectedState != _normalizeState(tarea.state);
    final evidenceChanged = _hasEvidenceChanges(tarea);
    final descriptionChanged =
        isAdmin && _descriptionController.text.trim() != tarea.description;
    final durationChanged =
        isAdmin &&
        (int.tryParse(_durationController.text.trim()) ?? 0) != tarea.duration;

    final validPendingEvidences = _pendingEvidences
        .where((e) => e.startsWith('http'))
        .toList();
    final hasNewEvidencesInPending =
        validPendingEvidences.length > tarea.evidences.length ||
        validPendingEvidences.any((e) => !tarea.evidences.contains(e));

    final currentStateNormalized = _normalizeState(tarea.state);
    final needsAutoStateUpdate =
        !isAdmin &&
        hasNewEvidencesInPending &&
        currentStateNormalized != 'finalizado' &&
        !stateChanged;

    if (obraId.isEmpty) {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          message: 'Las tareas deben estar asociadas a una obra',
        );
      }
      return;
    }

    try {
      if (isAdmin &&
          (descriptionChanged ||
              durationChanged ||
              stateChanged ||
              evidenceChanged)) {
        final duration =
            int.tryParse(_durationController.text.trim()) ?? tarea.duration;
        final description = _descriptionController.text.trim();

        String finalState = _selectedState;

        final updatedTarea = TareaEntity(
          id: tarea.id,
          name: tarea.name,
          description: description,
          state: finalState,
          duration: duration,
          evidences: validPendingEvidences,
          assignedTo: tarea.assignedTo,
          observation: tarea.observation,
          obraTareaId: tarea.obraTareaId,
        );

        tareaBloc.add(UpdateTarea(updatedTarea, obraId));

        try {
          if (!mounted) return;
          await tareaBloc.stream
              .where((state) => state is! TareaLoading)
              .timeout(const Duration(seconds: 10))
              .first;
        } catch (e) {
          if (!mounted) return;
        }
      } else {
        if (stateChanged) {
          tareaBloc.add(UpdateTareaState(obraId, tarea.id, _selectedState));

          try {
            if (!mounted) return;
            await tareaBloc.stream
                .where((state) => state is! TareaLoading)
                .timeout(const Duration(seconds: 10))
                .first;
          } catch (e) {
            if (!mounted) return;
          }
        }

        if (evidenceChanged || hasNewEvidencesInPending) {
          tareaBloc.add(
            UpdateTareaEvidences(obraId, tarea.id, validPendingEvidences),
          );

          try {
            if (!mounted) return;
            await tareaBloc.stream
                .where((state) => state is! TareaLoading)
                .timeout(const Duration(seconds: 10))
                .first;
          } catch (e) {
            if (!mounted) return;
          }

          if (needsAutoStateUpdate && !isAdmin) {
            tareaBloc.add(UpdateTareaState(obraId, tarea.id, 'finalizado'));

            try {
              if (!mounted) return;
              await tareaBloc.stream
                  .where((state) => state is! TareaLoading)
                  .timeout(const Duration(seconds: 10))
                  .first;
            } catch (e) {
              if (!mounted) return;
            }
          }
        }
      }

      obraBloc.add(const LoadObras());

      if (mounted) {
        setState(() {
          _userModifiedState = false;
        });
        CustomSnackBar.showSuccess(
          context,
          message: 'Cambios guardados correctamente',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          message: 'Error al guardar cambios: $e',
        );
      }
    }
  }
}
