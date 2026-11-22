import 'package:flutter/material.dart';

import 'app/app_routes.dart';
import 'app/inout_app.dart';
import 'features/account/account_routes.dart';
import 'shared/app_services.dart';

/// Runs the account flow (S01–S04) with the production app state:
///   flutter run -t lib/main_account.dart
/// Home (S05) is still a placeholder until the main shell is merged.
void main() {
  runApp(
    InOutApp(
      services: createAppServices(),
      initialRoute: AppRoutes.login,
      featureRoutes: accountRoutes,
    ),
  );
}
