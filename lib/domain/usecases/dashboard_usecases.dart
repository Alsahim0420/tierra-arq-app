import '../../core/repositories/dashboard_repository.dart';
import '../../core/entities/dashboard_entity.dart';

/// Use case para obtener los datos del dashboard
class GetDashboardUseCase {
  final DashboardRepository _repository;

  GetDashboardUseCase(this._repository);

  /// Ejecuta el caso de uso para obtener el dashboard
  Future<DashboardEntity> call() async {
    return await _repository.getDashboard();
  }
}
