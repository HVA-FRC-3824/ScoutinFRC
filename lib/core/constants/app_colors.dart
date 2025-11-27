import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFFC107);
  static const Color primaryDark = Color(0xFFFFA000);
  static const Color primaryLight = Color(0xFFFFE082);

  static const Color secondary = Color(0xFFD32F2F);
  static const Color secondaryDark = Color(0xFFB71C1C);
  
  static const Color tertiary = Color(0xFF1976D2);
  static const Color tertiaryDark = Color(0xFF0D47A1);

  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceHighlight = Color(0xFF2C2C2C);

  static const Color accent = Color(0xFF00E676);
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF00E676);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textDisabled = Color(0xFF78909C);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient redAllianceGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueAllianceGradient = LinearGradient(
    colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
