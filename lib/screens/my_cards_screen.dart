import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_colors.dart';
import '../services/card_service.dart';
import 'add_new_card_screen.dart';

/// Экран "Мои карты оплаты" (Payment Methods).
/// Показывает список добавленных банковских карт, загружаемых из Supabase.
/// Здесь можно выделять карточки (кликом) и удалять их.
class MyCardsScreen extends StatefulWidget {
  const MyCardsScreen({super.key});
  @override
  State<MyCardsScreen> createState() => _MyCardsScreenState();
}

class _MyCardsScreenState extends State<MyCardsScreen> {
  final CardService _cardService = CardService();
  
  List<Map<String, dynamic>> _cards = []; // Список скачанных карт из базы
  bool _isLoading = true; // Показывать ли загрузку при старте экрана
  bool _isDeleting = false; // Показывать ли загрузку на кнопке "Delete"
  
  // Set (Множество) хранит уникальные ID карт, которые пользователь выделил для удаления
  final Set<dynamic> _selectedIds = {};
  static const String _mastercardSvgStr =
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <circle fill="#EB001B" cx="12" cy="16" r="10"/>
  <circle fill="#F79E1B" cx="20" cy="16" r="10"/>
  <path fill="#FF5F00" d="M16 6.3C14.5 8.1 13.5 10.4 13.5 13s1 4.9 2.5 6.7c1.5-1.8 2.5-4.1 2.5-6.7S17.5 8.1 16 6.3z" opacity="0.8"/>
</svg>''';
  @override
  void initState() {
    super.initState();
    _loadCards(); // При заходе на экран сразу идем грузить карты из Supabase
  }

  /// Асинхронно скачиваем карты пользователя из базы данных
  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
      _selectedIds.clear(); // Сбрасываем выделение при обновлении списка
    });
    try {
      final cards = await _cardService.getUserCards();
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading cards: $e')));
      }
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    setState(() {
      _isDeleting = true;
    });
    try {
      await _cardService.deleteCards(_selectedIds.toList());
      await _loadCards();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting cards: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = _selectedIds.isNotEmpty;
    final Color buttonColor = hasSelection
        ? const Color(0xFFFA4D50)
        : const Color(0xFFEB6D6F);
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
          'Payment Methods',
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
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_cards.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      "No payment methods added yet.\nPlease add a new card.",
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
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _cards.length,
                    itemBuilder: (context, index) {
                      final card = _cards[index];
                      final dynamic cardId = card['id'];
                      final bool isSelected = _selectedIds.contains(cardId);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(cardId);
                            } else {
                              _selectedIds.add(cardId);
                            }
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
                                ? Border.all(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  )
                                : Border.all(
                                    color: Colors.transparent,
                                    width: 1.5,
                                  ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60.w,
                                height: 40.h,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.2),
                                  ),
                                ),
                                child: SizedBox(
                                  width: 32.w,
                                  height: 32.w,
                                  child: SvgPicture.string(_mastercardSvgStr),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      card['masked_number'] ?? 'Unknown Card',
                                      style: TextStyle(
                                        color: AppColors.textDark,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      card['cardholder_name'] ?? '',
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
                ),
              if (_cards.isNotEmpty) SizedBox(height: 24.h),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddNewCardScreen(),
                    ),
                  );
                  if (result != null) {
                    _loadCards();
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
                      'Add New Card',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: IgnorePointer(
                  ignoring: !hasSelection || _isDeleting,
                  child: ElevatedButton(
                    onPressed: hasSelection && !_isDeleting
                        ? _deleteSelected
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      disabledBackgroundColor: buttonColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                    ),
                    child: _isDeleting
                        ? SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          )
                        : Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
