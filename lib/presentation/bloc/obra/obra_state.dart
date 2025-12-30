import 'package:equatable/equatable.dart';
import '../../../core/entities/obra_entity.dart';

abstract class ObraState extends Equatable {
  const ObraState();

  @override
  List<Object?> get props => [];
}

class ObraInitial extends ObraState {
  const ObraInitial();
}

class ObraLoading extends ObraState {
  const ObraLoading();
}

class ObraLoaded extends ObraState {
  final List<ObraEntity> obras;
  final ObraEntity? selectedObra;

  const ObraLoaded({
    required this.obras,
    this.selectedObra,
  });

  @override
  List<Object?> get props => [obras, selectedObra];
}

class ObraError extends ObraState {
  final String message;

  const ObraError(this.message);

  @override
  List<Object?> get props => [message];
}

