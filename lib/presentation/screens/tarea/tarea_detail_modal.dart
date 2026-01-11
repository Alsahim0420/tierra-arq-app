// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/entities/tarea_entity.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../bloc/tarea/tarea_bloc.dart';
import '../../bloc/tarea/tarea_event.dart';
import '../../bloc/tarea/tarea_state.dart';
import '../../bloc/obra/obra_bloc.dart';
import '../../bloc/obra/obra_event.dart';
import '../../bloc/obra/obra_state.dart';
import '../../app/app.dart';
import '../../utils/format_utils.dart';
import '../../widgets/tarea_info_row.dart';
import '../../widgets/evidences_gallery.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/injection/injection_container.dart' as di;
import 'observation_modal.dart';

class TareaDetailModal extends StatefulWidget {
  const TareaDetailModal({
    super.key,
    required this.tarea,
    this.obraId,
    this.isAdmin = false,
    this.isMaster = false,
  });

  final TareaEntity tarea;
  final String? obraId;
  final bool isAdmin;
  final bool isMaster;

  @override
  State<TareaDetailModal> createState() => _TareaDetailModalState();
}

class _TareaDetailModalState extends State<TareaDetailModal> {
  late String _selectedState;
  final List<String> _estados = ['pendiente', 'en progreso', 'finalizado'];
  final ImagePicker _imagePicker = ImagePicker();
  CloudinaryService get _cloudinaryService => di.getIt<CloudinaryService>();
  List<String> _pendingEvidences = []; // Evidencias nuevas pendientes de subir
  bool _isUploading = false;
  bool _userModifiedState = false; // Flag para saber si el usuario modificó el estado manualmente
  String? _lastKnownTareaState; // Último estado conocido de la tarea desde el backend
  bool _isUserSelecting = false; // Flag para indicar que el usuario está seleccionando un valor
  
  // Controladores para edición simple (cuando no hay obraId)
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  // COMENTADO: _formKey solo se usa en _buildSimpleEditForm que está comentado
  // final _formKey = GlobalKey<FormState>();

