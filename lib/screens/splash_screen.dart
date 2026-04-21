import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Стартовый экран приложения (Splash Screen).
/// Этот экран показывается самым первым при запуске приложения. 
/// На нём проигрывается анимация логотипа, а затем происходит автоматический переход
/// на нужный экран в зависимости от того, вошел ли пользователь в аккаунт.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  /// Метод [initState] срабатывает один раз при запуске экрана.
  @override
  void initState() {
    super.initState();
    // Настраиваем общую длительность анимации (1200 миллисекунд)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Анимация масштаба: от 60% (0.6) до 100% (1.0) с пружинящим эффектом (easeOutBack)
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    // Анимация прозрачности: от 0 (невидимо) до 1 (полностью видимо)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    // Запускаем анимацию
    _animationController.forward();
    
    // Таймер: ждем 2 секунды (2000 мс) с момента запуска, а затем проверяем базу данных
    Timer(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      
      // Проверяем: есть ли "живая" сессия пользователя в Supabase?
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser != null) {
        // Если да — значит он ранее уже логинился, сразу кидаем его на главный экран
        context.go('/home');
      } else {
        // Если нет (или зашел первый раз) — показываем onboarding (обучение)
        context.go('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SvgPicture.asset(
                'assets/icons/logo.svg',
                width: 142.w,
                height: 188.h,
                allowDrawingOutsideViewBox: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
