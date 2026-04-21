import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_colors.dart';
import '../services/booking_service.dart';
import 'parking_ticket_screen.dart';
import 'cancel_parking_screen.dart';

/// Модель данных для забронированного места.
/// Хранит данные для карточки на экране "Booked" во всех трех категориях
/// (Ongoing, Completed, Canceled).
class BookedSpot {
  final String id;
  final String spotId;
  final String imagePath;
  final String title;
  final String location;
  final String time;
  final String price;
  final String duration;
  String status;
  final String vehicleName;
  final String vehiclePlate;
  final String name;
  final String phone;
  final String bookingDate;
  BookedSpot({
    required this.id,
    required this.spotId,
    required this.imagePath,
    required this.title,
    required this.location,
    required this.time,
    required this.price,
    required this.duration,
    required this.status,
    required this.vehicleName,
    required this.vehiclePlate,
    required this.name,
    required this.phone,
    required this.bookingDate,
  });
}

/// Экран со списком бронирований ("My Parking").
/// Содержит вкладки для фильтрации: Ongoing (Текущие), Completed (Завершенные) и Canceled (Отмененные).
/// Экран "Мои бронирования".
/// Отображает списки активных (Ongoing), завершенных (Completed) и отмененных (Canceled) бронирований.
/// Использует [DefaultTabController] для переключения между вкладками (TabBar).
class BookedScreen extends StatefulWidget {
  const BookedScreen({super.key});
  @override
  State<BookedScreen> createState() => _BookedScreenState();
}

