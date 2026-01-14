import '../../core/repositories/dashboard_repository.dart';
import '../../core/entities/dashboard_entity.dart';
import '../../core/datasources/dashboard_datasource.dart';

/// Implementación concreta del repositorio del dashboard
class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardDataSource _dataSource;

  DashboardRepositoryImpl(this._dataSource);

  @override
  Future<DashboardEntity> getDashboard() async {
    return await _dataSource.getDashboard();
  }
}
