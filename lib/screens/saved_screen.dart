import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart' show mockParkings, ParkingSpot;
import '../services/saved_service.dart';
import 'parking_details_screen.dart';

/// Экран "Закладки" (My Bookmark).
/// Отображает все парковочные места, которые пользователь пометил флажком "isSaved".
class SavedScreen extends StatefulWidget {
  // onStateSelected используется для передачи события обратно родительскому виджету (экрану Home),
  // чтобы перерисовать там иконки закладок, если мы убрали место из закладок здесь сверху.
  final VoidCallback onStateSelected;
  const SavedScreen({super.key, required this.onStateSelected});
  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final SavedService _savedService = SavedService();
  @override
  Widget build(BuildContext context) {
    const double globalLetterSpacing = 1.0;
    
    // Фильтруем оригинальный массив мест: берем только те, у которых isSaved == true
    final savedSpots = mockParkings.where((spot) => spot.isSaved).toList();
    
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
          'My Bookmark',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: globalLetterSpacing,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 24.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: TextField(
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textDark,
                    letterSpacing: globalLetterSpacing,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search',
                    hintStyle: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      letterSpacing: globalLetterSpacing,
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: SvgPicture.asset(
                        'assets/icons/ic_search.svg',
                        width: 20.w,
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
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: savedSpots.isEmpty
                  ? Center(
                      child: Text(
                        'No saved parking spots.',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 16.sp,
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        left: 20.w,
                        right: 20.w,
                        bottom: 20.h,
                      ),
                      itemCount: savedSpots.length,
                      itemBuilder: (context, index) {
                        final spot = savedSpots[index];
                        return _buildSavedCard(context, spot);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedCard(BuildContext context, ParkingSpot spot) {
    const double globalLetterSpacing = 1.0;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ParkingDetailsScreen(spot: spot),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: 20.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                mainAxisAlignment: MainAxisAlignment.center,
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
            ),
            // Кнопка-иконка "Убрать из закладок"
            GestureDetector(
              onTap: () {
                // setState говорит Flutter: "состояние изменилось, перерисуй этот кусок UI!"
                setState(() {
                  spot.isSaved = !spot.isSaved;
                });
                
                // Вызываем коллбек, чтобы обновить родительский экран (Home)
                widget.onStateSelected();
                
                // Отправляем изменения в Supabase базу данных (фоново)
                _savedService.toggleSaved(spot.id, spot.isSaved).catchError((
                  e,
                ) {
                  debugPrint('Failed to sync save state: $e');
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: SvgPicture.asset(
                  spot.isSaved
                      ? 'assets/icons/ic_bookmark_active.svg'
                      : 'assets/icons/ic_bookmark.svg',
                  key: UniqueKey(),
                  width: 24.w,
                  colorFilter: ColorFilter.mode(
                    spot.isSaved ? AppColors.primary : AppColors.textLight,
                    BlendMode.srcIn,
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
