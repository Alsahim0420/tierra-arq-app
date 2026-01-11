import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUser extends UserEvent {
  final String userId;

  const LoadUser(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadAllUsers extends UserEvent {
  const LoadAllUsers();
}

class CreateUser extends UserEvent {
  final String name;
  final String lastname;
  final String email;
  final String password;
  final int? phone;
  final String city;
  final int? dni;

  const CreateUser({
    required this.name,
    required this.lastname,
    required this.email,
    required this.password,
    this.phone,
    this.city = '',
    this.dni,
  });

  @override
  List<Object?> get props => [name, lastname, email, password, phone, city, dni];
}

