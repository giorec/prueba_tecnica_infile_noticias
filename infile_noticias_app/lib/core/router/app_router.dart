import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/feed/presentation/pages/feed_page.dart';

/// Rutas nombradas de la aplicación.
///
/// Usar constantes en lugar de strings para evitar errores tipográficos.
abstract final class AppRoutes {
  static const String splash  = '/';
  static const String login   = '/login';
  static const String register = '/register';
  static const String home    = '/home';
}

/// Configuración central del enrutador GoRouter con guards de sesión.
///
/// GUARD DE SESIÓN:
/// La función [_redirect] se evalúa en CADA navegación.
/// - Si el usuario NO está autenticado y trata de acceder a una ruta protegida
///   → redirige a /login.
/// - Si el usuario ESTÁ autenticado y accede a /login o /register
///   → redirige a /home (evita volver atrás al login).
/// - En /splash se permite siempre (espera a que el Cubit verifique la sesión).
GoRouter buildAppRouter(BuildContext context) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true, // Solo activo en debug

    // ── Función de redirección (guard de sesión) ─────────────────────────────
    redirect: (BuildContext ctx, GoRouterState state) {
      final authState = ctx.read<AuthCubit>().state;
      final currentPath = state.matchedLocation;

      final isAuthenticated  = authState is AuthAuthenticated;
      final isUnauthenticated = authState is AuthUnauthenticated;
      final isLoading = authState is AuthCheckingSession || authState is AuthInitial;

      // Permitir splash mientras se verifica la sesión.
      if (currentPath == AppRoutes.splash) return null;

      // Si aún verificando sesión, ir a splash y esperar.
      if (isLoading) return AppRoutes.splash;

      // Sin autenticación → forzar login.
      if (isUnauthenticated) {
        final publicPaths = [AppRoutes.login, AppRoutes.register];
        if (!publicPaths.contains(currentPath)) return AppRoutes.login;
        return null;
      }

      // Autenticado → no permitir volver a login/register.
      if (isAuthenticated) {
        final publicPaths = [AppRoutes.login, AppRoutes.register];
        if (publicPaths.contains(currentPath)) return AppRoutes.home;
        return null;
      }

      return null;
    },

    // ── Definición de rutas ───────────────────────────────────────────────────
    routes: [
      // Splash — pantalla de arranque con detección de sesión.
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (_, __) => const SplashPage(),
      ),

      // Login — acceso público.
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginPage(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // Registro — acceso público.
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterPage(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // Home — ruta protegida con el Feed de Noticias 70/30
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (_, __) => const FeedPage(),
      ),
    ],

    // ── Error page ────────────────────────────────────────────────────────────
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Ruta no encontrada: ${state.error}'),
      ),
    ),
  );
}

// ── Transición de fade entre pantallas (minimalista y corporativa) ─────────────
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
    child: child,
  );
}
