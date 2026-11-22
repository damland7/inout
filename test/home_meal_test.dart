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

  group('S07 Add / Edit Meal', () {
    testWidgets('validates, calculates live total and saves one meal', (
      tester,
    ) async {
      final services = await _open(tester, route: AppRoutes.mealEditor);
      final count = services.state.meals.length;

      await _tap(tester, find.byKey(const ValueKey('meal-save')));
      expect(find.text('Enter a food name'), findsOneWidget);
      expect(find.text('Enter calories between 1 and 5,000'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('meal-name')),
        'Homemade pasta',
      );
      await tester.enterText(find.byKey(const ValueKey('meal-kcal')), '200');
      await _tap(tester, find.byKey(const ValueKey('meal-servings-increase')));
      expect(find.text('300 kcal'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('meal-save')));
      expect(find.text('Meal saved'), findsOneWidget);
      expect(services.state.meals.length, count + 1);
      final saved = services.state.meals.last;
      expect(saved.foodName, 'Homemade pasta');
      expect(saved.servings, 1.5);
      expect(saved.kcalPerServing, 200);

      await _tap(tester, find.byKey(const ValueKey('meal-saved-ok')));
      await tester.scrollUntilVisible(find.text('Homemade pasta'), 220);
      await tester.pumpAndSettle();
      expect(find.text('Homemade pasta'), findsOneWidget);
    });

    testWidgets('editing keeps the id and deletion can be undone', (
      tester,
    ) async {
      final services = await _open(tester);
      final original = services.state.meals.first;
      final count = services.state.meals.length;

      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pushNamed(
            AppRoutes.mealEditor,
            arguments: MealEditorArguments(entry: original),
          );
      await tester.pumpAndSettle();
      expect(find.text('Edit Meal'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('meal-kcal')), '310');
      await _tap(tester, find.byKey(const ValueKey('meal-save')));
      await _tap(tester, find.byKey(const ValueKey('meal-saved-ok')));
      expect(services.state.meals.length, count);
      expect(
        services.state.meals
            .firstWhere((meal) => meal.id == original.id)
            .kcalPerServing,
        310,
      );

      final edited = services.state.meals.firstWhere(
        (meal) => meal.id == original.id,
      );
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pushNamed(
            AppRoutes.mealEditor,
            arguments: MealEditorArguments(entry: edited),
          );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('meal-delete')));
      await _tap(tester, find.byKey(const ValueKey('meal-delete-confirm')));
      expect(services.state.meals.any((meal) => meal.id == edited.id), isFalse);
      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();
      expect(
        services.state.meals.where((meal) => meal.id == edited.id),
        hasLength(1),
      );
    });
  });

  testWidgets('Home and Meal editor fit a small phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _open(tester);
    expect(tester.takeException(), isNull);
    await _open(tester, route: AppRoutes.mealEditor);
    expect(tester.takeException(), isNull);
  });
}
