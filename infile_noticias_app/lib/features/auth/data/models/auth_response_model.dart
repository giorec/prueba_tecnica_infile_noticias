import '../../domain/entities/auth_tokens.dart';

/// Modelo de datos para deserializar la respuesta de autenticación del backend.
///
/// Corresponde al DTO [TokenResponseDto] del backend .NET.
/// Se convierte a la entidad de dominio [AuthTokens] para que la UI
/// no dependa del formato de la API.
final class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAtUtc;
  final String tokenType;

  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAtUtc,
    this.tokenType = 'Bearer',
  });

  /// Deserializa desde el JSON de respuesta del backend.
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['accessToken'] as String,
      // El refresh token puede venir en el cuerpo o en la cookie HttpOnly.
      // Se espera que venga en el body para el cliente Flutter.
      refreshToken: json['refreshToken'] as String? ?? '',
      accessTokenExpiresAtUtc: DateTime.parse(
        json['accessTokenExpiresAtUtc'] as String,
      ),
      tokenType: json['tokenType'] as String? ?? 'Bearer',
    );
  }

  /// Convierte el modelo de datos en la entidad de dominio.
  AuthTokens toEntity() => AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        accessTokenExpiresAt: accessTokenExpiresAtUtc,
        tokenType: tokenType,
      );
}
