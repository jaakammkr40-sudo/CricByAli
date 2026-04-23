import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette — Deep teal (cricket pitch inspired)
  static const Color primary = Color(0xFF006D5B);
  static const Color primaryLight = Color(0xFF00A896);
  static const Color primaryDark = Color(0xFF004D40);

  // Secondary — Gold / Multan Sultans accent
  static const Color secondary = Color(0xFFFFD700);
  static const Color secondaryLight = Color(0xFFFFE94D);
  static const Color secondaryDark = Color(0xFFCC9D00);

  // Background — stadium night feel
  static const Color bgDeep = Color(0xFF060F1E);
  static const Color bgDark = Color(0xFF0A1628);
  static const Color bgMid = Color(0xFF0F2040);
  static const Color bgLight = Color(0xFF1A3055);

  // Cards
  static const Color cardBg = Color(0xFF1A2F4A);
  static const Color cardBorder = Color(0xFF2A4060);
  static const Color cardHighlight = Color(0xFF243856);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0C4DE);
  static const Color textMuted = Color(0xFF607D9B);

  // Status
  static const Color winnerGreen = Color(0xFF2ECC71);
  static const Color byePurple = Color(0xFF9B59B6);
  static const Color pendingGrey = Color(0xFF546E7A);
  static const Color errorRed = Color(0xFFE74C3C);

  // Gradients
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgDeep, bgDark, bgMid],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, primaryDark],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondary, secondaryDark],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardHighlight, cardBg],
  );

  static const LinearGradient winnerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A5C35), Color(0xFF0D3A22)],
  );
}
