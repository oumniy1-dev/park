import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../utils/app_colors.dart';
import '../services/auth_service.dart';

/// Экран "Редактировать профиль".
/// Позволяет пользователю обновить своё Имя, Фамилию и Номер телефона.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Контроллеры полей ввода текста
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 7## ### ## ##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );
  // Оригинальные данные пользователя (до момента начала редактирования).
  // Нужны, чтобы сравнивать текущий ввод и активировать кнопку только если были изменения.
  String _initialFirstName = '';
  String _initialLastName = '';
  String _initialPhone = '';
  
  bool _isLoading = false;
  bool _isChanged = false; // Флаг: "были ли внесены изменения?"
  
  /// Метод [initState] — часть "жизненного цикла" виджета.
  /// Он вызывается Flutter ровно ОДИН РАЗ, когда экран только-только создается.
  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Сразу при входе грузим старые данные юзера из Supabase
    
    // .addListener() заставляет контроллеры слушать каждый напечатанный символ
    // Функция _checkChanges будет вызываться при каждом нажатии клавиши юзером.
    _firstNameController.addListener(_checkChanges);
    _lastNameController.addListener(_checkChanges);
    _phoneController.addListener(_checkChanges);
  }

  void _loadInitialData() {
    final user = AuthService().getCurrentUser();
    if (user != null) {
      final fullName = user.userMetadata?['full_name'] as String? ?? '';
      final parts = fullName.trim().split(' ');
      _initialFirstName = parts.isNotEmpty ? parts.first : '';
      _initialLastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      String dbPhone = user.userMetadata?['phone'] as String? ?? '';
      String extractedDigits = dbPhone.replaceAll(RegExp(r'\D'), '');
      if (extractedDigits.isEmpty) {
        _phoneController.text = '+7 7';
        _initialPhone = '+7 7';
      } else {
        if (extractedDigits.startsWith('7') && extractedDigits.length > 1) {
          extractedDigits = extractedDigits.substring(1);
        }
        _initialPhone = _phoneMaskFormatter.maskText(extractedDigits);
        _phoneController.text = _initialPhone;
      }
      _firstNameController.text = _initialFirstName;
      _lastNameController.text = _initialLastName;
      _phoneController.text = _initialPhone;
    }
  }

  void _checkChanges() {
    final isDifferent =
        _firstNameController.text.trim() != _initialFirstName ||
        _lastNameController.text.trim() != _initialLastName ||
        _phoneController.text.trim() != _initialPhone;
    if (_isChanged != isDifferent) {
      setState(() {
        _isChanged = isDifferent;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Главная логика сохранения измененных данных в базу.
  Future<void> _handleUpdate() async {
    if (!_isChanged) return; // Запрещаем апдейт, если данные не менялись
    
    setState(() => _isLoading = true); // Включаем "крутилку"
    
    try {
      final newFullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
              .trim();
      final newPhone = _phoneController.text.trim();
      await AuthService().updateProfile(fullName: newFullName, phone: newPhone);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    String iconPath, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      height: 58.h,
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 20.w,
            colorFilter: const ColorFilter.mode(
              AppColors.textLight,
              BlendMode.srcIn,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
                letterSpacing: 1.0,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: hint,
                hintStyle: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.0,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double globalLetterSpacing = 1.0;
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
          'Edit Profile',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: globalLetterSpacing,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 32.h),
              _buildTextField(
                'First name',
                _firstNameController,
                'assets/icons/ic_profile.svg',
              ),
              _buildTextField(
                'Last name',
                _lastNameController,
                'assets/icons/ic_profile.svg',
              ),
              _buildTextField(
                'Phone number',
                _phoneController,
                'assets/icons/ic_phone.svg',
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneMaskFormatter],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: (_isChanged && !_isLoading) ? _handleUpdate : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isChanged
                        ? AppColors.primary
                        : AppColors.secondary,
                    disabledBackgroundColor: AppColors.secondary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Update',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: globalLetterSpacing,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}
