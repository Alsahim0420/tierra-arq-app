import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/tarea_entity.dart';
import '../../bloc/tarea/tarea_bloc.dart';
import '../../bloc/tarea/tarea_event.dart';
import '../../bloc/tarea/tarea_state.dart';
import '../../bloc/obra/obra_bloc.dart';
import '../../bloc/obra/obra_event.dart';
import '../../bloc/obra/obra_state.dart';
import '../../app/app.dart';

class ObservationModal extends StatefulWidget {
  const ObservationModal({
    super.key,
    required this.tarea,
    required this.obraId,
  });

  final TareaEntity tarea;
  final String obraId;

  @override
  State<ObservationModal> createState() => _ObservationModalState();
}

class _ObservationModalState extends State<ObservationModal> {
  late TextEditingController _observationController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _observationController = TextEditingController(
      text: widget.tarea.observation ?? '',
    );
  }

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _saveObservation(BuildContext context) async {
    if (!mounted) return;

    final observationText = _observationController.text.trim();
    final currentObservation = (widget.tarea.observation ?? '').trim();
    
    // Si no hay cambios, solo cerrar
    if (observationText == currentObservation) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final tareaBloc = context.read<TareaBloc>();
      final obraBloc = context.read<ObraBloc>();
      final obraId = widget.obraId;

      // Obtener la tarea más reciente del BLoC
      final obraState = obraBloc.state;
      TareaEntity latestTarea = widget.tarea;
      
      if (obraState is ObraLoaded) {
        try {
          final obra = obraState.obras.firstWhere(
            (o) => o.id == obraId,
          );
          latestTarea = obra.tareas.firstWhere(
            (t) => t.id == widget.tarea.id,
            orElse: () => widget.tarea,
          );
        } catch (e) {
          // Si no se encuentra, usar la tarea original
        }
      }

      final observationValue = observationText.isEmpty ? null : observationText;

      final updatedTarea = TareaEntity(
        id: latestTarea.id,
        name: latestTarea.name,
        description: latestTarea.description,
        evidences: latestTarea.evidences,
        state: latestTarea.state,
        duration: latestTarea.duration,
        assignedTo: latestTarea.assignedTo,
        observation: observationValue,
      );

      print('🔵 ObservationModal - Guardando observación: ${observationValue != null ? '"$observationValue"' : 'null'}');

      tareaBloc.add(
        UpdateTarea(updatedTarea, obraId),
      );

      // Esperar a que termine la actualización
      // El problema es que el stream puede no emitir si el estado no cambia
      // Vamos a esperar de forma más simple: esperar a que pase por Loading y luego a Loaded o Error
      try {
        final initialState = tareaBloc.state;
        print('🔵 ObservationModal - Estado inicial del BLoC: ${initialState.runtimeType}');
        
        // Esperar a que el estado cambie de Loading a Loaded o Error
        // Usamos skip(1) para saltar el estado inicial y esperar el siguiente
        await tareaBloc.stream
            .skip(1) // Saltar el estado inicial (puede ser Loading o Loaded)
            .where((state) => state is! TareaLoading) // Esperar que no esté en Loading
            .timeout(const Duration(seconds: 15))
            .first;
        print('🔵 ObservationModal - Observación guardada correctamente');
      } catch (e) {
        print('🔵 ObservationModal - Timeout o error esperando observación: $e');
        // Verificar el estado actual
        final currentState = tareaBloc.state;
        print('🔵 ObservationModal - Estado actual después del timeout: ${currentState.runtimeType}');
        if (currentState is TareaError) {
          print('🔵 ObservationModal - Error en el estado: ${currentState.message}');
          throw Exception(currentState.message);
        }
        // Si está en TareaLoaded, asumimos que se completó correctamente
        if (currentState is TareaLoaded) {
          print('🔵 ObservationModal - Estado es TareaLoaded, asumiendo éxito');
        }
      }

      if (mounted) {
        // Refrescar las obras para obtener los datos actualizados
        obraBloc.add(const LoadObras());
        
        Navigator.pop(context, true); // Retornar true para indicar que se guardó
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Observación guardada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('🔵 ObservationModal - Error al guardar observación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar observación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        minHeight: MediaQuery.of(context).size.height * 0.4,
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
            // Handle bar
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
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Observaciones',
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
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tarea: ${widget.tarea.name}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Agregar o editar observaciones',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _observationController,
                      maxLines: 10,
                      minLines: 5,
                      style: textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Escribe tus observaciones aquí...',
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
                    ),
                  ],
                ),
              ),
            ),
            // Footer with save button
            Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
              ),
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
                  onPressed: _isSaving
                      ? null
                      : () => _saveObservation(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _isSaving
                        ? Colors.white.withValues(alpha: 0.1)
                        : TierraApp.primary,
                    foregroundColor: _isSaving
                        ? Colors.white54
                        : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Guardar observación',
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
    );
  }
}

