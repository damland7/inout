// Isolated adapters for Bedirhan's screen development. These are not the
// completed shared implementations assigned to Hüseyin/Berre.
import 'package:flutter/material.dart';

import '../shared/contracts.dart';
import '../shared/formatters.dart';
import '../shared/models.dart';

AppServices createPreviewServices({DateTime? today, bool empty = false}) =>
    AppServices(
      state: PreviewState(today: today, empty: empty),
      calculations: const PreviewCalculations(),
      validators: const PreviewValidators(),
      accentName: (_) => 'Red',
      historyChartBuilder: (context, days, goal) => Card(
        child: SizedBox(
          height: 160,
          child: Center(
            child: Text(
              '7-day chart',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );

class PreviewState extends AppState {
  PreviewState({DateTime? today, bool empty = false})
    : today = calendarDate(today ?? DateTime.now()),
      _selected = calendarDate(today ?? DateTime.now()) {
    _profile = UserProfile(
      name: 'Berre Demirvakkas',
      email: 'berre.demirvakkas@sabanciuniv.edu',
      dailyGoalKcal: 2000,
      createdAt: DateTime(2026, 11),
    );
    if (empty) return;
    final eaten = [1195.0, 1980.0, 2050.0, 1720.0, 1940.0, 2158.0, 1900.0];
    final burned = [443.0, 420.0, 0.0, 163.0, 350.0, 0.0, 283.0];
    for (var i = 0; i < 7; i++) {
      final date = DateTime(
        this.today.year,
        this.today.month,
        this.today.day - i,
      );
      _meals.add(
        MealEntry(
          id: 'demo-meal-$i',
          foodName: 'Demo meal',
          kcalPerServing: eaten[i],
          servings: 1,
          mealType: MealType.lunch,
          date: date,
        ),
      );
      if (burned[i] > 0) {
        _workouts.add(
          WorkoutEntry(
            id: 'demo-workout-$i',
            activity: 'Demo workout',
            minutes: 30,
            kcalBurned: burned[i],
            date: date,
          ),
        );
      }
    }
  }
  @override
  final DateTime today;
  late UserProfile _profile;
  DateTime _selected;
  MainTab _tab = MainTab.history;
  bool _loggedIn = true;
  final _meals = <MealEntry>[];
  final _workouts = <WorkoutEntry>[];
  @override
  UserProfile get profile => _profile;
  @override
  List<MealEntry> get meals => List.unmodifiable(_meals);
  @override
  List<WorkoutEntry> get workouts => List.unmodifiable(_workouts);
  @override
  DateTime get selectedDate => _selected;
  @override
  MainTab get activeTab => _tab;
  @override
  bool get loggedIn => _loggedIn;
  @override
  void selectDate(DateTime date) {
    _selected = calendarDate(date);
    notifyListeners();
  }

  @override
  void selectTab(MainTab tab) {
    _tab = tab;
    notifyListeners();
  }

  @override
  void updateProfile({required String name, required int dailyGoalKcal}) {
    _profile = _profile.copyWith(name: name, dailyGoalKcal: dailyGoalKcal);
    notifyListeners();
  }

  @override
  void updateAppearance({required ThemeMode mode, required Color accent}) {
    _profile = _profile.copyWith(themeMode: mode, accentColor: accent);
    notifyListeners();
  }

  @override
  void saveMeal(MealEntry entry) {
    _meals.removeWhere((m) => m.id == entry.id);
    _meals.add(entry);
    notifyListeners();
  }

  @override
  void saveWorkout(WorkoutEntry entry) {
    _workouts.removeWhere((w) => w.id == entry.id);
    _workouts.add(entry);
    notifyListeners();
  }

  @override
  void removeEntry(String id) {
    _meals.removeWhere((m) => m.id == id);
    _workouts.removeWhere((w) => w.id == id);
    notifyListeners();
  }

  @override
  void restoreMeal(MealEntry entry) => saveMeal(entry);
  @override
  void restoreWorkout(WorkoutEntry entry) => saveWorkout(entry);
  @override
  void logIn() {
    _loggedIn = true;
    _tab = MainTab.home;
    notifyListeners();
  }

  @override
  void registerProfile({required String name, required String email}) {
    _meals.clear();
    _workouts.clear();
    _profile = UserProfile(
      name: name,
      email: email,
      dailyGoalKcal: 2000,
      createdAt: today,
      themeMode: profile.themeMode,
      accentColor: profile.accentColor,
    );
    _loggedIn = true;
    notifyListeners();
  }

  @override
  void logOut() {
    _meals.clear();
    _workouts.clear();
    _loggedIn = false;
    _profile = UserProfile(
      name: '',
      email: '',
      dailyGoalKcal: 2000,
      createdAt: today,
      themeMode: profile.themeMode,
      accentColor: profile.accentColor,
    );
    _tab = MainTab.home;
    _selected = today;
    notifyListeners();
  }
}

class PreviewCalculations implements AppCalculations {
  const PreviewCalculations();
  @override
  double mealTotal(MealEntry meal) => meal.kcalPerServing * meal.servings;
  @override
  double eatenOn(DateTime date, List<MealEntry> meals) => meals
      .where((m) => calendarDate(m.date) == calendarDate(date))
      .fold(0.0, (sum, meal) => sum + mealTotal(meal));
  @override
  double burnedOn(DateTime date, List<WorkoutEntry> workouts) => workouts
      .where((w) => calendarDate(w.date) == calendarDate(date))
      .fold(0.0, (sum, workout) => sum + workout.kcalBurned);
  @override
  double remaining({
    required double goal,
    required double eaten,
    required double burned,
  }) => goal - eaten + burned;
  @override
  HistoryReport history({
    required DateTime endingOn,
    required UserProfile profile,
    required List<MealEntry> meals,
    required List<WorkoutEntry> workouts,
  }) {
    final days = List.generate(7, (index) {
      final date = DateTime(
        endingOn.year,
        endingOn.month,
        endingOn.day - 6 + index,
      );
      final eaten = eatenOn(date, meals), burned = burnedOn(date, workouts);
      final hasEntries =
          meals.any((m) => calendarDate(m.date) == date) ||
          workouts.any((w) => calendarDate(w.date) == date);
      final left = remaining(
        goal: profile.dailyGoalKcal.toDouble(),
        eaten: eaten,
        burned: burned,
      );
      return HistoryDay(
        date: date,
        eaten: eaten,
        burned: burned,
        remaining: left,
        hasEntries: hasEntries,
        onTarget: left >= 0,
      );
    });
    return HistoryReport(
      days: days,
      averageEaten: days.fold<double>(0, (sum, d) => sum + d.eaten) / 7,
      averageBurned: days.fold<double>(0, (sum, d) => sum + d.burned) / 7,
      daysOnTarget: days.where((d) => d.onTarget).length,
    );
  }
}

class PreviewValidators implements AppValidators {
  const PreviewValidators();
  @override
  String? fullName(String? value) =>
      value == null || value.trim().isEmpty ? 'Enter your full name' : null;
  @override
  String? dailyGoal(String? value) {
    final goal = int.tryParse(value?.trim() ?? '');
    return goal == null || goal < 1200 || goal > 5000
        ? 'Goal must be between 1,200 and 5,000 kcal'
        : null;
  }

  @override
  String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your email';
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
        ? null
        : 'Enter a valid email address';
  }

  @override
  String? loginPassword(String? value) =>
      value == null || value.isEmpty ? 'Enter your password' : null;
  @override
  String? signUpPassword(String? value) => value == null || value.length < 6
      ? 'Password must be at least 6 characters'
      : null;
  @override
  String? confirmPassword(String? value, String password) =>
      value != password ? 'Passwords do not match' : null;
  @override
  String? foodName(String? value) =>
      value == null || value.trim().isEmpty ? 'Enter a food name' : null;
  String? _range(String? value, double min, double max, String message) {
    final number = double.tryParse(value?.trim() ?? '');
    return number == null || !number.isFinite || number < min || number > max
        ? message
        : null;
  }

  @override
  String? caloriesPerServing(String? value) =>
      _range(value, 1, 5000, 'Enter calories between 1 and 5,000');
  @override
  String? activity(String? value) =>
      value == null || value.trim().isEmpty ? 'Choose an activity' : null;
  @override
  String? duration(String? value) {
    final duration = int.tryParse(value?.trim() ?? '');
    return duration == null || duration < 1 || duration > 600
        ? 'Enter a duration between 1 and 600 minutes'
        : null;
  }

  @override
  String? caloriesBurned(String? value) =>
      _range(value, 1, 3000, 'Enter calories between 1 and 3,000');
}
