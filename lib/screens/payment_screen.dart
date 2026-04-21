import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import 'add_new_card_screen.dart';
import 'review_summary_screen.dart';
import '../services/card_service.dart';

/// Экран выбора способа оплаты перед подтверждением бронирования.
/// Подгружает фейковые способы ([Google Pay], [Apple Pay]) и реальные 
/// банковские карты пользователя из базы Supabase.
class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic>? bookingData; // Данные о процессе бронирования (время, место)
  const PaymentScreen({super.key, this.bookingData});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'Google Pay';
  late Future<List<Map<String, dynamic>>> _cardsFuture;
  @override
  void initState() {
    super.initState();
    _refreshCards();
  }

  void _refreshCards() {
    setState(() {
      _cardsFuture = CardService().getUserCards();
    });
  }

  static const String _googleSvgStr =
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>''';
  static const String _appleSvgStr =
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 384 512">
  <path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5q0 39.3 14.4 81.2c12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.4 49-.9 87.5-81.2 99.4-118-40.4-11.8-58.4-53.7-58.5-92.7zm-86.2-225.2c20.7-25.2 36-59.5 32-94.4-28.8 2.3-64.4 20.2-85.3 46.1-17.9 22-34.5 56.6-29.3 90.6 32.3 2.5 65.5-17.4 82.6-42.3z"/>
</svg>''';
  static const String _mastercardSvgStr =
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <circle fill="#EB001B" cx="12" cy="16" r="10"/>
  <circle fill="#F79E1B" cx="20" cy="16" r="10"/>
  <path fill="#FF5F00" d="M16 6.3C14.5 8.1 13.5 10.4 13.5 13s1 4.9 2.5 6.7c1.5-1.8 2.5-4.1 2.5-6.7S17.5 8.1 16 6.3z" opacity="0.8"/>
</svg>''';
  Widget _buildPaymentMethod(
    String title,
    String svgContent, {
    bool isApple = false,
  }) {
    final bool isSelected = _selectedMethod == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = title;
        });
      },
      child: Container(
        height: 64.h,
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          children: [
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: SvgPicture.string(
                svgContent,
                colorFilter: isApple
                    ? const ColorFilter.mode(Colors.black, BlendMode.srcIn)
                    : null,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textLight.withOpacity(0.5),
                  width: isSelected ? 6.w : 1.5.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double globalLetterSpacing = 1.0;
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
          'Payment',
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
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Payment Methods',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: globalLetterSpacing,
                ),
              ),
              SizedBox(height: 24.h),
              _buildPaymentMethod('Google Pay', _googleSvgStr),
              _buildPaymentMethod('Apple Pay', _appleSvgStr, isApple: true),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _cardsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: snapshot.data!.map((card) {
                      return _buildPaymentMethod(
                        card['masked_number'],
                        _mastercardSvgStr,
                        isApple: false,
                      );
                    }).toList(),
                  );
                },
              ),
              SizedBox(height: 16.h),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddNewCardScreen(),
                    ),
                  );
                  if (result != null && result is String && mounted) {
                    _refreshCards();
                    setState(() {
                      _selectedMethod = result;
                    });
                  }
                },
                child: Container(
                  height: 56.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: AppColors.primary,
                        size: 20.w,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Add New Card',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          letterSpacing: globalLetterSpacing,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Continue',
                onPressed: () {
                  if (widget.bookingData == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: No booking data found'),
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReviewSummaryScreen(
                        bookingData: widget.bookingData!,
                        selectedPaymentMethod: _selectedMethod,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
