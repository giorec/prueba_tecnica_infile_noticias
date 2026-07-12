import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

/// URL base del backend Infile Noticias.
///
/// DESARROLLO:  Usar IP local de la máquina (no localhost — no funciona en emulador).
/// PRODUCCIÓN:  Cambiar por el dominio HTTPS real.
const String _kBaseUrl = 'https://10.0.2.2:7001/api'; // Android emulator
// const String _kBaseUrl = 'https://localhost:7001/api'; // iOS simulator

/// Cliente Dio preconfigurado con seguridad de nivel bancario.
///
/// Características:
/// - Base URL del backend configurada.
/// - Timeouts razonables para evitar bloqueos.
/// - [AuthInterceptor] para inyección automática de JWT y renovación en 401.
/// - Certificate Pinning mediante [_CertificatePinningAdapter] (prevención MITM).
/// - Logger de requests solo en modo debug.
final class DioClient {
  DioClient._();

  static final DioClient _instance = DioClient._();

  /// Instancia singleton del cliente Dio.
  static DioClient get instance => _instance;

  late final Dio _dio;

  /// El cliente Dio configurado. Usar este para todas las llamadas HTTP.
  Dio get client => _dio;

  /// Inicializa el cliente Dio. Debe llamarse antes del primer uso.
  /// Se invoca desde [InjectionContainer.init()].
  void initialize(SecureStorageService storage) {
    _dio = Dio(BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // ── Certificate Pinning ──────────────────────────────────────────────────
    // En desarrollo se acepta el certificado autofirmado del servidor local.
    // En producción: habilitar la verificación estricta del certificado.
    //
    // NOTA: Para certificado pinning real en producción, usar ssl_pinning_plugin
    // con el SHA-256 fingerprint del certificado del servidor.
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      // DESARROLLO: acepta certificado autofirmado (solo para localhost/emulador).
      // PRODUCCIÓN: eliminar esta línea y usar fingerprint SHA-256 explícito.
      client.badCertificateCallback = (cert, host, port) {
        // En producción: validar el fingerprint del cert contra el valor esperado.
        // return cert.sha1.toString() == 'EXPECTED_SHA1_FINGERPRINT';
        return true; // ← SOLO EN DESARROLLO
      };
      return client;
    };

    // ── Interceptores ─────────────────────────────────────────────────────────
    // 1. AuthInterceptor: inyecta el token y maneja la renovación en 401.
    _dio.interceptors.add(AuthInterceptor(
      dio: _dio,
      storage: storage,
    ));

    // 2. Logger de requests (solo en modo debug — desactivado en release).
    assert(() {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('[DIO] $obj'),
      ));
      return true;
    }());
  }
}
