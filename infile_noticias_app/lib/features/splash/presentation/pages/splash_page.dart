import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';

/// Pantalla de bienvenida (Splash).
///
/// Responsabilidades:
/// 1. Mostrar el logo de Infile y la tagline mientras se verifica la sesión.
/// 2. Escuchar el [AuthCubit] para redirigir automáticamente a /login o /home.
///
/// Diseño: fondo blanco, logo centrado, animación de fade-in.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    // ── Animación de entrada del logo ────────────────────────────────────────
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();

    // ── Verificar sesión existente ───────────────────────────────────────────
    // Se ejecuta después del primer frame para que el contexto esté disponible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthCubit>().checkSession();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.home);
        } else if (state is AuthUnauthenticated) {
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo Infile ────────────────────────────────────────────────
                // Se sustituye por AssetImage cuando el logo esté disponible.
                _InfileLogoPlaceholder(),

                const SizedBox(height: 32),

                // ── Nombre de la app ─────────────────────────────────────────
                Text(
                  AppStrings.appName,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.infileBlue,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),

                const SizedBox(height: 8),

                // ── Tagline ──────────────────────────────────────────────────
                Text(
                  AppStrings.splashTagline,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mediumGray,
                        letterSpacing: 0.3,
                      ),
                ),

                const SizedBox(height: 64),

                // ── Indicador de carga ────────────────────────────────────────
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.infileBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder del logo de Infile.
///
/// Reemplazar con:
///   Image.asset('assets/images/infile_logo.png', width: 180)
/// cuando el archivo esté disponible.
class _InfileLogoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.infileBlueLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'INFILE',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppColors.infileBlue,
            letterSpacing: 6,
          ),
        ),
      ),
    );
  }
}
