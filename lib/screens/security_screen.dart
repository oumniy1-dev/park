import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_colors.dart';
import 'change_password_screen.dart';

/// Экран настроек безопасности приложения (Security).
/// Здесь находятся UI "тумблеры" (свитчи) для фиктивной настройки Face ID и Touch ID.
/// Наследуется от [StatefulWidget], так как состояния тумблеров должны храниться и меняться в реальном времени.
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  // Значения тумблеров. Используются просто для локального отображения (демо дизайн).
  bool faceId = false;
  bool rememberMe = true;
  bool touchId = true;
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
          'Security',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 16.h),
              _buildSwitchItem(
                title: 'Face ID',
                value: faceId,
                onChanged: (val) => setState(() => faceId = val),
              ),
              _buildSwitchItem(
                title: 'Remember me',
                value: rememberMe,
                onChanged: (val) => setState(() => rememberMe = val),
              ),
              _buildSwitchItem(
                title: 'Touch ID',
                value: touchId,
                onChanged: (val) => setState(() => touchId = val),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Google Authenticator',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 24.w,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                    ),
                    child: Text(
                      'Change Password',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
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

  /// Вспомогательный метод (виджет) для отрисовки строчки с тумблером,
  /// чтобы не дублировать код три раза подряд для каждого переключателя.
  Widget _buildSwitchItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Текст-название (Face ID, Touch ID ...)
          Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          // 2. Тумблер из пакета cupertino (iOS-style switch)
          Transform.scale(
            scale: 0.7, // Делаем тумблер чуть меньше стандартного
            child: CupertinoSwitch(
              activeColor: AppColors.primary,
              trackColor: Colors.grey.shade200,
              value: value,       // Текущее состояние (вкл/выкл)
              onChanged: onChanged, // Функция, вызываемая при нажатии
            ),
          ),
        ],
      ),
    );
  }
}
