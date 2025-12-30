import '../../core/repositories/tarea_repository.dart';
import '../../core/datasources/tarea_datasource.dart';
import '../../core/entities/tarea_entity.dart';

/// Implementación del repository de tareas
class TareaRepositoryImpl implements TareaRepository {
  final TareaDataSource _dataSource;

  TareaRepositoryImpl(this._dataSource);

  @override
  Future<List<TareaEntity>> getTareas() async {
    return await _dataSource.getTareas();
  }

  @override
  Future<TareaEntity?> getTareaById(String id) async {
    return await _dataSource.getTareaById(id);
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
  Future<void> deleteTarea(String id, String obraId) async {
    return await _dataSource.deleteTarea(id, obraId);
  }
}

