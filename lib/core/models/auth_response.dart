import 'user_model.dart';

/// Modelo de respuesta del login
class AuthResponse {
  AuthResponse({required this.token, this.refreshToken, required this.user});

  final String token;
  final String? refreshToken;
  final UserModel user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String?,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'user': user.toJson(),
    };
  }
}
