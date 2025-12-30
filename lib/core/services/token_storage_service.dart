import 'package:hive_flutter/hive_flutter.dart';
import '../models/token_model.dart';
import '../models/user_model.dart';

/// Servicio para almacenar y recuperar tokens usando Hive
class TokenStorageService {
  static const String _tokenBoxName = 'tokens';
  static const String _userBoxName = 'user';
  static const String _tokenKey = 'token';
  static const String _userKey = 'current_user';

  Box<TokenModel>? _tokenBox;
  Box<UserModel>? _userBox;

  /// Inicializar Hive y abrir las cajas
  Future<void> init() async {
    await Hive.initFlutter();

    // Registrar adaptadores
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TokenModelAdapter());
    }
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }

    // Abrir cajas
    _tokenBox = await Hive.openBox<TokenModel>(_tokenBoxName);
    _userBox = await Hive.openBox<UserModel>(_userBoxName);
  }

  /// Guardar token de acceso
  Future<void> saveToken(String token, {String? refreshToken}) async {
    if (_tokenBox == null) await init();

    final tokenModel = TokenModel(token: token, refreshToken: refreshToken);
    await _tokenBox!.put(_tokenKey, tokenModel);
  }

  /// Obtener token de acceso
  Future<String?> getToken() async {
    if (_tokenBox == null) await init();

    final tokenModel = _tokenBox!.get(_tokenKey);
    return tokenModel?.token;
  }

  /// Guardar refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    if (_tokenBox == null) await init();

    final tokenModel = _tokenBox!.get(_tokenKey);
    if (tokenModel != null) {
      final updatedToken = TokenModel(
        token: tokenModel.token,
        refreshToken: refreshToken,
        expiresAt: tokenModel.expiresAt,
      );
      await _tokenBox!.put(_tokenKey, updatedToken);
    } else {
      await _tokenBox!.put(
        _tokenKey,
        TokenModel(token: '', refreshToken: refreshToken),
      );
    }
  }

  /// Obtener refresh token
  Future<String?> getRefreshToken() async {
    if (_tokenBox == null) await init();

    final tokenModel = _tokenBox!.get(_tokenKey);
    return tokenModel?.refreshToken;
  }

  /// Guardar datos del usuario
  Future<void> saveUserData(UserModel user) async {
    if (_userBox == null) await init();

    await _userBox!.put(_userKey, user);
  }

  /// Obtener datos del usuario
  Future<UserModel?> getUserData() async {
    if (_userBox == null) await init();

    return _userBox!.get(_userKey);
  }

  /// Limpiar todos los tokens y datos
  Future<void> clearAll() async {
    if (_tokenBox == null) await init();
    if (_userBox == null) await init();

    await _tokenBox!.clear();
    await _userBox!.clear();
  }

  /// Verificar si hay una sesión guardada
  Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
