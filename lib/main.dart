import 'package:flutter/material.dart';

import 'app/app_routes.dart';
import 'app/inout_app.dart';
import 'preview/preview_services.dart';

/// Own-screen preview; production shared services are integrated by their owners.
void main() {
  const screen = String.fromEnvironment(
    'PREVIEW_SCREEN',
    defaultValue: 'history',
  );
  runApp(
    InOutApp(
      services: createPreviewServices(),
      initialRoute: screen == 'profile' ? AppRoutes.profile : AppRoutes.history,
    ),
  );
}
