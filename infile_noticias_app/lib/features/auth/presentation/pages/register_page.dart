import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../widgets/infile_logo_widget.dart';
import '../widgets/password_strength_indicator.dart';

/// Pantalla de registro de nuevo usuario.
///
/// Diseño: blanco predominante, acentos azul Infile.
/// Incluye:
/// - Logo de Infile.
/// - Campos: nombre completo, email, contraseña, confirmar contraseña.
/// - Indicador de fortaleza de contraseña en tiempo real.
/// - Validación completa contra la política de 13 caracteres.
/// - BlocListener para redirección al home tras registro exitoso.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeIn);
    _slideCtrl.forward();

    // Redibujar al cambiar la contraseña (para el indicador de fortaleza).
    _passwordCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().register(
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          confirmPassword: _confirmCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.home);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ── Logo ─────────────────────────────────────────────────
                    const Center(child: InfileLogoWidget(height: 52)),

                    const SizedBox(height: 32),

                    // ── Título ───────────────────────────────────────────────
                    Text(
                      AppStrings.registerTitle,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.registerSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 32),

                    // ── Formulario ───────────────────────────────────────────
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Nombre completo
                          TextFormField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: AppStrings.registerFullName,
                              prefixIcon: Icon(Icons.person_outline,
                                  color: AppColors.mediumGray),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? AppStrings.validationRequired
                                    : null,
                          ),

                          const SizedBox(height: 16),

                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: AppStrings.registerEmail,
                              prefixIcon: Icon(Icons.email_outlined,
                                  color: AppColors.mediumGray),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return AppStrings.validationRequired;
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(v.trim())) {
                                return AppStrings.validationEmail;
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Contraseña
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: AppStrings.registerPassword,
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: AppColors.mediumGray),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.mediumGray,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: _validatePassword,
                          ),

                          // Indicador de fortaleza en tiempo real
                          PasswordStrengthIndicator(
                            password: _passwordCtrl.text,
                          ),

                          const SizedBox(height: 16),

                          // Confirmar contraseña
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: AppStrings.registerConfirmPassword,
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: AppColors.mediumGray),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.mediumGray,
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return AppStrings.validationRequired;
                              }
                              if (v != _passwordCtrl.text) {
                                return AppStrings.validationPasswordMatch;
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 8),

                          // Política de contraseñas
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.infileBlueLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 16, color: AppColors.infileBlue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppStrings.passwordPolicy,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.infileBlue,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Botón de registro ───────────────────────────────
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, state) {
                              final isLoading = state is AuthLoading;
                              return ElevatedButton(
                                onPressed: isLoading ? null : _submit,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  AppColors.white),
                                        ),
                                      )
                                    : const Text(AppStrings.registerButton),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Link a Login ──────────────────────────────────────────
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppStrings.registerHaveAccount,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text(AppStrings.registerLoginLink),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Valida la contraseña contra la política de seguridad del proyecto.
  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return AppStrings.validationRequired;
    if (v.length < 13) return AppStrings.validationPasswordLength;
    if (!v.contains(RegExp(r'[A-Z]'))) return AppStrings.validationPasswordUpper;
    if (!v.contains(RegExp(r'[a-z]'))) return AppStrings.validationPasswordLower;
    if (!v.contains(RegExp(r'[0-9]'))) return AppStrings.validationPasswordDigit;
    if (!v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return AppStrings.validationPasswordSpecial;
    }
    return null;
  }
}
