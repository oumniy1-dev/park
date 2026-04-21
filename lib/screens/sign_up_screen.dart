import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import '../widgets/success_dialog.dart';
import '../services/auth_service.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 9) {
      text = text.substring(0, 9);
    }
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 1 || i == 4 || i == 6) && i != text.length - 1) {
        buffer.write(' ');
      }
    }
    String formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Экран регистрации нового аккаунта.
/// Использует [StatefulWidget], так как экран динамичный (реагирует на ввод данных).
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

/// Состояние экрана регистрации. Хранит контроллеры всех 6 текстовых полей.
class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _surnameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _repeatFocus = FocusNode();
  bool _obscurePassword = true;
  bool _obscureRepeat = true;
  bool _isLoading = false;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onTextChanged);
    _surnameController.addListener(_onTextChanged);
    _phoneController.addListener(_onTextChanged);
    _emailController.addListener(_onTextChanged);
    _passwordController.addListener(_onTextChanged);
    _repeatController.addListener(_onTextChanged);
    _nameFocus.addListener(_onFocusChange);
    _surnameFocus.addListener(_onFocusChange);
    _phoneFocus.addListener(_onFocusChange);
    _emailFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
    _repeatFocus.addListener(_onFocusChange);
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {
        if (_emailError != null) _emailError = null;
        if (_phoneError != null) _phoneError = null;
        if (_passwordError != null) _passwordError = null;
      });
    }
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _repeatController.dispose();
    _nameFocus.dispose();
    _surnameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _repeatFocus.dispose();
    super.dispose();
  }

  bool get _isButtonEnabled {
    if (_nameController.text.isEmpty ||
        _surnameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _repeatController.text.isEmpty) {
      return false;
    }
    if (_emailError != null || _phoneError != null || _passwordError != null) {
      return false;
    }
    return true;
  }

  /// Основная асинхронная задача регистрации. Вызывается по кнопке "Sign up".
  Future<void> _handleSignUp() async {
    // Прячем клавиатуру принудительно
    FocusScope.of(context).unfocus();
    
    bool isValid = true;
    
    // setState обновляет UI, чтобы показать пользователю ошибки валидации.
    // Сначала сбрасываем старые ошибки.
    setState(() {
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
      
      // Проверка №1: Есть ли собачка @ в email?
      if (!_emailController.text.contains('@')) {
        _emailError = 'Email address must contain @';
        isValid = false;
      }
      
      // Проверка №2: Длина введенного номера телефона (без учета пробелов) должна быть 9 цифр
      if (_phoneController.text.replaceAll(' ', '').length < 9) {
        _phoneError = 'Incomplete phone number';
        isValid = false;
      }
      
      // Проверка №3: Совпадают ли введенные пароли в обоих полях?
      if (_passwordController.text != _repeatController.text) {
        _passwordError = 'Passwords do not match';
        isValid = false;
      }
    });
    
    // Если есть хоть одна ошибка, просто выходим из функции (return) и ничего не отправляем
    if (!isValid) return;
    
    // Включаем крутилку (лоадер) на кнопке
    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      final response = await authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName:
            '${_nameController.text.trim()} ${_surnameController.text.trim()}',
        phone: '+7 7${_phoneController.text.replaceAll(' ', '')}',
      );
      if (!mounted) return;
      
      // Если сессия возвращена, значит Supabase уже авторизовал нас (авто-вход).
      // По нашей логике мы хотим, чтобы юзер сначала логинился вручную, 
      // поэтому мы делаем "принудительный выход" (signOut) свежего аккаунта
      // и отправляем юзера на окно об успешной регистрации.
      if (response.session != null) {
        await authService.signOut();
        if (!mounted) return;
        
        // showDialog показывает всплывающее окошко по центру экрана
        showDialog(
          context: context,
          barrierDismissible: false, // Нельзя закрыть просто нажав мимо окна
          barrierColor: Colors.black.withOpacity(0.6), // Затемняем фон
          builder: (context) => SuccessDialog(
            title: 'Account created!',
            subtitle:
                'Your account has been created successfully. You can now log in.',
            buttonText: 'Go to Login',
            onButtonPressed: () {
              context.pop();
              context.go('/login');
            },
          ),
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.6),
          builder: (context) => SuccessDialog(
            title: 'Almost there!',
            subtitle:
                'Please check your email to verify your account before logging in.',
            buttonText: 'Go to Login',
            onButtonPressed: () {
              context.pop();
              context.go('/login');
            },
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Supabase Error: ${e.message}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unknown Error: ${e.toString()}'),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required String iconPath,
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    String? errorText,
  }) {
    const double globalLetterSpacing = 1.0;
    bool isActive = controller.text.isNotEmpty || focusNode.hasFocus;
    bool hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(focusNode),
          child: Container(
            height: 58.h,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(
                focusNode.hasFocus ? 0.10 : 0.05,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: hasError
                  ? Border.all(color: AppColors.errorColor, width: 1)
                  : focusNode.hasFocus
                  ? Border.all(color: AppColors.primary, width: 1)
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildSvgIcon(iconPath, isActive),
                SizedBox(width: 16.w),
                if (prefixText != null)
                  Text(
                    prefixText,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                      letterSpacing: globalLetterSpacing,
                      height: 1.2,
                    ),
                  ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    obscureText: isPassword && (obscureText ?? true),
                    obscuringCharacter: '●',
                    keyboardType: keyboardType,
                    inputFormatters: inputFormatters,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                      letterSpacing: globalLetterSpacing,
                      height: 1.2,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: hintText,
                      hintStyle: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.normal,
                        letterSpacing: globalLetterSpacing,
                        height: 1.2,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (isPassword && onToggleObscure != null) ...[
                  SizedBox(width: 16.w),
                  GestureDetector(
                    onTap: onToggleObscure,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: SvgPicture.asset(
                        (obscureText ?? true)
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
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: EdgeInsets.only(top: 8.h, left: 4.w),
            child: Text(
              errorText,
              style: TextStyle(
                color: AppColors.errorColor,
                fontSize: 12.sp,
                letterSpacing: globalLetterSpacing,
              ),
            ),
          ),
      ],
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
          'Create Account',
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
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SizedBox(height: 30.h),
                  _buildTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    hintText: 'Name',
                    iconPath: 'assets/icons/ic_user.svg',
                  ),
                  SizedBox(height: 20.h),
                  _buildTextField(
                    controller: _surnameController,
                    focusNode: _surnameFocus,
                    hintText: 'Surname',
                    iconPath: 'assets/icons/ic_user.svg',
                  ),
                  SizedBox(height: 20.h),
                  _buildTextField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    hintText:
                        (_phoneFocus.hasFocus ||
                            _phoneController.text.isNotEmpty)
                        ? ''
                        : 'Phone Number',
                    iconPath: 'assets/icons/ic_phone.svg',
                    keyboardType: TextInputType.phone,
                    prefixText:
                        (_phoneFocus.hasFocus ||
                            _phoneController.text.isNotEmpty)
                        ? '+7 7'
                        : null,
                    inputFormatters: [PhoneNumberFormatter()],
                    errorText: _phoneError,
                  ),
                  SizedBox(height: 20.h),
                  _buildTextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    hintText: 'Email',
                    iconPath: 'assets/icons/ic_email.svg',
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                  ),
                  SizedBox(height: 20.h),
                  _buildTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    hintText: 'Password',
                    iconPath: 'assets/icons/ic_lock.svg',
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onToggleObscure: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  SizedBox(height: 20.h),
                  _buildTextField(
                    controller: _repeatController,
                    focusNode: _repeatFocus,
                    hintText: 'Repeat the password',
                    iconPath: 'assets/icons/ic_lock.svg',
                    isPassword: true,
                    obscureText: _obscureRepeat,
                    errorText: _passwordError,
                    onToggleObscure: () {
                      setState(() {
                        _obscureRepeat = !_obscureRepeat;
                      });
                    },
                  ),
                  SizedBox(height: 48.h),
                  PrimaryButton(
                    text: 'Sign up',
                    isLoading: _isLoading,
                    backgroundColor: _isButtonEnabled
                        ? AppColors.primary
                        : AppColors.secondary,
                    onPressed: _isButtonEnabled && !_isLoading
                        ? _handleSignUp
                        : null,
                  ),
                  SizedBox(height: 40.h),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
