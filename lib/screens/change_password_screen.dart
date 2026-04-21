import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import '../widgets/success_dialog.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();
  final FocusNode _currentFocus = FocusNode();
  final FocusNode _newFocus = FocusNode();
  final FocusNode _repeatFocus = FocusNode();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureRepeat = true;
  bool _isLoading = false;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_onTextChanged);
    _newPasswordController.addListener(_onTextChanged);
    _repeatPasswordController.addListener(_onTextChanged);
    _currentFocus.addListener(() => setState(() {}));
    _newFocus.addListener(() => setState(() {}));
    _repeatFocus.addListener(() => setState(() {}));
  }

  void _onTextChanged() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _repeatPasswordController.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _repeatFocus.dispose();
    super.dispose();
  }

  bool get _isButtonEnabled {
    return _currentPasswordController.text.isNotEmpty &&
        _newPasswordController.text.isNotEmpty &&
        _repeatPasswordController.text.isNotEmpty &&
        !_isLoading;
  }

  /// Основная логика смены пароля текущего пользователя в Supabase.
  Future<void> _handleChangePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final repeatPassword = _repeatPasswordController.text;
    
    // Предварительная валидация на стороне клиента
    if (newPassword != repeatPassword) {
      setState(() {
        _errorMessage = "Passwords do not match";
      });
      return;
    }
    
    setState(() {
      _isLoading = true; // Показываем лоадер на кнопке
      _errorMessage = null; // Сбрасываем старые ошибки
    });
    
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      // Шаг 1: Проверяем, есть ли текущий авторизованный пользователь
      if (user?.email == null) {
        throw Exception("User email not found. Please re-login.");
      }
      
      // Шаг 2: Supabase не позволяет менять пароль напрямую без подтверждения старого.
      // Поэтому мы делаем пере-аутентификацию (re-authenticate) с использованием
      // старого (текущего) пароля, который ввел пользователь.
      try {
        await supabase.auth.signInWithPassword(
          email: user!.email!,
          password: currentPassword,
        );
      } catch (authError) {
        // Если вход упал, значит старый пароль введен неверно
        setState(() {
          _errorMessage = "Current password is incorrect";
          _isLoading = false;
        });
        return;
      }
      
      // Шаг 3: Текущий пароль верен, обновляем атрибут `password` профиля в БД Supabase
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
      
      // Шаг 4: Показываем красивое всплывающее окно об успешной смене пароля
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.6),
          builder: (context) => SuccessDialog(
            title: 'Congratulations!',
            subtitle: 'Your password has been changed',
            buttonText: 'Back to Profile',
            onButtonPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred. Please try again.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isFieldActive(TextEditingController controller, FocusNode focusNode) {
    return controller.text.isNotEmpty || focusNode.hasFocus;
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    bool isError = false,
  }) {
    final isActive = _isFieldActive(controller, focusNode);
    return Container(
      height: 58.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(focusNode.hasFocus ? 0.10 : 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: isError
            ? Border.all(color: AppColors.errorColor, width: 1)
            : focusNode.hasFocus
            ? Border.all(color: AppColors.primary, width: 1)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSvgIcon('assets/icons/ic_lock.svg', isActive),
          SizedBox(width: 16.w),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              obscuringCharacter: '●',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: hintText,
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
            onTap: onToggleObscure,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: SvgPicture.asset(
                obscureText
                    ? 'assets/icons/ic_eye_slash.svg'
                    : 'assets/icons/ic_eye.svg',
                width: 20.w,
                height: 20.w,
                colorFilter: ColorFilter.mode(
                  isActive ? AppColors.primary : AppColors.textLight,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/ic_arrow_back.svg',
            width: 24.w,
            colorFilter: const ColorFilter.mode(
              AppColors.textDark,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Change Password',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current password',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildPasswordField(
                      controller: _currentPasswordController,
                      focusNode: _currentFocus,
                      hintText: 'Password',
                      obscureText: _obscureCurrent,
                      onToggleObscure: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                      isError: _errorMessage == "Current password is incorrect",
                    ),
                    if (_errorMessage == "Current password is incorrect")
                      Padding(
                        padding: EdgeInsets.only(top: 8.h, left: 4.w),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppColors.errorColor,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    SizedBox(height: 32.h),
                    Text(
                      'Create Your New Password',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildPasswordField(
                      controller: _newPasswordController,
                      focusNode: _newFocus,
                      hintText: 'Password',
                      obscureText: _obscureNew,
                      onToggleObscure: () =>
                          setState(() => _obscureNew = !_obscureNew),
                      isError: _errorMessage == "Passwords do not match",
                    ),
                    SizedBox(height: 16.h),
                    _buildPasswordField(
                      controller: _repeatPasswordController,
                      focusNode: _repeatFocus,
                      hintText: 'Repeat the password',
                      obscureText: _obscureRepeat,
                      onToggleObscure: () =>
                          setState(() => _obscureRepeat = !_obscureRepeat),
                      isError: _errorMessage == "Passwords do not match",
                    ),
                    if (_errorMessage == "Passwords do not match" ||
                        (_errorMessage != null &&
                            _errorMessage != "Current password is incorrect" &&
                            _errorMessage != "Passwords do not match"))
                      Padding(
                        padding: EdgeInsets.only(top: 8.h, left: 4.w),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppColors.errorColor,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: PrimaryButton(
                text: _isLoading ? 'Loading...' : 'Change',
                backgroundColor: _isButtonEnabled
                    ? AppColors.primary
                    : AppColors.secondary,
                onPressed: _isButtonEnabled ? _handleChangePassword : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
