import '../entities/tarea_entity.dart';

/// Repository abstracto para tareas
abstract class TareaRepository {
  Future<List<TareaEntity>> getTareas();
  Future<TareaEntity?> getTareaById(String id);
  Future<List<TareaEntity>> getTareasByObra(String obraId);
  Future<List<TareaEntity>> getTareasByUser(String userId);
  Future<TareaEntity> createTarea(TareaEntity tarea, String obraId);
  Future<TareaEntity> updateTarea(TareaEntity tarea, String obraId);
  Future<void> deleteTarea(String id, String obraId);
}
