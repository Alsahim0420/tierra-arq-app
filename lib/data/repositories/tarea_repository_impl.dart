import '../../core/repositories/tarea_repository.dart';
import '../../core/datasources/tarea_datasource.dart';
import '../../core/entities/tarea_entity.dart';

/// Implementación del repository de tareas
class TareaRepositoryImpl implements TareaRepository {
  final TareaDataSource _dataSource;

  TareaRepositoryImpl(this._dataSource);

  @override
  Future<List<TareaEntity>> getTareas({int page = 1, int limit = 10}) async {
    return await _dataSource.getTareas(page: page, limit: limit);
  }

  @override
  Future<TareaEntity?> getTareaById(String id) async {
    return await _dataSource.getTareaById(id);
  }

  @override
  Future<Map<String, dynamic>> getObraTareaById(String obraTareaId) async {
    return await _dataSource.getObraTareaById(obraTareaId);
  }

  @override
  Future<List<TareaEntity>> getTareasByObra(String obraId) async {
    return await _dataSource.getTareasByObra(obraId);
  }

  @override
  Future<List<TareaEntity>> getTareasByUser(String userId) async {
    return await _dataSource.getTareasByUser(userId);
  }

  @override
  Future<TareaEntity> createTarea(TareaEntity tarea, String obraId) async {
    return await _dataSource.createTarea(tarea, obraId);
  }

  @override
  Future<TareaEntity> updateTarea(TareaEntity tarea, String obraId) async {
    return await _dataSource.updateTarea(tarea, obraId);
  }

  @override
  Future<TareaEntity> updateTareaState(
    String obraId,
    String tareaId,
    String state,
  ) async {
    return await _dataSource.updateTareaState(obraId, tareaId, state);
  }

  @override
  Future<TareaEntity> updateTareaEvidences(
    String obraId,
    String tareaId,
    List<String> evidences,
  ) async {
    return await _dataSource.updateTareaEvidences(obraId, tareaId, evidences);
  }

  @override
  Future<void> deleteTarea(String id, String obraId) async {
    return await _dataSource.deleteTarea(id, obraId);
  }
}

