import 'user_entity.dart';

// Entidad de Tarea
class TareaEntity {
  TareaEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.evidences,
    required this.state,
    required this.duration,
    this.assignedTo,
    this.observation,
    this.obraTareaId,
  });

  final String id;
  final String name;
  final String description;
  final List<String> evidences;
  final String state;
  final int duration;
  final UserEntity? assignedTo;
  final String? observation;
  final String? obraTareaId; // ID de la relación obra-tarea (obra_tarea_id del API)
}

