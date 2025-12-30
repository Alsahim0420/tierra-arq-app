import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/obra_usecases.dart';
import 'obra_event.dart';
import 'obra_state.dart';

class ObraBloc extends Bloc<ObraEvent, ObraState> {
  final GetObrasUseCase getObrasUseCase;
  final GetObraByIdUseCase getObraByIdUseCase;
  final GetObrasByResponsableUseCase getObrasByResponsableUseCase;
  final CreateObraUseCase createObraUseCase;
  final UpdateObraUseCase updateObraUseCase;
  final DeleteObraUseCase deleteObraUseCase;

  ObraBloc({
    required this.getObrasUseCase,
    required this.getObraByIdUseCase,
    required this.getObrasByResponsableUseCase,
    required this.createObraUseCase,
    required this.updateObraUseCase,
    required this.deleteObraUseCase,
  }) : super(const ObraInitial()) {
    on<LoadObras>(_onLoadObras);
    on<LoadObraById>(_onLoadObraById);
    on<LoadObrasByResponsable>(_onLoadObrasByResponsable);
    on<CreateObra>(_onCreateObra);
    on<UpdateObra>(_onUpdateObra);
    on<DeleteObra>(_onDeleteObra);
    on<SelectObra>(_onSelectObra);
    on<ClearSelection>(_onClearSelection);
  }

  Future<void> _onLoadObras(
    LoadObras event,
    Emitter<ObraState> emit,
  ) async {
    emit(const ObraLoading());
    try {
      final obras = await getObrasUseCase();
      emit(ObraLoaded(obras: obras));
    } catch (e) {
      emit(ObraError('Error al cargar obras: $e'));
    }
  }

  Future<void> _onLoadObraById(
    LoadObraById event,
    Emitter<ObraState> emit,
  ) async {
    emit(const ObraLoading());
    try {
      final obra = await getObraByIdUseCase(event.id);
      if (obra != null) {
        final currentState = state;
        if (currentState is ObraLoaded) {
          emit(ObraLoaded(
            obras: currentState.obras,
            selectedObra: obra,
          ));
        } else {
          emit(ObraLoaded(obras: [], selectedObra: obra));
        }
      } else {
        emit(const ObraError('Obra no encontrada'));
      }
    } catch (e) {
      emit(ObraError('Error al cargar obra: $e'));
    }
  }

  Future<void> _onLoadObrasByResponsable(
    LoadObrasByResponsable event,
    Emitter<ObraState> emit,
  ) async {
    emit(const ObraLoading());
    try {
      final obras = await getObrasByResponsableUseCase(event.userId);
      emit(ObraLoaded(obras: obras));
    } catch (e) {
      emit(ObraError('Error al cargar obras: $e'));
    }
  }

  Future<void> _onCreateObra(
    CreateObra event,
    Emitter<ObraState> emit,
  ) async {
    emit(const ObraLoading());
    try {
      final obra = await createObraUseCase(event.obra);
      final currentState = state;
      if (currentState is ObraLoaded) {
        emit(ObraLoaded(
          obras: [...currentState.obras, obra],
          selectedObra: currentState.selectedObra,
        ));
      } else {
        emit(ObraLoaded(obras: [obra]));
      }
    } catch (e) {
      emit(ObraError('Error al crear obra: $e'));
    }
  }

  Future<void> _onUpdateObra(
    UpdateObra event,
    Emitter<ObraState> emit,
  ) async {
    emit(const ObraLoading());
    try {
      final obra = await updateObraUseCase(event.obra);
      final currentState = state;
      if (currentState is ObraLoaded) {
        final updatedObras = currentState.obras.map((o) {
          return o.id == obra.id ? obra : o;
        }).toList();
        emit(ObraLoaded(
          obras: updatedObras,
          selectedObra: currentState.selectedObra?.id == obra.id
              ? obra
              : currentState.selectedObra,
        ));
      }
    } catch (e) {
      emit(ObraError('Error al actualizar obra: $e'));
    }
  }

  Future<void> _onDeleteObra(
    DeleteObra event,
    Emitter<ObraState> emit,
  ) async {
    emit(const ObraLoading());
    try {
      await deleteObraUseCase(event.id);
      final currentState = state;
      if (currentState is ObraLoaded) {
        final updatedObras =
            currentState.obras.where((o) => o.id != event.id).toList();
        emit(ObraLoaded(
          obras: updatedObras,
          selectedObra: currentState.selectedObra?.id == event.id
              ? null
              : currentState.selectedObra,
        ));
      }
    } catch (e) {
      emit(ObraError('Error al eliminar obra: $e'));
    }
  }

  void _onSelectObra(
    SelectObra event,
    Emitter<ObraState> emit,
  ) {
    final currentState = state;
    if (currentState is ObraLoaded) {
      emit(ObraLoaded(
        obras: currentState.obras,
        selectedObra: event.obra,
      ));
    }
  }

  void _onClearSelection(
    ClearSelection event,
    Emitter<ObraState> emit,
  ) {
    final currentState = state;
    if (currentState is ObraLoaded) {
      emit(ObraLoaded(
        obras: currentState.obras,
        selectedObra: null,
      ));
    }
  }
}

