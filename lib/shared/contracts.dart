import 'package:flutter/material.dart';

import 'models.dart';

/// Shared state implementation is Hüseyin's package.
abstract class AppState extends ChangeNotifier {
  UserProfile get profile;
  List<MealEntry> get meals;
  List<WorkoutEntry> get workouts;
  DateTime get today;
  DateTime get selectedDate;
  MainTab get activeTab;
  bool get loggedIn;
  void selectDate(DateTime date);
  void selectTab(MainTab tab);
  void updateProfile({required String name, required int dailyGoalKcal});
  void updateAppearance({required ThemeMode mode, required Color accent});
  void saveMeal(MealEntry entry);
  void saveWorkout(WorkoutEntry entry);
  void removeEntry(String id);
  void restoreMeal(MealEntry entry);
  void restoreWorkout(WorkoutEntry entry);
  void logIn();
  void registerProfile({required String name, required String email});
  void logOut();
}

/// Calculations and validation are Berre's shared work.
abstract interface class AppCalculations {
  double mealTotal(MealEntry meal);
  double eatenOn(DateTime date, List<MealEntry> meals);
  double burnedOn(DateTime date, List<WorkoutEntry> workouts);
  double remaining({
    required double goal,
    required double eaten,
    required double burned,
  });
  HistoryReport history({
    required DateTime endingOn,
    required UserProfile profile,
    required List<MealEntry> meals,
    required List<WorkoutEntry> workouts,
  });
}

abstract interface class AppValidators {
  String? fullName(String? value);
  String? dailyGoal(String? value);
  String? email(String? value);
  String? loginPassword(String? value);
  String? signUpPassword(String? value);
  String? confirmPassword(String? value, String password);
  String? foodName(String? value);
  String? caloriesPerServing(String? value);
  String? activity(String? value);
  String? duration(String? value);
  String? caloriesBurned(String? value);
}

typedef HistoryChartBuilder = Widget Function(
  BuildContext context,
  List<HistoryDay> chronologicalDays,
  int dailyGoalKcal,
);
typedef SharedThemeBuilder = ThemeData Function(
  Brightness brightness,
  Color accent,
);
String defaultAccentName(Color color) => 'Accent';

class AppServices {
  const AppServices({
    required this.state,
    required this.calculations,
    required this.validators,
    required this.historyChartBuilder,
    this.accentName = defaultAccentName,
  });
  final AppState state;
  final AppCalculations calculations;
  final AppValidators validators;
  final HistoryChartBuilder historyChartBuilder;
  final String Function(Color) accentName;
}

class AppScope extends InheritedNotifier<AppState> {
  AppScope({super.key, required this.services, required super.child})
    : super(notifier: services.state);
  final AppServices services;
  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'Wrap screens in AppScope.');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(covariant AppScope oldWidget) =>
      services != oldWidget.services || super.updateShouldNotify(oldWidget);
}
