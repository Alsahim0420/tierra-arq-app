// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/tarea_entity.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../bloc/tarea/tarea_bloc.dart';
import '../../bloc/tarea/tarea_event.dart';
import '../../bloc/tarea/tarea_state.dart';
import '../../bloc/obra/obra_bloc.dart';
import '../../bloc/obra/obra_event.dart';
import '../../../core/theme/app_colors.dart';

class CreateTareaModal extends StatefulWidget {
  const CreateTareaModal({
    super.key,
    this.obraId,
  });

  final String? obraId;

  @override
  State<CreateTareaModal> createState() => _CreateTareaModalState();
}

class _CreateTareaModalState extends State<CreateTareaModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  String _selectedState = 'pendiente';
  final List<String> _estados = ['pendiente', 'en progreso', 'finalizado', 'estancado'];
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _createTarea(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;

    setState(() {
      _isCreating = true;
    });

    // Guardar referencias antes de async
    final tareaBloc = context.read<TareaBloc>();
    final obraBloc = context.read<ObraBloc>();
    final obraId = widget.obraId;

    try {
      final duration = int.tryParse(_durationController.text.trim()) ?? 0;

      // Crear la entidad de tarea (sin ID, el backend lo asignará)
      final newTarea = TareaEntity(
        id: '', // El backend asignará el ID
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        state: _selectedState,
        duration: duration,
        evidences: [],
        obraTareaId: null, // Nueva tarea, aún no tiene obra_tarea_id
      );

      // COMENTADO: Si obraId es null o vacío, crear tarea independiente está deshabilitado
      // Las tareas deben estar asociadas a una obra
      final finalObraId = obraId ?? '';
      if (finalObraId.isEmpty) {
        throw Exception('Las tareas deben estar asociadas a una obra');
      }
      tareaBloc.add(CreateTarea(newTarea, finalObraId));

      // Esperar a que termine la creación
      // El handler emite TareaLoading primero, luego TareaLoaded o TareaError
      try {
        
        // Esperar a que el estado cambie de Loading a Loaded o Error
        // Usamos skip(1) para saltar el estado inicial y esperar el siguiente
        final newState = await tareaBloc.stream
            .skip(1) // Saltar el estado inicial (puede ser Loading o Loaded)
            .where((state) {
              return state is! TareaLoading;
            })
            .timeout(const Duration(seconds: 15))
            .first;
        
        
        if (newState is TareaError) {
          throw Exception(newState.message);
        }
        
        if (newState is TareaLoaded) {
        }
      } catch (e) {
        // Verificar el estado actual
        final currentState = tareaBloc.state;
        
        if (currentState is TareaError) {
          throw Exception(currentState.message);
        }
        // Si está en TareaLoaded, asumimos que se completó correctamente
        if (currentState is TareaLoaded) {
        } else if (e.toString().contains('TimeoutException')) {
          throw Exception('Timeout al crear tarea. Por favor, verifica tu conexión e intenta nuevamente.');
        } else {
          rethrow;
        }
      }

      if (mounted) {
        // Refrescar las obras siempre (obraId ya está validado que no es vacío)
        obraBloc.add(const LoadObras());
        // COMENTADO: No refrescar lista de tareas independientes (funcionalidad deshabilitada)
        // tareaBloc.add(LoadTareas(page: 1, limit: 10));
        Navigator.pop(context, true);
        CustomSnackBar.showSuccess(
          context,
          message: 'Tarea creada correctamente',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          message: 'Error al crear tarea: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          minHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1B1B1B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Nueva Tarea',
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
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Nombre de la tarea',
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
                            hintText: 'Ej: Excavación y movimiento de tierras',
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
                                color: AppColors.primary,
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
                          maxLines: 4,
                          style: textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Describe la tarea...',
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
                                color: AppColors.primary,
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
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estado',
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    // ignore: deprecated_member_use
                                    value: _selectedState,
                                    decoration: InputDecoration(
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
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    dropdownColor: const Color(0xFF2B2B2B),
                                    style: textTheme.bodyMedium,
                                    items: _estados.map((estado) {
                                      return DropdownMenuItem<String>(
                                        value: estado,
                                        child: Text(estado),
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
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Requerido';
                                      }
                                      final duration = int.tryParse(value.trim());
                                      if (duration == null || duration <= 0) {
                                        return 'Debe ser un número positivo';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B1B),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isCreating
                        ? null
                        : () => _createTarea(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _isCreating
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppColors.primary,
                      foregroundColor: _isCreating
                          ? Colors.white54
                          : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Crear tarea',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
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
}

