import 'package:flutter/material.dart';

import 'contracts.dart';
import 'formatters.dart';
import 'models.dart';
import 'placeholder_data.dart';

/// The app's single source of truth for Step 2.2.
///
/// Every screen reads this through `AppScope.of(context).state` and rebuilds
/// when it calls [notifyListeners]. Data lives in memory and starts from
/// [PlaceholderData]; Firebase replaces it in Step 3.
class InOutState extends AppState {
  InOutState({
    DateTime Function()? clock,
    bool loggedIn = false,
    this.seedDemoData = true,
    this.onAppearanceChanged,
  }) : _clock = clock ?? DateTime.now {
    _selectedDate = today;
    _profile = _signedOutProfile(ThemeMode.system, _defaultAccent);
    if (loggedIn) _startDemoSession();
  }

  static const Color _defaultAccent = Color(0xFFB42332);

  final DateTime Function() _clock;

  /// When false, logging in starts with an empty account (used in tests).
  final bool seedDemoData;

  /// Called when the user changes theme or accent on S12, so the theme
  /// package can store the choice on the phone.
  final void Function(ThemeMode mode, Color accent)? onAppearanceChanged;

  late UserProfile _profile;
  late DateTime _selectedDate;
  MainTab _activeTab = MainTab.home;
  bool _loggedIn = false;
  final List<MealEntry> _meals = [];
  final List<WorkoutEntry> _workouts = [];

  // ---------------------------------------------------------------- reading

  @override
  UserProfile get profile => _profile;

  @override
  List<MealEntry> get meals => List.unmodifiable(_meals);

  @override
  List<WorkoutEntry> get workouts => List.unmodifiable(_workouts);

  @override
  DateTime get today => calendarDate(_clock());

  @override
  DateTime get selectedDate => _selectedDate;

  @override
  MainTab get activeTab => _activeTab;

  @override
  bool get loggedIn => _loggedIn;

  /// Meals logged on [date], in the order they were added.
  List<MealEntry> mealsOn(DateTime date) {
    final day = calendarDate(date);
    return List.unmodifiable(
      _meals.where((m) => calendarDate(m.date) == day),
    );
  }

  /// Workouts logged on [date], in the order they were added.
  List<WorkoutEntry> workoutsOn(DateTime date) {
    final day = calendarDate(date);
    return List.unmodifiable(
      _workouts.where((w) => calendarDate(w.date) == day),
    );
  }

  // ------------------------------------------------------------- navigation

  @override
  void selectDate(DateTime date) {
    var day = calendarDate(date);
    // Home's "next day" arrow stops at today: no logging in the future.
    if (day.isAfter(today)) day = today;
    if (day == _selectedDate) return;
    _selectedDate = day;
    notifyListeners();
  }

  @override
  void selectTab(MainTab tab) {
    if (tab == _activeTab) return;
    _activeTab = tab;
    notifyListeners();
  }

  // ---------------------------------------------------------------- profile

  @override
  void updateProfile({required String name, required int dailyGoalKcal}) {
    _profile = _profile.copyWith(
      name: name.trim(),
      dailyGoalKcal: dailyGoalKcal,
    );
    notifyListeners();
  }

  @override
  void updateAppearance({required ThemeMode mode, required Color accent}) {
    if (mode == _profile.themeMode && accent == _profile.accentColor) return;
    _profile = _profile.copyWith(themeMode: mode, accentColor: accent);
    onAppearanceChanged?.call(mode, accent);
    notifyListeners();
  }

  // ------------------------------------------------------------------- logs

  /// Adds a new meal, or replaces the meal with the same id (edit).
  @override
  void saveMeal(MealEntry entry) {
    _upsert(_meals, entry, (m) => m.id == entry.id);
    notifyListeners();
  }

  /// Adds a new workout, or replaces the workout with the same id (edit).
  @override
  void saveWorkout(WorkoutEntry entry) {
    _upsert(_workouts, entry, (w) => w.id == entry.id);
    notifyListeners();
  }

  /// Removes the meal or workout with [id]. Keep the removed entry if you
  /// want to offer UNDO, then call [restoreMeal] or [restoreWorkout].
  @override
  void removeEntry(String id) {
    final before = _meals.length + _workouts.length;
    _meals.removeWhere((m) => m.id == id);
    _workouts.removeWhere((w) => w.id == id);
    if (_meals.length + _workouts.length != before) notifyListeners();
  }

  /// Puts a deleted meal back. Restoring twice never creates a duplicate.
  @override
  void restoreMeal(MealEntry entry) => saveMeal(entry);

  /// Puts a deleted workout back. Restoring twice never creates a duplicate.
  @override
  void restoreWorkout(WorkoutEntry entry) => saveWorkout(entry);

  // ---------------------------------------------------------------- session

  /// UI-only login for Step 2.2: opens the demo account with sample data.
  /// Firebase Authentication replaces this in Step 3.
  @override
  void logIn() {
    if (!_loggedIn || _profile.email.isEmpty) _startDemoSession();
    _loggedIn = true;
    _activeTab = MainTab.home;
    _selectedDate = today;
    notifyListeners();
  }

  /// Creates a new, empty account after Sign Up. The goal is set on S04.
  /// The password is never stored.
  @override
  void registerProfile({required String name, required String email}) {
    _meals.clear();
    _workouts.clear();
    _profile = UserProfile(
      name: name.trim(),
      email: email.trim(),
      dailyGoalKcal: PlaceholderData.defaultGoalKcal,
      createdAt: today,
      themeMode: _profile.themeMode,
      accentColor: _profile.accentColor,
    );
    _loggedIn = true;
    _activeTab = MainTab.home;
    _selectedDate = today;
    notifyListeners();
  }

  /// Clears the account and its entries. Theme and accent stay, because
  /// they are a setting of the phone, not of the account.
  @override
  void logOut() {
    _meals.clear();
    _workouts.clear();
    _profile = _signedOutProfile(_profile.themeMode, _profile.accentColor);
    _loggedIn = false;
    _activeTab = MainTab.home;
    _selectedDate = today;
    notifyListeners();
  }

  // ---------------------------------------------------------------- helpers

  void _startDemoSession() {
    final day = today;
    final demo = PlaceholderData.demoProfile(day);
    _profile = UserProfile(
      name: demo.name,
      email: demo.email,
      dailyGoalKcal: demo.dailyGoalKcal,
      createdAt: demo.createdAt,
      themeMode: _profile.themeMode,
      accentColor: _profile.accentColor,
    );
    _meals
      ..clear()
      ..addAll(seedDemoData ? PlaceholderData.demoMeals(day) : const []);
    _workouts
      ..clear()
      ..addAll(seedDemoData ? PlaceholderData.demoWorkouts(day) : const []);
    _loggedIn = true;
  }

  UserProfile _signedOutProfile(ThemeMode mode, Color accent) => UserProfile(
    name: '',
    email: '',
    dailyGoalKcal: PlaceholderData.defaultGoalKcal,
    createdAt: today,
    themeMode: mode,
    accentColor: accent,
  );

  static void _upsert<T>(List<T> list, T entry, bool Function(T) sameId) {
    final index = list.indexWhere(sameId);
    if (index == -1) {
      list.add(entry);
    } else {
      list[index] = entry;
    }
  }
}
