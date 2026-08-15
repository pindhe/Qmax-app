import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color orange = Color(0xFFEA580C);
  static const Color orangeDark = Color(0xFFC2410C);
  static const Color navy = Color(0xFF0D1B2A);
  static const Color steel = Color(0xFF1B263B);
  static const Color cream = Color(0xFFF7F4EF);
  static const Color sand = Color(0xFFE8E0D5);
  static const Color success = Color(0xFF2D6A4F);
  static const Color warning = Color(0xFFB45309);
  static const Color error = Color(0xFFD62828);
  static const Color info = Color(0xFF1D4E89);

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: orange,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFFEDD5),
    onPrimaryContainer: Color(0xFF7C2D12),
    secondary: steel,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD6DCE6),
    onSecondaryContainer: navy,
    tertiary: Color(0xFFB45309),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFEF3C7),
    onTertiaryContainer: Color(0xFF78350F),
    error: error,
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: cream,
    onSurface: navy,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFFBF8F4),
    surfaceContainer: Color(0xFFF1EBE3),
    surfaceContainerHigh: sand,
    surfaceContainerHighest: Color(0xFFD9D0C4),
    outline: Color(0xFFC4B8A8),
    outlineVariant: Color(0xFFE4D9CC),
    shadow: Color(0x330D1B2A),
    scrim: Color(0x990D1B2A),
    inverseSurface: navy,
    onInverseSurface: cream,
    inversePrimary: Color(0xFFFB923C),
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFB923C),
    onPrimary: Color(0xFF431407),
    primaryContainer: Color(0xFFC2410C),
    onPrimaryContainer: Color(0xFFFFEDD5),
    secondary: Color(0xFF94A3B8),
    onSecondary: navy,
    secondaryContainer: Color(0xFF243044),
    onSecondaryContainer: Color(0xFFE2E8F0),
    tertiary: Color(0xFFFBBF24),
    onTertiary: Color(0xFF422006),
    tertiaryContainer: Color(0xFF78350F),
    onTertiaryContainer: Color(0xFFFEF3C7),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: Color(0xFF0F1720),
    onSurface: Color(0xFFF1EBE3),
    surfaceContainerLowest: Color(0xFF0A1016),
    surfaceContainerLow: Color(0xFF15202B),
    surfaceContainer: Color(0xFF1B2836),
    surfaceContainerHigh: Color(0xFF243044),
    surfaceContainerHighest: Color(0xFF334155),
    outline: Color(0xFF64748B),
    outlineVariant: Color(0xFF334155),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: cream,
    onInverseSurface: navy,
    inversePrimary: orange,
  );
}
