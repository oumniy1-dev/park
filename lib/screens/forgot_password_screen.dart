import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import '../services/auth_service.dart';


/// Экран "Забыли пароль".
/// Позволяет пользователю ввести свой Email.
/// Если Email найден в базе — переходим на экран создания нового пароля.
/// Email НЕ отправляется (работает с фейковыми адресами).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

/// Стейт экрана восстановления пароля.
/// Хранит контроллер поля ввода, флаги ошибки и загрузки.
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  bool _hasError = false;
  bool _isLoading = false;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onTextChanged);
    _emailFocus.addListener(_onEmailFocusChange);
  }

  void _onTextChanged() {
    if (!mounted) return;
    if (_hasError) {
      _hasError = false;
      _errorMessage = null;
    }
    setState(() {});
  }

  void _onEmailFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  bool get _isButtonEnabled {
    return _emailController.text.isNotEmpty && !_hasError && !_isLoading;
  }

  /// Логика обработки отправки Email для восстановления.
  /// Вместо отправки письма — проверяем email в базе и переходим на экран сброса.
  Future<void> _handleContinue() async {
    FocusScope.of(context).unfocus();

    // Базовая валидация формата email
    final email = _emailController.text.replaceAll(RegExp(r'\s+'), '').trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();

      // Проверяем, есть ли такой email в базе данных через RPC
      final bool emailExists = await authService.checkEmailExists(email);

      if (!emailExists) {
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _errorMessage = 'No account found with this email';
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      // Передаём email на экран сброса пароля через extra (без отправки письма)
      context.push('/reset-password', extra: email);

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isEmailActive() =>
      _emailController.text.isNotEmpty || _emailFocus.hasFocus;
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/ic_arrow_back.svg',
            width: 24.w,
            height: 24.w,
            colorFilter: const ColorFilter.mode(
              AppColors.textDark,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Forgot Password',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: globalLetterSpacing,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
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
                    SizedBox(height: 40.h),
                    Text(
                      'Recovery your\npassword',
                      style: TextStyle(
                        fontSize: 42.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        height: 1.1,
                        letterSpacing: globalLetterSpacing,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Enter the email address linked to this\naccount',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.normal,
                        color: AppColors.textDark.withOpacity(0.9),
                        height: 1.4,
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
                    if (_hasError)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h, left: 4.w),
                        child: Text(
                          _errorMessage ?? 'Invalid email address!',
                          style: TextStyle(
                            color: AppColors.errorColor,
                            fontSize: 12.sp,
                            letterSpacing: globalLetterSpacing,
                          ),
                        ),
                      ),
                    SizedBox(height: 30.h),
                    PrimaryButton(
                      text: 'Continue',
                      isLoading: _isLoading,
                      backgroundColor: _isButtonEnabled
                          ? AppColors.primary
                          : AppColors.secondary,
                      onPressed: _isButtonEnabled && !_isLoading
                          ? _handleContinue
                          : null,
                    ),
                    SizedBox(height: 20.h),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Remember your password?',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              letterSpacing: globalLetterSpacing,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: () => context.pop(),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 8.h,
                                horizontal: 4.w,
                              ),
                              child: Text(
                                'Login',
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
                            behavior: HitTestBehavior.opaque,
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
