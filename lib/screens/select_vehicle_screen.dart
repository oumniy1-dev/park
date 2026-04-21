import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import '../services/vehicle_service.dart';
import 'new_vehicle_screen.dart';
import 'book_parking_details_screen.dart';

class SelectVehicleScreen extends StatefulWidget {
  final String selectedSpotId;
  const SelectVehicleScreen({super.key, required this.selectedSpotId});
  @override
  State<SelectVehicleScreen> createState() => _SelectVehicleScreenState();
}

class _SelectVehicleScreenState extends State<SelectVehicleScreen> {
  final VehicleService _vehicleService = VehicleService();
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;
  int? _selectedIndex;
  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final vehicles = await _vehicleService.getVehicles();
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
        _selectedIndex = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading vehicles: $e')));
      }
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
          'Select your Vehicle',
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
            children: [
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_vehicles.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.h),
                  child: Center(
                    child: Text(
                      "No vehicles added yet.\nPlease add a new vehicle.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    bool isSelected = _selectedIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = isSelected ? null : index;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 16.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(16.r),
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 1.5)
                              : Border.all(
                                  color: Colors.transparent,
                                  width: 1.5,
                                ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60.w,
                              height: 36.h,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18.r),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Transform.scale(
                                  scale: 1.6,
                                  child: Image.asset(
                                    'assets/icons/ic_car_top.png',
                                    width: 22.h,
                                    height: 46.w,
                                    fit: BoxFit.contain,
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
                                    _vehicles[index]['make'] ?? 'Unknown Make',
                                    style: TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    _vehicles[index]['plate'] ?? '',
                                    style: TextStyle(
                                      color: AppColors.textLight.withOpacity(
                                        0.8,
                                      ),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 24.w,
                              height: 24.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 2.0,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 12.w,
                                        height: 12.w,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NewVehicleScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadVehicles();
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                  child: Center(
                    child: Text(
                      'Add New Vehicle',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Continue',
                onPressed: _selectedIndex != null
                    ? () {
                        final vehicle = _vehicles[_selectedIndex!];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookParkingDetailsScreen(
                              selectedSpotId: widget.selectedSpotId,
                              vehicleName: vehicle['make'] ?? 'Unknown Vehicle',
                              vehiclePlate: vehicle['plate'] ?? '',
                            ),
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
