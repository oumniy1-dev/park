import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import 'home_screen.dart';
import 'booked_screen.dart';
import '../services/auth_service.dart';

/// Экран парковочного талона (Parking Ticket).
/// Генерирует визуальный "билет" с QR-кодом для въезда на парковку.
/// Нижняя часть рисуется программно с помощью [CustomPainter] для эффекта "отрезанных краев".
class ParkingTicketScreen extends StatelessWidget {
  final BookedSpot? ticketInfo; // Информация о брони передается на этот экран
  const ParkingTicketScreen({super.key, this.ticketInfo});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          'Parking Ticket',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: CustomPaint(
                  painter: TicketPainter(),
                  child: Container(
                    padding: EdgeInsets.all(24.w),
                    width: double.infinity,
                    child: Builder(
                      builder: (context) {
                        final user = AuthService().getCurrentUser();
                        final String dynamicName =
                            user?.userMetadata?['full_name'] as String? ??
                            ticketInfo?.name ??
                            'Andrew Ainsley';
                        final String dynamicPhone =
                            user?.userMetadata?['phone'] as String? ??
                            ticketInfo?.phone ??
                            '+1 111 467 378 399';
                        return Column(
                          children: [
                            SizedBox(height: 8.h),
                            Text(
                              'Scan this on the scanner machine\nwhen you are in the parking lot',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 24.h),
                            Icon(
                              Icons.qr_code_2,
                              size: 200.w,
                              color: Colors.black,
                            ),
                            SizedBox(height: 48.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildDetailItem('Name', dynamicName),
                                ),
                                Expanded(
                                  child: _buildDetailItem(
                                    'Vehicle',
                                    '${ticketInfo?.vehicleName ?? 'Ford F'} (${ticketInfo?.vehiclePlate ?? 'AF 4793 JU'})',
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildDetailItem(
                                    'Parking Area',
                                    ticketInfo?.title ?? 'Mega Park',
                                  ),
                                ),
                                Expanded(
                                  child: _buildDetailItem(
                                    'Parking Spot',
                                    '1st Floor (${ticketInfo?.spotId ?? 'A05'})',
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildDetailItem(
                                    'Duration',
                                    ticketInfo?.duration
                                            .replaceAll('/', '')
                                            .trim() ??
                                        '4 hours',
                                  ),
                                ),
                                Expanded(
                                  child: _buildDetailItem(
                                    'Date',
                                    ticketInfo?.bookingDate ??
                                        'December 16, 2024',
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildDetailItem(
                                    'Hours',
                                    ticketInfo?.time ?? '09 AM - 13 PM',
                                  ),
                                ),
                                Expanded(
                                  child: _buildDetailItem(
                                    'Phone',
                                    dynamicPhone,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: PrimaryButton(
                text: 'Go to Home',
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Класс [TicketPainter] наследуется от CustomPainter.
/// Он отвечает за рисование фона билета (белый прямоугольник с "дырками" по бокам
/// и пунктирной линией разрыва посередине).
class TicketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    final path = Path();
    final radius = 24.0.r;
    final cutoutRadius = 16.0.r;
    final cutoutY = size.height * 0.52;
    path.moveTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, cutoutY - cutoutRadius);
    path.arcToPoint(
      Offset(size.width, cutoutY + cutoutRadius),
      radius: Radius.circular(cutoutRadius),
      clockwise: false,
    );
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - radius,
      size.height,
    );
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.lineTo(0, cutoutY + cutoutRadius);
    path.arcToPoint(
      Offset(0, cutoutY - cutoutRadius),
      radius: Radius.circular(cutoutRadius),
      clockwise: false,
    );
    path.lineTo(0, radius);
    path.close();
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
    final dashPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startX = cutoutRadius + 5.0;
    while (startX < size.width - cutoutRadius - 5.0) {
      canvas.drawLine(
        Offset(startX, cutoutY),
        Offset(startX + dashWidth, cutoutY),
        dashPaint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
