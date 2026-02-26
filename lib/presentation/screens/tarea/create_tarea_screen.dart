// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/tarea_entity.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/injection/injection_container.dart' as di;
import '../../../domain/usecases/tarea_usecases.dart';
import '../../bloc/tarea/tarea_bloc.dart';
import '../../bloc/tarea/tarea_event.dart';
import '../../../core/theme/app_colors.dart';
import '../../utils/format_utils.dart';

class CreateTareaScreen extends StatefulWidget {
  const CreateTareaScreen({super.key, this.tarea});

  final TareaEntity? tarea;

  @override
  State<CreateTareaScreen> createState() => _CreateTareaScreenState();
}

class _CreateTareaScreenState extends State<CreateTareaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  late TextEditingController _observationController;
  late String _selectedState;
  final List<String> _estados = ['pendiente', 'en progreso', 'finalizado', 'estancado'];
  bool _isCreating = false;
  bool _isEditing = false;
  TareaEntity? _createdTarea;
  TareaEntity? _editedTarea;

  bool get _isEditMode => widget.tarea != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tarea?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.tarea?.description ?? '',
    );
    _durationController = TextEditingController(
      text: widget.tarea?.duration.toString() ?? '',
    );
    _observationController = TextEditingController(
      text: widget.tarea?.observation ?? '',
    );
    _selectedState = widget.tarea != null
        ? FormatUtils.formatStateText(widget.tarea!.state)
        : 'pendiente';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _saveTarea() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;

    setState(() {
      if (_isEditMode) {
        _isEditing = true;
      } else {
        _isCreating = true;
      }
    });

    final createTareaUseCase = di.getIt<CreateTareaUseCase>();
    final updateTareaUseCase = di.getIt<UpdateTareaUseCase>();

    try {
      final duration = int.tryParse(_durationController.text.trim()) ?? 0;

      if (_isEditMode && widget.tarea != null) {
        // Modo edición
        final updatedTarea = TareaEntity(
          id: widget.tarea!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          state: _selectedState,
          duration: duration,
          evidences: widget.tarea!.evidences,
          obraTareaId: widget.tarea!.obraTareaId,
          observation: _observationController.text.trim().isEmpty
              ? null
              : _observationController.text.trim(),
        );

        final savedTarea = await updateTareaUseCase.call(updatedTarea, '');

        // Actualizar el Bloc para mantener consistencia
        final tareaBloc = context.read<TareaBloc>();
        tareaBloc.add(UpdateTarea(savedTarea, ''));

        if (mounted) {
          setState(() {
            _editedTarea = savedTarea;
            _isEditing = false;
          });

          CustomSnackBar.showSuccess(
            context,
            message: 'Tarea actualizada correctamente',
          );
        }
      } else {
        // Modo creación
        final newTarea = TareaEntity(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          state: _selectedState,
          duration: duration,
          evidences: [],
          obraTareaId: null,
          observation: _observationController.text.trim().isEmpty
              ? null
              : _observationController.text.trim(),
        );

        final createdTarea = await createTareaUseCase.call(newTarea, '');

        // Verificar que se creó la tarea correctamente
        if (createdTarea.id.isEmpty) {
          throw Exception('No se pudo obtener el ID de la tarea creada');
        }

        // Actualizar el Bloc para mantener consistencia
        final tareaBloc = context.read<TareaBloc>();
        tareaBloc.add(CreateTarea(createdTarea, ''));

        if (mounted) {
          setState(() {
            _createdTarea = createdTarea;
            _isCreating = false;
          });

          CustomSnackBar.showSuccess(
            context,
            message: 'Tarea creada correctamente',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _isEditing = false;
        });

        CustomSnackBar.showError(context, message: 'Error: $e');
      }
    }
  }

  Future<void> _editTarea() async {
    if (!_formKey.currentState!.validate()) return;
    await _saveTarea();
  }

  void _goBack() {
    final tareaToReturn = _isEditMode ? _editedTarea : _createdTarea;
    Navigator.pop(context, tareaToReturn ?? widget.tarea);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tareaToShow = _isEditMode ? _editedTarea : _createdTarea;
    // Mostrar formulario si:
    // - No hay tarea guardada para mostrar (ni creada ni editada)
    // En modo edición: mostrar formulario con datos originales, luego mostrar vista después de guardar
    // En modo creación: mostrar formulario vacío, luego mostrar vista después de guardar
    final showForm = tareaToShow == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Editar Tarea' : 'Nueva Tarea',
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: AppColors.appBarColor(isDark),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Builder(
                  builder: (context) {
                    if (showForm) {
                      return _buildForm(context, textTheme, isDark);
                    } else {
                      final tarea = _isEditMode ? _editedTarea : _createdTarea;
                      if (tarea != null) {
                        return _buildTareaView(
                          context,
                          textTheme,
                          isDark,
                          tarea,
                        );
                      } else {
                        // Fallback: mostrar formulario si por alguna razón tareaToShow es null
                        return _buildForm(context, textTheme, isDark);
                      }
                    }
                  },
                ),
              ),
            ),
            // Botón Guardar - Solo se muestra cuando se visualiza la tarea creada (pantallazo 2)
            if (!showForm)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B1B1B) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _goBack,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Guardar',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
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

  Widget _buildForm(BuildContext context, TextTheme textTheme, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre
          Text(
            'Nombre *',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            enabled: !_isCreating && !_isEditing,
            style: textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Ej: Instalación eléctrica',
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF2B2B2B)
                  : Colors.grey.shade100,
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
                borderSide: BorderSide(color: AppColors.primary, width: 2),
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
          const SizedBox(height: 20),
          // Descripción
          Text(
            'Descripción *',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            enabled: !_isCreating && !_isEditing,
            maxLines: 3,
            style: textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Describe la tarea...',
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF2B2B2B)
                  : Colors.grey.shade100,
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
                borderSide: BorderSide(color: AppColors.primary, width: 2),
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
          const SizedBox(height: 20),
          // Duración
          Text(
            'Duración (días) *',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _durationController,
            enabled: !_isCreating && !_isEditing,
            keyboardType: TextInputType.number,
            style: textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: '5',
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF2B2B2B)
                  : Colors.grey.shade100,
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
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Requerido';
              }
              final duration = int.tryParse(value.trim());
              if (duration == null || duration <= 0) {
                return 'Debe ser positivo';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          // Estado
          Text(
            'Estado',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _selectedState,
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF2B2B2B)
                  : Colors.grey.shade100,
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
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            dropdownColor: isDark ? const Color(0xFF2B2B2B) : Colors.white,
            style: textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white : Colors.black87,
            ),
            items: _estados.map((estado) {
              return DropdownMenuItem<String>(
                value: estado,
                child: Text(estado),
              );
            }).toList(),
            onChanged: (_isCreating || _isEditing)
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        _selectedState = value;
                      });
                    }
                  },
          ),
          const SizedBox(height: 20),
          // Observación
          Text(
            'Observación',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _observationController,
            enabled: !_isCreating && !_isEditing,
            maxLines: 2,
            style: textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Observaciones adicionales...',
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF2B2B2B)
                  : Colors.grey.shade100,
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
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),
          // Botón Crear/Actualizar Tarea
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_isCreating || _isEditing)
                  ? null
                  : (_isEditMode ? _editTarea : _saveTarea),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: (_isCreating || _isEditing)
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isEditMode ? 'Actualizar Tarea' : 'Crear Tarea',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTareaView(
    BuildContext context,
    TextTheme textTheme,
    bool isDark,
    TareaEntity tarea,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Row(
          children: [
            Expanded(
              child: Text(
                tarea.name,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            // Icono de editar
            IconButton(
              icon: Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: _isEditing
                  ? null
                  : () {
                      setState(() {
                        _createdTarea = null;
                        _editedTarea = null;
                      });
                    },
              tooltip: 'Editar tarea',
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Descripción
        if (tarea.description.isNotEmpty) ...[
          Text(
            'Descripción',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2B2B2B) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tarea.description,
              style: textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        // Información adicional
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                context,
                textTheme,
                isDark,
                'Estado',
                FormatUtils.formatStateText(tarea.state),
                FormatUtils.getStateColor(tarea.state),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                context,
                textTheme,
                isDark,
                'Duración',
                '${tarea.duration} días',
                Colors.blue,
              ),
            ),
          ],
        ),
        // Observación
        if (tarea.observation != null && tarea.observation!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Observación',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2B2B2B) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tarea.observation!,
              style: textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    TextTheme textTheme,
    bool isDark,
    String label,
    String value,
    Color valueColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2B2B) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
