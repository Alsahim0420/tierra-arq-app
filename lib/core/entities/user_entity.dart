// Entidad de Usuario
class UserEntity {
  UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.lastname = '',
    this.phone,
    this.city = '',
    this.dni,
    this.address = '',
    this.specialty = '',
    this.experienceYears,
    this.birthDate,
    this.joinDate,
    this.status = 'Activo',
    this.notes = '',
  });

  final String id;
  final String email;
  final String name;
  final String lastname;
  final String role;
  final int? phone;
  final String city;
  final int? dni;
  final String address;
  final String specialty;
  final int? experienceYears;
  final DateTime? birthDate;
  final DateTime? joinDate;
  final String status;
  final String notes;

  String get fullName => lastname.isEmpty ? name : '$name $lastname';
}

