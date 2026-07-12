import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Verifica si el dispositivo tiene hardware biométrico y está configurado
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  /// Solicita la autenticación biométrica al usuario
  Future<bool> authenticate({required String reason}) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        // Si no hay biometría, en un entorno bancario estricto podríamos denegar,
        // pero por usabilidad permitiremos el acceso si el SO no soporta biometría.
        // Opcional: Requerir PIN del sistema operativo.
        return true; 
      }

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
      );
    } on PlatformException {
      return false;
    }
  }
}
