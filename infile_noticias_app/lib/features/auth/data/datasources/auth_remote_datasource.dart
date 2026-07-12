import 'package:dio/dio.dart';
import '../models/auth_response_model.dart';

/// Fuente de datos remota para autenticación.
///
/// Responsabilidad única: comunicarse con los endpoints /auth del backend.
/// No contiene lógica de negocio — solo serialización/deserialización y HTTP.
final class AuthRemoteDataSource {
  final Dio _dio;

  const AuthRemoteDataSource(this._dio);

  /// Llama a POST /auth/login con las credenciales del usuario.
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Llama a POST /auth/register con los datos del nuevo usuario.
  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    // El backend en registro devuelve 201 Created con los datos del usuario,
    // no tokens directamente. Se hace un login automático tras el registro.
    await _dio.post(
      '/auth/register',
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );
    // Auto-login tras registro exitoso.
    return login(email: email, password: password);
  }

  /// Llama a POST /auth/logout para revocar el Refresh Token en el servidor.
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Ignorar errores de logout — el cliente igual limpia la sesión local.
    }
  }
}
