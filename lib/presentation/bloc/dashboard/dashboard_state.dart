import '../../../core/entities/dashboard_entity.dart';

/// Estados del DashboardBloc
abstract class DashboardState {
  const DashboardState();
}

/// Estado inicial del dashboard
class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// Estado de carga del dashboard
class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// Estado cuando el dashboard se ha cargado exitosamente
class DashboardLoaded extends DashboardState {
  const DashboardLoaded(this.dashboard);

  final DashboardEntity dashboard;
}

/// Estado de error del dashboard
class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;
}
