import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import '../services/card_service.dart';

/// Экран "Добавить новую карту" (New Card).
/// Здесь пользователь вводит данные своей банковской карты, 
/// после чего номер карты маскируется и сохраняется в базу данных.
class AddNewCardScreen extends StatefulWidget {
  const AddNewCardScreen({super.key});
  @override
  State<AddNewCardScreen> createState() => _AddNewCardScreenState();
}

class _AddNewCardScreenState extends State<AddNewCardScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  bool _isLoading = false;
  
  // MaskTextInputFormatter - супер мощный плагин, который заставляет текстовое поле
  // автоматически подстраивать вводимые символы под нужный шаблон (маску).
  // Символ "#" означает "разрешена только цифра".
  
  // Маска для номера карты: 16 цифр, разбитых пробелами по 4.
  final _cardNumberMask = MaskTextInputFormatter(
    mask: '#### #### #### ####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _expiryMask = MaskTextInputFormatter(
    mask: '##/##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _cvvMask = MaskTextInputFormatter(
    mask: '###',
    filter: {"#": RegExp(r'[0-9]')},
  );
  @override
  void dispose() {
    _nameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    TextInputFormatter? formatter,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 56.h,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Center(
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatter != null ? [formatter] : null,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
            letterSpacing: 1.0,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textLight.withOpacity(0.7),
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
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
          'New Card',
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
              _buildTextField(
                hint: 'Cardholder Name',
                controller: _nameController,
              ),
              SizedBox(height: 20.h),
              _buildTextField(
                hint: 'Card Number',
                controller: _cardNumberController,
                formatter: _cardNumberMask,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      hint: 'Expiry (MM/YY)',
                      controller: _expiryController,
                      formatter: _expiryMask,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildTextField(
                      hint: 'CVV',
                      controller: _cvvController,
                      formatter: _cvvMask,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      text: 'Add New Card',
                      onPressed: () async {
                        if (_cardNumberController.text.length < 16 ||
                            _nameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter valid card details'),
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _isLoading = true;
                        });
                        try {
                          await CardService().addCard(
                            cardholderName: _nameController.text.trim(),
                            cardNumber: _cardNumberController.text.trim(),
                            expiry: _expiryController.text.trim(),
                            cvv: _cvvController.text.trim(),
                          );
                          if (mounted) {
                            String clean = _cardNumberController.text
                                .replaceAll(' ', '');
                            String masked = '.... .... .... ';
                            if (clean.length >= 4) {
                              masked += clean.substring(clean.length - 4);
                            } else {
                              masked += clean;
                            }
                            Navigator.pop(context, masked);
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error adding card: $e')),
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
