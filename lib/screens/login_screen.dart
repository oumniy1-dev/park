import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import '../services/auth_service.dart';

/// Экран авторизации пользователя в приложении.
/// Наследуется от [StatefulWidget], так как экран содержит интерактивные элементы
/// (текстовые поля, кнопку с загрузкой), состояние которых нужно изменять и перерисовывать.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Класс состояния (State) для экрана LoginScreen.
/// Здесь хранятся все переменные и функции, управляющие логикой.
class _LoginScreenState extends State<LoginScreen> {
  // Контроллеры нужны для считывания текста из полей ввода (Email и Пароль)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _hasError = false;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onTextChanged);
    _passwordController.addListener(_onTextChanged);
    _emailFocus.addListener(_onEmailFocusChange);
    _passwordFocus.addListener(_onPasswordFocusChange);
  }

  void _onTextChanged() {
    if (!mounted) return;
    if (_hasError) {
      _hasError = false;
    }
    setState(() {});
  }

  void _onEmailFocusChange() {
    if (_hasError && _emailFocus.hasFocus) {
      _emailController.clear();
    }
    if (mounted) setState(() {});
  }

  void _onPasswordFocusChange() {
    if (_hasError && _passwordFocus.hasFocus) {
      _passwordController.clear();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _isEmailActive() =>
      _emailController.text.isNotEmpty || _emailFocus.hasFocus;
  bool _isPasswordActive() =>
      _passwordController.text.isNotEmpty || _passwordFocus.hasFocus;
  bool get _isButtonEnabled {
    return _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        !_hasError;
  }

  /// Главная логика попытки входа в аккаунт.
  /// Вызывается при нажатии на кнопку "Sign in".
  Future<void> _handleLogin() async {
    // Убираем клавиатуру с экрана
    FocusScope.of(context).unfocus();
    
    // Включаем лоадер (загрузку). setState дает команду Flutter перерисовать экран.
    setState(() => _isLoading = true);
    
    try {
      final authService = AuthService();
      // Вызываем сервис авторизации Supabase (встроенный метод в наш класс)
      await authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Если мы дошли сюда, значит ошибки не было, вход успешен!
      // Проверяем, существует ли еще экран (mounted), и переходим на Главную страницу (Home)
      if (!mounted) return;
      context.go('/home');
      
    } catch (e) {
      // Если произошла ошибка (например, неверный пароль), попадаем сюда (catch).
      if (!mounted) return;
      
      // Показываем красную обводку на полях
      setState(() {
        _hasError = true;
      });
      
      // Показываем всплывающее уведомление (SnackBar) снизу экрана с текстом ошибки
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSvgIcon(String path, bool isActive) {
    return SvgPicture.asset(
      path,
      width: 20.w,
      height: 20.w,
      colorFilter: ColorFilter.mode(
        isActive ? AppColors.primary : AppColors.textLight,
        BlendMode.srcIn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double globalLetterSpacing = 1.0;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 80.h),
                    Text(
                      'Login to your\nAccount',
                      style: TextStyle(
                        fontSize: 42.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        height: 1.1,
                        letterSpacing: globalLetterSpacing,
                      ),
                    ),
                    SizedBox(height: 48.h),
                    GestureDetector(
                      onTap: () =>
                          FocusScope.of(context).requestFocus(_emailFocus),
                      child: Container(
                        height: 58.h,
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(
                            _emailFocus.hasFocus ? 0.10 : 0.05,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          border: _hasError
                              ? Border.all(
                                  color: AppColors.errorColor,
                                  width: 1,
                                )
                              : _emailFocus.hasFocus
                              ? Border.all(color: AppColors.primary, width: 1)
                              : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildSvgIcon(
                              'assets/icons/ic_email.svg',
                              _isEmailActive(),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: TextField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textDark,
                                  letterSpacing: globalLetterSpacing,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: 'Email',
                                  hintStyle: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.normal,
                                    letterSpacing: globalLetterSpacing,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    GestureDetector(
                      onTap: () =>
                          FocusScope.of(context).requestFocus(_passwordFocus),
                      child: Container(
                        height: 58.h,
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(
                            _passwordFocus.hasFocus ? 0.10 : 0.05,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          border: _hasError
                              ? Border.all(
                                  color: AppColors.errorColor,
                                  width: 1,
                                )
                              : _passwordFocus.hasFocus
                              ? Border.all(color: AppColors.primary, width: 1)
                              : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildSvgIcon(
                              'assets/icons/ic_lock.svg',
                              _isPasswordActive(),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: TextField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                obscureText: _obscurePassword,
                                obscuringCharacter: '●',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textDark,
                                  letterSpacing: globalLetterSpacing,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: 'Password',
                                  hintStyle: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.normal,
                                    letterSpacing: globalLetterSpacing,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              child: _buildSvgIcon(
                                _obscurePassword
                                    ? 'assets/icons/ic_eye_slash.svg'
                                    : 'assets/icons/ic_eye.svg',
                                _isPasswordActive(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_hasError)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h, left: 4.w),
                        child: Text(
                          'Invalid email or password!',
                          style: TextStyle(
                            color: AppColors.errorColor,
                            fontSize: 12.sp,
                            letterSpacing: globalLetterSpacing,
                          ),
                        ),
                      ),
                    SizedBox(height: 24.h),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _rememberMe = !_rememberMe;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            _rememberMe
                                ? 'assets/icons/ic_checkbox_selected.svg'
                                : 'assets/icons/ic_checkbox_unselected.svg',
                            width: 24.w,
                            height: 24.h,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Remember me',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark,
                              letterSpacing: globalLetterSpacing,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30.h),
                    PrimaryButton(
                      text: 'Sign in',
                      isLoading: _isLoading,
                      backgroundColor: _isButtonEnabled
                          ? AppColors.primary
                          : AppColors.secondary,
                      onPressed: _isButtonEnabled && !_isLoading
                          ? _handleLogin
                          : null,
                    ),
                    SizedBox(height: 20.h),
                    Center(
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: Text(
                          'Forgot the password?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: globalLetterSpacing,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(height: 20.h),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Don\'t have an account?',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              letterSpacing: globalLetterSpacing,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: () {
                              context.push('/signup');
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 8.h,
                                horizontal: 4.w,
                              ),
                              child: Text(
                                'Sign up',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: globalLetterSpacing,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
