import 'package:flutter/material.dart';

/// Shared text styles. Every style uses the bundled Inter font.
///
/// Sizes follow the Step 2.1 design rules: titles 28/24/20, body 16,
/// help and captions 14.
abstract final class AppTextStyles {
  static const fontFamily = 'Inter';

  static TextTheme textTheme(Color text, Color help) => TextTheme(
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: text,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: text,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: text,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: text,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: text,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: text),
    bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: text),
    bodySmall: TextStyle(fontSize: 14, height: 1.4, color: help),
    labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: help,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
      color: help,
    ),
  );
}
