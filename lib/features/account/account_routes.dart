import 'package:flutter/widgets.dart';

import '../../app/app_routes.dart';
import 'forgot_password_screen.dart';
import 'goal_setup_screen.dart';
import 'login_screen.dart';
import 'sign_up_screen.dart';

/// S01–S04 routes. Pass to `InOutApp(featureRoutes: ...)` to replace the
/// placeholders for these screens.
final Map<String, WidgetBuilder> accountRoutes = {
  AppRoutes.login: (_) => const LoginScreen(),
  AppRoutes.signUp: (_) => const SignUpScreen(),
  AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
  AppRoutes.goalSetup: (_) => const GoalSetupScreen(),
};
