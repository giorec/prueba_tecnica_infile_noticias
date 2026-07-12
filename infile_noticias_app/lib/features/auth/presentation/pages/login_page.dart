import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../widgets/infile_logo_widget.dart';

/// Pantalla de inicio de sesión.
///
/// Diseño: fondo blanco predominante, acentos azul Infile, tipografía Inter.
/// Incluye:
/// - Logo corporativo de Infile en la parte superior.
/// - Campos de email y contraseña con validación inline.
/// - Botón primario azul de inicio de sesión.
/// - Link a la pantalla de registro.
/// - Manejo de estados de carga y error desde el AuthCubit.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _slideController, curve: Curves.easeIn);
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.home);
        } else if (state is AuthError) {
          _showErrorSnackbar(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        // Sin AppBar — pantalla inmersiva
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 48),

                          // ── Logo Infile ─────────────────────────────────────
                          const Center(child: InfileLogoWidget(height: 64)),

                          const SizedBox(height: 48),

                          // ── Título ──────────────────────────────────────────
                          Text(
                            AppStrings.loginTitle,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.loginSubtitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),

                          const SizedBox(height: 36),

                          // ── Formulario ──────────────────────────────────────
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Email
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.loginEmail,
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: AppColors.mediumGray,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return AppStrings.validationRequired;
                                    }
                                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
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
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: AppStrings.loginPassword,
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: AppColors.mediumGray,
                                    ),
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
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return AppStrings.validationRequired;
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),

                          // ── Olvidé mi contraseña ────────────────────────────
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // TODO: implementar flujo de recuperación
                              },
                              child: const Text(AppStrings.loginForgotPassword),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ── Botón de login ──────────────────────────────────
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
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            AppColors.white,
                                          ),
                                        ),
                                      )
                                    : const Text(AppStrings.loginButton),
                              );
                            },
                          ),

                          const Spacer(),

                          // ── Link a Registro ──────────────────────────────────
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppStrings.loginNoAccount,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                TextButton(
                                  onPressed: () => context.push(AppRoutes.register),
                                  child: const Text(AppStrings.loginRegisterLink),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }
}
