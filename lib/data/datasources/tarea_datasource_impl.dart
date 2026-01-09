import 'dart:convert';
import '../../core/datasources/tarea_datasource.dart';
import '../../core/entities/tarea_entity.dart';
import '../../core/entities/user_entity.dart';
import '../../core/services/http_service.dart';
import '../../core/exceptions/app_exceptions.dart';

/// Implementación concreta del datasource de tareas con llamadas HTTP reales
class TareaDataSourceImpl implements TareaDataSource {
  final HttpService _httpService;

  TareaDataSourceImpl({
    required HttpService httpService,
  }) : _httpService = httpService;

  @override
  Future<List<TareaEntity>> getTareas() async {
    // TODO: Implementar cuando esté disponible el endpoint
    throw const ServerException('Endpoint de obtención de todas las tareas no implementado');
  }

  @override
  Future<TareaEntity?> getTareaById(String id) async {
    // TODO: Implementar cuando esté disponible el endpoint
    throw const ServerException('Endpoint de obtención de tarea por ID no implementado');
  }

  @override
  Future<List<TareaEntity>> getTareasByObra(String obraId) async {
    // Las tareas se obtienen junto con las obras en ObraDataSourceImpl
    // Este método puede mantenerse para compatibilidad pero las tareas
    // ya vienen en la respuesta de obras
    return [];
  }

  @override
  Future<List<TareaEntity>> getTareasByUser(String userId) async {
    // TODO: Implementar cuando esté disponible el endpoint
    throw const ServerException('Endpoint de obtención de tareas por usuario no implementado');
  }

  @override
  Future<TareaEntity> createTarea(TareaEntity tarea, String obraId) async {
    // TODO: Implementar cuando esté disponible el endpoint
    throw const ServerException('Endpoint de creación de tarea no implementado');
  }

