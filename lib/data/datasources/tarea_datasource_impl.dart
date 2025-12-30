import '../../core/datasources/tarea_datasource.dart';
import '../../core/entities/tarea_entity.dart';

/// Implementación concreta del datasource de tareas (mock por ahora)
class TareaDataSourceImpl implements TareaDataSource {
  final List<TareaEntity> _tareas = [];
  final Map<String, List<String>> _obraTareas = {}; // obraId -> [tareaIds]

  @override
  Future<List<TareaEntity>> getTareas() async {
    return List.from(_tareas);
  }

  @override
  Future<TareaEntity?> getTareaById(String id) async {
    try {
      return _tareas.firstWhere((tarea) => tarea.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<TareaEntity>> getTareasByObra(String obraId) async {
    final tareaIds = _obraTareas[obraId] ?? [];
    return _tareas.where((t) => tareaIds.contains(t.id)).toList();
  }

  @override
  Future<List<TareaEntity>> getTareasByUser(String userId) async {
    return _tareas
        .where((tarea) => tarea.assignedTo?.id == userId)
        .toList();
  }

  @override
  Future<TareaEntity> createTarea(TareaEntity tarea, String obraId) async {
    _tareas.add(tarea);
    _obraTareas.putIfAbsent(obraId, () => []).add(tarea.id);
    return tarea;
  }

  @override
  Future<TareaEntity> updateTarea(TareaEntity tarea, String obraId) async {
    final index = _tareas.indexWhere((t) => t.id == tarea.id);
    if (index != -1) {
      _tareas[index] = tarea;
    }
    return tarea;
  }

  @override
  Future<void> deleteTarea(String id, String obraId) async {
    _tareas.removeWhere((tarea) => tarea.id == id);
    _obraTareas[obraId]?.remove(id);
  }
}

