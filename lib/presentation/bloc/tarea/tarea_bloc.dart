import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/tarea_usecases.dart';
import 'tarea_event.dart';
import 'tarea_state.dart';

class TareaBloc extends Bloc<TareaEvent, TareaState> {
  final GetTareasUseCase getTareasUseCase;
  final GetTareaByIdUseCase getTareaByIdUseCase;
  final GetObraTareaByIdUseCase getObraTareaByIdUseCase;
  final GetTareasByObraUseCase getTareasByObraUseCase;
  final GetTareasByUserUseCase getTareasByUserUseCase;
  final CreateTareaUseCase createTareaUseCase;
  final UpdateTareaUseCase updateTareaUseCase;
  final UpdateTareaStateUseCase updateTareaStateUseCase;
  final UpdateTareaEvidencesUseCase updateTareaEvidencesUseCase;
  final DeleteTareaUseCase deleteTareaUseCase;

  TareaBloc({
    required this.getTareasUseCase,
    required this.getTareaByIdUseCase,
    required this.getObraTareaByIdUseCase,
    required this.getTareasByObraUseCase,
    required this.getTareasByUserUseCase,
    required this.createTareaUseCase,
    required this.updateTareaUseCase,
    required this.updateTareaStateUseCase,
    required this.updateTareaEvidencesUseCase,
    required this.deleteTareaUseCase,
  }) : super(const TareaInitial()) {
    on<LoadTareas>(_onLoadTareas);
    on<LoadTareaById>(_onLoadTareaById);
    on<LoadObraTareaById>(_onLoadObraTareaById);
    on<LoadTareasByObra>(_onLoadTareasByObra);
    on<LoadTareasByUser>(_onLoadTareasByUser);
    on<CreateTarea>(_onCreateTarea);
    on<UpdateTarea>(_onUpdateTarea);
    on<UpdateTareaState>(_onUpdateTareaState);
    on<UpdateTareaEvidences>(_onUpdateTareaEvidences);
    on<DeleteTarea>(_onDeleteTarea);
    on<SelectTarea>(_onSelectTarea);
    on<ClearSelection>(_onClearSelection);
  }

  Future<void> _onLoadTareas(
    LoadTareas event,
    Emitter<TareaState> emit,
  ) async {
    emit(const TareaLoading());
    try {
      final tareas = await getTareasUseCase(page: event.page, limit: event.limit);
      emit(TareaLoaded(tareas: tareas));
    } catch (e) {
      emit(TareaError('Error al cargar tareas: $e'));
    }
  }

  Future<void> _onLoadTareaById(
    LoadTareaById event,
    Emitter<TareaState> emit,
  ) async {
    emit(const TareaLoading());
    try {
      final tarea = await getTareaByIdUseCase(event.id);
      if (tarea != null) {
        final currentState = state;
        if (currentState is TareaLoaded) {
          emit(TareaLoaded(
            tareas: currentState.tareas,
            selectedTarea: tarea,
          ));
        } else {
          emit(TareaLoaded(tareas: [], selectedTarea: tarea));
        }
      } else {
        emit(const TareaError('Tarea no encontrada'));
      }
    } catch (e) {
      emit(TareaError('Error al cargar tarea: $e'));
    }
  }

  Future<void> _onLoadObraTareaById(
    LoadObraTareaById event,
    Emitter<TareaState> emit,
  ) async {
    emit(const TareaLoading());
    try {
      final obraTarea = await getObraTareaByIdUseCase(event.obraTareaId);
      final currentState = state;
      if (currentState is TareaLoaded) {
        emit(TareaLoaded(
          tareas: currentState.tareas,
          selectedTarea: currentState.selectedTarea,
          selectedObraTarea: obraTarea,
        ));
      } else {
        emit(TareaLoaded(tareas: [], selectedObraTarea: obraTarea));
      }
    } catch (e) {
      emit(TareaError('Error al cargar obra-tarea: $e'));
    }
  }

  Future<void> _onLoadTareasByObra(
    LoadTareasByObra event,
    Emitter<TareaState> emit,
  ) async {
    emit(const TareaLoading());
    try {
      final tareas = await getTareasByObraUseCase(event.obraId);
      emit(TareaLoaded(tareas: tareas));
    } catch (e) {
      emit(TareaError('Error al cargar tareas: $e'));
    }
  }

  Future<void> _onLoadTareasByUser(
    LoadTareasByUser event,
    Emitter<TareaState> emit,
  ) async {
    emit(const TareaLoading());
    try {
      final tareas = await getTareasByUserUseCase(event.userId);
      emit(TareaLoaded(tareas: tareas));
    } catch (e) {
      emit(TareaError('Error al cargar tareas: $e'));
    }
  }

  Future<void> _onCreateTarea(
    CreateTarea event,
    Emitter<TareaState> emit,
  ) async {
    emit(const TareaLoading());
    try {
      final tarea = await createTareaUseCase(event.tarea, event.obraId);
      final currentState = state;
      if (currentState is TareaLoaded) {
        emit(TareaLoaded(
          tareas: [...currentState.tareas, tarea],
          selectedTarea: currentState.selectedTarea,
        ));
      } else {
        emit(TareaLoaded(tareas: [tarea]));
      }
    } catch (e) {
      emit(TareaError('Error al crear tarea: $e'));
    }
  }

