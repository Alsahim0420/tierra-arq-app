import 'package:hive/hive.dart';

part 'user_model.g.dart';

/// Modelo de usuario para almacenamiento y API
@HiveType(typeId: 0)
class UserModel extends HiveObject {
  UserModel({
    required this.id,
    required this.type,
    required this.name,
    required this.lastname,
    required this.email,
    this.phone,
    this.city = '',
    this.dni,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String type;

  @HiveField(2)
  String name;

  @HiveField(3)
  String lastname;

  @HiveField(4)
  String email;

  @HiveField(5)
  int? phone;

  @HiveField(6)
  String city;

  @HiveField(7)
  int? dni;

  String get fullName => lastname.isEmpty ? name : '$name $lastname';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'lastname': lastname,
      'email': email,
      'phone': phone,
      'city': city,
      'dni': dni,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? json['role']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      lastname: json['lastname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone'] != null
          ? int.tryParse(json['phone'].toString())
          : null,
      city: json['city']?.toString() ?? '',
      dni: json['dni'] != null ? int.tryParse(json['dni'].toString()) : null,
    );
  }
}
