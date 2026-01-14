/// Eventos del DashboardBloc
abstract class DashboardEvent {
  const DashboardEvent();
}

/// Evento para cargar el dashboard
class LoadDashboard extends DashboardEvent {
  const LoadDashboard();
}

/// Evento para refrescar el dashboard
class RefreshDashboard extends DashboardEvent {
  const RefreshDashboard();
}
