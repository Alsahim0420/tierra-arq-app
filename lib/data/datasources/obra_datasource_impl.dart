import 'dart:convert';
import '../../core/datasources/obra_datasource.dart';
import '../../core/entities/obra_entity.dart';
import '../../core/entities/user_entity.dart';
import '../../core/entities/tarea_entity.dart';
import '../../core/services/http_service.dart';
import '../../core/exceptions/app_exceptions.dart';

/// Implementación concreta del datasource de obras
class ObraDataSourceImpl implements ObraDataSource {
  final HttpService _httpService;

  ObraDataSourceImpl({required HttpService httpService})
      : _httpService = httpService;

  @override
  Future<List<ObraEntity>> getObras() async {
    // Por ahora solo tenemos el endpoint por responsable
    // Si necesitas todas las obras, se puede agregar otro endpoint
    throw const ServerException('Endpoint no implementado');
  }

  @override
  Future<ObraEntity?> getObraById(String id) async {
    try {
      final response = await _httpService.get('/obra/$id');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _mapObraFromApi(data);
      }
      return null;
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException('Error al obtener obra: ${e.toString()}');
    }
  }

  @override
  Future<List<ObraEntity>> getObrasByResponsable(String userId) async {
    try {
      final response = await _httpService.get('/master/responsable/$userId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data
              .map((item) => _mapObraFromApi(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw ServerException(
          'Error al obtener obras',
          response.statusCode,
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException('Error al obtener obras: ${e.toString()}');
    }
  }

  /// Mapear respuesta del API a ObraEntity
  ObraEntity _mapObraFromApi(Map<String, dynamic> data) {
    return ObraEntity(
      id: data['_id']?.toString() ?? data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      city: data['city']?.toString() ?? '',
      costo: (data['costo'] ?? data['cost'] ?? 0.0).toDouble(),
      responsable: _mapUserFromApi(
        data['responsable'] as Map<String, dynamic>? ?? {},
      ),
      tareas: _mapTareasFromApi(data['tareas'] as List<dynamic>? ?? []),
    );
  }

  /// Mapear usuario desde API
  UserEntity _mapUserFromApi(Map<String, dynamic> data) {
    return UserEntity(
      id: data['_id']?.toString() ?? data['id']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      lastname: data['lastname']?.toString() ?? '',
      role: data['type']?.toString() ?? data['role']?.toString() ?? '',
      phone: data['phone'] != null
          ? int.tryParse(data['phone'].toString())
          : null,
      city: data['city']?.toString() ?? '',
      dni: data['dni'] != null ? int.tryParse(data['dni'].toString()) : null,
    );
  }

  /// Mapear tareas desde API
  List<TareaEntity> _mapTareasFromApi(List<dynamic> data) {
    return data.map((item) {
      final tareaData = item as Map<String, dynamic>;
      return TareaEntity(
        id: tareaData['_id']?.toString() ?? tareaData['id']?.toString() ?? '',
        name: tareaData['title']?.toString() ??
            tareaData['name']?.toString() ??
            '',
        description: tareaData['description']?.toString() ?? '',
        state: tareaData['status']?.toString() ??
            tareaData['state']?.toString() ??
            'pendiente',
        duration: tareaData['duration'] != null
            ? int.tryParse(tareaData['duration'].toString()) ?? 0
            : 0,
        evidences: (tareaData['evidences'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        assignedTo: tareaData['assignedTo'] != null
            ? _mapUserFromApi(tareaData['assignedTo'] as Map<String, dynamic>)
            : null,
      );
    }).toList();
  }

  @override
  Future<ObraEntity> createObra(ObraEntity obra) async {
    // TODO: Implementar cuando esté disponible el endpoint
    throw const ServerException('Endpoint de creación no implementado');
  }

  @override
  Future<ObraEntity> updateObra(ObraEntity obra) async {
    // TODO: Implementar cuando esté disponible el endpoint
    throw const ServerException('Endpoint de actualización no implementado');
  }

  @override
  Future<void> deleteObra(String id) async {
    // TODO: Implementar cuando esté disponible el endpoint
    throw const ServerException('Endpoint de eliminación no implementado');
  }
}

