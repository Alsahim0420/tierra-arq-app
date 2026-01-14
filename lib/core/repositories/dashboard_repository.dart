import '../../core/entities/dashboard_entity.dart';

/// Interfaz abstracta para el repositorio del dashboard
abstract class DashboardRepository {
  /// Obtiene los datos del dashboard
  Future<DashboardEntity> getDashboard();
}
