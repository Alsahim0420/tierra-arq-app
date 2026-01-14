import '../../core/entities/dashboard_entity.dart';

/// Interfaz abstracta para el datasource del dashboard
abstract class DashboardDataSource {
  /// Obtiene los datos del dashboard
  ///
  /// Endpoint: GET /master/dashboard
  /// Retorna DashboardEntity con todas las estadísticas y obras recientes
  Future<DashboardEntity> getDashboard();
}
