import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/obra_usecases.dart';
import '../../../core/entities/obra_entity.dart';
import 'obra_event.dart';
import 'obra_state.dart';

class ObraBloc extends Bloc<ObraEvent, ObraState> {
  final GetObrasUseCase getObrasUseCase;
  final GetObrasFinalizadasUseCase getObrasFinalizadasUseCase;
  final GetObrasByResponsableUseCase getObrasByResponsableUseCase;
  final CreateObraUseCase createObraUseCase;
  final UpdateObraUseCase updateObraUseCase;
  final DeleteObraUseCase deleteObraUseCase;

  ObraBloc({
    required this.getObrasUseCase,
    required this.getObrasFinalizadasUseCase,
    required this.getObrasByResponsableUseCase,
    required this.createObraUseCase,
    required this.updateObraUseCase,
    required this.deleteObraUseCase,
  }) : super(const ObraInitial()) {
    on<LoadObras>(_onLoadObras);
    on<LoadObrasFinalizadas>(_onLoadObrasFinalizadas);
    on<LoadObrasByResponsable>(_onLoadObrasByResponsable);
    on<CreateObra>(_onCreateObra);
    on<UpdateObra>(_onUpdateObra);
    on<DeleteObra>(_onDeleteObra);
    on<SelectObra>(_onSelectObra);
    on<ClearSelection>(_onClearSelection);
  }

  Future<void> _onLoadObras(LoadObras event, Emitter<ObraState> emit) async {
    emit(const ObrasActivasLoading());
    try {
      final obras = await getObrasUseCase();
      
      // Deduplicar obras por ID para evitar duplicados
      final deduplicatedObras = <String, ObraEntity>{};
      for (final obra in obras) {
        if (obra.id.isNotEmpty) {
          // Si ya existe una obra con el mismo ID, mantener la primera
          if (!deduplicatedObras.containsKey(obra.id)) {
            deduplicatedObras[obra.id] = obra;
          }
        }
      }
      final uniqueObras = deduplicatedObras.values.toList();
      emit(ObraLoaded(obras: uniqueObras));
    } catch (e) {
      emit(ObraError('Error al cargar obras: $e'));
    }
  }

  Future<void> _onLoadObrasFinalizadas(
    LoadObrasFinalizadas event,
    Emitter<ObraState> emit,
  ) async {
    emit(const ObrasFinalizadasLoading());
    try {
      final obras = await getObrasFinalizadasUseCase.call(page: 1, limit: 10);
      // Deduplicar obras por ID para evitar duplicados
      final deduplicatedObras = <String, ObraEntity>{};
      for (final obra in obras) {
        if (obra.id.isNotEmpty) {
          // Si ya existe una obra con el mismo ID, mantener la primera
          if (!deduplicatedObras.containsKey(obra.id)) {
            deduplicatedObras[obra.id] = obra;
          }
        }
      }
      final uniqueObras = deduplicatedObras.values.toList();
      emit(ObrasFinalizadasLoaded(obras: uniqueObras));
    } catch (e) {
      emit(ObraError('Error al cargar obras finalizadas: $e'));
    }
  }

  Future<void> _onLoadObrasByResponsable(
    LoadObrasByResponsable event,
    Emitter<ObraState> emit,
  ) async {
    emit(const ObrasActivasLoading());
    try {
      final obras = await getObrasByResponsableUseCase(event.userId);
      // Deduplicar obras por ID para evitar duplicados
      final deduplicatedObras = <String, ObraEntity>{};
      for (final obra in obras) {
        if (obra.id.isNotEmpty) {
          // Si ya existe una obra con el mismo ID, mantener la primera
          if (!deduplicatedObras.containsKey(obra.id)) {
            deduplicatedObras[obra.id] = obra;
          }
        }
      }
      final uniqueObras = deduplicatedObras.values.toList();
      emit(ObraLoaded(obras: uniqueObras));
    } catch (e) {
      emit(ObraError('Error al cargar obras: $e'));
    }
  }

