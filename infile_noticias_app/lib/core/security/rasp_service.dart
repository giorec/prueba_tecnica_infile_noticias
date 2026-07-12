import 'package:freerasp/freerasp.dart';
import 'package:flutter/material.dart';

/// Servicio de detección de amenazas a nivel de dispositivo y entorno.
///
/// Usa el SDK freeRASP (Talsec) para detectar:
/// - Privileged access: Root (Android) / Jailbreak (iOS)
/// - Emuladores / Simuladores
/// - Depuradores activos (anti-debugging)
/// - Hooks de runtime (Frida, Xposed)
/// - App Integrity: firma del APK/IPA comprometida
/// - Fuentes de instalación no oficiales
///
/// POLÍTICA DE SEGURIDAD:
/// Si se detecta cualquiera de estas amenazas, la app purga los tokens
/// de sesión y muestra un diálogo bloqueante al usuario.
final class RaspService {
  RaspService._();

  static final RaspService instance = RaspService._();

  /// Inicializa freeRASP con los callbacks de amenaza.
  ///
  /// Debe llamarse lo más temprano posible en [main()] antes de [runApp()].
  /// [onThreatDetected] recibe el nombre de la amenaza para logging/telemetría.
  Future<void> initialize({
    required void Function(String threatName) onThreatDetected,
  }) async {
    // ── Configuración de la aplicación para freeRASP ─────────────────────────
    final config = TalsecConfig(
      androidConfig: AndroidConfig(
        packageName: 'com.infile.infile_noticias_app',
        // SHA-256 del certificado de firma del APK (release keystore).
        // Calcular con: keytool -printcert -file release.cer
        signingCertHashes: ['your-sha256-cert-hash-here'],
        supportedStores: ['com.android.vending'], // Solo Google Play Store
      ),
      iosConfig: IOSConfig(
        bundleIds: ['com.infile.infileNoticiasApp'],
        teamId: 'YOUR_TEAM_ID', // Apple Developer Team ID
      ),
      watcherMail: 'security@infile.com.gt',
      isProd: false, // ← Cambiar a true en builds de producción
    );

    // ── Callbacks para cada tipo de amenaza (API real de freeRASP 6.x) ───────
    final callback = ThreatCallback(
      // Root / Jailbreak — amenaza crítica
      onPrivilegedAccess: () => onThreatDetected('Root / Acceso privilegiado detectado'),

      // Ejecución en emulador / simulador
      onSimulator: () => onThreatDetected('Emulador / Simulador detectado'),

      // App tampered — firma del APK/IPA comprometida
      onAppIntegrity: () => onThreatDetected('Integridad de la app comprometida'),

      // Depurador adjunto — intento de análisis dinámico
      onDebug: () => onThreatDetected('Depurador detectado'),

      // Hooks de runtime (Frida, Xposed)
      onHooks: () => onThreatDetected('Hook de código detectado'),

      // Instalación desde fuente no oficial
      onUnofficialStore: () => onThreatDetected('Fuente de instalación no confiable'),

      // Device binding comprometido
      onDeviceBinding: () => onThreatDetected('Device binding comprometido'),

      // Sin hardware seguro disponible
      onSecureHardwareNotAvailable: () =>
          onThreatDetected('Hardware seguro no disponible'),

      // ADB habilitado (Android Debug Bridge activo)
      onADBEnabled: () => onThreatDetected('ADB habilitado detectado'),
    );

    // Inicializar Talsec y adjuntar los callbacks.
    await Talsec.instance.start(config);
    Talsec.instance.attachListener(callback);
  }

  /// Muestra un diálogo de seguridad bloqueante y finaliza la app.
  static Future<void> showSecurityBlockDialog(
    BuildContext context,
    String threatName,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.security, size: 48, color: Color(0xFFEF4444)),
        title: const Text(
          'Entorno no seguro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Se detectó: $threatName.\n\n'
          'Por razones de seguridad, Infile Noticias no puede ejecutarse '
          'en este dispositivo o entorno.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () =>
                throw Exception('SecurityThreatDetected:$threatName'),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
