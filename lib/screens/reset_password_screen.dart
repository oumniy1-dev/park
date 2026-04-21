import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import '../widgets/success_dialog.dart';
import '../services/auth_service.dart';

/// Экран создания нового пароля.
/// Сюда пользователь попадает с экрана "Забыли пароль" — email передаётся параметром [email].
/// Пароль обновляется напрямую в базе данных через SQL-функцию (без email-ссылки),
/// что позволяет работать с фейковыми адресами электронной почты.
class ResetPasswordScreen extends StatefulWidget {
  /// Email пользователя, чей пароль нужно сбросить.
  final String email;
  const ResetPasswordScreen({super.key, required this.email});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

/// Стейт экрана сброса пароля.
/// Хранит контроллеры полей ввода, флаги видимости паролей, ошибки и загрузки.
class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _repeatFocus = FocusNode();
  bool _obscurePassword = true;
  bool _obscureRepeat = true;
  bool _rememberMe = false;
  bool _hasError = false;
  bool _isLoading = false;
  String _errorMessage = '';
  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onTextChanged);
    _repeatController.addListener(_onTextChanged);
    _passwordFocus.addListener(_onPasswordFocusChange);
    _repeatFocus.addListener(_onRepeatFocusChange);
  }

  void _onTextChanged() {
    if (!mounted) return;
    if (_hasError) {
      _hasError = false;
    }
    setState(() {});
  }

  void _onPasswordFocusChange() {
    if (_hasError && _passwordFocus.hasFocus) {
      _passwordController.clear();
      _repeatController.clear();
    }
    if (mounted) setState(() {});
  }

  void _onRepeatFocusChange() {
    if (_hasError && _repeatFocus.hasFocus) {
      _repeatController.clear();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _repeatController.dispose();
    _passwordFocus.dispose();
    _repeatFocus.dispose();
    super.dispose();
  }

  bool get _isButtonEnabled {
    return _passwordController.text.isNotEmpty &&
        _repeatController.text.isNotEmpty &&
        !_hasError &&
        !_isLoading;
  }

  /// Реальное обновление пароля через RPC-функцию в Supabase.
  Future<void> _handleContinue() async {
    FocusScope.of(context).unfocus();

    // Пароль должен быть не менее 6 символов
    if (_passwordController.text.length < 6) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Password must be at least 6 characters';
      });
      return;
    }

    // Пароли должны совпадать
    if (_passwordController.text != _repeatController.text) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Passwords do not match!';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      // Обновляем пароль напрямую через SQL-функцию reset_user_password в Supabase.
      // Никакого email не отправляется — пароль меняется сразу в auth.users.
      final success = await authService.resetPasswordDirectly(
        email: widget.email,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      if (!success) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to update password. Try again.';
          _isLoading = false;
        });
        return;
      }

      // Успех — показываем диалог поздравления
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (context) => SuccessDialog(
          title: 'Congratulations!',
          subtitle: 'Your password has been changed',
          buttonText: 'Go to Login',
          onButtonPressed: () {
            context.pop();
            context.go('/login');
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isPasswordActive() =>
      _passwordController.text.isNotEmpty || _passwordFocus.hasFocus;
  bool _isRepeatActive() =>
      _repeatController.text.isNotEmpty || _repeatFocus.hasFocus;
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
          'Create New Password',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
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
                child: Align(
                  alignment: const Alignment(0.0, -0.25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Your New Password',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: 30.h),
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
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintText: 'Password',
                                    hintStyle: TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.normal,
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
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  child: SvgPicture.asset(
                                    _obscurePassword
                                        ? 'assets/icons/ic_eye_slash.svg'
                                        : 'assets/icons/ic_eye.svg',
                                    width: 20.w,
                                    height: 20.w,
                                    colorFilter: ColorFilter.mode(
                                      _isPasswordActive()
                                          ? AppColors.primary
                                          : AppColors.textLight,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      GestureDetector(
                        onTap: () =>
                            FocusScope.of(context).requestFocus(_repeatFocus),
                        child: Container(
                          height: 58.h,
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(
                              _repeatFocus.hasFocus ? 0.10 : 0.05,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            border: _hasError
                                ? Border.all(
                                    color: AppColors.errorColor,
                                    width: 1,
                                  )
                                : _repeatFocus.hasFocus
                                ? Border.all(color: AppColors.primary, width: 1)
                                : null,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildSvgIcon(
                                'assets/icons/ic_lock.svg',
                                _isRepeatActive(),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: TextField(
                                  controller: _repeatController,
                                  focusNode: _repeatFocus,
                                  obscureText: _obscureRepeat,
                                  obscuringCharacter: '●',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDark,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintText: 'Repeat the password',
                                    hintStyle: TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _obscureRepeat = !_obscureRepeat;
                                  });
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  child: SvgPicture.asset(
                                    _obscureRepeat
                                        ? 'assets/icons/ic_eye_slash.svg'
                                        : 'assets/icons/ic_eye.svg',
                                    width: 20.w,
                                    height: 20.w,
                                    colorFilter: ColorFilter.mode(
                                      _isRepeatActive()
                                          ? AppColors.primary
                                          : AppColors.textLight,
                                      BlendMode.srcIn,
                                    ),
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
                            _errorMessage.isNotEmpty ? _errorMessage : 'Passwords do not match!',
                            style: TextStyle(
                              color: AppColors.errorColor,
                              fontSize: 12.sp,
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
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30.h),
                      PrimaryButton(
                        text: 'Continue',
                        isLoading: _isLoading,
                        backgroundColor: _isButtonEnabled
                            ? AppColors.primary
                            : AppColors.secondary,
                        onPressed: _isButtonEnabled && !_isLoading ? _handleContinue : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
