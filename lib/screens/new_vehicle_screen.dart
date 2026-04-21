import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import '../services/vehicle_service.dart';

class NewVehicleScreen extends StatefulWidget {
  const NewVehicleScreen({super.key});
  @override
  State<NewVehicleScreen> createState() => _NewVehicleScreenState();
}

class _NewVehicleScreenState extends State<NewVehicleScreen> {
  final VehicleService _vehicleService = VehicleService();
  bool _isLoading = false;
  final TextEditingController _makeController = TextEditingController();
  final FocusNode _makeFocusNode = FocusNode();
  final TextEditingController _plateMiddleController = TextEditingController();
  final FocusNode _plateMiddleFocusNode = FocusNode();
  final TextEditingController _plateRegionController = TextEditingController();
  final FocusNode _plateRegionFocusNode = FocusNode();
  bool get _isFormValid {
    return _makeController.text.isNotEmpty &&
        _plateMiddleController.text.isNotEmpty &&
        _plateRegionController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _makeFocusNode.addListener(() => setState(() {}));
    _makeController.addListener(() => setState(() {}));
    _plateMiddleController.addListener(() {
      setState(() {});
      if (_plateMiddleController.text.length == 7) {
        _plateRegionFocusNode.requestFocus();
      }
    });
    _plateRegionController.addListener(() {
      setState(() {});
      if (_plateRegionController.text.isEmpty) {}
    });
  }

  @override
  void dispose() {
    _makeFocusNode.dispose();
    _makeController.dispose();
    _plateMiddleFocusNode.dispose();
    _plateMiddleController.dispose();
    _plateRegionFocusNode.dispose();
    _plateRegionController.dispose();
    super.dispose();
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
          'New Vehicle',
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
              Container(
                decoration: BoxDecoration(
                  color:
                      (_makeFocusNode.hasFocus ||
                          _makeController.text.isNotEmpty)
                      ? AppColors.primary.withOpacity(0.10)
                      : AppColors.primary.withOpacity(0.05),
                  border: _makeFocusNode.hasFocus
                      ? Border.all(color: AppColors.primary, width: 1.0)
                      : Border.all(color: Colors.transparent, width: 1.0),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                child: TextField(
                  controller: _makeController,
                  focusNode: _makeFocusNode,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Car Make',
                    hintStyle: TextStyle(
                      color: AppColors.textLight.withOpacity(0.7),
                      fontSize: 14.sp,
                    ),
                    icon: SvgPicture.asset(
                      'assets/icons/ic_car.svg',
                      width: 24.w,
                      colorFilter: ColorFilter.mode(
                        (_makeFocusNode.hasFocus ||
                                _makeController.text.isNotEmpty)
                            ? AppColors.primary
                            : AppColors.textLight.withOpacity(0.8),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              Container(
                height: 72.h,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2.0),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 40.w,
                      padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '🇰🇿',
                            style: TextStyle(fontSize: 22.sp, height: 1.0),
                          ),
                          Text(
                            'KZ',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 14.sp,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Center(
                          child: TextField(
                            controller: _plateMiddleController,
                            focusNode: _plateMiddleFocusNode,
                            textAlign: TextAlign.center,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [_KzMiddleFormatter()],
                            style: GoogleFonts.inter(
                              fontSize: 42.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              letterSpacing: 1.0,
                              height: 1.1,
                            ),
                            decoration: InputDecoration(
                              hintText: '000 AAA',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 42.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textLight.withOpacity(0.5),
                                letterSpacing: 1.0,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 2.0, color: Colors.black),
                    SizedBox(
                      width: 70.w,
                      child: Center(
                        child: TextField(
                          controller: _plateRegionController,
                          focusNode: _plateRegionFocusNode,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          style: GoogleFonts.inter(
                            fontSize: 42.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            letterSpacing: 1.0,
                            height: 1.1,
                          ),
                          decoration: InputDecoration(
                            hintText: '00',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 42.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight.withOpacity(0.5),
                              letterSpacing: 1.0,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      text: 'Continue',
                      onPressed: _isFormValid
                          ? () async {
                              setState(() {
                                _isLoading = true;
                              });
                              try {
                                String fullPlate =
                                    '${_plateMiddleController.text} ${_plateRegionController.text}'
                                        .trim();
                                await _vehicleService.addVehicle(
                                  make: _makeController.text.trim(),
                                  plate: fullPlate,
                                );
                                if (mounted) {
                                  Navigator.pop(context, true);
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error adding vehicle: $e'),
                                    ),
                                  );
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              }
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

class _KzMiddleFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) return newValue;
    String raw = newValue.text.toUpperCase();
    String formatted = '';
    int digits = 0;
    int letters = 0;
    for (int i = 0; i < raw.length; i++) {
      String char = raw[i];
      if (digits < 3) {
        if (RegExp(r'[0-9]').hasMatch(char)) {
          formatted += char;
          digits++;
        }
      } else {
        if (letters == 0 && !formatted.endsWith(' ')) {
          formatted += ' ';
        }
        if (RegExp(r'[A-Z]').hasMatch(char)) {
          formatted += char;
          letters++;
        }
      }
      if (letters == 3) break;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
