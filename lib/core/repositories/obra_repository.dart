import '../entities/obra_entity.dart';

/// Repository abstracto para obras
abstract class ObraRepository {
  Future<List<ObraEntity>> getObras();
  // Future<ObraEntity?> getObraById(String id);
  Future<List<ObraEntity>> getObrasByResponsable(String userId);
  Future<ObraEntity> createObra(ObraEntity obra);
  Future<ObraEntity> updateObra(ObraEntity obra);
  Future<void> deleteObra(String id);
}
