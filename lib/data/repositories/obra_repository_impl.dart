import '../../core/repositories/obra_repository.dart';
import '../../core/datasources/obra_datasource.dart';
import '../../core/entities/obra_entity.dart';

/// Implementación del repository de obras
class ObraRepositoryImpl implements ObraRepository {
  final ObraDataSource _dataSource;

  ObraRepositoryImpl(this._dataSource);

  @override
  Future<List<ObraEntity>> getObras() async {
    return await _dataSource.getObras();
  }

  @override
  Future<ObraEntity?> getObraById(String id) async {
    return await _dataSource.getObraById(id);
  }

  @override
  Future<List<ObraEntity>> getObrasByResponsable(String userId) async {
    return await _dataSource.getObrasByResponsable(userId);
  }

  @override
  Future<ObraEntity> createObra(ObraEntity obra) async {
    return await _dataSource.createObra(obra);
  }

  @override
  Future<ObraEntity> updateObra(ObraEntity obra) async {
    return await _dataSource.updateObra(obra);
  }

  @override
  Future<void> deleteObra(String id) async {
    return await _dataSource.deleteObra(id);
  }
}

