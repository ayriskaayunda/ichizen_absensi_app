import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF624F82);

  // Backgrounds card
  static const Color background = Color(0xFFF9FAFB);
  static const Color background2 = Color(0xffF9F3EF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFF3F4F6);

  // Text
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color placeholder = Color(0xFF6B7280);

  // Borders & dividers
  static const Color border = Color(0xFFE5E7EB);

  // States
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Added colors for attendance list design, mapping to your existing states
  static const Color accentGreen = AppColors.success;
  static const Color accentRed = AppColors.error;
  static const Color accentOrange =
      AppColors.warning; // untuk text menampilkan text warning

  // Specific light background colors for the cards
  static const Color lightGreenBackground = Color(0xFFE8F5E9);
  static const Color lightRedBackground = Color(0xFFFFEBEE);
  static const Color lightOrangeBackground = Color(0xFFFFF3E0);
}
