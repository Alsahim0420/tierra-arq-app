import 'dart:io';
import '../entities/obra_entity.dart';

/// Repository abstracto para obras
abstract class ObraRepository {
  Future<List<ObraEntity>> getObras();
  Future<List<ObraEntity>> getObrasFinalizadas({int page = 1, int limit = 10});
  // Future<ObraEntity?> getObraById(String id);
  Future<List<ObraEntity>> getObrasByResponsable(String userId);
  Future<ObraEntity> createObra(ObraEntity obra);
  Future<ObraEntity> updateObra(ObraEntity obra);
  Future<void> deleteObra(String id);
  
  /// Procesa un documento y crea una obra con sus tareas
  Future<ObraEntity> processDocument(File file);
  
  /// Actualiza los estados de todas las obras basándose en el estado de sus tareas
  /// Retorna un mapa con las estadísticas: {total, actualizadas, noActualizadas}
  Future<Map<String, int>> updateObrasEstados();
}
