import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';

/// Экран обучения / приветствия (Onboarding).
/// Состоит из нескольких "страниц" (слайдов), которые можно листать свайпом.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // PageController управляет виджетом PageView (листы)
  final PageController _pageController = PageController();
  
  // Текущий индекс отображаемого слайда
  int _currentPage = 0;
  
  // Данные слайдов: название картинки и текст
  final List<Map<String, String>> onboardingData = [
    {
      "title": "Book your parking\nspace in advance",
      "image": "assets/images/onboarding_car.png",
    },
    {"title": "Save time", "image": "assets/images/131.png"},
    {"title": "Let's get started!", "image": "assets/images/141.png"},
  ];
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 30.h),
              Row(
                children: List.generate(
                  onboardingData.length,
                  (index) => Expanded(
                    child: Container(
                      height: 4.h,
                      margin: EdgeInsets.only(
                        right: index == onboardingData.length - 1 ? 0 : 8.w,
                      ),
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.indicatorActive
                            : AppColors.indicatorInactive,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (value) {
                    setState(() {
                      _currentPage = value;
                    });
                  },
                  itemCount: onboardingData.length,
                  itemBuilder: (context, index) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 40.h),
                        SizedBox(
                          height: 100.h,
                          child: Text(
                            onboardingData[index]["title"]!,
                            style: TextStyle(
                              fontSize: 36.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: Image.asset(
                            onboardingData[index]["image"]!,
                            fit: BoxFit.contain,
                            height: 350.h,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 300.h,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Image not found:\n${onboardingData[index]["image"]!}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              );
                            },
                          ),
                        ),
                        const Spacer(),
                      ],
                    );
                  },
                ),
              ),
              // "Главная" кнопка внизу экрана. Меняет текст на последнем слайде
              PrimaryButton(
                text: _currentPage == onboardingData.length - 1
                    ? 'Start!'      // На последнем слайде пишем Start
                    : 'Continue',   // На остальных пишем Continue
                onPressed: () {
                  // Если слайд не последний...
                  if (_currentPage < onboardingData.length - 1) {
                    // Анимированно перелистываем на следующий (nextPage)
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    // Если это был последний слайд (Start!), то отправляем юзера на логин
                    context.go('/login');
                  }
                },
              ),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }
}
