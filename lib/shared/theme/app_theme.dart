import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Builds the app theme for light or dark mode with the user's accent.
///
/// Matches `SharedThemeBuilder`, so `InOutApp(themeBuilder: buildAppTheme)`
/// applies it to every screen. Changing the accent or mode on S12 rebuilds
/// the whole app immediately.
ThemeData buildAppTheme(Brightness brightness, Color accent) {
  final dark = brightness == Brightness.dark;
  final seeded = ColorScheme.fromSeed(seedColor: accent, brightness: brightness);
  final isDefaultRed = accent.toARGB32() == AppColors.primary.toARGB32();

  final scheme = dark
      ? seeded.copyWith(
          surface: AppColors.darkBackground,
          surfaceContainerLowest: AppColors.darkBackground,
          surfaceContainerLow: AppColors.darkCard,
          surfaceContainer: AppColors.darkCard,
          onSurface: AppColors.darkText,
          onSurfaceVariant: AppColors.darkTextHelp,
          outline: AppColors.darkOutline,
          error: AppColors.darkError,
        )
      : seeded.copyWith(
          primary: accent,
          onPrimary: Colors.white,
          primaryContainer: isDefaultRed ? AppColors.primaryPale : null,
          surface: AppColors.surface,
          surfaceContainerLowest: AppColors.card,
          surfaceContainerLow: AppColors.card,
          onSurface: AppColors.text,
          onSurfaceVariant: AppColors.textHelp,
          outline: AppColors.outline,
          error: AppColors.error,
        );

  final text = AppTextStyles.textTheme(
    scheme.onSurface,
    scheme.onSurfaceVariant,
  ).apply(fontFamily: AppTextStyles.fontFamily);

  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
  );
  const buttonSize = Size(64, AppSpacing.tapTarget);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: AppTextStyles.fontFamily,
    textTheme: text,
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonSize,
        shape: controlShape,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonSize,
        shape: controlShape,
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, AppSpacing.tapTarget),
        textStyle: text.labelLarge,
      ),
    ),
  );
}
