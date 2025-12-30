// Modelo de Usuario según el esquema
class UserModel {
  UserModel({
    required this.id,
    required this.type,
    required this.name,
    required this.lastname,
    required this.email,
    required this.phone,
    required this.city,
    required this.dni,
  });

  final String id; // Primary Key
  final String type; // Tipo de usuario (admin, maestro, etc.)
  final String name;
  final String lastname;
  final String email;
  final int phone;
  final String city;
  final int dni;

  String get fullName => '$name $lastname';

  UserModel copyWith({
    String? id,
    String? type,
    String? name,
    String? lastname,
    String? email,
    int? phone,
    String? city,
    int? dni,
  }) {
    return UserModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      lastname: lastname ?? this.lastname,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      dni: dni ?? this.dni,
    );
  }

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
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      lastname: json['lastname'] as String,
      email: json['email'] as String,
      phone: json['phone'] as int,
      city: json['city'] as String,
      dni: json['dni'] as int,
    );
  }
}

