import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import '../services/booking_service.dart';
import 'booking_successful_screen.dart';
import 'booked_screen.dart';

class ReviewSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final String selectedPaymentMethod;
  const ReviewSummaryScreen({
    super.key,
    required this.bookingData,
    required this.selectedPaymentMethod,
  });
  @override
  State<ReviewSummaryScreen> createState() => _ReviewSummaryScreenState();
}

class _ReviewSummaryScreenState extends State<ReviewSummaryScreen> {
  final BookingService _bookingService = BookingService();
  bool _isLoading = false;
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: isTotal ? AppColors.textDark : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    const double globalLetterSpacing = 1.0;
    final now = DateTime.now();
    final List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final String currentDateStr =
        '${months[now.month - 1]} ${now.day}, ${now.year}';
    String rawPrice = widget.bookingData['price'].toString().replaceAll(
      '\$',
      '',
    );
    double amount = double.tryParse(rawPrice) ?? 0.0;
    double taxes = amount * 0.10;
    double total = amount + taxes;
    final String timeRange = widget.bookingData['timeRange'];
    final String durationLabel = widget.bookingData['duration']
        .toString()
        .replaceAll('/', '')
        .trim();
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
          'Review Summary',
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
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCard(
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              'Parking Area',
                              widget.bookingData['parkingTitle'],
                            ),
                            _buildSummaryRow(
                              'Address',
                              widget.bookingData['location'],
                            ),
                            _buildSummaryRow(
                              'Vehicle',
                              '${widget.bookingData['vehicleName']} (${widget.bookingData['vehiclePlate']})',
                            ),
                            _buildSummaryRow(
                              'Parking Spot',
                              'Spot (${widget.bookingData['spotId']})',
                            ),
                            _buildSummaryRow('Date', currentDateStr),
                            _buildSummaryRow('Duration', durationLabel),
                            _buildSummaryRow('Hours', timeRange),
                          ],
                        ),
                      ),
                      _buildCard(
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              'Amount',
                              '\$${amount.toStringAsFixed(2)}',
                            ),
                            _buildSummaryRow(
                              'Taxes & Fees (10%)',
                              '\$${taxes.toStringAsFixed(2)}',
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Divider(
                                color: Colors.grey.withOpacity(0.2),
                                thickness: 1,
                              ),
                            ),
                            _buildSummaryRow(
                              'Total',
                              '\$${total.toStringAsFixed(2)}',
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                      _buildCard(
                        child: Row(
                          children: [
                            if (widget.selectedPaymentMethod == 'Apple Pay')
                              Icon(Icons.apple, size: 32.w, color: Colors.black)
                            else if (widget.selectedPaymentMethod ==
                                'Google Pay')
                              Container(
                                width: 32.w,
                                height: 32.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.withOpacity(0.1),
                                ),
                                child: Center(
                                  child: Text(
                                    'G',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18.sp,
                                    ),
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                width: 32.w,
                                height: 32.w,
                                child: SvgPicture.string(
                                  '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
                                  <circle fill="#EB001B" cx="12" cy="16" r="10"/>
                                  <circle fill="#F79E1B" cx="20" cy="16" r="10"/>
                                  <path fill="#FF5F00" d="M16 6.3C14.5 8.1 13.5 10.4 13.5 13s1 4.9 2.5 6.7c1.5-1.8 2.5-4.1 2.5-6.7S17.5 8.1 16 6.3z" opacity="0.8"/>
                                </svg>''',
                                ),
                              ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Text(
                                widget.selectedPaymentMethod == 'New Card Added'
                                    ? '.... .... .... 4679'
                                    : widget.selectedPaymentMethod,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Change',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      text: 'Confirm Payment',
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });
                        try {
                          String finalPriceLabel =
                              '\$${total.toStringAsFixed(2)}';
                          await _bookingService.addBooking(
                            spotId: widget.bookingData['spotId'],
                            parkingTitle: widget.bookingData['parkingTitle'],
                            location: widget.bookingData['location'],
                            timeRange: widget.bookingData['timeRange'],
                            price: finalPriceLabel,
                            duration: widget.bookingData['duration'],
                            vehicleName: widget.bookingData['vehicleName'],
                            vehiclePlate: widget.bookingData['vehiclePlate'],
                          );
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                            final user =
                                Supabase.instance.client.auth.currentUser;
                            final metadata = user?.userMetadata ?? {};
                            final String name =
                                metadata['full_name'] ?? 'Unknown User';
                            final String phone =
                                metadata['phone'] ?? '+7 700 000 00 00';
                            final fakeSpot = BookedSpot(
                              id: '',
                              spotId: widget.bookingData['spotId'],
                              imagePath: 'assets/images/img_parking_1.png',
                              title: widget.bookingData['parkingTitle'],
                              location: widget.bookingData['location'],
                              time: widget.bookingData['timeRange'],
                              price: finalPriceLabel,
                              duration: widget.bookingData['duration'],
                              status: 'Now active',
                              vehicleName: widget.bookingData['vehicleName'],
                              vehiclePlate: widget.bookingData['vehiclePlate'],
                              name: name,
                              phone: phone,
                              bookingDate: currentDateStr,
                            );
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) =>
                                  BookingSuccessfulDialog(ticketInfo: fakeSpot),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