  @override
  Future<TareaEntity> updateTarea(TareaEntity tarea, String obraId) async {
    try {
      print('🔵 updateTarea - INICIO - tarea.id: ${tarea.id}');
      print('🔵 updateTarea - tarea.observation: ${tarea.observation != null ? '"${tarea.observation}"' : 'null'}');
      
      // Construir el body solo con los campos que se quieren actualizar
      // Todos los campos son opcionales según el endpoint
      final body = <String, dynamic>{};
      
      // Solo agregar campos si tienen valores (no vacíos o no nulos)
      if (tarea.name.isNotEmpty) {
        body['name'] = tarea.name;
      }
      if (tarea.description.isNotEmpty) {
        body['description'] = tarea.description;
      }
      if (tarea.state.isNotEmpty) {
        // Normalizar el estado para la API
        body['state'] = _normalizeStateForApi(tarea.state);
      }
      if (tarea.duration > 0) {
        body['duration'] = tarea.duration;
      }
      // Incluir observation incluso si es null (para poder borrarla) o si tiene contenido
      if (tarea.observation != null) {
        // Si tiene contenido, agregarlo
        if (tarea.observation!.isNotEmpty) {
          body['observation'] = tarea.observation;
          print('🔵 updateTarea - Agregando observation al body: "${tarea.observation}"');
        } else {
          // Si está vacío, enviar null para borrarlo
          body['observation'] = null;
          print('🔵 updateTarea - Agregando observation null al body (para borrar)');
        }
      } else {
        // Si es null, también enviarlo para poder borrar la observación existente
        body['observation'] = null;
        print('🔵 updateTarea - Agregando observation null al body (tarea.observation es null)');
      }
      // Incluir evidencias si hay alguna
      if (tarea.evidences.isNotEmpty) {
        body['evidences'] = tarea.evidences;
      }

      final endpoint = '/master/obra/$obraId/tarea/${tarea.id}';
      print('🔵 updateTarea - Body completo: $body');
      print('🔵 updateTarea - Endpoint: $endpoint');
      print('🔵 updateTarea - URL completa: https://tierra-platform-backend.vercel.app/api$endpoint');
      
      final response = await _httpService.put(
        endpoint,
        body: body,
      );
      
      print('🔵 updateTarea - Response statusCode: ${response.statusCode}');
      print('🔵 updateTarea - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // La respuesta puede venir en diferentes formatos
        Map<String, dynamic> tareaData;
        if (data.containsKey('data')) {
          if (data['data'] is Map) {
            final dataObj = data['data'] as Map<String, dynamic>;
            if (dataObj.containsKey('tarea')) {
              tareaData = dataObj['tarea'] as Map<String, dynamic>;
            } else {
              tareaData = dataObj;
            }
          } else {
            tareaData = {'_id': tarea.id};
          }
        } else if (data.containsKey('tarea')) {
          tareaData = data['tarea'] as Map<String, dynamic>;
        } else {
          // Si la respuesta no trae la tarea completa, usar los datos enviados
          tareaData = data;
        }

        return _mapTareaFromApi(tareaData);
      } else if (response.statusCode == 404) {
        throw const ServerException('Tarea no encontrada', 404);
      } else {
        throw ServerException(
          'Error al actualizar la tarea',
          response.statusCode,
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException('Error al actualizar tarea: ${e.toString()}');
    }
  }

  @override
  Future<TareaEntity> updateTareaEvidences(
    String obraId,
    String tareaId,
    List<String> evidences,
  ) async {
    try {
      final response = await _httpService.put(
        '/master/obra/$obraId/tarea/$tareaId', 
        body: {'evidences': evidences},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // La respuesta puede venir en diferentes formatos
        Map<String, dynamic> tareaData;
        if (data.containsKey('data')) {
          if (data['data'] is Map) {
            final dataObj = data['data'] as Map<String, dynamic>;
            if (dataObj.containsKey('tarea')) {
              tareaData = dataObj['tarea'] as Map<String, dynamic>;
            } else {
              tareaData = dataObj;
            }
          } else {
            tareaData = {'_id': tareaId, 'evidences': evidences};
          }
        } else if (data.containsKey('tarea')) {
          tareaData = data['tarea'] as Map<String, dynamic>;
        } else {
          // Si no viene la tarea completa, crear una respuesta básica
          tareaData = {'_id': tareaId, 'evidences': evidences};
        }

        return _mapTareaFromApi(tareaData);
      } else if (response.statusCode == 404) {
        throw const ServerException('Tarea no encontrada', 404);
      } else {
        throw ServerException(
          'Error al actualizar evidencias de la tarea',
          response.statusCode,
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException('Error al actualizar evidencias: ${e.toString()}');
    }
  }

  @override
  Future<TareaEntity> updateTareaState(
    String obraId,
    String tareaId,
    String state,
  ) async {
    try {
      // Normalizar el estado para la API (convertir "en progreso" a "en_proceso")
      final normalizedState = _normalizeStateForApi(state);

      final response = await _httpService.put(
        '/master/obra/$obraId/tarea/$tareaId/estado',
        body: {'state': normalizedState},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // La respuesta puede venir en diferentes formatos
        // Intentar obtener la tarea actualizada desde la respuesta
        Map<String, dynamic> tareaData;
        if (data.containsKey('data')) {
          if (data['data'] is Map) {
            final dataObj = data['data'] as Map<String, dynamic>;
            if (dataObj.containsKey('tarea')) {
              tareaData = dataObj['tarea'] as Map<String, dynamic>;
            } else {
              tareaData = dataObj;
            }
          } else {
            // Si no viene la tarea completa, crear una respuesta básica
            tareaData = {'_id': tareaId, 'state': normalizedState};
          }
        } else if (data.containsKey('tarea')) {
          tareaData = data['tarea'] as Map<String, dynamic>;
        } else {
          // Si no viene la tarea completa, crear una respuesta básica
          // con el estado actualizado
          tareaData = {'_id': tareaId, 'state': normalizedState};
        }

        return _mapTareaFromApi(tareaData);
      } else if (response.statusCode == 404) {
        throw const ServerException('Tarea no encontrada', 404);
      } else {
        throw ServerException(
          'Error al actualizar el estado de la tarea',
          response.statusCode,
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException('Error al actualizar estado de tarea: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteTarea(String id, String obraId) async {
    // TODO: Implementar cuando esté disponible el endpoint
    throw const ServerException('Endpoint de eliminación de tarea no implementado');
  }

  /// Normalizar el estado desde el formato de API al formato de UI
  /// API: "pendiente", "en_proceso", "finalizado"
  /// UI: "pendiente", "en progreso", "finalizado"
  String _normalizeStateFromApi(String state) {
    final normalized = state.toLowerCase().trim();
    if (normalized == 'en_proceso' || normalized == 'en_progreso') {
      return 'en progreso';
    }
    if (normalized == 'pendiente' || normalized == 'pending') {
      return 'pendiente';
    }
    if (normalized == 'finalizado' ||
        normalized == 'finalizada' ||
        normalized == 'completada' ||
        normalized == 'completado' ||
        normalized == 'completed') {
      return 'finalizado';
    }
    // Si no coincide, devolver el valor normalizado tal cual
    return normalized;
  }

  /// Normalizar el estado desde el formato de UI al formato de API
  /// UI: "pendiente", "en progreso", "finalizado"
  /// API: "pendiente", "en_proceso", "finalizado"
  String _normalizeStateForApi(String state) {
    final normalized = state.toLowerCase().trim();
    if (normalized == 'en progreso' || normalized == 'en_progreso') {
      return 'en_proceso';
    }
    if (normalized == 'pendiente' || normalized == 'pending') {
      return 'pendiente';
    }
    if (normalized == 'finalizado' ||
        normalized == 'finalizada' ||
        normalized == 'completada' ||
        normalized == 'completado' ||
        normalized == 'completed') {
      return 'finalizado';
    }
    // Si ya está en formato API, devolverlo tal cual
    return normalized;
  }

  /// Mapear respuesta del API a TareaEntity
  TareaEntity _mapTareaFromApi(Map<String, dynamic> data) {
    // Mapear assignedTo de forma segura
    UserEntity? assignedTo;
    if (data['assignedTo'] != null) {
      if (data['assignedTo'] is Map) {
        assignedTo = _mapUserFromApi(
          data['assignedTo'] as Map<String, dynamic>,
        );
      } else if (data['assignedTo'] is String) {
        // Si viene como String (ID), crear un objeto básico
        assignedTo = _mapUserFromApi({'id': data['assignedTo']});
      }
    }

    // Mapear evidences de forma segura
    List<String> evidences = [];
    if (data['evidences'] != null && data['evidences'] is List) {
      evidences = (data['evidences'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return TareaEntity(
      id: data['_id']?.toString() ?? data['id']?.toString() ?? '',
      name: data['title']?.toString() ??
          data['name']?.toString() ??
          '',
      description: data['description']?.toString() ?? '',
      state: _normalizeStateFromApi(
          data['status']?.toString() ??
          data['state']?.toString() ??
          'pendiente'),
      duration: data['duration'] != null
          ? int.tryParse(data['duration'].toString()) ?? 0
          : 0,
      evidences: evidences,
      assignedTo: assignedTo,
      observation: data['observation']?.toString(),
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
}

