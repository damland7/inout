import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inout_app/app/app_routes.dart';
import 'package:inout_app/app/inout_app.dart';
import 'package:inout_app/preview/preview_services.dart';
import 'package:inout_app/shared/contracts.dart';

Future<void> openProfile(WidgetTester tester, AppServices services) => tester
    .pumpWidget(InOutApp(services: services, initialRoute: AppRoutes.profile));

void main() {
  testWidgets('logged-out entry starts with Login as the only route', (
    tester,
  ) async {
    final services = createPreviewServices();
    services.state.logOut();
    await tester.pumpWidget(
      InOutApp(services: services, initialRoute: AppRoutes.login),
    );
    expect(
      Navigator.of(tester.element(find.text('S01 Login'))).canPop(),
      isFalse,
    );
  });
  testWidgets('repeated clean Back closes only the editor', (tester) async {
    final services = createPreviewServices();
    await openProfile(tester, services);
    await tester.scrollUntilVisible(find.text('Edit Profile'), 150);
    await tester.ensureVisible(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    final back = tester.widget<BackButton>(find.byType(BackButton));
    back.onPressed!();
    back.onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('S05 Home'), findsNothing);
  });

  testWidgets('profile save preserves email and updates shared goal/name', (
    tester,
  ) async {
    final services = createPreviewServices(today: DateTime(2026, 11, 7));
    await openProfile(tester, services);
    await tester.scrollUntilVisible(find.text('Edit Profile'), 150);
    await tester.ensureVisible(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-name')),
      'Bedirhan Ceylan',
    );
    await tester.enterText(find.byKey(const ValueKey('profile-goal')), '1900');
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(services.state.profile.name, 'Bedirhan Ceylan');
    expect(services.state.profile.dailyGoalKcal, 1900);
    expect(services.state.profile.email, 'berre.demirvakkas@sabanciuniv.edu');
    expect(find.text('Profile updated'), findsOneWidget);
  });
  testWidgets('invalid form keeps profile unchanged and shows inline errors', (
    tester,
  ) async {
    final services = createPreviewServices();
    await openProfile(tester, services);
    await tester.scrollUntilVisible(find.text('Edit Profile'), 150);
    await tester.ensureVisible(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('profile-name')), '   ');
    await tester.enterText(find.byKey(const ValueKey('profile-goal')), '6000');
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your full name'), findsOneWidget);
    expect(
      find.text('Goal must be between 1,200 and 5,000 kcal'),
      findsOneWidget,
    );
    expect(services.state.profile.dailyGoalKcal, 2000);
  });
  testWidgets('back with edits supports keep editing then discard', (
    tester,
  ) async {
    final services = createPreviewServices();
    await openProfile(tester, services);
    await tester.scrollUntilVisible(find.text('Edit Profile'), 150);
    await tester.ensureVisible(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-name')),
      'Unsaved',
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('profile-name')), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(services.state.profile.name, 'Berre Demirvakkas');
    expect(find.text('Profile'), findsOneWidget);
  });
  testWidgets(
    'logout cancellation keeps state; confirmation clears private stack',
    (tester) async {
      final services = createPreviewServices();
      await openProfile(tester, services);
      await tester.scrollUntilVisible(find.text('Log out'), 200);
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(services.state.loggedIn, isTrue);
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Log Out'));
      await tester.pumpAndSettle();
      expect(services.state.loggedIn, isFalse);
      expect(services.state.meals, isEmpty);
      expect(find.text('S01 Login'), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.text('S01 Login'))).canPop(),
        isFalse,
      );
    },
  );
  testWidgets('history uses last seven days and day tap selects Home date', (
    tester,
  ) async {
    final services = createPreviewServices(today: DateTime(2026, 11, 7));
    await tester.pumpWidget(
      InOutApp(
        services: services,
        initialRoute: AppRoutes.history,
        homeBuilder: (context) => Scaffold(
          body: Text(
            'Selected day: ${AppScope.of(context).state.selectedDate.day}',
          ),
        ),
      ),
    );
    expect(find.text('5/7'), findsOneWidget);
    expect(find.text('1849'), findsOneWidget);
    expect(find.text('237'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('history-day-2026-11-6')),
      180,
    );
    await tester.tap(find.byKey(const ValueKey('history-day-2026-11-6')));
    await tester.pumpAndSettle();
    expect(find.text('Selected day: 6'), findsOneWidget);
  });
  testWidgets(
    'history window crosses New Year with chronological chart and newest rows',
    (tester) async {
      final base = createPreviewServices(today: DateTime(2027, 1, 3));
      final chartDates = <DateTime>[];
      final services = AppServices(
        state: base.state,
        calculations: base.calculations,
        validators: base.validators,
        historyChartBuilder: (context, days, goal) {
          chartDates
            ..clear()
            ..addAll(days.map((day) => day.date));
          return const SizedBox(height: 40);
        },
      );
      await tester.pumpWidget(
        InOutApp(services: services, initialRoute: AppRoutes.history),
      );
      expect(chartDates, [
        DateTime(2026, 12, 28),
        DateTime(2026, 12, 29),
        DateTime(2026, 12, 30),
        DateTime(2026, 12, 31),
        DateTime(2027, 1, 1),
        DateTime(2027, 1, 2),
        DateTime(2027, 1, 3),
      ]);
      expect(
        find.text('Last 7 days · Mon 28 Dec – Sun 3 Jan 2027'),
        findsOneWidget,
      );
      final newest = find.byKey(const ValueKey('history-day-2027-1-3'));
      final previous = find.byKey(const ValueKey('history-day-2027-1-2'));
      expect(
        tester.getTopLeft(newest).dy,
        lessThan(tester.getTopLeft(previous).dy),
      );
    },
  );
  testWidgets('empty History action opens Food List', (tester) async {
    final services = createPreviewServices(empty: true);
    await tester.pumpWidget(
      InOutApp(services: services, initialRoute: AppRoutes.history),
    );
    expect(find.text('No history yet'), findsOneWidget);
    await tester.tap(find.text('Log a meal'));
    await tester.pumpAndSettle();
    expect(find.text('S06 Food List'), findsOneWidget);
  });
  for (final width in [320.0, 360.0, 430.0]) {
    testWidgets('own screens fit width $width with large text and keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final services = createPreviewServices();
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        InOutApp(services: services, initialRoute: AppRoutes.profile),
      );
      await tester.scrollUntilVisible(find.text('Edit Profile'), 150);
      await tester.ensureVisible(find.text('Edit Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final editContext = tester.element(find.byType(Scaffold).last);
      expect(MediaQuery.of(editContext).viewInsets.bottom, 280);
      expect(MediaQuery.of(editContext).size.width, width);
      expect(MediaQuery.textScalerOf(editContext).scale(10), 16);
      await tester.ensureVisible(find.byKey(const ValueKey('profile-goal')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('profile-goal')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.pumpAndSettle();
      final saveCenter = tester.getCenter(find.text('Save Changes'));
      expect(saveCenter.dy, lessThan(740 - 280));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.text('Profile updated'), findsOneWidget);
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.pumpWidget(
        InOutApp(
          key: const ValueKey('history'),
          services: services,
          initialRoute: AppRoutes.history,
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).last, const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
