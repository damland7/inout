import 'package:flutter/material.dart';

/// Shared colour palette (Step 2.1 PDF, design rules page).
///
/// Screens read colours from `Theme.of(context).colorScheme`; these
/// constants are only used to build the theme and the accent picker.
abstract final class AppColors {
  // Light mode
  static const primary = Color(0xFFB42332);
  static const primaryPale = Color(0xFFFCE8EB);
  static const surface = Color(0xFFF7F3F4);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF344054);
  static const textHelp = Color(0xFF667085);
  static const outline = Color(0xFFD0D5DD);
  static const error = Color(0xFFB42318);

  // Dark mode
  static const darkBackground = Color(0xFF0F1218);
  static const darkCard = Color(0xFF1A1F29);
  static const darkText = Color(0xFFE4E7EC);
  static const darkTextHelp = Color(0xFF98A2B3);
  static const darkOutline = Color(0xFF344054);
  static const darkError = Color(0xFFF97066);

  // History: a day within the goal and a day over the goal.
  static const onTarget = Color(0xFF12B76A);
  static const overGoal = Color(0xFFD92D20);
}

/// One accent colour the user can pick on S12 Appearance.
class AccentOption {
  const AccentOption(this.name, this.color);
  final String name;
  final Color color;
}

/// The five accents offered on S12. Red is the default.
const List<AccentOption> accentOptions = [
  AccentOption('Red', AppColors.primary),
  AccentOption('Blue', Color(0xFF1570EF)),
  AccentOption('Green', Color(0xFF079455)),
  AccentOption('Purple', Color(0xFF7A5AF8)),
  AccentOption('Orange', Color(0xFFE04F16)),
];

/// Display name of [color] for Profile ("Dark · Blue").
String accentNameFor(Color color) {
  for (final option in accentOptions) {
    if (option.color.toARGB32() == color.toARGB32()) return option.name;
  }
  return 'Custom';
}
