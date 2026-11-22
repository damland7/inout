import 'package:flutter/widgets.dart';

import '../app/app_routes.dart';
import 'appearance/appearance_screen.dart';
import 'food/food_list_screen.dart';
import 'workout/workout_editor_screen.dart';

/// S06, S08 and S12 routes. Pass to `InOutApp(featureRoutes: ...)` to
/// replace the placeholders for these screens.
final Map<String, WidgetBuilder> foodWorkoutAppearanceRoutes = {
  AppRoutes.foodList: (_) => const FoodListScreen(),
  AppRoutes.workoutEditor: (_) => const WorkoutEditorScreen(),
  AppRoutes.appearance: (_) => const AppearanceScreen(),
};
