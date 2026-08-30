import 'package:flutter/material.dart';

class AppColors {
  static const Color softPink = Color(0xFFFFD1DC);
  static const Color softBlue = Color(0xFFADD8E6);
  static const Color mintGreen = Color(0xFF98FB98);
  static const Color softYellow = Color(0xFFFFFACD);
  static const Color lavender = Color(0xFFE6E6FA);

  static const Color background = Color(0xFFFDFDFD);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF757575);

  // Gradient Biru (6155F5 -> 0284F6)
  static const Color gradientBlueStart = Color(0xFF6155F5);
  static const Color gradientBlueEnd = Color(0xFF0284F6);

  static const LinearGradient gradientBiru = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF6155F5),
      Color(0xFF0284F6),
    ],
  );

  // Gradient Orange (FFCC00 -> F96E0D, atas kebawah)
  static const LinearGradient gradientOrange = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFCC00),
      Color(0xFFF96E0D),
    ],
  );

  // Gradient Partner Blue (0088FF -> 0775D5, kiri ke kanan)
  static const LinearGradient gradientPartnerBlue = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF0088FF),
      Color(0xFF0775D5),
    ],
  );

  // Gradient Avatar Ring (985CF8 atas -> AEBFFF tengah -> 0088FF bawah)
  static const LinearGradient gradientAvatarRing = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF985CF8),
      Color(0xFFAEBFFF),
      Color(0xFF0088FF),
    ],
  );

  // Book List Screen Theme Tokens
  static const Color primaryPurple = Color(0xFF5D5FEF);
  static const Color progressOrange = Color(0xFFFF7A00);
  static const Color fabGold = Color(0xFFFFB300);
  static const Color cardDarkText = Color(0xFF1E293B);
  static const Color cardSubText = Color(0xFF94A3B8);

  static const LinearGradient gradientProgressOrange = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFF7A00),
      Color(0xFFFF4848),
    ],
  );
}
