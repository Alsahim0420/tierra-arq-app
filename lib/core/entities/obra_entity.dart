import 'user_entity.dart';
import 'tarea_entity.dart';

// Entidad de Obra
class ObraEntity {
  ObraEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.city,
    required this.tareas,
    required this.responsable,
    required this.costo,
    this.costoEstimado,
    this.costoFinal,
    this.estado =
        'pendiente', // Estado de la obra: pendiente, en_proceso, finalizado, estancado
    this.fechaInicio,
    this.fechaFin,
    this.fechaEntrega,
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final String city;
  final List<TareaEntity> tareas;
  final UserEntity responsable;
  final double costo;
  final double? costoEstimado; // Costo estimado de la obra (opcional)
  final double? costoFinal; // Costo final de la obra (suma de costos de tareas finalizadas)
  final String estado; // Estado de la obra: pendiente, en_proceso, finalizado
  final DateTime? fechaInicio; // Fecha de inicio de la obra
  final DateTime? fechaFin; // Fecha de finalización planificada
  final DateTime? fechaEntrega; // Fecha de entrega proyectada
}
