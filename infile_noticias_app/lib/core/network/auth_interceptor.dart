import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

/// Interceptor de autenticación JWT para Dio.
///
/// Responsabilidades:
/// 1. Inyecta el Access Token en el header Authorization de cada request.
/// 2. Ante un error HTTP 401 (token expirado o inválido):
///    a. Obtiene el Refresh Token del Secure Storage.
///    b. Llama al endpoint /auth/refresh-token del backend.
///    c. Persiste los nuevos tokens en Secure Storage.
///    d. Reintenta la request original con el nuevo Access Token.
///    e. Si el refresh falla, purga la sesión y el usuario es redirigido a /login.
///
/// DISEÑO DE SEGURIDAD:
/// - Los tokens nunca se exponen en logs en builds de release.
/// - Solo se hace UN intento de refresh (evita bucles infinitos).
/// - Si el refresh falla, se limpia la sesión completa (tokens + datos).
final class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorageService _storage;

  /// Control para evitar múltiples intentos de refresh simultáneos.
  bool _isRefreshing = false;

  AuthInterceptor({required Dio dio, required SecureStorageService storage})
      : _dio = dio,
        _storage = storage;

  // ── Request: inyectar Access Token ────────────────────────────────────────────
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Rutas que NO necesitan autenticación — se omite el header.
    const publicPaths = ['/auth/login', '/auth/register', '/auth/refresh-token'];
    final isPublicPath =
        publicPaths.any((path) => options.path.endsWith(path));

    if (!isPublicPath) {
      final token = await _storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  // ── Error: manejar 401 con rotación de token ──────────────────────────────────
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Solo actuar en respuestas 401 y si no estamos ya refrescando.
    final is401 = err.response?.statusCode == 401;
    final isRefreshEndpoint = err.requestOptions.path.contains('refresh-token');

    if (is401 && !_isRefreshing && !isRefreshEndpoint) {
      _isRefreshing = true;

      try {
        final refreshed = await _tryRefreshTokens();
        if (refreshed) {
          // ── Reintentar la request original con el nuevo token ───────────────
          final newToken = await _storage.getAccessToken();
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newToken';

          final retryResponse = await _dio.fetch(retryOptions);
          _isRefreshing = false;
          return handler.resolve(retryResponse);
        } else {
          // ── Refresh falló: limpiar sesión ───────────────────────────────────
          await _storage.clearSession();
          _isRefreshing = false;
          return handler.next(err);
        }
      } catch (_) {
        await _storage.clearSession();
        _isRefreshing = false;
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  // ── Método privado: intenta renovar los tokens ────────────────────────────────
  Future<bool> _tryRefreshTokens() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      // NOTA: la cookie HttpOnly se maneja automáticamente por el backend.
      // Se envía el refresh token también en el body como fallback para Flutter.
      final response = await _dio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
        options: Options(
          // Excluir el interceptor en esta llamada específica para evitar bucles.
          extra: {'skipAuthInterceptor': true},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final newAccessToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;
        final expiryStr = data['accessTokenExpiresAtUtc'] as String?;

        if (newAccessToken == null) return false;

        await _storage.saveSession(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken ?? refreshToken,
          accessTokenExpiry: expiryStr != null
              ? DateTime.tryParse(expiryStr) ?? DateTime.now().add(const Duration(minutes: 15))
              : DateTime.now().add(const Duration(minutes: 15)),
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
