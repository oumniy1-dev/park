import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_colors.dart';
import 'primary_button.dart';

class SuccessDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback? onButtonPressed;
  final String iconPath;
  const SuccessDialog({
    super.key,
    this.title = 'Successfully!',
    this.subtitle = 'Password reset email sent',
    this.buttonText = 'Reset Password',
    this.onButtonPressed,
    this.iconPath = 'assets/icons/img_success.svg',
  });
  @override
  Widget build(BuildContext context) {
    const double globalLetterSpacing = 1.0;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.r)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Padding(
        padding: EdgeInsets.only(
          top: 40.h,
          bottom: 30.h,
          left: 30.w,
          right: 30.w,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 175.w,
              child: SvgPicture.asset(iconPath, fit: BoxFit.contain),
            ),
            SizedBox(height: 32.h),
            Text(
              title,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: globalLetterSpacing,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 14.sp,
                fontWeight: FontWeight.normal,
                letterSpacing: globalLetterSpacing,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.h),
            PrimaryButton(
              text: buttonText,
              onPressed:
                  onButtonPressed ??
                  () {
                    context.pop();
                    context.push('/reset-password');
                  },
            ),
          ],
        ),
      ),
    );
  }
}