  Future<void> _onCreateObra(CreateObra event, Emitter<ObraState> emit) async {
    // Obtener el estado actual ANTES de emitir loading
    final previousState = state;
    // Si hay un estado previo con obras activas, usar loading específico
    if (previousState is ObraLoaded) {
      emit(const ObrasActivasLoading());
    } else {
      emit(const ObraLoading());
    }
    try {
      final obra = await createObraUseCase(event.obra);
      
      if (previousState is ObraLoaded) {
        // Verificar si la obra ya existe en la lista para evitar duplicados
        final obraExists = previousState.obras.any((o) => o.id == obra.id);
        if (obraExists) {
          // Si ya existe, actualizar en lugar de agregar
          final updatedObras = previousState.obras.map((o) {
            return o.id == obra.id ? obra : o;
          }).toList();
          emit(
            ObraLoaded(
              obras: updatedObras,
              selectedObra: previousState.selectedObra,
            ),
          );
        } else {
          // Si no existe, agregar
          emit(
            ObraLoaded(
              obras: [...previousState.obras, obra],
              selectedObra: previousState.selectedObra,
            ),
          );
        }
      } else {
        // Si no había estado previo con obras, crear nuevo estado con la obra creada
        emit(ObraLoaded(obras: [obra]));
      }
    } catch (e) {
      emit(ObraError('Error al crear obra: $e'));
    }
  }

  Future<void> _onUpdateObra(UpdateObra event, Emitter<ObraState> emit) async {
    final currentState = state;
    // Usar loading específico según el estado actual
    if (currentState is ObraLoaded) {
      emit(const ObrasActivasLoading());
    } else if (currentState is ObrasFinalizadasLoaded) {
      emit(const ObrasFinalizadasLoading());
    } else {
      emit(const ObraLoading());
    }
    try {
      final obra = await updateObraUseCase(event.obra);
      // Actualizar según el estado original
      if (currentState is ObraLoaded) {
        final updatedObras = currentState.obras.map((o) {
          return o.id == obra.id ? obra : o;
        }).toList();
        emit(
          ObraLoaded(
            obras: updatedObras,
            selectedObra: currentState.selectedObra?.id == obra.id
                ? obra
                : currentState.selectedObra,
          ),
        );
      } else if (currentState is ObrasFinalizadasLoaded) {
        final updatedObras = currentState.obras.map((o) {
          return o.id == obra.id ? obra : o;
        }).toList();
        emit(ObrasFinalizadasLoaded(obras: updatedObras));
      } else {
        // Si no había estado previo, crear nuevo estado con la obra actualizada
        emit(ObraLoaded(obras: [obra]));
      }
    } catch (e) {
      emit(ObraError('Error al actualizar obra: $e'));
    }
  }

  Future<void> _onDeleteObra(DeleteObra event, Emitter<ObraState> emit) async {
    emit(const ObraLoading());
    try {
      await deleteObraUseCase(event.id);
      final currentState = state;
      if (currentState is ObraLoaded) {
        final updatedObras = currentState.obras
            .where((o) => o.id != event.id)
            .toList();
        emit(
          ObraLoaded(
            obras: updatedObras,
            selectedObra: currentState.selectedObra?.id == event.id
                ? null
                : currentState.selectedObra,
          ),
        );
      }
    } catch (e) {
      emit(ObraError('Error al eliminar obra: $e'));
    }
  }

  void _onSelectObra(SelectObra event, Emitter<ObraState> emit) {
    final currentState = state;
    if (currentState is ObraLoaded) {
      emit(ObraLoaded(obras: currentState.obras, selectedObra: event.obra));
    }
  }

  void _onClearSelection(ClearSelection event, Emitter<ObraState> emit) {
    final currentState = state;
    if (currentState is ObraLoaded) {
      emit(ObraLoaded(obras: currentState.obras, selectedObra: null));
    }
  }
}
