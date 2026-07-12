/// Constantes de cadenas de texto de la aplicación.
/// Centraliza todos los textos para facilitar internacionalización futura.
abstract final class AppStrings {
  // ── General ─────────────────────────────────────────────────────────────────
  static const String appName = 'Infile Noticias';

  // ── Splash ──────────────────────────────────────────────────────────────────
  static const String splashTagline = 'Información que transforma';

  // ── Login ───────────────────────────────────────────────────────────────────
  static const String loginTitle = 'Bienvenido';
  static const String loginSubtitle = 'Inicia sesión para continuar';
  static const String loginEmail = 'Correo electrónico';
  static const String loginPassword = 'Contraseña';
  static const String loginButton = 'Iniciar sesión';
  static const String loginNoAccount = '¿No tienes cuenta? ';
  static const String loginRegisterLink = 'Regístrate';
  static const String loginForgotPassword = '¿Olvidaste tu contraseña?';

  // ── Registro ─────────────────────────────────────────────────────────────────
  static const String registerTitle = 'Crear cuenta';
  static const String registerSubtitle = 'Completa tus datos para comenzar';
  static const String registerFullName = 'Nombre completo';
  static const String registerEmail = 'Correo electrónico';
  static const String registerPassword = 'Contraseña';
  static const String registerConfirmPassword = 'Confirmar contraseña';
  static const String registerButton = 'Crear cuenta';
  static const String registerHaveAccount = '¿Ya tienes cuenta? ';
  static const String registerLoginLink = 'Inicia sesión';

  // ── Política de contraseñas (mostrar al usuario) ─────────────────────────────
  static const String passwordPolicy =
      'Mínimo 13 caracteres, con mayúscula, minúscula, número y carácter especial.';

  // ── Errores de validación ─────────────────────────────────────────────────────
  static const String validationRequired = 'Este campo es requerido';
  static const String validationEmail = 'Ingresa un correo válido';
  static const String validationPasswordLength =
      'La contraseña debe tener al menos 13 caracteres';
  static const String validationPasswordUpper =
      'Debe incluir al menos una letra mayúscula';
  static const String validationPasswordLower =
      'Debe incluir al menos una letra minúscula';
  static const String validationPasswordDigit =
      'Debe incluir al menos un número';
  static const String validationPasswordSpecial =
      'Debe incluir al menos un carácter especial (!@#\$%^&*...)';
  static const String validationPasswordMatch = 'Las contraseñas no coinciden';

  // ── Mensajes de red / seguridad ───────────────────────────────────────────────
  static const String networkError =
      'Error de conexión. Verifica tu red e intenta de nuevo.';
  static const String unauthorizedError =
      'Sesión expirada. Por favor inicia sesión nuevamente.';
  static const String securityError =
      'Dispositivo no compatible. La app no puede ejecutarse en este entorno.';
  static const String rootDetectedError =
      'Se detectó root/jailbreak en el dispositivo. Por razones de seguridad, la app no puede continuar.';
}
