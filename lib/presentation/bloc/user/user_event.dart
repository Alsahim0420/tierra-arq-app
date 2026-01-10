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

