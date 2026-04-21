import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/sign_up_screen.dart';
import 'utils/app_colors.dart';

/// Главная точка входа в приложение.
/// Здесь инициализируются основные зависимости, в частности подключение к Supabase (Backend-as-a-Service),
/// а также запускается корневой виджет приложения с необходимыми провайдерами стейта.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://whmrnullqqckasqyjbgm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndobXJudWxscXFja2FzcXlqYmdtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2MTczNTEsImV4cCI6MjA5MDE5MzM1MX0.MH5Eqo_t54FsSrutn5qgMJeNFpQxhrz0d4M5sVPYLDM',
  );
  runApp(
    MultiProvider(
      providers: [Provider<bool>.value(value: true)],
      child: const ParkingApp(),
    ),
  );
}

/// Главный класс (Root Widget) приложения.
/// Настраивает маршрутизацию (GoRouter), управление базовыми темами и 
/// адаптивный дизайн через ScreenUtil.
class ParkingApp extends StatelessWidget {
  const ParkingApp({super.key});
  @override
  Widget build(BuildContext context) {
    // Настройка роутинга (навигации) между экранами с помощью пакета GoRouter.
    // Содержит пути ('/path') и кастомные анимации (переходы) между экранами.
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(
          path: '/onboarding',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const OnboardingScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: CurveTween(
                        curve: Curves.easeInOutCirc,
                      ).animate(animation),
                      child: child,
                    );
                  },
              transitionDuration: const Duration(milliseconds: 800),
            );
          },
        ),
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const LoginScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            );
          },
        ),
        GoRoute(
          path: '/signup',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const SignUpScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(
                      begin: begin,
                      end: end,
                    ).chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
            );
          },
        ),
        GoRoute(
          path: '/forgot-password',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const ForgotPasswordScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(
                      begin: begin,
                      end: end,
                    ).chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
            );
          },
        ),
        GoRoute(
          path: '/reset-password',
          pageBuilder: (context, state) {
            // Получаем email, переданный с экрана forgot-password
            final email = state.extra as String? ?? '';
            return CustomTransitionPage(
              key: state.pageKey,
              child: ResetPasswordScreen(email: email),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(
                      begin: begin,
                      end: end,
                    ).chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
            );
          },
        ),
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: CurveTween(
                        curve: Curves.easeInOutCirc,
                      ).animate(animation),
                      child: child,
                    );
                  },
              transitionDuration: const Duration(milliseconds: 800),
            );
          },
        ),
      ],
    );
    return ScreenUtilInit(
      designSize: const Size(402, 874),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'SmartPark',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: AppColors.background,
            useMaterial3: true,
            textTheme: () {
              final base = GoogleFonts.urbanistTextTheme(
                Theme.of(context).textTheme,
              );
              return base.copyWith(
                displayLarge: base.displayLarge?.copyWith(letterSpacing: 1.0),
                displayMedium: base.displayMedium?.copyWith(letterSpacing: 1.0),
                displaySmall: base.displaySmall?.copyWith(letterSpacing: 1.0),
                headlineLarge: base.headlineLarge?.copyWith(letterSpacing: 1.0),
                headlineMedium: base.headlineMedium?.copyWith(
                  letterSpacing: 1.0,
                ),
                headlineSmall: base.headlineSmall?.copyWith(letterSpacing: 1.0),
                titleLarge: base.titleLarge?.copyWith(letterSpacing: 1.0),
                titleMedium: base.titleMedium?.copyWith(letterSpacing: 1.0),
                titleSmall: base.titleSmall?.copyWith(letterSpacing: 1.0),
                bodyLarge: base.bodyLarge?.copyWith(letterSpacing: 1.0),
                bodyMedium: base.bodyMedium?.copyWith(letterSpacing: 1.0),
                bodySmall: base.bodySmall?.copyWith(letterSpacing: 1.0),
                labelLarge: base.labelLarge?.copyWith(letterSpacing: 1.0),
                labelMedium: base.labelMedium?.copyWith(letterSpacing: 1.0),
                labelSmall: base.labelSmall?.copyWith(letterSpacing: 1.0),
              );
            }(),
          ),
          routerConfig: router,
        );
      },
    );
  }
}
