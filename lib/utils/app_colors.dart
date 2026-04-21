import 'package:flutter/material.dart';

/// Хранилище всех константных цветов и градиентов, используемых в приложении.
/// Обеспечивает единую стилистику и позволяет легко поменять цвета (тему) во всем проекте.
class AppColors {
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6D78EB), Color(0xFF4D5DFA)],
  );
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF4D5DFA), Color(0xFF6D78EB)],
  );
  static const Color primary = Color(0xFF4D5DFA);
  static const Color secondary = Color(0xFF6D78EB);
  static const Color background = Color(0xFFFFFFFF);
  static const Color indicatorActive = Color(0xFF4D5DFA);
  static const Color indicatorInactive = Color(0xFFE0E0E0);
  static const Color textDark = Color(0xFF212121);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color inputBackground = Color(0xFFF5F8FE);
  static const Color errorColor = Color(0xFFF74B4B);
}
