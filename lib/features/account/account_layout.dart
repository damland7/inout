import 'package:flutter/material.dart';

import '../../app/app_routes.dart';

/// Scrollable, centred column used by S01–S04. It scrolls when the keyboard
/// is open or the phone is small, and stays 480 px wide on large phones, so
/// none of the account screens can overflow.
class AccountLayout extends StatelessWidget {
  const AccountLayout({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}

/// The app logo (local image). Shows a simple icon until the asset is added.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 88});
  final double size;

  /// Added to pubspec.yaml by the theme/assets package.
  static const assetPath = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'InOut logo',
      image: true,
      child: ClipOval(
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: size,
            height: size,
            color: scheme.primaryContainer,
            alignment: Alignment.center,
            child: Icon(
              Icons.local_fire_department_rounded,
              size: size * 0.5,
              color: scheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Question? Action" row that wraps on narrow screens.
class AccountLinkRow extends StatelessWidget {
  const AccountLinkRow({
    super.key,
    required this.question,
    required this.action,
    required this.onPressed,
  });
  final String question;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(question),
      TextButton(onPressed: onPressed, child: Text(action)),
    ],
  );
}

/// Returns to S01 Login: pops if Login is below, otherwise replaces.
void backToLogin(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
  } else {
    navigator.pushReplacementNamed(AppRoutes.login);
  }
}
