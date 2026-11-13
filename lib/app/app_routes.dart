import 'package:flutter/material.dart';

import '../shared/contracts.dart';
import '../shared/models.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const goalSetup = '/goal-setup';
  static const home = '/';
  static const foodList = '/foods';
  static const mealEditor = '/meal';
  static const workoutEditor = '/workout';
  static const history = '/history';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const appearance = '/appearance';

  static const titles = {
    login: 'S01 Login',
    signUp: 'S02 Sign Up',
    forgotPassword: 'S03 Forgot Password',
    goalSetup: 'S04 Goal Setup',
    home: 'S05 Home',
    foodList: 'S06 Food List',
    mealEditor: 'S07 Add / Edit Meal',
    workoutEditor: 'S08 Add / Edit Workout',
    history: 'S09 History',
    profile: 'S10 Profile',
    editProfile: 'S11 Edit Profile',
    appearance: 'S12 Appearance',
  };

  static void openHome(BuildContext context, {DateTime? date}) {
    final state = AppScope.of(context).state;
    state.selectTab(MainTab.home);
    if (date != null) state.selectDate(date);
    Navigator.pushNamedAndRemoveUntil(context, home, (_) => false);
  }

  static void openMainTab(BuildContext context, MainTab tab) {
    AppScope.of(context).state.selectTab(tab);
    Navigator.pushNamedAndRemoveUntil(context, home, (_) => false);
  }
}

class MealEditorArguments {
  const MealEditorArguments({this.entry, this.food, this.date});
  final MealEntry? entry;
  final FoodItem? food;
  final DateTime? date;
}

class WorkoutEditorArguments {
  const WorkoutEditorArguments({this.entry, this.date});
  final WorkoutEntry? entry;
  final DateTime? date;
}

class ForgotPasswordArguments {
  const ForgotPasswordArguments(this.email);
  final String email;
}
