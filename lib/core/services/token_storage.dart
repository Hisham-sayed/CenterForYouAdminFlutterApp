import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const String _accessTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessTokenExpirationKey = 'access_token_expiration';
  static const String _refreshTokenExpirationKey = 'refresh_token_expiration';

  static final TokenStorage _instance = TokenStorage._internal();
  factory TokenStorage() => _instance;
  TokenStorage._internal();

  final _storage = const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime accessTokenExpiration,
    required DateTime refreshTokenExpiration,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _accessTokenExpirationKey, value: accessTokenExpiration.toIso8601String());
    await _storage.write(key: _refreshTokenExpirationKey, value: refreshTokenExpiration.toIso8601String());
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<DateTime?> getAccessTokenExpiration() async {
    final exp = await _storage.read(key: _accessTokenExpirationKey);
    if (exp == null) return null;
    return DateTime.tryParse(exp);
  }

  Future<DateTime?> getRefreshTokenExpiration() async {
    final exp = await _storage.read(key: _refreshTokenExpirationKey);
    if (exp == null) return null;
    return DateTime.tryParse(exp);
  }

  Future<bool> isAccessTokenValid() async {
    final expiration = await getAccessTokenExpiration();
    if (expiration == null) return false;
    // Buffer: consider expired if within 10 seconds of expiration to be safe
    return DateTime.now().isBefore(expiration.subtract(const Duration(seconds: 10)));
  }

  Future<bool> isRefreshTokenValid() async {
    final expiration = await getRefreshTokenExpiration();
    if (expiration == null) return false;
    return DateTime.now().isBefore(expiration);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _accessTokenExpirationKey);
    await _storage.delete(key: _refreshTokenExpirationKey);
  }
}
