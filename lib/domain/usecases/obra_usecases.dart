import 'dart:io';
import '../../core/repositories/obra_repository.dart';
import '../../core/entities/obra_entity.dart';
import '../../core/entities/reporte_pdf_entity.dart';

/// Use case para obtener todas las obras del usuario logueado
class GetObrasUseCase {
  final ObraRepository _repository;

  GetObrasUseCase(this._repository);

  Future<List<ObraEntity>> call() async {
    return await _repository.getObras();
  }
}

/// Use case para obtener todas las obras finalizadas del usuario logueado
class GetObrasFinalizadasUseCase {
  final ObraRepository _repository;

  GetObrasFinalizadasUseCase(this._repository);

  Future<List<ObraEntity>> call({int page = 1, int limit = 10}) async {
    return await _repository.getObrasFinalizadas(page: page, limit: limit);
  }
}

// /// Use case para obtener una obra por ID
// class GetObraByIdUseCase {
//   final ObraRepository _repository;

//   GetObraByIdUseCase(this._repository);

//   Future<ObraEntity?> call(String id) async {
//     return await _repository.getObras(id);
//   }
// }

/// Use case para obtener obras por responsable
class GetObrasByResponsableUseCase {
  final ObraRepository _repository;

  GetObrasByResponsableUseCase(this._repository);

  Future<List<ObraEntity>> call(String userId) async {
    return await _repository.getObrasByResponsable(userId);
  }
}

/// Use case para crear una obra
class CreateObraUseCase {
  final ObraRepository _repository;

  CreateObraUseCase(this._repository);

  Future<ObraEntity> call(ObraEntity obra) async {
    return await _repository.createObra(obra);
  }
}

/// Use case para actualizar una obra
class UpdateObraUseCase {
  final ObraRepository _repository;

  UpdateObraUseCase(this._repository);

  Future<ObraEntity> call(ObraEntity obra) async {
    return await _repository.updateObra(obra);
  }
}

/// Use case para procesar un documento y crear una obra
class ProcessDocumentUseCase {
  final ObraRepository _repository;

  ProcessDocumentUseCase(this._repository);

  Future<ObraEntity> call(File file) async {
    return await _repository.processDocument(file);
  }
}

/// Use case para actualizar los estados de todas las obras
class UpdateObrasEstadosUseCase {
  final ObraRepository _repository;

  UpdateObrasEstadosUseCase(this._repository);

  /// Actualiza los estados de todas las obras basándose en el estado de sus tareas
  /// Retorna un mapa con las estadísticas: {total, actualizadas, noActualizadas}
  Future<Map<String, int>> call() async {
    return await _repository.updateObrasEstados();
  }
}

/// Use case para eliminar una obra
class DeleteObraUseCase {
  final ObraRepository _repository;

  DeleteObraUseCase(this._repository);

  Future<void> call(String id) async {
    return await _repository.deleteObra(id);
  }
}

/// Use case para obtener los reportes PDF de una obra
class GetReportesPdfUseCase {
  final ObraRepository _repository;

  GetReportesPdfUseCase(this._repository);

  Future<List<ReportePdfEntity>> call({
    required String obraId,
    int page = 1,
    int limit = 10,
  }) async {
    return await _repository.getReportesPdf(
      obraId: obraId,
      page: page,
      limit: limit,
    );
  }
}
