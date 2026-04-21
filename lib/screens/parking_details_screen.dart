import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart';
import 'parking_spot_screen.dart';
import '../services/saved_service.dart';

/// Экран с подробной информацией о выбранной парковке.
/// Открывается при клике на карточку парковки на главном экране.
class ParkingDetailsScreen extends StatefulWidget {
  final ParkingSpot spot; // Данные парковки передаются с предыдущего экрана
  const ParkingDetailsScreen({super.key, required this.spot});
  @override
  State<ParkingDetailsScreen> createState() => _ParkingDetailsScreenState();
}

class _ParkingDetailsScreenState extends State<ParkingDetailsScreen> {
  late bool _isSaved;
  final SavedService _savedService = SavedService();
  @override
  void initState() {
    super.initState();
    _isSaved = widget.spot.isSaved;
  }

  @override
  Widget build(BuildContext context) {
    final spot = widget.spot;
    const double globalLetterSpacing = 1.0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Parking Details',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: globalLetterSpacing,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 24.w,
          right: 24.w,
          top: 16.h,
          bottom: MediaQuery.of(context).padding.bottom + 16.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.textLight.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: SizedBox(
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ParkingSpotScreen(),
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
                  child: Text(
                    'View parking',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: globalLetterSpacing,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                width: double.infinity,
                height: 200.h,
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
                Expanded(
                  child: Column(
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
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSaved = !_isSaved;
                      widget.spot.isSaved = _isSaved;
                    });
                    _savedService
                        .toggleSaved(widget.spot.id, _isSaved)
                        .catchError((e) {
                          debugPrint('Failed to sync save state: $e');
                        });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.only(top: 4.h, left: 8.w, bottom: 8.h),
                    child: SvgPicture.asset(
                      _isSaved
                          ? 'assets/icons/ic_bookmark_active.svg'
                          : 'assets/icons/ic_bookmark.svg',
                      width: 24.w,
                      height: 24.w,
                      colorFilter: ColorFilter.mode(
                        _isSaved ? AppColors.primary : AppColors.textLight,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                _buildOutlinedTag(
                  'assets/icons/ic_location.svg',
                  '2 km',
                  globalLetterSpacing,
                ),
                SizedBox(width: 12.w),
                _buildOutlinedTag(
                  'assets/icons/ic_clock.svg',
                  '08:00 - 22:00',
                  globalLetterSpacing,
                ),
              ],
            ),
            SizedBox(height: 32.h),
            Text(
              'Description',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                letterSpacing: globalLetterSpacing,
              ),
            ),
            SizedBox(height: 12.h),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text since the 1500s. ",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textLight,
                      height: 1.5,
                      letterSpacing: globalLetterSpacing,
                    ),
                  ),
                  TextSpan(
                    text: 'Read more...',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      height: 1.5,
                      letterSpacing: globalLetterSpacing,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 24.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '\$${spot.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                      letterSpacing: globalLetterSpacing,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'per hour',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textLight,
                      letterSpacing: globalLetterSpacing,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedTag(
    String iconPath,
    String label,
    double letterSpacing,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary, width: 1),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 14.w,
            height: 14.w,
            colorFilter: const ColorFilter.mode(
              AppColors.primary,
              BlendMode.srcIn,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: letterSpacing,
            ),
          ),
        ],
      ),
    );
  }
}
