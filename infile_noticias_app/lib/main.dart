import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/security/rasp_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/feed/presentation/bloc/feed_cubit.dart';
import 'core/security/inactivity_wrapper.dart';
import 'injection_container.dart';

/// Punto de entrada de la aplicación Infile Noticias.
///
/// Secuencia de arranque:
/// 1. Inicializar Flutter bindings.
/// 2. Configurar orientación (solo portrait).
/// 3. Inicializar dependencias (GetIt).
/// 4. Inicializar freeRASP (detección de amenazas).
/// 5. Lanzar la app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Orientación forzada a portrait (app móvil corporativa) ──────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Estilo de la barra de estado (íconos oscuros sobre fondo claro) ──────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // ── Inicializar inyección de dependencias ────────────────────────────────────
  await initializeDependencies();

  // ── Inicializar freeRASP para detección de amenazas ──────────────────────────
  // NOTA: La acción ante amenaza se maneja en la UI con un dialog bloqueante.
  // En producción, también se debe reportar el evento al servidor.
  await RaspService.instance.initialize(
    onThreatDetected: (threatName) {
      // Limpiar sesión inmediatamente al detectar amenaza.
      SecureStorageService.instance.clearSession();
      // El builder del MaterialApp mostrará el dialog en el contexto correcto.
      debugPrint('⚠️ ALERTA DE SEGURIDAD: $threatName');
    },
  );

  runApp(const InfileNoticiasApp());
}

/// Widget raíz de la aplicación.
class InfileNoticiasApp extends StatelessWidget {
  const InfileNoticiasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => sl<AuthCubit>(),
        ),
        BlocProvider<FeedCubit>(
          create: (_) => sl<FeedCubit>(),
        ),
      ],
      child: Builder(
        builder: (context) {
          // El router se construye aquí para tener acceso al BlocProvider.
          final router = buildAppRouter(context);

          return InactivityWrapper(
            timeout: const Duration(minutes: 5), // Límite de inactividad
            child: MaterialApp.router(
              title: 'Infile Noticias',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,

              // ── GoRouter ──────────────────────────────────────────────────────
              routerConfig: router,

              // ── Builder para refresh del router cuando cambia el estado Auth ──
              // GoRouter escucha el AuthCubit para re-evaluar los guards de sesión.
              builder: (context, child) {
                return BlocListener<AuthCubit, AuthState>(
                  listener: (context, state) {
                    // Forzar re-evaluación del redirect cuando cambia la sesión.
                    router.refresh();
                  },
                  child: child!,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
