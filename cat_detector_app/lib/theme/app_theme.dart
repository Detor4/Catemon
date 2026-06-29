import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Markazlashtirilgan typography + ThemeData.
class AppText {
  const AppText._();

  /// Nunito 900 italic — sarlavhalar.
  static TextStyle display(double size, {Color color = AppColors.textPrimary}) {
    return GoogleFonts.nunito(
      fontSize: size,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: color,
      letterSpacing: -0.5,
      height: 1.05,
    );
  }

  /// Nunito 800 — score, raqam, rarity yorliqlari.
  static TextStyle game(double size, {Color color = AppColors.textPrimary}) {
    return GoogleFonts.nunito(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color,
    );
  }

  /// Nunito 700 — kichik sarlavhalar.
  static TextStyle heading(double size, {Color color = AppColors.textPrimary}) {
    return GoogleFonts.nunito(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }

  /// Inter — body matn.
  static TextStyle body(
    double size, {
    Color color = AppColors.textSecondary,
    FontWeight weight = FontWeight.w400,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  /// CAPS yorliqlar — +1.5 tracking.
  static TextStyle caps(double size, {Color color = AppColors.textPrimary}) {
    return GoogleFonts.nunito(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 1.5,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static const radiusCard = 20.0;
  static const radiusButton = 14.0;
  static const radiusPill = 50.0;
  static const radiusCamera = 24.0;

  static List<BoxShadow> cardShadow = const [
    BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 8)),
  ];

  static List<BoxShadow> glow(Color color, {double blur = 24, double spread = 0}) {
    return [
      BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: blur, spreadRadius: spread),
    ];
  }

  static List<BoxShadow> neon(Color color) {
    return [
      BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 0),
    ];
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentSecondary,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      splashColor: AppColors.accent.withValues(alpha: 0.1),
    );
  }
}
