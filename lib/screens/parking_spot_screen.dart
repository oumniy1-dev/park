import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import 'select_vehicle_screen.dart';
import '../services/booking_service.dart';

enum SpotStatus { occupied, available, reserved, selected }

class ParkingSpotModel {
  final String id;
  SpotStatus status;
  ParkingSpotModel({required this.id, required this.status});
}

class ParkingSpotScreen extends StatefulWidget {
  const ParkingSpotScreen({super.key});
  @override
  State<ParkingSpotScreen> createState() => _ParkingSpotScreenState();
}

class _ParkingSpotScreenState extends State<ParkingSpotScreen> {
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  int _selectedFloorIndex = 0;
  @override
  void initState() {
    super.initState();
    BookingService().checkAndClearExpiredBookingsGlobally();
    _subscription = Supabase.instance.client
        .from('parking_spots')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
          if (!mounted) return;
          setState(() {
            for (var dbSpot in data) {
              final id = dbSpot['id'] as String;
              final statusStr = dbSpot['status'] as String;
              SpotStatus newStatus;
              if (statusStr == 'occupied') {
                newStatus = SpotStatus.occupied;
              } else if (statusStr == 'booked') {
                newStatus = SpotStatus.reserved;
              } else {
                newStatus = SpotStatus.available;
              }
              List<ParkingSpotModel> allSpots = [
                ..._parkingRows.expand((row) => row),
                ..._parkingRowsBottom.expand((row) => row),
              ];
              for (var s in allSpots) {
                if (s.id == id) {
                  if (s.status == SpotStatus.selected &&
                      newStatus == SpotStatus.occupied) {
                    s.status = SpotStatus.occupied;
                  } else if (s.status != SpotStatus.selected) {
                    s.status = newStatus;
                  }
                }
              }
            }
          });
        });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  final List<String> _floors = [
    '1st Floor',
    '2nd Floor',
    '3rd Floor',
    '4th Floor',
  ];
  final List<List<ParkingSpotModel>> _parkingRows = [
    [
      ParkingSpotModel(id: 'A01', status: SpotStatus.available),
      ParkingSpotModel(id: 'A02', status: SpotStatus.available),
    ],
    [
      ParkingSpotModel(id: 'A03', status: SpotStatus.available),
      ParkingSpotModel(id: 'A04', status: SpotStatus.available),
    ],
    [
      ParkingSpotModel(id: 'A05', status: SpotStatus.available),
      ParkingSpotModel(id: 'A06', status: SpotStatus.available),
    ],
  ];
  final List<List<ParkingSpotModel>> _parkingRowsBottom = [
    [
      ParkingSpotModel(id: 'A07', status: SpotStatus.available),
      ParkingSpotModel(id: 'A08', status: SpotStatus.available),
    ],
    [
      ParkingSpotModel(id: 'A09', status: SpotStatus.available),
      ParkingSpotModel(id: 'A10', status: SpotStatus.available),
    ],
    [
      ParkingSpotModel(id: 'A11', status: SpotStatus.available),
      ParkingSpotModel(id: 'A12', status: SpotStatus.available),
    ],
  ];
  bool get _hasSelectedSpot {
    return _parkingRows
            .expand((row) => row)
            .any((s) => s.status == SpotStatus.selected) ||
        _parkingRowsBottom
            .expand((row) => row)
            .any((s) => s.status == SpotStatus.selected);
  }

  @override
  Widget build(BuildContext context) {
    const double globalLetterSpacing = 1.0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
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
          'Parking Spot',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: globalLetterSpacing,
          ),
        ),
        titleSpacing: 0,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: PrimaryButton(
            text: 'Book a Parking Space',
            onPressed: _hasSelectedSpot
                ? () {
                    String selectedSpotId =
                        [..._parkingRows, ..._parkingRowsBottom]
                            .expand((row) => row)
                            .firstWhere((s) => s.status == SpotStatus.selected)
                            .id;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SelectVehicleScreen(selectedSpotId: selectedSpotId),
                      ),
                    );
                  }
                : null,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 16.h),
            SizedBox(
              height: 40.h,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _floors.length,
                separatorBuilder: (context, index) => SizedBox(width: 12.w),
                itemBuilder: (context, index) {
                  final isSelected = _selectedFloorIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFloorIndex = index),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.6),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        _floors[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.primary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: globalLetterSpacing,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 32.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 40.w,
                    child: Padding(
                      padding: EdgeInsets.only(top: 100.h),
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          '2 W A Y   T R A F F I C',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 10.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 257.w,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: Text(
                              'Entry',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 257.w,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AppColors.textLight.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            children: _parkingRows
                                .map((row) => _buildParkingRow(row))
                                .toList(),
                          ),
                        ),
                        SizedBox(
                          width: 257.w,
                          height: 50.h,
                          child: Row(
                            children: List.generate(
                              9,
                              (index) => Expanded(
                                child: Container(
                                  height: 1,
                                  margin: EdgeInsets.symmetric(horizontal: 6.w),
                                  color: index % 2 == 0
                                      ? AppColors.textLight.withOpacity(0.6)
                                      : Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 257.w,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AppColors.textLight.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            children: _parkingRowsBottom
                                .map((row) => _buildParkingRow(row))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildParkingRow(List<ParkingSpotModel> spots) {
    return Column(
      children: [
        SizedBox(
          height: 72.h,
          child: Row(
            children: [
              Expanded(child: Center(child: _buildSpotWidget(spots[0]))),
              Container(
                width: 1,
                height: 72.h,
                color: AppColors.textLight.withOpacity(0.5),
              ),
              Expanded(child: Center(child: _buildSpotWidget(spots[1]))),
            ],
          ),
        ),
        Container(
          width: 257.w,
          height: 1,
          color: AppColors.textLight.withOpacity(0.5),
        ),
      ],
    );
  }

  Widget _buildSpotWidget(ParkingSpotModel spot) {
    return GestureDetector(
      onTap: () {
        if (spot.status == SpotStatus.available) {
          setState(() {
            for (var row in _parkingRows) {
              for (var s in row) {
                if (s.status == SpotStatus.selected)
                  s.status = SpotStatus.available;
              }
            }
            for (var row in _parkingRowsBottom) {
              for (var s in row) {
                if (s.status == SpotStatus.selected)
                  s.status = SpotStatus.available;
              }
            }
            spot.status = SpotStatus.selected;
          });
        } else if (spot.status == SpotStatus.selected) {
          setState(() {
            spot.status = SpotStatus.available;
          });
        }
      },
      child: Center(
        child: () {
          switch (spot.status) {
            case SpotStatus.occupied:
              return SizedBox(
                width: 90.w,
                height: 42.h,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Transform.scale(
                    scale: 1.6,
                    child: Image.asset(
                      'assets/icons/ic_car_top.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            case SpotStatus.available:
              return Container(
                width: 100.w,
                height: 42.h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.primary, width: 1.0),
                ),
                alignment: Alignment.center,
                child: Text(
                  spot.id,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
              );
            case SpotStatus.reserved:
              return Container(
                width: 100.w,
                height: 42.h,
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  spot.id,
                  style: TextStyle(
                    color: AppColors.errorColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
              );
            case SpotStatus.selected:
              return Container(
                width: 100.w,
                height: 42.h,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      spot.id,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Icon(
                        Icons.check,
                        color: AppColors.primary,
                        size: 14.w,
                      ),
                    ),
                  ],
                ),
              );
          }
        }(),
      ),
    );
  }
}
