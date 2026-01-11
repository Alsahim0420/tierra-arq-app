import 'package:equatable/equatable.dart';
import '../../../core/entities/obra_entity.dart';

abstract class ObraEvent extends Equatable {
  const ObraEvent();

  @override
  List<Object?> get props => [];
}

class LoadObras extends ObraEvent {
  const LoadObras();
}

class LoadObrasFinalizadas extends ObraEvent {
  const LoadObrasFinalizadas();
}

class LoadObraById extends ObraEvent {
  final String id;

  const LoadObraById(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadObrasByResponsable extends ObraEvent {
  final String userId;

  const LoadObrasByResponsable(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CreateObra extends ObraEvent {
  final ObraEntity obra;

  const CreateObra(this.obra);

  @override
  List<Object?> get props => [obra];
}

class UpdateObra extends ObraEvent {
  final ObraEntity obra;

  const UpdateObra(this.obra);

  @override
  List<Object?> get props => [obra];
}

class DeleteObra extends ObraEvent {
  final String id;

  const DeleteObra(this.id);

  @override
  List<Object?> get props => [id];
}

class SelectObra extends ObraEvent {
  final ObraEntity obra;

  const SelectObra(this.obra);

  @override
  List<Object?> get props => [obra];
}

class ClearSelection extends ObraEvent {
  const ClearSelection();
}
