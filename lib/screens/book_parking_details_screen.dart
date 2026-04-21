import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import 'payment_screen.dart';

class BookParkingDetailsScreen extends StatefulWidget {
  final String selectedSpotId;
  final String vehicleName;
  final String vehiclePlate;
  const BookParkingDetailsScreen({
    super.key,
    required this.selectedSpotId,
    required this.vehicleName,
    required this.vehiclePlate,
  });
  @override
  State<BookParkingDetailsScreen> createState() =>
      _BookParkingDetailsScreenState();
}

class _BookParkingDetailsScreenState extends State<BookParkingDetailsScreen> {
  double _pricePerHour = 3.0;
  bool _isLoadingPrice = true;
  late DateTime _startTime;
  late DateTime _closingTime;
  List<double> _allowedDurations = [];
  double _durationHours = 1.0;
  int _sliderIndex = 0;
  @override
  void initState() {
    super.initState();
    _fetchPriceFromDb(); // Асинхронно загружаем актуальную цену за час из базы данных
    
    DateTime now = DateTime.now();
    
    // --- Шаг 1: Рассчитываем время старта парковки (_startTime) ---
    // Если сейчас после 22:00 (уже закрыто), сдвигаем бронь на следующее утро (08:00)
    // Если сейчас до 08:00 утра (еще не открыто), ставим старт ровно на 08:00 текущего дня.
    // Если мы в рабочем диапазоне, старт = прямо сейчас.
    if (now.hour >= 22) {
      _startTime = DateTime(now.year, now.month, now.day + 1, 8, 0);
    } else if (now.hour < 8) {
      _startTime = DateTime(now.year, now.month, now.day, 8, 0);
    } else {
      _startTime = now;
    }
    
    // --- Шаг 2: Устанавливаем время закрытия парковки ---
    _closingTime = DateTime(
      _startTime.year,
      _startTime.month,
      _startTime.day,
      22,
      0, // Парковка работает ровно до 22:00
    );
    
    // --- Шаг 3: Вычисляем, сколько часов осталось до конца дня ---
    double remainingHours =
        _closingTime.difference(_startTime).inMinutes / 60.0;
        
    // Максимальная длительность = 14 часов (с 8 утра до 22 вечера)
    if (remainingHours > 14.0) remainingHours = 14.0;
    
    // --- Шаг 4: Формируем шаг слайдера в зависимости от доступного времени ---
    if (remainingHours <= 0) {
      _allowedDurations = [1.0]; // Минимум 1 час, если вдруг логика пересеклась
    } else {
      // Добавляем целые часы (1, 2, 3...)
      for (int i = 1; i <= remainingHours.floor(); i++) {
        _allowedDurations.add(i.toDouble());
      }
      // Добавляем дробный остаток (например, если осталось 2.5 часа)
      if (remainingHours > remainingHours.floor()) {
        _allowedDurations.add(remainingHours);
      }
      if (_allowedDurations.isEmpty) {
        _allowedDurations.add(remainingHours);
      }
    }
    _durationHours = _allowedDurations.first;
    _sliderIndex = 0;
  }

  Future<void> _fetchPriceFromDb() async {
    try {
      final response = await Supabase.instance.client
          .from('parkings')
          .select('price_per_hour')
          .eq('title', 'Mega Park')
          .maybeSingle();
      if (response != null && response['price_per_hour'] != null) {
        if (mounted) {
          setState(() {
            _pricePerHour = (response['price_per_hour'] as num).toDouble();
            _isLoadingPrice = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingPrice = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching price from DB: $e');
      if (mounted) {
        setState(() {
          _isLoadingPrice = false;
        });
      }
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getDurationLabel() {
    if (_durationHours == _durationHours.toInt()) {
      return '${_durationHours.toInt()} hrs';
    } else {
      return '${_durationHours.toStringAsFixed(1)} hrs';
    }
  }

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
          'Book Parking Details',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Duration',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 24.h),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4.h,
                  activeTrackColor: AppColors.primary.withOpacity(0.7),
                  inactiveTrackColor: Colors.grey.withOpacity(0.2),
                  overlayColor: AppColors.primary.withOpacity(0.1),
                  thumbShape: _CustomThumbShape(thumbRadius: 10.r),
                  valueIndicatorShape:
                      const RectangularSliderValueIndicatorShape(),
                  valueIndicatorTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  valueIndicatorColor: AppColors.primary.withOpacity(0.8),
                  showValueIndicator: ShowValueIndicator.always,
                ),
                child: Slider(
                  value: _sliderIndex.toDouble(),
                  min: 0,
                  max: _allowedDurations.length > 1
                      ? (_allowedDurations.length - 1).toDouble()
                      : 1.0,
                  divisions: _allowedDurations.length > 1
                      ? _allowedDurations.length - 1
                      : 1,
                  label: _getDurationLabel(),
                  onChanged: _allowedDurations.length > 1
                      ? (value) {
                          setState(() {
                            _sliderIndex = value.toInt();
                            _durationHours = _allowedDurations[_sliderIndex];
                          });
                        }
                      : null,
                ),
              ),
              SizedBox(height: 32.h),
              Text(
                'Start Hour',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(_startTime),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          Icon(
                            Icons.access_time,
                            color: Colors.black,
                            size: 20.w,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: SvgPicture.asset(
                      'assets/icons/ic_arrow_right.svg',
                      width: 24.w,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(
                              _startTime.add(
                                Duration(
                                  minutes: (_durationHours * 60).round(),
                                ),
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          Icon(
                            Icons.access_time,
                            color: Colors.black,
                            size: 20.w,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 12.h),
              Builder(
                builder: (context) {
                  int payableHours = _durationHours.ceil();
                  return RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _isLoadingPrice
                              ? '...\$ '
                              : '\$${(payableHours * _pricePerHour).toStringAsFixed(2)} ',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        TextSpan(
                          text: '/ $payableHours hours',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textLight.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Continue',
                onPressed: () {
                  int payableHours = _durationHours.ceil();
                  String timeRange =
                      '${_formatTime(_startTime)} - ${_formatTime(_startTime.add(Duration(minutes: (_durationHours * 60).round())))}';
                  String priceLabel =
                      '\$${(payableHours * _pricePerHour).toStringAsFixed(2)}';
                  String durationLabel = '/ $payableHours hours';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        bookingData: {
                          'spotId': widget.selectedSpotId,
                          'parkingTitle': 'Mega Park',
                          'location': 'Rozybakieva',
                          'timeRange': timeRange,
                          'price': priceLabel,
                          'duration': durationLabel,
                          'vehicleName': widget.vehicleName,
                          'vehiclePlate': widget.vehiclePlate,
                        },
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

class _CustomThumbShape extends SliderComponentShape {
  final double thumbRadius;
  const _CustomThumbShape({required this.thumbRadius});
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(thumbRadius);
  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, thumbRadius, fillPaint);
    canvas.drawCircle(center, thumbRadius, borderPaint);
  }
}
