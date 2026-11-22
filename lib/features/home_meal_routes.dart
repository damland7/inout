import 'package:flutter/widgets.dart';

import '../app/app_routes.dart';
import 'meal/meal_editor_screen.dart';

/// Damla's S07 route. S05 Home is supplied as InOutApp.homeBuilder so it can
/// host the persistent Home / History / Profile navigation shell.
final Map<String, WidgetBuilder> homeMealRoutes = {
  AppRoutes.mealEditor: (_) => const MealEditorScreen(),
};