  String _normalizeState(String state) {
    // Normalizar diferentes formatos de estado a nuestro formato estándar
    // Eliminar espacios extra y normalizar
    final normalized = state.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Comparar sin espacios extra
    final cleanNormalized = normalized.replaceAll(' ', '');
    
    if (cleanNormalized == 'en_proceso' || cleanNormalized == 'en_progreso' || normalized == 'en progreso') {
      return 'en progreso';
    }
    if (cleanNormalized == 'pendiente' || cleanNormalized == 'pending' || normalized == 'pendiente') {
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
    // Si no coincide, devolver "pendiente" por defecto (siempre debe estar en _estados)
    return 'pendiente';
  }

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores para edición simple (cuando no hay obraId)
    // También los usaremos para admin cuando hay obraId
    _nameController = TextEditingController(text: widget.tarea.name);
    _descriptionController = TextEditingController(text: widget.tarea.description);
    _durationController = TextEditingController(text: widget.tarea.duration.toString());
    
    // NO refrescar las obras aquí para evitar reconstrucciones innecesarias
    // Solo refrescar cuando sea necesario (al abrir el modal)
    // context.read<ObraBloc>().add(const LoadObras());
    
    final normalizedState = _normalizeState(widget.tarea.state);
    
    // Asegurar que el estado normalizado esté en la lista _estados
    if (_estados.contains(normalizedState)) {
      _selectedState = normalizedState;
    } else {
      // Si no está en la lista, usar "pendiente" por defecto
      _selectedState = 'pendiente';
    }
    // Inicializar con evidencias existentes
    _pendingEvidences = List<String>.from(widget.tarea.evidences);
    // Guardar el estado inicial de la tarea
    _lastKnownTareaState = normalizedState;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // Método para obtener la tarea actualizada del ObraBloc
  TareaEntity _getUpdatedTarea(BuildContext context) {
    final obraState = context.read<ObraBloc>().state;
        // COMENTADO: Solo cargar obra si hay obraId (tareas independientes deshabilitadas)
        if (obraState is ObraLoaded && widget.obraId != null && widget.obraId!.isNotEmpty) {
      // Buscar la obra que contiene esta tarea (solo si hay obraId)
      final obra = obraState.obras.firstWhere(
        (o) => o.id == widget.obraId,
        orElse: () => throw Exception('Obra no encontrada'),
      );
      // Buscar la tarea actualizada en la obra
      try {
        final updatedTarea = obra.tareas.firstWhere(
          (t) => t.id == widget.tarea.id,
        );
        return updatedTarea;
      } catch (e) {
        // Si no se encuentra, usar la tarea original
        return widget.tarea;
      }
    }
    return widget.tarea;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocBuilder<ObraBloc, ObraState>(
      builder: (context, obraState) {
        // Obtener la tarea actualizada del BLoC
        final tarea = _getUpdatedTarea(context);
        
        // Solo actualizar el estado desde el backend si:
        // 1. El usuario NO ha modificado el estado manualmente
        // 2. El estado de la tarea cambió desde el backend (diferente al último conocido)
        // 3. El estado del backend es diferente al que el usuario seleccionó
        final normalizedState = _normalizeState(tarea.state);
        
        // NO actualizar desde el backend si:
        // 1. El usuario ya modificó el estado manualmente
        // 2. El usuario está seleccionando un valor en este momento
        if (_userModifiedState || _isUserSelecting) {
        } else if (_estados.contains(normalizedState) && 
            normalizedState != _lastKnownTareaState &&
            normalizedState != _selectedState) {
          // El estado cambió desde el backend, actualizar
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_userModifiedState && !_isUserSelecting) {
              setState(() {
                _selectedState = normalizedState;
                _lastKnownTareaState = normalizedState;
                _pendingEvidences = List<String>.from(tarea.evidences);
              });
            } else {
            }
          });
        } else if (!_userModifiedState && _lastKnownTareaState == null) {
          // Primera vez, inicializar el último estado conocido
          _lastKnownTareaState = normalizedState;
        }
        
        // Actualizar controladores de descripción y duración si es admin cuando la tarea se actualiza desde el backend
        // Solo actualizar si el valor del backend es diferente y el usuario no está editando
        // COMENTADO: Solo actualizar si hay obraId (tareas independientes deshabilitadas)
        if (widget.isAdmin && widget.obraId != null && widget.obraId!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && tarea.description != _descriptionController.text &&
                _descriptionController.text == widget.tarea.description) {
              setState(() {
                _descriptionController.text = tarea.description;
              });
            }
            if (mounted && tarea.duration.toString() != _durationController.text &&
                _durationController.text == widget.tarea.duration.toString()) {
              setState(() {
                _durationController.text = tarea.duration.toString();
              });
            }
          });
        }

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B1B) : const Color(0xFFFFFFFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: 12,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: 
              // COMENTADO: Formulario simple para tareas independientes (obraId == null) - funcionalidad deshabilitada
              // Las tareas deben estar asociadas a una obra
              // widget.obraId == null
              //     ? _buildSimpleEditForm(context, textTheme, tarea)
              //     : 
              widget.obraId == null
                  ? Center(
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
                            'Las tareas deben estar asociadas a una obra',
                            style: textTheme.bodyLarge?.copyWith(
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Column(
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
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2B2B2B) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                child: Builder(
                  builder: (context) {
                    // Asegurar que el valor esté en la lista y sea exactamente uno de los items
                    // Normalizar _selectedState para asegurar coincidencia exacta
                    final normalizedSelected = _normalizeState(_selectedState);
                    String? validValue;
                    
                    // Buscar coincidencia exacta en _estados
                    for (final estado in _estados) {
                      if (estado == normalizedSelected) {
                        validValue = estado;
                        break;
                      }
                    }
                    validValue ??= 'pendiente'; // Si no se encuentra, usar pendiente
                    
                    // Verificar que no haya duplicados en _estados
                    final uniqueEstados = _estados.toSet().toList();
                    if (uniqueEstados.length != _estados.length) {
                    }
                    
                    // Verificar que validValue esté en items
                    final itemsValues = _estados.map((e) => e).toList();
                    final matchingItems = itemsValues.where((v) => v == validValue).length;
                    if (matchingItems != 1) {
                    }
                    
                    return DropdownButtonFormField<String>(
                      key: ValueKey('dropdown_$validValue'), // Key único para el dropdown
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
                  dropdownColor: isDark ? const Color(0xFF2B2B2B) : const Color(0xFFF5F5F5),
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
                      key: ValueKey(estado), // Agregar key único para evitar duplicados
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
                          // Marcar que el usuario está seleccionando
                          _isUserSelecting = true;
                          
                          setState(() {
                            _selectedState = value;
                            _userModifiedState = true; // Marcar que el usuario modificó el estado
                            _lastKnownTareaState = value; // Actualizar el último estado conocido para evitar que se sobrescriba
                          });
                          
                          // Después de un breve delay, permitir actualizaciones del backend nuevamente
                          // pero mantener _userModifiedState = true para que no se sobrescriba
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
                  },
                ),
              ),
              const SizedBox(height: 32),
              // Descripción: editable para admin, solo lectura para master
              Text(
                'Descripción',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.isAdmin) ...[
                // Admin puede editar la descripción
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Descripción de la tarea',
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: Colors.white38,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2B2B2B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ] else ...[
                // Master solo puede ver la descripción
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2B2B2B) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    tarea.description.isNotEmpty ? tarea.description : 'Sin descripción',
                    style: textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Text(
                'Información',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: isDark ? const Color(0xFF2B2B2B) : const Color(0xFFF5F5F5),
                shape: RoundedRectangleBorder(
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Duración: editable para admin, solo lectura para master
                      if (widget.isAdmin) ...[
                        // Admin puede editar la duración
                        Text(
                          'Duración (días)',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          style: textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: '5',
                            hintStyle: textTheme.bodyMedium?.copyWith(
                              color: Colors.white38,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1B1B1B),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: TierraApp.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ] else ...[
                        // Master solo puede ver la duración
                        if (tarea.duration > 0) ...[
                          TareaInfoRow(
                            icon: Icons.access_time,
                            label: 'Duración',
                            value: '${tarea.duration} días',
                          ),
                        ],
                      ],
                      if (tarea.duration > 0 &&
                          (tarea.evidences.isNotEmpty ||
                              tarea.assignedTo != null ||
                              widget.isAdmin))
                        const SizedBox(height: 16),
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
                                color: isDark ? Colors.white54 : Colors.black54,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Observaciones',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
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
                    style: TextButton.styleFrom(
                      foregroundColor: TierraApp.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _openObservationModal(context, tarea),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2B2B2B) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  child: tarea.observation != null && tarea.observation!.isNotEmpty
                      ? Text(
                          tarea.observation!,
                          style: textTheme.bodyMedium?.copyWith(
                            height: 1.5,
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
                            const SizedBox(width: 8),
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
              // Sección de Evidencias
              // Admin puede ver/editar evidencias en cualquier estado
              // Master solo puede ver/editar evidencias cuando el estado es "finalizado"
              if (widget.isAdmin || _selectedState == 'finalizado') ...[
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Evidencias',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    if (_pendingEvidences.isNotEmpty)
                      Text(
                        '${_pendingEvidences.length}',
                        style: textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Grid de evidencias existentes y nuevas
                if (_pendingEvidences.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
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
                                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                        child: Icon(
                                          Icons.broken_image,
                                          color: isDark ? Colors.white54 : Colors.black54,
                                        ),
                                      );
                                    },
                                  )
                                : Image.file(
                                    File(evidenceUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                        child: Icon(
                                          Icons.broken_image,
                                          color: isDark ? Colors.white54 : Colors.black54,
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
                          // Botón de eliminar: admin siempre puede eliminar, master solo en "finalizado"
                          if (widget.isAdmin || _selectedState == 'finalizado')
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
                                    color: Colors.red.withValues(alpha: 0.8),
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
                const SizedBox(height: 12),
                // Botones para agregar evidencias
                // Admin puede agregar en cualquier estado, master solo en "finalizado"
                if (widget.isAdmin || _selectedState == 'finalizado') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploading ? null : () => _pickImageFromGallery(context),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galería'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_isUploading) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: Builder(
                  builder: (context) {
                    final hasChanges = _hasChanges(tarea);
                    final hasEvidenceChanges = _hasEvidenceChanges(tarea);
                    final validPendingEvidences = _pendingEvidences
                        .where((e) => e.startsWith('http'))
                        .toList();
                    final hasNewEvidences = validPendingEvidences.length > tarea.evidences.length ||
                        validPendingEvidences.any((e) => !tarea.evidences.contains(e));
                    
                    // Verificar cambios en descripción y duración para admin
                    final hasDescriptionChanges = widget.isAdmin && 
                                                  _descriptionController.text.trim() != tarea.description;
                    final hasDurationChanges = widget.isAdmin && 
                                              (int.tryParse(_durationController.text.trim()) ?? 0) != tarea.duration;
                    
                    // Ya no incluimos observación en canSave, se maneja por separado
                    final canSave = (hasChanges || 
                                    hasEvidenceChanges || 
                                    hasNewEvidences || 
                                    hasDescriptionChanges || 
                                    hasDurationChanges) && 
                                   !_isUploading;
                    
                    return FilledButton(
                      onPressed: canSave
                          ? () {
                              _saveChanges(context);
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: canSave
                            ? TierraApp.primary
                            : Colors.white.withValues(alpha: 0.1),
                        foregroundColor: canSave
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
        );
      },
    );
  }

  // Versión simplificada del modal para edición sin obraId
  // COMENTADO: Método para edición simple de tareas independientes (sin obraId) - funcionalidad deshabilitada
  // El _formKey aún se declara pero solo se usa en este método comentado
  /*
  Widget _buildSimpleEditForm(BuildContext context, TextTheme textTheme, TareaEntity tarea) {
    return Form(
      key: _formKey, // COMENTADO: _formKey solo se usa aquí
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
                  'Editar Tarea',
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
          // Nombre
          Text(
            'Nombre',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            style: textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Nombre de la tarea',
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: Colors.white38,
              ),
              filled: true,
              fillColor: const Color(0xFF2B2B2B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: TierraApp.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre es requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          // Descripción
          Text(
            'Descripción',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            style: textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Descripción de la tarea',
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: Colors.white38,
              ),
              filled: true,
              fillColor: const Color(0xFF2B2B2B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: TierraApp.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La descripción es requerida';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          // Duración
          Text(
            'Duración (días)',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            style: textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: '5',
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: Colors.white38,
              ),
              filled: true,
              fillColor: const Color(0xFF2B2B2B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: TierraApp.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La duración es requerida';
              }
              final duration = int.tryParse(value.trim());
              if (duration == null || duration <= 0) {
                return 'Debe ser un número positivo';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          // Botón Guardar
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _saveSimpleChanges(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: TierraApp.primary,
                foregroundColor: Colors.black,
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
    );
  }
  */

  // COMENTADO: Método para guardar cambios simples de tareas independientes - funcionalidad deshabilitada
  /*
  Future<void> _saveSimpleChanges(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    final tareaBloc = context.read<TareaBloc>();
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;

    // Crear tarea actualizada con solo nombre, descripción y duración
    final updatedTarea = TareaEntity(
      id: widget.tarea.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      state: widget.tarea.state, // Mantener el estado original
      duration: duration,
      evidences: widget.tarea.evidences, // Mantener evidencias originales
      assignedTo: widget.tarea.assignedTo,
      observation: widget.tarea.observation, // Mantener observación original
      obraTareaId: widget.tarea.obraTareaId, // Mantener obraTareaId original
    );

    tareaBloc.add(UpdateTarea(updatedTarea, ''));

    // Esperar a que termine
    try {
      await tareaBloc.stream
          .where((state) => state is! TareaLoading)
          .skip(1)
          .timeout(const Duration(seconds: 10))
          .first;
    } catch (e) {
      final currentState = tareaBloc.state;
      if (currentState is! TareaLoaded && currentState is! TareaError) {
        rethrow;
      }
    }

    if (mounted) {
      // Refrescar la lista de tareas
      tareaBloc.add(LoadTareas(page: 1, limit: 10));
      Navigator.pop(context, true);
      CustomSnackBar.showSuccess(
        context,
        message: 'Tarea actualizada correctamente',
      );
    }
  }
  */

  void _openObservationModal(BuildContext context, TareaEntity tarea) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: true,
      builder: (context) => BlocBuilder<ObraBloc, ObraState>(
        builder: (context, obraState) {
          // Obtener la tarea actualizada del BLoC
          final updatedTarea = _getUpdatedTarea(context);
          final obraId = widget.obraId ?? '';
          return ObservationModal(
            tarea: updatedTarea,
            obraId: obraId,
          );
        },
      ),
    ).then((saved) { 
      // Si se guardó la observación, refrescar el modal principal
      if (saved == true && mounted) {
        context.read<ObraBloc>().add(const LoadObras());
      }
    });
  }

  bool _hasChanges(TareaEntity tarea) {
    final stateChanged = _selectedState != _normalizeState(tarea.state);
    // Ya no verificamos cambios en observación aquí, se maneja en el modal separado
    // Los cambios en descripción y duración se verifican en el builder del botón
    return stateChanged;
  }

  bool _hasEvidenceChanges(TareaEntity tarea) {
    // Comparar si las evidencias han cambiado
    final currentEvidences = tarea.evidences;
    
    // Si las longitudes son diferentes, hay cambios
    if (_pendingEvidences.length != currentEvidences.length) {
      return true;
    }
    
    // Verificar si hay URLs nuevas (que empiezan con http pero no están en las originales)
    final validPendingEvidences = _pendingEvidences.where((e) => e.startsWith('http')).toList();
    final newUrls = validPendingEvidences.where((e) => !currentEvidences.contains(e)).toList();
    
    return newUrls.isNotEmpty;
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    try {
      // Solicitar permiso de galería
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se necesita permiso para acceder a la galería'),
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
          ),
        );
      }
    }
  }

  Future<void> _takePicture(BuildContext context) async {
    try {
      // Solicitar permiso de cámara
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se necesita permiso para usar la cámara'),
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al tomar foto: $e'),
          ),
        );
      }
    }
  }

  Future<void> _uploadImage(String imagePath) async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Agregar la imagen local a la lista (para preview)
      setState(() {
        _pendingEvidences.add(imagePath);
      });

      // Subir a Cloudinary
      final imageFile = File(imagePath);
      final cloudinaryUrl = await _cloudinaryService.uploadImage(
        imageFile,
        folder: 'evidencias',
      );

      // Reemplazar la ruta local con la URL de Cloudinary
      setState(() {
        final index = _pendingEvidences.indexOf(imagePath);
        if (index != -1) {
          _pendingEvidences[index] = cloudinaryUrl;
        }
        // Si hay evidencias y el estado no es "finalizado", actualizar automáticamente
        // Solo para master, admin puede mantener cualquier estado
        if (!widget.isAdmin) {
          final validEvidences = _pendingEvidences
              .where((e) => e.startsWith('http'))
              .toList();
          if (validEvidences.isNotEmpty && _selectedState != 'finalizado') {
            _selectedState = 'finalizado';
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen subida correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Remover la imagen si falla la subida
      setState(() {
        _pendingEvidences.remove(imagePath);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _saveChanges(BuildContext context) async {
    // Guardar referencias antes de operaciones async para evitar problemas con contexto desactivado
    if (!mounted) return;
    
    final tareaBloc = context.read<TareaBloc>();
    final obraBloc = context.read<ObraBloc>();
    final obraId = widget.obraId;
    
    // Obtener la tarea actualizada
    final tarea = _getUpdatedTarea(context);
    
    final stateChanged = _selectedState != _normalizeState(tarea.state);
    // Ya no manejamos observación aquí, se maneja en el modal separado
    final evidenceChanged = _hasEvidenceChanges(tarea);
    
    // Verificar si admin modificó descripción o duración
    final descriptionChanged = widget.isAdmin && 
                               _descriptionController.text.trim() != tarea.description;
    final durationChanged = widget.isAdmin && 
                            (int.tryParse(_durationController.text.trim()) ?? 0) != tarea.duration;
    
    // Filtrar evidencias válidas (solo URLs)
    final validPendingEvidences = _pendingEvidences
        .where((e) => e.startsWith('http'))
        .toList();
    final hasNewEvidencesInPending = validPendingEvidences.length > tarea.evidences.length ||
        validPendingEvidences.any((e) => !tarea.evidences.contains(e));
    
    final currentStateNormalized = _normalizeState(tarea.state);
    // Solo auto-actualizar estado si es master, admin puede cambiar estado manualmente sin restricciones
    final needsAutoStateUpdate = !widget.isAdmin &&
                                 hasNewEvidencesInPending && 
                                 currentStateNormalized != 'finalizado' && 
                                 !stateChanged;
    
    // COMENTADO: Manejo de tareas independientes (obraId == null) - funcionalidad deshabilitada
    // Las tareas deben estar asociadas a una obra
    if (obraId == null || obraId.isEmpty) {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          message: 'Las tareas deben estar asociadas a una obra',
        );
      }
      return;
    }
    /* COMENTADO: Código para actualizar tareas independientes
    if (obraId == null) {
      // Actualizar todo usando UpdateTarea (evidencias, estado, etc.)
      
      // Determinar el estado final
      String finalState = _selectedState;
      if (needsAutoStateUpdate && !stateChanged) {
        finalState = 'finalizado';
      }
      
      // Crear tarea actualizada con todas las modificaciones
      final updatedTarea = TareaEntity(
        id: tarea.id,
        name: tarea.name,
        description: tarea.description,
        state: finalState,
        duration: tarea.duration,
        evidences: validPendingEvidences,
        assignedTo: tarea.assignedTo,
        observation: tarea.observation,
        obraTareaId: tarea.obraTareaId, // Mantener obraTareaId original
      );
      
      tareaBloc.add(UpdateTarea(updatedTarea, ''));
      
      // Esperar a que termine
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
    */
      // Si hay obraId
      // Si es admin y modificó descripción o duración, usar UpdateTarea para actualizar todo junto
      if (widget.isAdmin && (descriptionChanged || durationChanged || stateChanged || evidenceChanged)) {
        // Admin puede actualizar todo junto usando UpdateTarea
        final duration = int.tryParse(_durationController.text.trim()) ?? tarea.duration;
        final description = _descriptionController.text.trim();
        
        // Determinar el estado final
        String finalState = _selectedState;
        
        // Crear tarea actualizada con todas las modificaciones
        final updatedTarea = TareaEntity(
          id: tarea.id,
          name: tarea.name,
          description: description,
          state: finalState,
          duration: duration,
          evidences: validPendingEvidences,
          assignedTo: tarea.assignedTo,
          observation: tarea.observation,
          obraTareaId: tarea.obraTareaId, // Mantener obraTareaId original
        );
        
        tareaBloc.add(UpdateTarea(updatedTarea, obraId));
        
        // Esperar a que termine
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
        // Para master (o admin sin cambios en descripción/duración), usar los métodos específicos
        // 1. Si hay evidencias nuevas, actualizar evidencias primero y ESPERAR
        if (hasNewEvidencesInPending || evidenceChanged) {
          tareaBloc.add(
            UpdateTareaEvidences(
              obraId,
              tarea.id,
              validPendingEvidences,
            ),
          );
          
          // Esperar a que termine la actualización (deje de estar en loading)
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
        
        // 2. Si cambió el estado manualmente O necesita auto-actualización por evidencias
        if (stateChanged) {
          // Usuario cambió el estado manualmente
          tareaBloc.add(
            UpdateTareaState(
              obraId,
              tarea.id,
              _selectedState,
            ),
          );
          
          // Esperar a que termine
          try {
            if (!mounted) return;
            await tareaBloc.stream
                .where((state) => state is! TareaLoading)
                .timeout(const Duration(seconds: 10))
                .first;
          } catch (e) {
            if (!mounted) return;
          }
        } else if (needsAutoStateUpdate) {
          // Auto-actualizar a "finalizado" solo si hay evidencias nuevas Y el usuario NO cambió el estado
          // Solo para master
          
          tareaBloc.add(
            UpdateTareaState(
              obraId,
              tarea.id,
              'finalizado',
            ),
          );
          
          // Esperar a que termine
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
    // COMENTADO: Fin del bloque else para obraId != null
    // }
    
    // 3. La observación se maneja en un modal separado, no aquí

    if (mounted) {
      Navigator.pop(context);
      // Refrescar las obras para obtener los datos actualizados
      obraBloc.add(const LoadObras());
    }
  }
}
