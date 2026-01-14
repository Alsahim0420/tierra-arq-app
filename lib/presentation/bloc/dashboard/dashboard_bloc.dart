import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/dashboard_usecases.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

/// Bloc para manejar el estado del dashboard
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardUseCase _getDashboardUseCase;

  DashboardBloc({
    required GetDashboardUseCase getDashboardUseCase,
  })  : _getDashboardUseCase = getDashboardUseCase,
        super(const DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboard>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    try {
      final dashboard = await _getDashboardUseCase();
      emit(DashboardLoaded(dashboard));
    } catch (e) {
      emit(DashboardError('Error al cargar dashboard: $e'));
    }
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    // Mantener el estado actual si hay datos cargados
    if (state is DashboardLoaded) {
      // Mostrar loading pero mantener datos anteriores
      final currentDashboard = (state as DashboardLoaded).dashboard;
      emit(const DashboardLoading());
      try {
        final dashboard = await _getDashboardUseCase();
        emit(DashboardLoaded(dashboard));
      } catch (e) {
        // Si falla, volver al estado anterior
        emit(DashboardLoaded(currentDashboard));
        emit(DashboardError('Error al refrescar dashboard: $e'));
      }
    } else {
      // Si no hay datos, cargar normalmente
      emit(const DashboardLoading());
      try {
        final dashboard = await _getDashboardUseCase();
        emit(DashboardLoaded(dashboard));
      } catch (e) {
        emit(DashboardError('Error al cargar dashboard: $e'));
      }
    }
  }
}
