import 'package:equatable/equatable.dart';
import '../../../core/entities/tarea_entity.dart';

abstract class TareaEvent extends Equatable {
  const TareaEvent();

  @override
  List<Object?> get props => [];
}

class LoadTareas extends TareaEvent {
  const LoadTareas();
}

class LoadTareaById extends TareaEvent {
  final String id;

  const LoadTareaById(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadTareasByObra extends TareaEvent {
  final String obraId;

  const LoadTareasByObra(this.obraId);

  @override
  List<Object?> get props => [obraId];
}

class LoadTareasByUser extends TareaEvent {
  final String userId;

  const LoadTareasByUser(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CreateTarea extends TareaEvent {
  final TareaEntity tarea;
  final String obraId;

  const CreateTarea(this.tarea, this.obraId);

  @override
  List<Object?> get props => [tarea, obraId];
}

class UpdateTarea extends TareaEvent {
  final TareaEntity tarea;
  final String obraId;

  const UpdateTarea(this.tarea, this.obraId);

  @override
  List<Object?> get props => [tarea, obraId];
}

class DeleteTarea extends TareaEvent {
  final String id;
  final String obraId;

  const DeleteTarea(this.id, this.obraId);

  @override
  List<Object?> get props => [id, obraId];
}

class SelectTarea extends TareaEvent {
  final TareaEntity tarea;

  const SelectTarea(this.tarea);

  @override
  List<Object?> get props => [tarea];
}

class ClearSelection extends TareaEvent {
  const ClearSelection();
}

