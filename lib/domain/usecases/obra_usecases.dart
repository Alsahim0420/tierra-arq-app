import '../../core/repositories/obra_repository.dart';
import '../../core/entities/obra_entity.dart';

/// Use case para obtener todas las obras del usuario logueado
class GetObrasUseCase {
  final ObraRepository _repository;

  GetObrasUseCase(this._repository);

  Future<List<ObraEntity>> call() async {
    return await _repository.getObras();
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

/// Use case para eliminar una obra
class DeleteObraUseCase {
  final ObraRepository _repository;

  DeleteObraUseCase(this._repository);

  Future<void> call(String id) async {
    return await _repository.deleteObra(id);
  }
}
