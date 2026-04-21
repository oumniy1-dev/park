import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_colors.dart';
import 'notification_screen.dart';
import 'security_screen.dart';
import '../services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'my_vehicles_screen.dart';
import 'my_cards_screen.dart';

/// Экран профиля текущего пользователя.
/// Позволяет управлять аватаром, видеть email/имя и переходить к смежным настройкам (машины, карты, безопасность).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;
  /// Открывает галерею устройства для выбора нового аватара (фотографии).
  /// Сжимает изображение, загружает в Supabase Storage и обновляет профиль.
  Future<void> _pickAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _isUploading = true);
        final Uint8List bytes = await image.readAsBytes();
        String ext = 'jpg';
        if (image.name.contains('.')) {
          ext = image.name.split('.').last;
        }
        final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await AuthService().uploadAvatar(bytes, fileName);
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double globalLetterSpacing = 1.0;
    final user = AuthService().getCurrentUser();
    final String fullName =
        user?.userMetadata?['full_name'] as String? ?? 'John Doe';
    final String email = user?.email ?? 'example@email.com';
    final String? avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16.w,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 20.w),
          child: SvgPicture.asset('assets/icons/ic_icon2.svg', width: 32.w),
        ),
        leadingWidth: 52.w,
        title: Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: globalLetterSpacing,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 24.h),
              GestureDetector(
                onTap: _isUploading ? null : _pickAvatar,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        shape: BoxShape.circle,
                        image: (avatarUrl != null && !_isUploading)
                            ? DecorationImage(
                                image: NetworkImage(avatarUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _isUploading
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: SvgPicture.asset(
                        'assets/icons/ic_edit.svg',
                        width: 32.w,
                        height: 32.w,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                fullName,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: globalLetterSpacing,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                email,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  letterSpacing: globalLetterSpacing,
                ),
              ),
              SizedBox(height: 48.h),
              _buildSvgMenuItem(
                title: 'Edit Profile',
                svgAsset: 'assets/icons/ic_profile.svg',
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                  if (result == true && mounted) {
                    setState(() {});
                  }
                },
              ),
              _buildSvgMenuItem(
                title: 'My Vehicles',
                svgAsset: 'assets/icons/ic_vehicle.svg',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyVehiclesScreen(),
                    ),
                  );
                },
              ),
              _buildSvgMenuItem(
                title: 'Payment',
                svgAsset: 'assets/icons/ic_payment.svg',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyCardsScreen(),
                    ),
                  );
                },
              ),
              _buildSvgMenuItem(
                title: 'Notifications',
                svgAsset: 'assets/icons/ic_notification.svg',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
              ),
              _buildSvgMenuItem(
                title: 'Security',
                svgAsset: 'assets/icons/ic_security.svg',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SecurityScreen(),
                    ),
                  );
                },
              ),
              _buildSvgMenuItem(
                title: 'Help',
                svgAsset: 'assets/icons/ic_help.svg',
              ),
              SizedBox(height: 24.h),
              _buildSvgMenuItem(
                title: 'Logout',
                svgAsset: 'assets/icons/ic_logout.svg',
                isDestructive: true,
                onTap: () {
                  _showLogoutBottomSheet(context);
                },
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Вспомогательный виджет для отрисовки пунктов меню с иконками SVG.
  Widget _buildSvgMenuItem({
    required String title,
    required String svgAsset,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    const double globalLetterSpacing = 1.0;
    final color = isDestructive ? const Color(0xFFFF4848) : AppColors.textDark;
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Row(
          children: [
            SvgPicture.asset(
              svgAsset,
              width: 24.w,
              height: 24.w,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            SizedBox(width: 20.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: globalLetterSpacing,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Показывает нижнее всплывающее окно (диалог) с подтверждением перед выходом из аккаунта (Logout).
  void _showLogoutBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 24.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Text(
                'Logout',
                style: TextStyle(
                  color: const Color(0xFFFF4848),
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              Divider(color: Colors.grey.shade200, height: 1),
              SizedBox(height: 24.h),
              Text(
                'Are you sure you want to log out?',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () async {
                    await AuthService().signOut();
                    if (!context.mounted) return;
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                  ),
                  child: Text(
                    'Yes, Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        );
      },
    );
  }
}
