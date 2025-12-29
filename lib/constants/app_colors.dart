import 'package:flutter/material.dart';

/// App Color Constants - Đảm bảo consistency về màu sắc
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFFC1473B);
  static const Color primaryLight = Color(0xFFE57373);
  static const Color primaryDark = Color(0xFF9C1B0B);

  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textWhite = Colors.white;

  // Accent Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC1473B), Color(0xFF9C1B0B)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFAFAFA), Colors.white],
  );

  // Dashboard Card Gradients
  static const LinearGradient cardGradient1 = LinearGradient(
    colors: [Color(0xFFFFF9C4), Color(0xFFFFF59D)],
  );

  static const LinearGradient cardGradient2 = LinearGradient(
    colors: [Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
  );

  static const LinearGradient cardGradient3 = LinearGradient(
    colors: [Color(0xFFFFCDD2), Color(0xFFEF9A9A)],
  );

  static const LinearGradient cardGradient4 = LinearGradient(
    colors: [Color(0xFFD7CCC8), Color(0xFFBCAAA4)],
  );

  // Shadow Colors
  static Color shadow = Colors.black.withValues(alpha: 0.08);
  static Color shadowDark = Colors.black.withValues(alpha: 0.15);

  // Badge & Notification
  static const Color badgeColor = Color(0xFFFF6B6B);
  static const Color badgeBackground = Color(0xFFFFEBEE);

  // Border Colors
  static Color borderColor = Colors.grey.withValues(alpha: 0.2);
  static Color dividerColor = Colors.grey.withValues(alpha: 0.12);
}
