import '../entities/user_entity.dart';
import '../models/user_model.dart';

/// Mapper para convertir entre UserEntity y UserModel
class UserMapper {
  /// Convertir UserModel a UserEntity
  static UserEntity toEntity(UserModel model) {
    return UserEntity(
      id: model.id,
      email: model.email,
      name: model.name,
      lastname: model.lastname,
      role: model.type,
      phone: model.phone,
      city: model.city,
      dni: model.dni,
    );
  }

  /// Convertir UserEntity a UserModel
  static UserModel toModel(UserEntity entity) {
    return UserModel(
      id: entity.id,
      type: entity.role,
      name: entity.name,
      lastname: entity.lastname,
      email: entity.email,
      phone: entity.phone,
      city: entity.city,
      dni: entity.dni,
    );
  }

  /// Convertir Map (de API) a UserModel
  static UserModel fromJson(Map<String, dynamic> json) {
    return UserModel.fromJson(json);
  }

  /// Convertir UserModel a Map
  static Map<String, dynamic> toJson(UserModel model) {
    return model.toJson();
  }

  /// Convertir Map (de API) a UserEntity
  static UserEntity fromJsonToEntity(Map<String, dynamic> json) {
    return toEntity(fromJson(json));
  }
}