  Future<void> _onUpdateTarea(
    UpdateTarea event,
    Emitter<TareaState> emit,
  ) async {
    emit(const TareaLoading());
    try {
      final tarea = await updateTareaUseCase(event.tarea, event.obraId);
      final currentState = state;
      if (currentState is TareaLoaded) {
        final updatedTareas = currentState.tareas.map((t) {
          return t.id == tarea.id ? tarea : t;
        }).toList();
        emit(TareaLoaded(
          tareas: updatedTareas,
          selectedTarea: currentState.selectedTarea?.id == tarea.id
              ? tarea
              : currentState.selectedTarea,
        ));
      } else {
      // Si no hay estado cargado, crear uno nuevo con la tarea actualizada
        emit(TareaLoaded(tareas: [tarea], selectedTarea: tarea));
      }
    } catch (e) {
      emit(TareaError('Error al actualizar tarea: $e'));
    }
  }

  Future<void> _onUpdateTareaState(
    UpdateTareaState event,
    Emitter<TareaState> emit,
  ) async {
    developer.log('🔄 [TareaBloc] _onUpdateTareaState iniciado', name: 'TareaStateFlow');
    developer.log('🔄 [TareaBloc] obraId: ${event.obraId}', name: 'TareaStateFlow');
    developer.log('🔄 [TareaBloc] tareaId: ${event.tareaId}', name: 'TareaStateFlow');
    developer.log('🔄 [TareaBloc] estado: ${event.state}', name: 'TareaStateFlow');
    
    emit(const TareaLoading());
    try {
      developer.log('🔄 [TareaBloc] Llamando a updateTareaStateUseCase...', name: 'TareaStateFlow');
      final tarea = await updateTareaStateUseCase(
        event.obraId,
        event.tareaId,
        event.state,
      );
      developer.log('🔄 [TareaBloc] Tarea actualizada recibida', name: 'TareaStateFlow');
      developer.log('🔄 [TareaBloc] Tarea - id: ${tarea.id}', name: 'TareaStateFlow');
      developer.log('🔄 [TareaBloc] Tarea - state: ${tarea.state}', name: 'TareaStateFlow');
      
      final currentState = state;
      if (currentState is TareaLoaded) {
        developer.log('🔄 [TareaBloc] Estado actual es TareaLoaded con ${currentState.tareas.length} tareas', name: 'TareaStateFlow');
        final updatedTareas = currentState.tareas.map((t) {
          return t.id == tarea.id ? tarea : t;
        }).toList();
        developer.log('🔄 [TareaBloc] Emitiendo TareaLoaded con ${updatedTareas.length} tareas', name: 'TareaStateFlow');
        emit(TareaLoaded(
          tareas: updatedTareas,
          selectedTarea: currentState.selectedTarea?.id == tarea.id
              ? tarea
              : currentState.selectedTarea,
        ));
      } else {
        developer.log('🔄 [TareaBloc] Estado actual NO es TareaLoaded, creando nuevo estado', name: 'TareaStateFlow');
        emit(TareaLoaded(tareas: [tarea], selectedTarea: tarea));
      }
      developer.log('🔄 [TareaBloc] _onUpdateTareaState completado exitosamente', name: 'TareaStateFlow');
    } catch (e, stackTrace) {
      developer.log('❌ [TareaBloc] Error en _onUpdateTareaState: $e', name: 'TareaStateFlow');
      developer.log('❌ [TareaBloc] Stack trace: $stackTrace', name: 'TareaStateFlow');
      emit(TareaError('Error al actualizar estado de tarea: $e'));
    }
  }

  Future<void> _onUpdateTareaEvidences(
    UpdateTareaEvidences event,
    Emitter<TareaState> emit,
  ) async {
    emit(const TareaLoading());
    try {
      final tarea = await updateTareaEvidencesUseCase(
        event.obraId,
        event.tareaId,
        event.evidences,
      );
      final currentState = state;
      if (currentState is TareaLoaded) {
        final updatedTareas = currentState.tareas.map((t) {
          return t.id == tarea.id ? tarea : t;
        }).toList();
        emit(TareaLoaded(
          tareas: updatedTareas,
          selectedTarea: currentState.selectedTarea?.id == tarea.id
              ? tarea
              : currentState.selectedTarea,
        ));
      } else {
        // Si no hay estado cargado, crear uno nuevo con la tarea actualizada
        emit(TareaLoaded(tareas: [tarea], selectedTarea: tarea));
      }
    } catch (e) {
      emit(TareaError('Error al actualizar evidencias de tarea: $e'));
    }
  }

  Future<void> _onDeleteTarea(
    DeleteTarea event,
    Emitter<TareaState> emit,
  ) async {
    emit(const TareaLoading());
    try {
      await deleteTareaUseCase(event.id, event.obraId);
      final currentState = state;
      if (currentState is TareaLoaded) {
        final updatedTareas =
            currentState.tareas.where((t) => t.id != event.id).toList();
        emit(TareaLoaded(
          tareas: updatedTareas,
          selectedTarea: currentState.selectedTarea?.id == event.id
              ? null
              : currentState.selectedTarea,
        ));
      }
    } catch (e) {
      emit(TareaError('Error al eliminar tarea: $e'));
    }
  }

  void _onSelectTarea(
    SelectTarea event,
    Emitter<TareaState> emit,
  ) {
    final currentState = state;
    if (currentState is TareaLoaded) {
      emit(TareaLoaded(
        tareas: currentState.tareas,
        selectedTarea: event.tarea,
      ));
    }
  }

  void _onClearSelection(
    ClearSelection event,
    Emitter<TareaState> emit,
  ) {
    final currentState = state;
    if (currentState is TareaLoaded) {
      emit(TareaLoaded(
        tareas: currentState.tareas,
        selectedTarea: null,
      ));
    }
  }
}

