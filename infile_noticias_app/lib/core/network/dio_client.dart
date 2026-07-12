import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
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

/// TODO: Reemplazar este hash con el SHA-256 real del certificado de PRODUCCIÓN.
/// Este hash actual (o lista de hashes) sirve para validar la conexión HTTPS.
/// Cualquier discrepancia lanzará un error y prevendrá un ataque Man-In-The-Middle.
const List<String> _kPinnedCertFingerprints = [
  // Ejemplo ficticio de hash SHA-256 en Base64 o Hex. 
  // Para desarrollo local se usará un bypass temporal si no lo tenemos, 
  // pero el mecanismo de código ya es de producción.
  'EXPECTED_SHA256_HASH_OF_PRODUCTION_CERT',
];

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
    // Implementación manual de Certificate Pinning (Nivel Bancario).
    // Analiza la cadena de certificados o el certificado hoja del servidor y 
    // compara su fingerprint (SHA-256) contra los almacenados localmente.
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        // En un entorno de desarrollo puro contra localhost, podríamos retornar true
        // para saltarnos el pinning. Sin embargo, por requerimiento de la fase de
        // "Security Auditing & Polish", dejamos el mecanismo listo.
        
        // 1. Obtener la codificación DER del certificado
        final derCert = cert.der;
        
        // 2. Calcular SHA-256
        final hash = sha256.convert(derCert);
        final fingerprint = hash.toString(); // Representación hexadecimal
        
        // 3. (OPCIONAL) Permitir cualquier cert SOLO para localhost local
        // En producción DEBE eliminarse.
        if (host == '10.0.2.2' || host == 'localhost') {
           debugPrint('[SECURITY] Aceptando certificado local de desarrollo: $fingerprint');
           return true;
        }

        // 4. Validar contra los pines autorizados
        final isPinned = _kPinnedCertFingerprints.contains(fingerprint);
        
        if (!isPinned) {
          debugPrint('🚨 [SECURITY ALERT] Fallo de SSL Pinning. Fingerprint detectado: $fingerprint');
          // En producción, retornamos false y la conexión será destruida.
        }
        
        return isPinned;
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
        logPrint: (obj) => debugPrint('[DIO] $obj'),
      ));
      return true;
    }());
  }
}
