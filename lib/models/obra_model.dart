import 'tarea_model.dart';
import 'user_model.dart';

// Modelo de Obra según el esquema
class ObraModel {
  ObraModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.city,
    required this.tareas,
    required this.responsable,
    required this.costo,
  });

  final String id; // Primary Key
  final String title;
  final String description;
  final String location;
  final String city;
  final List<TareaModel> tareas; // Lista de tareas
  final UserModel responsable; // Usuario responsable
  final double costo;

  ObraModel copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? city,
    List<TareaModel>? tareas,
    UserModel? responsable,
    double? costo,
  }) {
    return ObraModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      city: city ?? this.city,
      tareas: tareas ?? tareas?.map((t) => t.copyWith()).toList() ?? this.tareas,
      responsable: responsable ?? this.responsable,
      costo: costo ?? this.costo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'city': city,
      'tareas': tareas.map((t) => t.toJson()).toList(),
      'responsable': responsable.toJson(),
      'costo': costo,
    };
  }

  factory ObraModel.fromJson(Map<String, dynamic> json) {
    return ObraModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      city: json['city'] as String,
      tareas: (json['tareas'] as List<dynamic>)
          .map((t) => TareaModel.fromJson(t as Map<String, dynamic>))
          .toList(),
      responsable: UserModel.fromJson(
        json['responsable'] as Map<String, dynamic>,
      ),
      costo: (json['costo'] as num).toDouble(),
    );
  }
}

