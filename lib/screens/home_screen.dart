import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_colors.dart';
import 'parking_details_screen.dart';
import 'saved_screen.dart';
import 'booked_screen.dart';
import 'profile_screen.dart';
import '../services/saved_service.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/notification_service.dart';
import 'notification_screen.dart';

/// Модель данных (класс) для описания парковочного места.
/// Хранит всю информацию, необходимую для отображения карточки на главном экране.
class ParkingSpot {
  final String id; // Уникальный идентификатор парковки
  final String imagePath;
  final String title;
  final String location;
  final int price;
  bool isSaved;
  ParkingSpot({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.location,
    required this.price,
    this.isSaved = false,
  });
}

final List<ParkingSpot> mockParkings = [
  ParkingSpot(
    id: '1',
    imagePath: 'assets/images/img_parking_1.png',
    title: 'Mega Park',
    location: 'Rozybakieva',
    price: 3,
    isSaved: false,
  ),
];

/// Главный экран приложения. Содержит приветствие пользователя, поисковую строку,
/// карточки парковок и нижнюю навигационную панель (BottomNavigationBar) для переключения вкладок.
/// Главный экран приложения (Home Screen).
/// Здесь пользователь видит список доступных парковок, может их искать
/// и переходить в свои закладки (Saved) или активные бронирования (Booked).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final SavedService _savedService = SavedService();
  @override
  void initState() {
    super.initState();
    BookingService().checkAndClearExpiredBookingsGlobally();
    _loadSavedStatus();
  }

  /// Асинхронно загружает список сохраненных парковок из Supabase, 
  /// чтобы обновить статус иконки-закладки (isSaved) для каждой карточки.
  Future<void> _loadSavedStatus() async {
    try {
      final savedIds = await _savedService.getSavedParkings();
      if (mounted) {
        setState(() {
          for (var spot in mockParkings) {
            spot.isSaved = savedIds.contains(spot.id);
          }
        });
      }
    } catch (e) {}
  }

  /// Показывает нижнюю всплывающую панель (BottomSheet) с краткой информацией о выбранной парковке.
  /// Содержит кнопку сохранения в закладки и кнопку "Details" для перехода к экрану деталей парковки.
  void _showDetailsBottomSheet(BuildContext context, ParkingSpot spot) {
    const double globalLetterSpacing = 1.0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 24.h,
            top: 12.h,
            left: 24.w,
            right: 24.w,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 3.h,
                decoration: BoxDecoration(
                  color: AppColors.textLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Details',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: globalLetterSpacing,
                ),
              ),
              SizedBox(height: 24.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  width: double.infinity,
                  height: 180.h,
                  color: AppColors.inputBackground,
                  child: Center(
                    child: Icon(
                      Icons.image,
                      color: AppColors.textLight,
                      size: 48.w,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spot.title,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          letterSpacing: globalLetterSpacing,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        spot.location,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textLight,
                          letterSpacing: globalLetterSpacing,
                        ),
                      ),
                    ],
                  ),
                  StatefulBuilder(
                    builder: (context, setSheetState) {
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            spot.isSaved = !spot.isSaved;
                          });
                          setState(() {});
                          _savedService
                              .toggleSaved(spot.id, spot.isSaved)
                              .catchError((e) {
                                debugPrint('Failed to sync save state: $e');
                              });
                        },
                        child: SvgPicture.asset(
                          spot.isSaved
                              ? 'assets/icons/ic_bookmark_active.svg'
                              : 'assets/icons/ic_bookmark.svg',
                          key: UniqueKey(),
                          width: 24.w,
                          height: 24.w,
                          colorFilter: ColorFilter.mode(
                            spot.isSaved
                                ? AppColors.primary
                                : AppColors.textLight,
                            BlendMode.srcIn,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              SizedBox(
                height: 55.h,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.08),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: globalLetterSpacing,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ParkingDetailsScreen(spot: spot),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: globalLetterSpacing,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            SvgPicture.asset(
                              'assets/icons/ic_arrow_right.svg',
                              width: 24.w,
                              height: 24.w,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavIcon(String path, bool isActive) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: SvgPicture.asset(
        path,
        width: 24.w,
        height: 24.w,
        colorFilter: ColorFilter.mode(
          isActive ? AppColors.primary : AppColors.textLight,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double globalLetterSpacing = 1.0;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textLight,
            selectedLabelStyle: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: globalLetterSpacing,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: globalLetterSpacing,
            ),
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon('assets/icons/ic_home.svg', false),
                activeIcon: _buildNavIcon(
                  'assets/icons/ic_home_active.svg',
                  true,
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon('assets/icons/ic_bookmark.svg', false),
                activeIcon: _buildNavIcon(
                  'assets/icons/ic_bookmark_active.svg',
                  true,
                ),
                label: 'Saved',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon('assets/icons/ic_ticket.svg', false),
                activeIcon: _buildNavIcon(
                  'assets/icons/ic_ticket_active.svg',
                  true,
                ),
                label: 'Booked',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon('assets/icons/ic_profile.svg', false),
                activeIcon: _buildNavIcon(
                  'assets/icons/ic_profile_active.svg',
                  true,
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: _selectedIndex == 0
              ? _buildHomeTab(globalLetterSpacing)
              : _selectedIndex == 1
              ? SavedScreen(onStateSelected: () => setState(() {}))
              : _selectedIndex == 2
              ? const BookedScreen()
              : _selectedIndex == 3
              ? const ProfileScreen()
              : Center(child: Text('Coming soon')),
        ),
      ),
    );
  }

  /// Строит содержимое (контент) главной вкладки 'Home'.
  /// Включает профиль пользователя с аватаром в шапке, бейдж уведомлений и список доступных мест (Nearby).
  Widget _buildHomeTab(double globalLetterSpacing) {
    final user = AuthService().getCurrentUser();
    final String fullName =
        user?.userMetadata?['full_name'] as String? ?? 'Didar';
    final String firstName = fullName.split(' ').first;
    final String? avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    backgroundColor: Colors.white.withOpacity(0.8),
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,
                  ),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: NotificationService().getUserNotifications(),
                    builder: (context, snapshot) {
                      final notifications = snapshot.data ?? [];
                      final hasUnread = notifications.any(
                        (n) => n['is_read'] == false,
                      );
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationScreen(),
                            ),
                          ).then((_) {
                            if (mounted) setState(() {});
                          });
                        },
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          alignment: Alignment.center,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Center(
                                child: SvgPicture.asset(
                                  'assets/icons/ic_notification.svg',
                                  width: 20.w,
                                  height: 20.w,
                                ),
                              ),
                              if (hasUnread)
                                Positioned(
                                  top: 8.w,
                                  right: 8.w,
                                  child: Container(
                                    width: 10.w,
                                    height: 10.w,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 6.w,
                                        height: 6.w,
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.primary,
                                            width: 1.5.w,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 25.h),
              Text(
                'Good Morning, $firstName',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  letterSpacing: globalLetterSpacing,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Find the best\nplace to park',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  letterSpacing: globalLetterSpacing,
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
            ),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                top: 30.h,
                left: 24.w,
                right: 24.w,
                bottom: 20.h,
              ),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: TextField(
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textDark,
                      letterSpacing: globalLetterSpacing,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search',
                      hintStyle: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        letterSpacing: globalLetterSpacing,
                      ),
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: SvgPicture.asset(
                          'assets/icons/ic_search.svg',
                          width: 20.w,
                          height: 20.w,
                          colorFilter: const ColorFilter.mode(
                            AppColors.textLight,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: 50.w,
                        minHeight: 20.w,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 18.h),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Parking Nearby',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        letterSpacing: globalLetterSpacing,
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/icons/ic_more.svg',
                      width: 20.w,
                      height: 20.w,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textLight,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mockParkings.length,
                  itemBuilder: (context, index) {
                    final spot = mockParkings[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 20.h),
                      child: GestureDetector(
                        onTap: () => _showDetailsBottomSheet(context, spot),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16.r),
                              child: Container(
                                width: 80.w,
                                height: 80.w,
                                color: AppColors.inputBackground,
                                child: Center(
                                  child: Icon(
                                    Icons.image,
                                    color: AppColors.textLight,
                                    size: 32.w,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    spot.title,
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                      letterSpacing: globalLetterSpacing,
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/ic_location.svg',
                                        width: 14.w,
                                        height: 14.w,
                                        colorFilter: const ColorFilter.mode(
                                          AppColors.textLight,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        spot.location,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textLight,
                                          letterSpacing: globalLetterSpacing,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '\$${spot.price}/',
                                          style: TextStyle(
                                            fontSize: 20.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.secondary,
                                            letterSpacing: globalLetterSpacing,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'hr',
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
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