class _BookedScreenState extends State<BookedScreen> {
  final BookingService _bookingService = BookingService();
  List<BookedSpot> _bookings = [];
  bool _isLoading = true;
  String _selectedTab = 'Ongoing';
  final List<String> _tabs = ['Ongoing', 'Completed', 'Canceled'];
  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  /// Асинхронно загружает историю бронирований текущего пользователя из Supabase (через BookingService).
  Future<void> _loadBookings() async {
    try {
      // 1. Получаем сырой список бронирований (Map) из Supabase
      final data = await _bookingService.getBookings();
      if (mounted) {
        setState(() {
          // 2. Преобразуем каждую запись Map (Словарь) в строго типизированный Dart-объект BookedSpot
          // Это нужно для того, чтобы UI-компоненты получали безопасные (non-nullable) поля.
          _bookings = data
              .map(
                (b) => BookedSpot(
                  id: b['id']?.toString() ?? '',
                  spotId: b['spot_id']?.toString() ?? '',
                  imagePath: 'assets/images/img_parking_1.png',
                  title: b['parking_title'] ?? '-',
                  location: b['location'] ?? '-',
                  time: b['time_range'] ?? '-',
                  price: b['price'] ?? '-',
                  duration: b['duration'] ?? '-',
                  status: b['status'] ?? '-', // статус определяет, в какой вкладке (табе) появится карточка
                  vehicleName: b['vehicle_name'] ?? 'Unknown',
                  vehiclePlate: b['vehicle_plate'] ?? '-',
                  name: b['name'] ?? 'Unknown User',
                  phone: b['phone'] ?? '+000',
                  bookingDate: b['booking_date'] ?? 'Unknown Date',
                ),
              )
              .toList();
              
          // 3. Скрываем индикатор загрузки после успешного парсинга данных
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading bookings: $e');
      if (mounted) {
        setState(() => _isLoading = false); // Если произошла ошибка сети, всё равно снимаем лоадер (исчезает крутилка)
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double globalLetterSpacing = 1.0;
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
          'My Parking',
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
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _tabs.map((tab) => _buildTab(tab)).toList(),
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: Builder(
                builder: (context) {
                  List<BookedSpot> filteredBookings = _bookings.where((spot) {
                    if (_selectedTab == 'Ongoing')
                      return spot.status.toLowerCase() == 'now active';
                    if (_selectedTab == 'Completed')
                      return spot.status.toLowerCase() == 'completed';
                    if (_selectedTab == 'Canceled')
                      return spot.status.toLowerCase() == 'cancelled';
                    return false;
                  }).toList();
                  if (_isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (filteredBookings.isEmpty) {
                    return Center(
                      child: Text(
                        'No $_selectedTab bookings',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 20.w,
                      right: 20.w,
                      bottom: 20.h,
                    ),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      return _buildBookedCard(context, filteredBookings[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Вспомогательный виджет для отрисовки переключателей вкладок на экране.
  Widget _buildTab(String title) {
    bool isSelected = _selectedTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = title;
          });
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.primary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// Строит карточку бронирования (информация о времени, цене, месте).
  /// Меняет кнопки и бейджи (активные/неактивные) в зависимости от статуса (isOngoing, isCompleted, isCanceled).
  Widget _buildBookedCard(BuildContext context, BookedSpot spot) {
    const double globalLetterSpacing = 1.0;
    bool isOngoing = spot.status.toLowerCase() == 'now active';
    bool isCompleted = spot.status.toLowerCase() == 'completed';
    bool isCanceled = spot.status.toLowerCase() == 'cancelled';
    Color badgeColor;
    Color badgeTextColor;
    if (isOngoing) {
      badgeColor = AppColors.primary;
      badgeTextColor = Colors.white;
    } else if (isCompleted) {
      badgeColor = Colors.transparent;
      badgeTextColor = const Color(0xFF4CAF50);
    } else {
      badgeColor = Colors.red.withOpacity(0.1);
      badgeTextColor = Colors.red;
    }
    return Container(
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
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  width: 100.w,
                  height: 100.w,
                  color: AppColors.inputBackground,
                  child: Center(
                    child: Icon(
                      Icons.image,
                      color: AppColors.textLight,
                      size: 40.w,
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
                    Text(
                      spot.location,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textLight,
                        letterSpacing: globalLetterSpacing,
                      ),
                    ),
                    if (isOngoing) SizedBox(height: 12.h),
                    if (isOngoing)
                      Text(
                        spot.time,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                          letterSpacing: globalLetterSpacing,
                        ),
                      ),
                    SizedBox(height: isOngoing ? 8.h : 16.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: spot.price,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  letterSpacing: globalLetterSpacing,
                                ),
                              ),
                              TextSpan(
                                text: ' ${spot.duration}',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textLight,
                                  letterSpacing: globalLetterSpacing,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(6.r),
                            border: isOngoing
                                ? null
                                : Border.all(color: badgeTextColor, width: 1.0),
                          ),
                          child: Text(
                            isCompleted
                                ? 'Completed'
                                : (isCanceled ? 'Canceled' : spot.status),
                            style: TextStyle(
                              color: badgeTextColor,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isOngoing) ...[
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 40.h,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ParkingTicketScreen(ticketInfo: spot),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: Text(
                  'View Ticket',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: globalLetterSpacing,
                  ),
                ),
              ),
            ),
          ] else ...[
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40.h,
                    child: OutlinedButton(
                      onPressed: () {
                        _showCancelBottomSheet(context, spot);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        side: BorderSide(color: AppColors.primary, width: 1.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Cancel Booking',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: globalLetterSpacing,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: SizedBox(
                    height: 40.h,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ParkingTicketScreen(ticketInfo: spot),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'View Ticket',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: globalLetterSpacing,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showCancelBottomSheet(BuildContext context, BookedSpot spot) {
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
                'Cancel Parking',
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
                'Are you sure you want to cancel your\nParking Reservation?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Only 80% of the money you can refund from your payment according to our policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14.sp,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                        ),
                        child: FittedBox(
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
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: SizedBox(
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CancelParkingScreen(spot: spot),
                            ),
                          ).then((_) => _loadBookings());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                        ),
                        child: FittedBox(
                          child: Text(
                            'Yes, Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
            ],
          ),
        );
      },
    );
  }
}
