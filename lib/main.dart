import 'package:flutter/material.dart';

import 'app/app_routes.dart';
import 'app/inout_app.dart';
import 'features/account/account_routes.dart';
import 'features/food_workout_appearance_routes.dart';
import 'shared/app_services.dart';
import 'shared/theme/app_theme.dart';

/// InOut. The app opens on S01 Log In with the production state, the shared
/// theme (Inter font, light/dark, accent) and every finished screen. Screens
/// that are not merged yet show a placeholder.
void main() {
  runApp(
    InOutApp(
      services: createAppServices(),
      initialRoute: AppRoutes.login,
      themeBuilder: buildAppTheme,
      featureRoutes: {...accountRoutes, ...foodWorkoutAppearanceRoutes},
    ),
  );
}
