// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TokenModelAdapter extends TypeAdapter<TokenModel> {
  @override
  final int typeId = 1;

  @override
  TokenModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TokenModel(
      token: fields[0] as String,
      refreshToken: fields[1] as String?,
      expiresAt: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TokenModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.token)
      ..writeByte(1)
      ..write(obj.refreshToken)
      ..writeByte(2)
      ..write(obj.expiresAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
