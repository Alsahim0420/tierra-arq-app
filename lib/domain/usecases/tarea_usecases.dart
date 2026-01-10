import '../../core/repositories/tarea_repository.dart';
import '../../core/entities/tarea_entity.dart';

/// Use case para obtener todas las tareas
class GetTareasUseCase {
  final TareaRepository _repository;

  GetTareasUseCase(this._repository);

  Future<List<TareaEntity>> call() async {
    return await _repository.getTareas();
  }
}

/// Use case para obtener una tarea por ID
class GetTareaByIdUseCase {
  final TareaRepository _repository;

  GetTareaByIdUseCase(this._repository);

  Future<TareaEntity?> call(String id) async {
    return await _repository.getTareaById(id);
  }
}

/// Use case para obtener tareas por obra
class GetTareasByObraUseCase {
  final TareaRepository _repository;

  GetTareasByObraUseCase(this._repository);

  Future<List<TareaEntity>> call(String obraId) async {
    return await _repository.getTareasByObra(obraId);
  }
}

/// Use case para obtener tareas por usuario
class GetTareasByUserUseCase {
  final TareaRepository _repository;

  GetTareasByUserUseCase(this._repository);

  Future<List<TareaEntity>> call(String userId) async {
    return await _repository.getTareasByUser(userId);
  }
}

/// Use case para crear una tarea
class CreateTareaUseCase {
  final TareaRepository _repository;

  CreateTareaUseCase(this._repository);

  Future<TareaEntity> call(TareaEntity tarea, String obraId) async {
    return await _repository.createTarea(tarea, obraId);
  }
}

/// Use case para actualizar una tarea
class UpdateTareaUseCase {
  final TareaRepository _repository;

  UpdateTareaUseCase(this._repository);

  Future<TareaEntity> call(TareaEntity tarea, String obraId) async {
    return await _repository.updateTarea(tarea, obraId);
  }
}

/// Use case para actualizar el estado de una tarea
class UpdateTareaStateUseCase {
  final TareaRepository _repository;

  UpdateTareaStateUseCase(this._repository);

  Future<TareaEntity> call(String obraId, String tareaId, String state) async {
    return await _repository.updateTareaState(obraId, tareaId, state);
  }
}

/// Use case para actualizar las evidencias de una tarea
class UpdateTareaEvidencesUseCase {
  final TareaRepository _repository;

  UpdateTareaEvidencesUseCase(this._repository);

  Future<TareaEntity> call(String obraId, String tareaId, List<String> evidences) async {
    return await _repository.updateTareaEvidences(obraId, tareaId, evidences);
  }
}

/// Use case para eliminar una tarea
class DeleteTareaUseCase {
  final TareaRepository _repository;

  DeleteTareaUseCase(this._repository);

  Future<void> call(String id, String obraId) async {
    return await _repository.deleteTarea(id, obraId);
  }
}

