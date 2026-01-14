import 'obra_entity.dart';

/// Entidad que representa los datos del dashboard
class DashboardEntity {
  DashboardEntity({
    required this.totalObras,
    required this.obrasActivas,
    required this.obrasFinalizadas,
    required this.totalTareas,
    required this.tareasPendientes,
    required this.tareasEnProgreso,
    required this.tareasCompletadas,
    required this.presupuestoProyectado,
    required this.presupuestoEjecutado,
    required this.varianzaPresupuestaria,
    required this.obrasATiempo,
    required this.obrasRetrasadas,
    required this.obrasAdelantadas,
    List<ObraEntity>? obrasATiempoLista,
    List<ObraEntity>? obrasRetrasadasLista,
    List<ObraEntity>? obrasAdelantadasLista,
    required this.obrasRecientes,
    this.porcentajeAvancePromedio,
    this.obrasEstancadas,
    this.tareasEstancadas,
  }) : obrasATiempoLista = obrasATiempoLista,
       obrasRetrasadasLista = obrasRetrasadasLista,
       obrasAdelantadasLista = obrasAdelantadasLista;

  // Estadísticas de obras
  final int totalObras;
  final int obrasActivas;
  final int obrasFinalizadas;
  final int? obrasEstancadas;

  // Estadísticas de tareas
  final int totalTareas;
  final int tareasPendientes;
  final int tareasEnProgreso;
  final int tareasCompletadas;
  final int? tareasEstancadas;

  // Información financiera
  final double presupuestoProyectado;
  final double presupuestoEjecutado;
  final double varianzaPresupuestaria;

  // Cronograma
  final int obrasATiempo;
  final int obrasRetrasadas;
  final int obrasAdelantadas;
  
  // Listas de obras por estado de cronograma (nullable para compatibilidad con estados anteriores)
  final List<ObraEntity>? obrasATiempoLista;
  final List<ObraEntity>? obrasRetrasadasLista;
  final List<ObraEntity>? obrasAdelantadasLista;

  // Obras recientes
  final List<ObraEntity> obrasRecientes;

  // Porcentaje de avance promedio (opcional)
  final double? porcentajeAvancePromedio;
}
