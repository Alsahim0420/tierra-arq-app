import 'package:hive/hive.dart';

part 'token_model.g.dart';

/// Modelo para almacenar tokens
@HiveType(typeId: 1)
class TokenModel extends HiveObject {
  TokenModel({required this.token, this.refreshToken, this.expiresAt});

  @HiveField(0)
  String token;

  @HiveField(1)
  String? refreshToken;

  @HiveField(2)
  DateTime? expiresAt;

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }
}
