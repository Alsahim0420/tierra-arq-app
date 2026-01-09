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
import '../../../core/injection/injection_container.dart' as di;
import 'observation_modal.dart';

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
  final List<String> _estados = ['pendiente', 'en progreso', 'finalizado'];
  final ImagePicker _imagePicker = ImagePicker();
  CloudinaryService get _cloudinaryService => di.getIt<CloudinaryService>();
  List<String> _pendingEvidences = []; // Evidencias nuevas pendientes de subir
  bool _isUploading = false;
  bool _userModifiedState = false; // Flag para saber si el usuario modificó el estado manualmente
  String? _lastKnownTareaState; // Último estado conocido de la tarea desde el backend
  bool _isUserSelecting = false; // Flag para indicar que el usuario está seleccionando un valor

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
    print('🔵 _normalizeState - Estado no reconocido: "$state" -> normalizado: "$normalized" -> retornando "pendiente"');
    return 'pendiente';
  }

  @override
  void initState() {
    super.initState();
    // NO refrescar las obras aquí para evitar reconstrucciones innecesarias
    // Solo refrescar cuando sea necesario (al abrir el modal)
    // context.read<ObraBloc>().add(const LoadObras());
    
    final normalizedState = _normalizeState(widget.tarea.state);
    print('🔵 initState - widget.tarea.state: "${widget.tarea.state}"');
    print('🔵 initState - normalizedState: "$normalizedState"');
    print('🔵 initState - _estados: $_estados');
    print('🔵 initState - contiene normalizedState: ${_estados.contains(normalizedState)}');
    
    // Asegurar que el estado normalizado esté en la lista _estados
    if (_estados.contains(normalizedState)) {
      _selectedState = normalizedState;
      print('🔵 initState - _selectedState asignado: "$_selectedState"');
    } else {
      // Si no está en la lista, usar "pendiente" por defecto
      _selectedState = 'pendiente';
      print('🔵 initState - _selectedState por defecto: "$_selectedState"');
    }
    // Inicializar con evidencias existentes
    _pendingEvidences = List<String>.from(widget.tarea.evidences);
    // Guardar el estado inicial de la tarea
    _lastKnownTareaState = normalizedState;
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Método para obtener la tarea actualizada del ObraBloc
  TareaEntity _getUpdatedTarea(BuildContext context) {
    final obraState = context.read<ObraBloc>().state;
    if (obraState is ObraLoaded) {
      // Buscar la obra que contiene esta tarea
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
    
    return BlocBuilder<ObraBloc, ObraState>(
      builder: (context, obraState) {
        // Obtener la tarea actualizada del BLoC
        final tarea = _getUpdatedTarea(context);
        
        // Solo actualizar el estado desde el backend si:
        // 1. El usuario NO ha modificado el estado manualmente
        // 2. El estado de la tarea cambió desde el backend (diferente al último conocido)
        // 3. El estado del backend es diferente al que el usuario seleccionó
        final normalizedState = _normalizeState(tarea.state);
        
        print('🔵 BlocBuilder - _userModifiedState: $_userModifiedState');
        print('🔵 BlocBuilder - normalizedState: "$normalizedState"');
        print('🔵 BlocBuilder - _lastKnownTareaState: "$_lastKnownTareaState"');
        print('🔵 BlocBuilder - _selectedState: "$_selectedState"');
        
        // NO actualizar desde el backend si:
        // 1. El usuario ya modificó el estado manualmente
        // 2. El usuario está seleccionando un valor en este momento
        if (_userModifiedState || _isUserSelecting) {
          print('🔵 BlocBuilder - Usuario modificó/seleccionando estado, NO actualizar desde backend');
          print('🔵 BlocBuilder - _userModifiedState: $_userModifiedState, _isUserSelecting: $_isUserSelecting');
        } else if (_estados.contains(normalizedState) && 
            normalizedState != _lastKnownTareaState &&
            normalizedState != _selectedState) {
          // El estado cambió desde el backend, actualizar
          print('🔵 BlocBuilder - Estado cambió desde backend, actualizando...');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_userModifiedState && !_isUserSelecting) {
              print('🔵 BlocBuilder - addPostFrameCallback ejecutado, actualizando estado a: "$normalizedState"');
              setState(() {
                _selectedState = normalizedState;
                _lastKnownTareaState = normalizedState;
                _pendingEvidences = List<String>.from(tarea.evidences);
              });
            } else {
              print('🔵 BlocBuilder - addPostFrameCallback NO actualiza porque _userModifiedState: $_userModifiedState, _isUserSelecting: $_isUserSelecting');
            }
          });
        } else if (!_userModifiedState && _lastKnownTareaState == null) {
          // Primera vez, inicializar el último estado conocido
          print('🔵 BlocBuilder - Primera vez, inicializando _lastKnownTareaState: "$normalizedState"');
          _lastKnownTareaState = normalizedState;
        } else {
          print('🔵 BlocBuilder - No se actualiza estado (condiciones no cumplidas)');
        }

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF1B1B1B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    
                    print('🔵 Dropdown - _selectedState original: "$_selectedState"');
                    print('🔵 Dropdown - normalizedSelected: "$normalizedSelected"');
                    print('🔵 Dropdown - validValue: "$validValue"');
                    print('🔵 Dropdown - _estados: $_estados');
                    print('🔵 Dropdown - items count: ${_estados.length}');
                    
                    // Verificar que no haya duplicados en _estados
                    final uniqueEstados = _estados.toSet().toList();
                    if (uniqueEstados.length != _estados.length) {
                      print('🔵 ERROR - Hay duplicados en _estados!');
                    }
                    
                    // Verificar que validValue esté en items
                    final itemsValues = _estados.map((e) => e).toList();
                    final matchingItems = itemsValues.where((v) => v == validValue).length;
                    print('🔵 Dropdown - Items con valor "$validValue": $matchingItems');
                    if (matchingItems != 1) {
                      print('🔵 ERROR - Debe haber exactamente 1 item con valor "$validValue", pero hay $matchingItems');
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
                    print('🔵 Dropdown item - estado: "$estado", value: "$estado"');
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
                            print('🔵 Usuario cambió el estado a: $value');
                            print('🔵 _userModifiedState: $_userModifiedState');
                            print('🔵 _lastKnownTareaState actualizado a: $_lastKnownTareaState');
                          });
                          
                          // Después de un breve delay, permitir actualizaciones del backend nuevamente
                          // pero mantener _userModifiedState = true para que no se sobrescriba
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (mounted) {
                              setState(() {
                                _isUserSelecting = false;
                              });
                              print('🔵 _isUserSelecting reseteado a false');
                            }
                          });
                        }
                      },
                    );
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Observaciones',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
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
                    color: const Color(0xFF2B2B2B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: tarea.observation != null && tarea.observation!.isNotEmpty
                      ? Text(
                          tarea.observation!,
                          style: textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        )
                      : Row(
                          children: [
                            Icon(
                              Icons.note_add_outlined,
                              size: 20,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Toca para agregar observaciones',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              // Sección de Evidencias (solo cuando el estado es "finalizado")
              if (_selectedState == 'finalizado') ...[
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Evidencias',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    if (_pendingEvidences.isNotEmpty)
                      Text(
                        '${_pendingEvidences.length}',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
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
                                        color: Colors.grey.shade800,
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: Colors.white54,
                                        ),
                                      );
                                    },
                                  )
                                : Image.file(
                                    File(evidenceUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade800,
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: Colors.white54,
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
                if (_isUploading) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subiendo evidencias...',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
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
                    // Ya no incluimos observación en canSave, se maneja por separado
                    final canSave = (hasChanges || hasEvidenceChanges || hasNewEvidences) && !_isUploading;
                    
                    print('🔵 Botón Guardar - hasChanges: $hasChanges');
                    print('🔵 Botón Guardar - hasEvidenceChanges: $hasEvidenceChanges');
                    print('🔵 Botón Guardar - hasNewEvidences: $hasNewEvidences');
                    print('🔵 Botón Guardar - canSave: $canSave');
                    print('🔵 Botón Guardar - _isUploading: $_isUploading');
                    
                    return FilledButton(
                      onPressed: canSave
                          ? () {
                              print('🔵 Botón presionado!');
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
          return ObservationModal(
            tarea: updatedTarea,
            obraId: widget.obraId,
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
    return stateChanged;
  }

  bool _hasEvidenceChanges(TareaEntity tarea) {
    // Comparar si las evidencias han cambiado
    final currentEvidences = tarea.evidences;
    
    print('🔵 _hasEvidenceChanges - currentEvidences: $currentEvidences');
    print('🔵 _hasEvidenceChanges - _pendingEvidences: $_pendingEvidences');
    
    // Si las longitudes son diferentes, hay cambios
    if (_pendingEvidences.length != currentEvidences.length) {
      print('🔵 _hasEvidenceChanges - Diferencia en longitud: ${_pendingEvidences.length} vs ${currentEvidences.length}');
      return true;
    }
    
    // Verificar si hay URLs nuevas (que empiezan con http pero no están en las originales)
    final validPendingEvidences = _pendingEvidences.where((e) => e.startsWith('http')).toList();
    final newUrls = validPendingEvidences.where((e) => !currentEvidences.contains(e)).toList();
    
    print('🔵 _hasEvidenceChanges - validPendingEvidences: $validPendingEvidences');
    print('🔵 _hasEvidenceChanges - newUrls: $newUrls');
    print('🔵 _hasEvidenceChanges - resultado: ${newUrls.isNotEmpty}');
    
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
        final validEvidences = _pendingEvidences
            .where((e) => e.startsWith('http'))
            .toList();
        print('🔵 _uploadImage - validEvidences después de subir: $validEvidences');
        print('🔵 _uploadImage - _selectedState antes: $_selectedState');
        if (validEvidences.isNotEmpty && _selectedState != 'finalizado') {
          _selectedState = 'finalizado';
          print('🔵 _uploadImage - Estado actualizado a: $_selectedState');
        }
        print('🔵 _uploadImage - _pendingEvidences final: $_pendingEvidences');
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
    
    print('🔵 _saveChanges llamado');
    final stateChanged = _selectedState != _normalizeState(tarea.state);
    // Ya no manejamos observación aquí, se maneja en el modal separado
    final evidenceChanged = _hasEvidenceChanges(tarea);
    
    print('🔵 stateChanged: $stateChanged');
    print('🔵 evidenceChanged: $evidenceChanged');
    print('🔵 _selectedState: $_selectedState');
    print('🔵 tarea.state: ${tarea.state}');
    print('🔵 _pendingEvidences: $_pendingEvidences');

    // Filtrar evidencias válidas (solo URLs)
    final validPendingEvidences = _pendingEvidences
        .where((e) => e.startsWith('http'))
        .toList();
    final hasNewEvidencesInPending = validPendingEvidences.length > tarea.evidences.length ||
        validPendingEvidences.any((e) => !tarea.evidences.contains(e));
    
    print('🔵 Resumen de cambios:');
    print('🔵 - stateChanged: $stateChanged');
    print('🔵 - hasNewEvidencesInPending: $hasNewEvidencesInPending');
    
    final currentStateNormalized = _normalizeState(tarea.state);
    final needsAutoStateUpdate = hasNewEvidencesInPending && 
                                 currentStateNormalized != 'finalizado' && 
                                 !stateChanged;
    
    print('🔵 - needsAutoStateUpdate: $needsAutoStateUpdate (evidencias nuevas + estado no finalizado + usuario no cambió estado)');
    
    // 1. Si hay evidencias nuevas, actualizar evidencias primero y ESPERAR
    if (hasNewEvidencesInPending || evidenceChanged) {
      print('🔵 1. Actualizando evidencias con UpdateTareaEvidences');
      print('🔵 Evidencias a enviar: $validPendingEvidences');
      
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
        print('🔵 1.1. Actualización de evidencias completada');
      } catch (e) {
        print('🔵 1.1. Timeout esperando evidencias: $e');
        if (!mounted) return;
      }
    }
    
    // 2. Si cambió el estado manualmente O necesita auto-actualización por evidencias
    if (stateChanged) {
      // Usuario cambió el estado manualmente
      print('🔵 2. Actualizando estado con UpdateTareaState (cambio manual)');
      print('🔵 Nuevo estado: $_selectedState');
      
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
        print('🔵 2.1. Actualización de estado completada');
      } catch (e) {
        print('🔵 2.1. Timeout esperando estado: $e');
        if (!mounted) return;
      }
    } else if (needsAutoStateUpdate) {
      // Auto-actualizar a "finalizado" solo si hay evidencias nuevas Y el usuario NO cambió el estado
      print('🔵 2. Auto-actualizando estado a "finalizado" por evidencias nuevas');
      
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
        print('🔵 2.1. Auto-actualización de estado completada');
      } catch (e) {
        print('🔵 2.1. Timeout esperando auto-estado: $e');
        if (!mounted) return;
      }
    }
    
    // 3. La observación se maneja en un modal separado, no aquí
    print('🔵 3. Observación se maneja en modal separado');

    if (mounted) {
      Navigator.pop(context);
      // Refrescar las obras para obtener los datos actualizados
      obraBloc.add(const LoadObras());
    }
  }
}
