import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _expiresAtKey = 'auth_expires_at';
  static const _deviceIdKey = 'device_id';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    String? expiresAt,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    if (expiresAt != null && expiresAt.isNotEmpty) {
      await _storage.write(key: _expiresAtKey, value: expiresAt);
    } else {
      await _storage.delete(key: _expiresAtKey);
    }
  }

  Future<void> saveAccessToken(String accessToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
  }

  Future<String?> getAccessToken() => _readSafe(_accessTokenKey);

  Future<String?> getRefreshToken() => _readSafe(_refreshTokenKey);

  Future<String?> getExpiresAt() => _readSafe(_expiresAtKey);

  Future<void> saveDeviceId(String deviceId) async {
    await _storage.write(key: _deviceIdKey, value: deviceId);
  }

  Future<String?> getDeviceId() => _readSafe(_deviceIdKey);

  // Restoring app data to a new device (Android "switch/restore") copies the
  // encrypted values but not the Keystore key that encrypted them, so reads
  // fail with a BadPaddingException. Wipe the unreadable storage instead of
  // throwing, otherwise callers (e.g. ApiClient's interceptor) hang forever.
  Future<String?> _readSafe(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      await _storage.deleteAll();
      return null;
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
  }

  // Backward-compatible aliases.
  Future<void> saveToken(String token) => saveAccessToken(token);

  Future<String?> getToken() => getAccessToken();

  Future<void> clearToken() => clearSession();
}
