import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import 'parking_ticket_screen.dart';
import 'booked_screen.dart';

class BookingSuccessfulDialog extends StatelessWidget {
  final BookedSpot ticketInfo;
  const BookingSuccessfulDialog({super.key, required this.ticketInfo});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/img_success.svg',
              width: 140.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 24.h),
            Text(
              'Successful!',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              'Successfully made payment for\nyour parking',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            PrimaryButton(
              text: 'View Parking Ticket',
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ParkingTicketScreen(ticketInfo: ticketInfo),
                  ),
                );
              },
            ),
            SizedBox(height: 16.h),
            PrimaryButton(
              text: 'Back to Home',
              backgroundColor: AppColors.primary.withOpacity(0.1),
              textColor: AppColors.primary,
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}
