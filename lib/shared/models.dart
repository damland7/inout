import 'package:flutter/material.dart';

enum MainTab { home, history, profile }

enum MealType {
  breakfast('Breakfast'),
  lunch('Lunch'),
  dinner('Dinner'),
  snack('Snack');

  const MealType(this.label);
  final String label;
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.dailyGoalKcal,
    required this.createdAt,
    this.themeMode = ThemeMode.system,
    this.accentColor = const Color(0xFFB42332),
  });
  final String name;
  final String email;
  final int dailyGoalKcal;
  final DateTime createdAt;
  final ThemeMode themeMode;
  final Color accentColor;
  UserProfile copyWith({
    String? name,
    int? dailyGoalKcal,
    ThemeMode? themeMode,
    Color? accentColor,
  }) => UserProfile(
    name: name ?? this.name,
    email: email,
    dailyGoalKcal: dailyGoalKcal ?? this.dailyGoalKcal,
    createdAt: createdAt,
    themeMode: themeMode ?? this.themeMode,
    accentColor: accentColor ?? this.accentColor,
  );
}

class MealEntry {
  const MealEntry({
    required this.id,
    required this.foodName,
    required this.kcalPerServing,
    required this.servings,
    required this.mealType,
    required this.date,
  });
  final String id;
  final String foodName;
  final double kcalPerServing;
  final double servings;
  final MealType mealType;
  final DateTime date;
}

class WorkoutEntry {
  const WorkoutEntry({
    required this.id,
    required this.activity,
    required this.minutes,
    required this.kcalBurned,
    required this.date,
  });
  final String id;
  final String activity;
  final int minutes;
  final double kcalBurned;
  final DateTime date;
}

class FoodItem {
  const FoodItem({
    required this.name,
    required this.servingLabel,
    required this.kcalPerServing,
    required this.imageUrl,
  });
  final String name;
  final String servingLabel;
  final double kcalPerServing;
  final String imageUrl;
}

class HistoryDay {
  const HistoryDay({
    required this.date,
    required this.eaten,
    required this.burned,
    required this.remaining,
    required this.hasEntries,
    required this.onTarget,
  });
  final DateTime date;
  final double eaten;
  final double burned;
  final double remaining;
  final bool hasEntries;
  final bool onTarget;
}

class HistoryReport {
  HistoryReport({
    required List<HistoryDay> days,
    required this.averageEaten,
    required this.averageBurned,
    required this.daysOnTarget,
  }) : days = List.unmodifiable(days);

  /// Chronological, oldest first; the screen reverses rows only.
  final List<HistoryDay> days;
  final double averageEaten;
  final double averageBurned;
  final int daysOnTarget;
  bool get isEmpty => !days.any((d) => d.hasEntries);
}
