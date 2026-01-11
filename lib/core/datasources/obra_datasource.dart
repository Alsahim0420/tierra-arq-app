import '../entities/obra_entity.dart';

/// Datasource abstracto para obras
abstract class ObraDataSource {
  Future<List<ObraEntity>> getObras();
  Future<List<ObraEntity>> getObrasFinalizadas({int page = 1, int limit = 10});

  Future<List<ObraEntity>> getObrasByResponsable(String userId);
  Future<ObraEntity> createObra(ObraEntity obra);
  Future<ObraEntity> updateObra(ObraEntity obra);
  Future<void> deleteObra(String id);
}
