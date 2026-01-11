// ignore_for_file: unused_catch_clause, unused_catch_stack, duplicate_ignore

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
  Future<List<TareaEntity>> getTareas({int page = 1, int limit = 10}) async {
    try {
      final endpoint = '/master/tarea?page=$page&limit=$limit';

      final response = await _httpService.get(endpoint);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // La respuesta puede venir en diferentes formatos
        List<dynamic> tareasList = [];
        if (data.containsKey('data')) {
          if (data['data'] is Map) {
            final dataObj = data['data'] as Map<String, dynamic>;
            // La API devuelve las tareas en 'docs' cuando hay paginación
            if (dataObj.containsKey('docs') && dataObj['docs'] is List) {
              tareasList = dataObj['docs'] as List<dynamic>;
            } else if (dataObj.containsKey('tareas') && dataObj['tareas'] is List) {
              tareasList = dataObj['tareas'] as List<dynamic>;
            } else if (dataObj.containsKey('tasks') && dataObj['tasks'] is List) {
              tareasList = dataObj['tasks'] as List<dynamic>;
            }
          } else if (data['data'] is List) {
            tareasList = data['data'] as List<dynamic>;
          }
        } else if (data.containsKey('tareas') && data['tareas'] is List) {
          tareasList = data['tareas'] as List<dynamic>;
        } else if (data.containsKey('tasks') && data['tasks'] is List) {
          tareasList = data['tasks'] as List<dynamic>;
        } else if (data is List) {
          tareasList = data as List<dynamic>;
        }

        final tareas = tareasList
            .map((item) {
              if (item is Map<String, dynamic>) {
                try {
                  final tarea = _mapTareaFromApi(item);
                  return tarea;
                // ignore: unused_catch_stack
                } catch (e, stackTrace) {
                  return null;
                }
              }
              return null;
            })
            .whereType<TareaEntity>()
            .toList();

        return tareas;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw ServerException('Error al obtener tareas', response.statusCode);
      }
    } on AppException catch (e) {
        rethrow;
    } catch (e, stackTrace) {
      throw UnknownException('Error al obtener tareas: ${e.toString()}');
    }
  }

  @override
  Future<TareaEntity?> getTareaById(String id) async {
    try {
      final endpoint = '/master/tarea/$id';
      final response = await _httpService.get(endpoint);

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
            tareaData = {};
          }
        } else if (data.containsKey('tarea')) {
          tareaData = data['tarea'] as Map<String, dynamic>;
        } else {
          tareaData = data;
        }

        final tarea = _mapTareaFromApi(tareaData);
        return tarea;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw ServerException('Error al obtener la tarea', response.statusCode);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException('Error al obtener tarea por ID: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getObraTareaById(String obraTareaId) async {
    try {
      final endpoint = '/master/obra-tarea/$obraTareaId';
      
      final response = await _httpService.get(endpoint);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // La respuesta tiene estructura: {"status":"success","obra_tarea":{...}}
        Map<String, dynamic> obraTareaData;
        if (data.containsKey('obra_tarea') && data['obra_tarea'] is Map) {
          obraTareaData = data['obra_tarea'] as Map<String, dynamic>;
        } else if (data.containsKey('data')) {
          if (data['data'] is Map) {
            final dataObj = data['data'] as Map<String, dynamic>;
            if (dataObj.containsKey('obra_tarea')) {
              obraTareaData = dataObj['obra_tarea'] as Map<String, dynamic>;
            } else {
              obraTareaData = dataObj;
            }
          } else {
            obraTareaData = {};
          }
        } else {
          obraTareaData = data;
        }

        return obraTareaData;
      } else if (response.statusCode == 404) {
        throw ServerException('Obra-Tarea no encontrada', 404);
      } else {
        throw ServerException('Error al obtener obra-tarea', response.statusCode);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException('Error al obtener obra-tarea por ID: ${e.toString()}');
    }
  }

  @override
  Future<List<TareaEntity>> getTareasByObra(String obraId) async {
    // Las tareas se obtienen junto con las obras en ObraDataSourceImpl
    // Este método puede mantenerse para compatibilidad pero las tareas
    // ya vienen en la respuesta de obras
    return [];
  }

  @override
  Future<List<TareaEntity>> getTareasByUser(String userId) async => throw const ServerException('Endpoint de obtención de tareas por usuario no implementado');

  @override
  Future<TareaEntity> createTarea(TareaEntity tarea, String obraId) async {
    try {
      // Determinar el endpoint y body según si hay obraId o no
      final String endpoint;
      final Map<String, dynamic> body;

      if (obraId.isEmpty) {
        // Crear tarea independiente usando POST /api/master/tarea
        endpoint = '/master/tarea';
        body = <String, dynamic>{
          'name': tarea.name,
          'description': tarea.description,
          'state': _normalizeStateForApi(tarea.state),
          'duration': tarea.duration,
          'evidences': tarea.evidences.isNotEmpty ? tarea.evidences : [],
        };
        // Nota: observation no se incluye en la creación de tarea independiente según el CURL
      } else {
        // Crear tarea asociada a una obra usando POST /api/master/obra/{obraId}/tarea
        endpoint = '/master/obra/$obraId/tarea';
        body = <String, dynamic>{
          'name': tarea.name,
          'description': tarea.description,
          'duration': tarea.duration,
          'state': _normalizeStateForApi(tarea.state),
          'evidences': tarea.evidences.isNotEmpty ? tarea.evidences : [],
          'observation': tarea.observation ?? '',
        };
      }

      final response = await _httpService.post(
        endpoint,
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
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
            tareaData = {};
          }
        } else if (data.containsKey('tarea')) {
          tareaData = data['tarea'] as Map<String, dynamic>;
        } else {
          tareaData = data;
        }

        final createdTarea = _mapTareaFromApi(tareaData);
        return createdTarea;
      } else if (response.statusCode == 400) {
        String errorMessage = 'Datos inválidos';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['message']?.toString() ?? errorMessage;
        } catch (_) {
          // Si no se puede parsear el error, usar el mensaje por defecto
        }
        throw ValidationException(errorMessage);
      } else if (response.statusCode == 404) {
        throw ServerException('Obra no encontrada', response.statusCode);
      } else if (response.statusCode == 401) {
        throw AuthenticationException('No autorizado');
      } else if (response.statusCode >= 500) {
        throw ServerException(
          'El servidor no está disponible. Intenta más tarde.',
          response.statusCode,
        );
      } else {
        String errorMessage = 'Error al crear la tarea';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['message']?.toString() ?? errorMessage;
        } catch (_) {
          // Si no se puede parsear el error, usar el mensaje por defecto
        }
        throw ServerException(errorMessage, response.statusCode);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException('Error al crear tarea: ${e.toString()}');
    }
  }

  @override
  Future<TareaEntity> updateTarea(TareaEntity tarea, String obraId) async {
    try {
      
      // Construir el body según el formato del endpoint
      // Para tareas independientes: name, description, state, duration, observation (sin evidences)
      // Para tareas en obra: name, description, state, duration, observation, evidences
      final body = <String, dynamic>{
        'name': tarea.name,
        'description': tarea.description,
        'state': _normalizeStateForApi(tarea.state),
        'duration': tarea.duration,
      };
      
      // Incluir observation
      // Si tiene contenido, agregarlo; si está vacío o es null, no incluirlo (según CURL)
      if (tarea.observation != null && tarea.observation!.isNotEmpty) {
        body['observation'] = tarea.observation;
      }
      
      // Solo incluir evidences si la tarea está asociada a una obra (obraId no vacío)
      // Las tareas independientes no incluyen evidences en el body de edición según el CURL
      if (obraId.isNotEmpty) {
        body['evidences'] = tarea.evidences;
      }

      // Determinar el endpoint según si hay obraId o no
      final String endpoint;
      if (obraId.isNotEmpty) {
        // Si hay obraId, usar: PUT /master/obra/{obraId}/tarea/{tareaId}
        endpoint = '/master/obra/$obraId/tarea/${tarea.id}';
      } else {
        // Si no hay obraId, usar: PUT /master/tarea/{tareaId}
        endpoint = '/master/tarea/${tarea.id}';
      }

      
      final response = await _httpService.put(
        endpoint,
        body: body,
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
            tareaData = {'_id': tarea.id};
          }
        } else if (data.containsKey('tarea')) {
          tareaData = data['tarea'] as Map<String, dynamic>;
        } else {
          // Si la respuesta no trae la tarea completa, usar los datos enviados
          tareaData = data;
        }

        
        final mappedTarea = _mapTareaFromApi(tareaData);
            return mappedTarea;
      } else if (response.statusCode == 404) {
        throw const ServerException('Tarea no encontrada', 404);
      } else {
        throw ServerException(
          'Error al actualizar la tarea: ${response.body}',
          response.statusCode,
        );
      }
    } on AppException catch (e) {
      rethrow;
    } catch (e, stackTrace) {
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
    try {
      final response = await _httpService.delete('/master/tarea/$id');
      if (response.statusCode == 200) {
        return;
      } else {
        throw ServerException('Error al eliminar la tarea', response.statusCode);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException('Error al eliminar tarea: ${e.toString()}');
    }
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
    
    try {
      // Mapear ID
      final id = data['_id']?.toString() ?? data['id']?.toString() ?? '';
      if (id.isEmpty) {
        throw Exception('ID de tarea es vacío o no existe');
      }

      // Mapear name
      final name = data['title']?.toString() ??
          data['name']?.toString() ??
          '';
      if (name.isEmpty) {
        throw Exception('Name de tarea es vacío o no existe');
      }

      // Mapear description
      final description = data['description']?.toString() ?? '';

      // Mapear state
      final stateRaw = data['status']?.toString() ??
          data['state']?.toString() ??
          'pendiente';
      final state = _normalizeStateFromApi(stateRaw);

      // Mapear duration
      final duration = data['duration'] != null
          ? int.tryParse(data['duration'].toString()) ?? 0
          : 0;

      // Mapear assignedTo de forma segura
      UserEntity? assignedTo;
      if (data['assignedTo'] != null) {
        try {
          if (data['assignedTo'] is Map) {
            assignedTo = _mapUserFromApi(
              data['assignedTo'] as Map<String, dynamic>,
            );
          } else if (data['assignedTo'] is String) {
            // Si viene como String (ID), crear un objeto básico con valores por defecto
            final userId = data['assignedTo'] as String;
            assignedTo = _mapUserFromApi({
              'id': userId,
              'email': '',
              'name': '',
              'role': '',
            });
          }
        } catch (e) {
          // Continuar sin assignedTo si falla
          assignedTo = null;
        }
      } else {
      }

      // Mapear evidences de forma segura
      List<String> evidences = [];
      if (data['evidences'] != null && data['evidences'] is List) {
        evidences = (data['evidences'] as List)
            .map((e) => e.toString())
            .toList();
      } else {
      }

      // Mapear observation
      final observation = data['observation']?.toString();
      
      // Mapear obraTareaId si existe
      final obraTareaId = data['obra_tarea_id']?.toString();

      // Crear TareaEntity
      final tarea = TareaEntity(
        id: id,
        name: name,
        description: description,
        state: state,
        duration: duration,
        evidences: evidences,
        assignedTo: assignedTo,
        observation: observation,
        obraTareaId: obraTareaId,
      );
      return tarea;
    } catch (e, stackTrace) {
      rethrow;
    }
  }

  /// Mapear usuario desde API
  UserEntity _mapUserFromApi(Map<String, dynamic> data) {
    try {
      final id = data['_id']?.toString() ?? data['id']?.toString() ?? '';
      final email = data['email']?.toString() ?? '';
      final name = data['name']?.toString() ?? '';
      final lastname = data['lastname']?.toString() ?? '';
      final role = data['type']?.toString() ?? data['role']?.toString() ?? '';
      final phone = data['phone'] != null
          ? int.tryParse(data['phone'].toString())
          : null;
      final city = data['city']?.toString() ?? '';
      final dni = data['dni'] != null ? int.tryParse(data['dni'].toString()) : null;


      // Validar solo ID (los demás campos pueden estar vacíos si es un usuario parcial)
      if (id.isEmpty) {
        throw Exception('UserEntity requiere ID no vacío. Data recibida: $data');
      }

      final user = UserEntity(
        id: id,
        email: email,
        name: name,
        lastname: lastname,
        role: role,
        phone: phone,
        city: city,
        dni: dni,
      );
      return user;
    } catch (e) {
      rethrow;
    }
  }
}

