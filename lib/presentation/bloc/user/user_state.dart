import 'package:equatable/equatable.dart';
import '../../../core/entities/user_entity.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {
  const UserInitial();
}

class UserLoading extends UserState {
  const UserLoading();
}

class UserLoaded extends UserState {
  final UserEntity user;

  const UserLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class UsersLoaded extends UserState {
  final List<UserEntity> users;

  const UsersLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}

