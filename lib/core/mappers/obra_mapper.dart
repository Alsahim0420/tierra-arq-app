import '../entities/obra_entity.dart';
import '../entities/tarea_entity.dart';
import 'user_mapper.dart' as user_mapper;

/// Mapper para convertir entre modelos y entidades de Obra
class ObraMapper {
  /// Convertir JSON de la API a ObraEntity
  static ObraEntity fromJson(Map<String, dynamic> json) {
    return ObraEntity(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      costo: (json['costo'] ?? json['cost'] ?? 0.0) is int
          ? (json['costo'] ?? json['cost'] ?? 0).toDouble()
          : (json['costo'] ?? json['cost'] ?? 0.0) as double,
      responsable: user_mapper.UserMapper.fromJsonToEntity(
        json['responsable'] as Map<String, dynamic>? ?? {},
      ),
      tareas: (json['tareas'] as List<dynamic>?)
              ?.map((t) => TareaMapper.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      estado: json['estado']?.toString() ?? 'pendiente',
    );
  }

  /// Convertir lista de JSON a lista de ObraEntity
  static List<ObraEntity> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => fromJson(json as Map<String, dynamic>))
        .toList();
  }
}


/// Mapper temporal para Tarea (necesario para ObraMapper)
class TareaMapper {
  static TareaEntity fromJson(Map<String, dynamic> json) {
    return TareaEntity(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['title']?.toString() ?? json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      state: json['status']?.toString() ?? json['state']?.toString() ?? 'pending',
      duration: json['duration'] is int
          ? json['duration'] as int
          : (json['duration'] is double
              ? (json['duration'] as double).toInt()
              : 0),
      assignedTo: json['assignedTo'] != null
          ? user_mapper.UserMapper.fromJsonToEntity(
              json['assignedTo'] as Map<String, dynamic>,
            )
          : null,
      evidences: (json['evidences'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      observation: json['observation']?.toString(),
      obraTareaId: json['obra_tarea_id']?.toString(), // Mapear obra_tarea_id desde el API
    );
  }
}

