import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inout_app/app/app_routes.dart';
import 'package:inout_app/app/inout_app.dart';
import 'package:inout_app/features/account/account_routes.dart';
import 'package:inout_app/shared/app_services.dart';
import 'package:inout_app/shared/app_state.dart';
import 'package:inout_app/shared/contracts.dart';

Future<AppServices> _open(WidgetTester tester, String route) async {
  final services = createAppServices(
    state: InOutState(clock: () => DateTime(2026, 11, 20)),
  );
  await tester.pumpWidget(
    InOutApp(
      key: UniqueKey(),
      services: services,
      initialRoute: route,
      featureRoutes: accountRoutes,
    ),
  );
  await tester.pumpAndSettle();
  return services;
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String key, String text) =>
    tester.enterText(find.byKey(ValueKey(key)), text);

void _useScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('S01 Login', () {
    testWidgets('empty form shows inline errors and stays on Login', (
      tester,
    ) async {
      await _open(tester, AppRoutes.login);
      await _tapButton(tester, 'Log In');
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
      expect(find.text('S05 Home'), findsNothing);
    });

    testWidgets('valid login opens Home and Back cannot return', (
      tester,
    ) async {
      final services = await _open(tester, AppRoutes.login);
      await _type(tester, 'login-email', 'berre@example.com');
      await _type(tester, 'login-password', 'secret');
      await _tapButton(tester, 'Log In');
      expect(find.text('S05 Home'), findsOneWidget);
      expect(services.state.loggedIn, isTrue);
      expect(
        Navigator.of(tester.element(find.text('S05 Home'))).canPop(),
        isFalse,
      );
    });

    testWidgets('show/hide button reveals the password', (tester) async {
      await _open(tester, AppRoutes.login);
      await _type(tester, 'login-password', 'secret');
      EditableText field() => tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('login-password')),
          matching: find.byType(EditableText),
        ),
      );
      expect(field().obscureText, isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(field().obscureText, isFalse);
    });
  });

  group('S02 Sign Up', () {
    testWidgets('password needs 6 characters and confirmation must match', (
      tester,
    ) async {
      await _open(tester, AppRoutes.login);
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      await _type(tester, 'signup-name', 'Ada Lovelace');
      await _type(tester, 'signup-email', 'ada@example.com');
      await _type(tester, 'signup-password', '12345');
      await _type(tester, 'signup-confirm', '12346');
      await _tapButton(tester, 'Create Account');
      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
      expect(find.text('Passwords do not match'), findsOneWidget);

      await _type(tester, 'signup-password', '123456');
      await _type(tester, 'signup-confirm', '123456');
      await tester.pumpAndSettle();
      expect(find.text('Password must be at least 6 characters'), findsNothing);
      expect(find.text('Passwords do not match'), findsNothing);
    });

    testWidgets('blank name and email are rejected', (tester) async {
      await _open(tester, AppRoutes.signUp);
      await _tapButton(tester, 'Create Account');
      expect(find.text('Enter your full name'), findsOneWidget);
      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('valid sign up opens Goal Setup with no way back', (
      tester,
    ) async {
      final services = await _open(tester, AppRoutes.login);
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      await _type(tester, 'signup-name', 'Ada Lovelace');
      await _type(tester, 'signup-email', 'ada@example.com');
      await _type(tester, 'signup-password', '123456');
      await _type(tester, 'signup-confirm', '123456');
      await _tapButton(tester, 'Create Account');
      expect(find.text('Set your daily goal'), findsOneWidget);
      expect(services.state.profile.name, 'Ada Lovelace');
      expect(services.state.meals, isEmpty);
      expect(find.byType(BackButton), findsNothing);
      expect(
        Navigator.of(tester.element(find.text('Set your daily goal'))).canPop(),
        isFalse,
      );
    });
  });

  group('S03 Forgot Password', () {
    testWidgets('email from Login is pre-filled and dialog returns to Login', (
      tester,
    ) async {
      await _open(tester, AppRoutes.login);
      await _type(tester, 'login-email', 'berre@example.com');
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.text('berre@example.com'), findsOneWidget);
      final send = find.widgetWithText(FilledButton, 'Send Reset Link');
      await tester.ensureVisible(send);
      await tester.tap(send);
      // The spinner continues behind the confirmation dialog.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Check your email'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Back to Log In'));
      await tester.pumpAndSettle();
      expect(find.text('Track what you eat and what you burn'), findsOneWidget);
    });

    testWidgets('invalid email shows an inline error', (tester) async {
      await _open(tester, AppRoutes.forgotPassword);
      await _type(tester, 'forgot-email', 'not-an-email');
      await _tapButton(tester, 'Send Reset Link');
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(find.text('Check your email'), findsNothing);
    });
  });

  group('S04 Goal Setup', () {
    testWidgets('goal must be between 1,200 and 5,000', (tester) async {
      await _open(tester, AppRoutes.goalSetup);
      const message = 'Goal must be between 1,200 and 5,000 kcal';
      for (final value in ['1199', '5001']) {
        await _type(tester, 'goal-field', value);
        await _tapButton(tester, 'Start Tracking');
        expect(find.text(message), findsOneWidget, reason: value);
      }
      for (final value in ['1200', '5000']) {
        await _type(tester, 'goal-field', value);
        await tester.pumpAndSettle();
        expect(find.text(message), findsNothing, reason: value);
      }
    });

    testWidgets('quick pick fills the field and Start Tracking saves it', (
      tester,
    ) async {
      final services = await _open(tester, AppRoutes.goalSetup);
      await tester.tap(find.byKey(const ValueKey('goal-chip-2500')));
      await tester.pump();
      expect(find.text('2500'), findsOneWidget);
      await _tapButton(tester, 'Start Tracking');
      expect(services.state.profile.dailyGoalKcal, 2500);
      expect(find.text('S05 Home'), findsOneWidget);
    });
  });

  group('responsive', () {
    for (final size in const [Size(320, 568), Size(360, 640), Size(430, 932)]) {
      testWidgets('no overflow at ${size.width.toInt()} px wide', (
        tester,
      ) async {
        _useScreen(tester, size);
        for (final route in [
          AppRoutes.login,
          AppRoutes.signUp,
          AppRoutes.forgotPassword,
          AppRoutes.goalSetup,
        ]) {
          await _open(tester, route);
          expect(tester.takeException(), isNull, reason: route);
        }
      });
    }

    testWidgets('large text on a small phone does not overflow', (
      tester,
    ) async {
      _useScreen(tester, const Size(320, 568));
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _open(tester, AppRoutes.signUp);
      await _tapButton(tester, 'Create Account');
      expect(tester.takeException(), isNull);
    });
  });
}
