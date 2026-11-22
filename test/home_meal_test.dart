import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inout_app/app/app_routes.dart';
import 'package:inout_app/app/inout_app.dart';
import 'package:inout_app/features/food_workout_appearance_routes.dart';
import 'package:inout_app/features/history/history_screen.dart';
import 'package:inout_app/features/home/home_screen.dart';
import 'package:inout_app/features/home_meal_routes.dart';
import 'package:inout_app/features/profile/profile_screen.dart';
import 'package:inout_app/shared/app_services.dart';
import 'package:inout_app/shared/app_state.dart';
import 'package:inout_app/shared/contracts.dart';
import 'package:inout_app/shared/models.dart';
import 'package:inout_app/shared/theme/app_theme.dart';

final _today = DateTime(2026, 11, 20);

AppServices _services({bool loggedIn = true}) => createAppServices(
  state: InOutState(clock: () => _today, loggedIn: loggedIn),
);

Future<AppServices> _open(
  WidgetTester tester, {
  String route = AppRoutes.home,
  AppServices? services,
  Map<String, WidgetBuilder> extraRoutes = const {},
}) async {
  final app = services ?? _services();
  await tester.pumpWidget(
    InOutApp(
      services: app,
      initialRoute: route,
      themeBuilder: buildAppTheme,
      homeBuilder: (_) => const HomeScreen(),
      featureRoutes: {
        ...foodWorkoutAppearanceRoutes,
        ...homeMealRoutes,
        ...extraRoutes,
      },
    ),
  );
  await tester.pumpAndSettle();
  return app;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('S05 Home', () {
    testWidgets('shows the shared daily totals and grouped entries', (
      tester,
    ) async {
      await _open(tester);

      expect(find.text('Today, Fri 20 Nov'), findsOneWidget);
      expect(find.text('1,248 kcal'), findsOneWidget);
      expect(find.text('1,195 kcal'), findsOneWidget);
      expect(find.textContaining('443 burned'), findsOneWidget);
      expect(find.text('BREAKFAST'), findsOneWidget);
      expect(find.text('Lentil soup'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Running'), 260);
      await tester.pumpAndSettle();
      expect(find.text('Running'), findsOneWidget);
    });

    testWidgets('changes date, returns to today and blocks future days', (
      tester,
    ) async {
      final services = await _open(tester);
      final next = tester.widget<IconButton>(
        find.byKey(const ValueKey('home-date-next')),
      );
      expect(next.onPressed, isNull);

      await _tap(tester, find.byKey(const ValueKey('home-date-previous')));
      expect(find.text('Thu 19 Nov'), findsOneWidget);
      expect(find.text('Back to today'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('home-back-today')));
      expect(services.state.selectedDate, _today);
    });

    testWidgets('add menu passes the selected date to Food List', (
      tester,
    ) async {
      Object? received;
      await _open(
        tester,
        extraRoutes: {
          AppRoutes.foodList: (context) {
            received = ModalRoute.of(context)?.settings.arguments;
            return const Scaffold(body: Text('food route'));
          },
        },
      );

      await _tap(tester, find.byKey(const ValueKey('home-add')));
      await _tap(tester, find.byKey(const ValueKey('home-add-meal')));
      expect(find.text('food route'), findsOneWidget);
      expect(received, _today);
    });

    testWidgets('delete updates totals and UNDO restores exactly once', (
      tester,
    ) async {
      final services = await _open(tester);
      final meal = services.state.meals.first;
      final count = services.state.meals.length;

      await _tap(tester, find.byKey(ValueKey('home-delete-${meal.id}')));
      await _tap(tester, find.byKey(const ValueKey('home-delete-confirm')));
      expect(services.state.meals.length, count - 1);
      expect(find.text('${meal.foodName} deleted'), findsOneWidget);

      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();
      expect(services.state.meals.length, count);
      expect(
        services.state.meals.where((entry) => entry.id == meal.id),
        hasLength(1),
      );
    });

    testWidgets('bottom navigation preserves the shared shell', (tester) async {
      await _open(tester);
      await _tap(tester, find.byKey(const ValueKey('nav-history')));
      expect(find.byType(HistoryScreen), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('nav-profile')));
      expect(find.byType(ProfileScreen), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('nav-home')));
      expect(find.text('Today, Fri 20 Nov'), findsOneWidget);
    });
  });
}
