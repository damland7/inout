import 'contracts.dart';

/// Inline validation rules for every form (Step 2.1 PDF, input rules).
///
/// Each method returns the error text shown under the field, or `null`
/// when the value is valid. Numbers that are not finite (NaN, infinity)
/// are always rejected.
class InOutValidators implements AppValidators {
  const InOutValidators();

  static const minGoal = 1200;
  static const maxGoal = 5000;
  static const minPasswordLength = 6;
  static const maxKcalPerServing = 5000;
  static const maxDurationMinutes = 600;
  static const maxKcalBurned = 3000;

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static bool _blank(String? value) => value == null || value.trim().isEmpty;

  static double? _number(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    return number == null || !number.isFinite ? null : number;
  }

  static int? _wholeNumber(String? value) => int.tryParse(value?.trim() ?? '');

  @override
  String? fullName(String? value) =>
      _blank(value) ? 'Enter your full name' : null;

  @override
  String? email(String? value) {
    if (_blank(value)) return 'Enter your email';
    return _email.hasMatch(value!.trim()) ? null : 'Enter a valid email address';
  }

  @override
  String? loginPassword(String? value) =>
      value == null || value.isEmpty ? 'Enter your password' : null;

  @override
  String? signUpPassword(String? value) =>
      value == null || value.length < minPasswordLength
      ? 'Password must be at least $minPasswordLength characters'
      : null;

  @override
  String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    return value == password ? null : 'Passwords do not match';
  }

  @override
  String? dailyGoal(String? value) {
    final goal = _wholeNumber(value);
    return goal == null || goal < minGoal || goal > maxGoal
        ? 'Goal must be between 1,200 and 5,000 kcal'
        : null;
  }

  @override
  String? foodName(String? value) =>
      _blank(value) ? 'Enter a food name' : null;

  @override
  String? caloriesPerServing(String? value) {
    final kcal = _number(value);
    return kcal == null || kcal < 1 || kcal > maxKcalPerServing
        ? 'Enter calories between 1 and 5,000'
        : null;
  }

  @override
  String? activity(String? value) =>
      _blank(value) ? 'Choose an activity' : null;

  @override
  String? duration(String? value) {
    final minutes = _wholeNumber(value);
    return minutes == null || minutes < 1 || minutes > maxDurationMinutes
        ? 'Enter a duration between 1 and 600 minutes'
        : null;
  }

  @override
  String? caloriesBurned(String? value) {
    final kcal = _number(value);
    return kcal == null || kcal < 1 || kcal > maxKcalBurned
        ? 'Enter calories between 1 and 3,000'
        : null;
  }
}
