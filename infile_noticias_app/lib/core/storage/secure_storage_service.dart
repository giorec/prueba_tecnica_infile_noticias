import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper seguro sobre [FlutterSecureStorage].
///
/// Centraliza el acceso al almacenamiento seguro del dispositivo:
/// - iOS:     Keychain Services
/// - Android: EncryptedSharedPreferences (AES-256 en Android Keystore)
///
/// POLÍTICA DE SEGURIDAD:
/// - NUNCA usar SharedPreferences para tokens de autenticación.
/// - Esta clase es la ÚNICA interfaz autorizada para leer/escribir tokens.
/// - Los tokens se eliminan completamente en logout y al detectar inactividad.
final class SecureStorageService {
  SecureStorageService._();

  /// Instancia singleton del servicio.
  static final SecureStorageService instance = SecureStorageService._();

  // Configuración de seguridad específica por plataforma.
  static final FlutterSecureStorage _storage = FlutterSecureStorage(
    // Android: usa AES-256 con clave en Android Keystore (hardware-backed si disponible)
    aOptions: const AndroidOptions(
      encryptedSharedPreferences: true, // EncryptedSharedPreferences API
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
    ),
    // iOS: acceso solo cuando el dispositivo está desbloqueado
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── Claves de almacenamiento (privadas, no exponer fuera de la clase) ────────
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyAccessTokenExpiry = 'auth_access_token_expiry';
  static const String _keyUserId = 'auth_user_id';

  // ── Access Token ─────────────────────────────────────────────────────────────

  /// Persiste el Access Token JWT en el almacenamiento seguro.
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _keyAccessToken, value: token);

  /// Lee el Access Token JWT. Retorna null si no existe o fue purgado.
  Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);

  // ── Refresh Token ─────────────────────────────────────────────────────────────

  /// Persiste el Refresh Token en el almacenamiento seguro.
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _keyRefreshToken, value: token);

  /// Lee el Refresh Token. Retorna null si no existe o fue purgado.
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);

  // ── Expiración del Access Token ───────────────────────────────────────────────

  /// Guarda la fecha de expiración del Access Token en ISO 8601.
  Future<void> saveAccessTokenExpiry(DateTime expiry) =>
      _storage.write(key: _keyAccessTokenExpiry, value: expiry.toIso8601String());

  /// Lee la fecha de expiración del Access Token.
  Future<DateTime?> getAccessTokenExpiry() async {
    final raw = await _storage.read(key: _keyAccessTokenExpiry);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // ── User ID ────────────────────────────────────────────────────────────────────

  /// Guarda el ID del usuario autenticado.
  Future<void> saveUserId(String userId) =>
      _storage.write(key: _keyUserId, value: userId);

  /// Lee el ID del usuario autenticado.
  Future<String?> getUserId() => _storage.read(key: _keyUserId);

  // ── Sesión completa ────────────────────────────────────────────────────────────

  /// Guarda el par completo de tokens tras un login/refresh exitoso.
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required DateTime accessTokenExpiry,
    String? userId,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveAccessTokenExpiry(accessTokenExpiry),
      if (userId != null) saveUserId(userId),
    ]);
  }

  /// Verifica si hay una sesión activa (Access Token presente y no expirado).
  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    if (token == null) return false;
    final expiry = await getAccessTokenExpiry();
    if (expiry == null) return false;
    // Se considera inválido si falta menos de 1 minuto para expirar.
    return DateTime.now().isBefore(expiry.subtract(const Duration(minutes: 1)));
  }

  /// Verifica si existe un Refresh Token (para intentar renovación automática).
  Future<bool> hasRefreshToken() async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }

  /// Elimina TODOS los tokens del almacenamiento seguro.
  ///
  /// Invocar en:
  /// - Logout explícito del usuario.
  /// - Expiración del timer de inactividad (Fase 4).
  /// - Detección de anomalía de seguridad.
  Future<void> clearSession() => _storage.deleteAll();
}
