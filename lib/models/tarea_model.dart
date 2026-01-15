import 'user_model.dart';

// Modelo de Tarea según el esquema
class TareaModel {
  TareaModel({
    required this.id,
    required this.name,
    required this.description,
    required this.evidences,
    required this.state,
    required this.duration,
    this.assignedTo,
  });

  final String id; // Primary Key
  final String name;
  final String description;
  final List<String> evidences; // Lista de strings (paths/URLs)
  final String state; // Estado de la tarea (pending, inProgress, completed)
  final int duration; // Duración en algún formato (horas, días, etc.)
  final UserModel? assignedTo; // Usuario asignado (opcional)

  TareaModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? evidences,
    String? state,
    int? duration,
    UserModel? assignedTo,
  }) {
    return TareaModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      evidences: evidences ?? List<String>.from(this.evidences),
      state: state ?? this.state,
      duration: duration ?? this.duration,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'evidences': evidences,
      'state': state,
      'duration': duration,
      'assignedTo': assignedTo?.toJson(),
    };
  }

  factory TareaModel.fromJson(Map<String, dynamic> json) {
    return TareaModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      evidences: (json['evidences'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      state: json['state'] as String,
      duration: json['duration'] as int,
      assignedTo: json['assignedTo'] != null
          ? UserModel.fromJson(json['assignedTo'] as Map<String, dynamic>)
          : null,
    );
  }
}

