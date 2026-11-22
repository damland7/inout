import 'package:flutter/material.dart';

import 'app/app_routes.dart';
import 'app/inout_app.dart';
import 'preview/preview_services.dart';

/// Bedirhan's own-screen preview of S09-S11 with the temporary adapters:
///   flutter run -t lib/main_preview.dart --dart-define=PREVIEW_SCREEN=profile
/// The real app starts from lib/main.dart.
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
