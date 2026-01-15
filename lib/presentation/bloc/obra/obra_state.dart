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

/// Estado de loading específico para obras activas
class ObrasActivasLoading extends ObraState {
  const ObrasActivasLoading();
}

/// Estado de loading específico para obras finalizadas
class ObrasFinalizadasLoading extends ObraState {
  const ObrasFinalizadasLoading();
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

class ObrasFinalizadasLoaded extends ObraState {
  final List<ObraEntity> obras;

  const ObrasFinalizadasLoaded({required this.obras});

  @override
  List<Object?> get props => [obras];
}

