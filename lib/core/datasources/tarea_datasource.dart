import '../entities/tarea_entity.dart';

/// Datasource abstracto para tareas
abstract class TareaDataSource {
  Future<List<TareaEntity>> getTareas({int page = 1, int limit = 10});
  Future<TareaEntity?> getTareaById(String id);
  Future<Map<String, dynamic>> getObraTareaById(String obraTareaId);
  Future<List<TareaEntity>> getTareasByObra(String obraId);
  Future<List<TareaEntity>> getTareasByUser(String userId);
  Future<TareaEntity> createTarea(TareaEntity tarea, String obraId);
  Future<TareaEntity> updateTarea(TareaEntity tarea, String obraId);
  Future<TareaEntity> updateTareaState(String obraId, String tareaId, String state);
  Future<TareaEntity> updateTareaEvidences(String obraId, String tareaId, List<String> evidences);
  Future<void> deleteTarea(String id, String obraId);
}
