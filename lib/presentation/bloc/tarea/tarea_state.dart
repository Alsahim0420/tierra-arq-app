import 'package:equatable/equatable.dart';
import '../../../core/entities/tarea_entity.dart';

abstract class TareaState extends Equatable {
  const TareaState();

  @override
  List<Object?> get props => [];
}

class TareaInitial extends TareaState {
  const TareaInitial();
}

class TareaLoading extends TareaState {
  const TareaLoading();
}

class TareaLoaded extends TareaState {
  final List<TareaEntity> tareas;
  final TareaEntity? selectedTarea;
  final Map<String, dynamic>? selectedObraTarea;

  const TareaLoaded({
    required this.tareas,
    this.selectedTarea,
    this.selectedObraTarea,
  });

  @override
  List<Object?> get props => [tareas, selectedTarea, selectedObraTarea];
}

class TareaError extends TareaState {
  final String message;

  const TareaError(this.message);

  @override
  List<Object?> get props => [message];
}

