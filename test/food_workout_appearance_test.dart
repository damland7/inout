import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inout_app/app/app_routes.dart';
import 'package:inout_app/app/inout_app.dart';
import 'package:inout_app/features/food_workout_appearance_routes.dart';
import 'package:inout_app/shared/app_services.dart';
import 'package:inout_app/shared/app_state.dart';
import 'package:inout_app/shared/calculations.dart';
import 'package:inout_app/shared/contracts.dart';
import 'package:inout_app/shared/models.dart';
import 'package:inout_app/shared/theme/app_colors.dart';
import 'package:inout_app/shared/theme/app_theme.dart';
import 'package:inout_app/shared/validators.dart';

final _today = DateTime(2026, 11, 20);

AppServices _services({bool loggedIn = true}) => createAppServices(
  state: InOutState(clock: () => _today, loggedIn: loggedIn),
);

Future<AppServices> _open(
  WidgetTester tester,
  String route, {
  AppServices? services,
}) async {
  final app = services ?? _services();
  await tester.pumpWidget(
    InOutApp(
      key: UniqueKey(),
      services: app,
      initialRoute: route,
      themeBuilder: buildAppTheme,
      featureRoutes: foodWorkoutAppearanceRoutes,
    ),
  );
  await tester.pumpAndSettle();
  return app;
}

Future<void> _push(WidgetTester tester, String route, Object arguments) async {
  tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(
    route,
    arguments: arguments,
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _useScreen(WidgetTester tester, Size size, {double textScale = 1}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  group('Calculations', () {
    const calc = InOutCalculations();

    test('meal total and remaining match the Step 2.1 examples', () {
      final soup = MealEntry(
        id: 'm1',
        foodName: 'Lentil soup',
        kcalPerServing: 180,
        servings: 2,
        mealType: MealType.lunch,
        date: _today,
      );
      expect(calc.mealTotal(soup), 360);
      expect(calc.remaining(goal: 2000, eaten: 1195, burned: 443), 1248);
      expect(calc.remaining(goal: 2000, eaten: 835, burned: 443), 1608);
    });

    test('history is the last 7 days, oldest first, from shared state', () {
      final state = InOutState(clock: () => _today, loggedIn: true);
      final report = calc.history(
        endingOn: state.today,
        profile: state.profile,
        meals: state.meals,
        workouts: state.workouts,
      );
      expect(report.days, hasLength(7));
      expect(report.days.first.date, DateTime(2026, 11, 14));
      expect(report.days.last.date, DateTime(2026, 11, 20));
      expect(report.days.last.eaten, 1195);
      expect(report.days.last.burned, 443);
      expect(report.days.last.remaining, 1248);
      expect(report.days.last.onTarget, isTrue);
    });

    test('history crosses a month and year boundary', () {
      final report = calc.history(
        endingOn: DateTime(2027, 1, 3),
        profile: UserProfile(
          name: 'A',
          email: 'a@b.co',
          dailyGoalKcal: 2000,
          createdAt: DateTime(2026),
        ),
        meals: const [],
        workouts: const [],
      );
      expect(report.days.first.date, DateTime(2026, 12, 28));
      expect(report.isEmpty, isTrue);
      expect(report.daysOnTarget, 7);
    });
  });

  group('Validators', () {
    const v = InOutValidators();

    test('numbers must be finite and inside the limits', () {
      expect(v.caloriesPerServing('NaN'), isNotNull);
      expect(v.caloriesPerServing('Infinity'), isNotNull);
      expect(v.caloriesPerServing('0'), isNotNull);
      expect(v.caloriesPerServing('5000'), isNull);
      expect(v.caloriesBurned('3000'), isNull);
      expect(v.caloriesBurned('3001'), isNotNull);
      expect(v.duration('30.5'), isNotNull);
      expect(v.duration('600'), isNull);
      expect(v.duration('601'), isNotNull);
      expect(v.dailyGoal('1199'), isNotNull);
      expect(v.dailyGoal('1200'), isNull);
    });

    test('account fields', () {
      expect(v.email('ada@example'), isNotNull);
      expect(v.email(' ada@example.com '), isNull);
      expect(v.signUpPassword('12345'), isNotNull);
      expect(v.confirmPassword('abc', 'abd'), 'Passwords do not match');
      expect(v.fullName('   '), isNotNull);
    });
  });

  group('Theme', () {
    test('light theme uses the exact accent and the Inter font', () {
      final theme = buildAppTheme(Brightness.light, AppColors.primary);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Inter');
    });

    test('dark theme uses the dark background', () {
      final theme = buildAppTheme(Brightness.dark, AppColors.primary);
      expect(theme.scaffoldBackgroundColor, AppColors.darkBackground);
    });

    test('accent names', () {
      expect(accentNameFor(const Color(0xFF1570EF)), 'Blue');
      expect(accentNameFor(AppColors.primary), 'Red');
    });
  });

  group('S06 Food List', () {
    testWidgets('search filters, no result offers a custom food', (
      tester,
    ) async {
      await _open(tester, AppRoutes.foodList);
      expect(find.text('Lentil soup'), findsOneWidget);
      expect(find.text('COMMON FOODS'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('food-search')), 'SIM');
      await tester.pumpAndSettle();
      expect(find.text('Simit'), findsOneWidget);
      expect(find.text('Lentil soup'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('food-search')),
        'pizzza',
      );
      await tester.pumpAndSettle();
      expect(find.text('No foods match “pizzza”'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('add-custom-food')));
      expect(find.text('S07 Add / Edit Meal'), findsOneWidget);

      // Back keeps the search text.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(find.text('pizzza'), findsOneWidget);
    });

    testWidgets('tapping a food opens the meal editor with that food', (
      tester,
    ) async {
      MealEditorArguments? received;
      final services = _services();
      await tester.pumpWidget(
        InOutApp(
          services: services,
          initialRoute: AppRoutes.foodList,
          featureRoutes: {
            ...foodWorkoutAppearanceRoutes,
            AppRoutes.mealEditor: (context) {
              received =
                  ModalRoute.of(context)!.settings.arguments
                      as MealEditorArguments?;
              return const Scaffold(body: Text('meal editor'));
            },
          },
        ),
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('food-Lentil soup')));
      expect(find.text('meal editor'), findsOneWidget);
      expect(received?.food?.kcalPerServing, 180);
      expect(received?.date, services.state.selectedDate);
    });
  });

  group('S08 Add / Edit Workout', () {
    testWidgets('inline errors, then one saved entry and a dialog', (
      tester,
    ) async {
      final services = await _open(tester, AppRoutes.workoutEditor);
      final before = services.state.workouts.length;

      await _tap(tester, find.byKey(const ValueKey('workout-save')));
      expect(find.text('Choose an activity'), findsOneWidget);
      expect(
        find.text('Enter a duration between 1 and 600 minutes'),
        findsOneWidget,
      );
      expect(find.text('Enter calories between 1 and 3,000'), findsOneWidget);
      expect(services.state.workouts.length, before);

      await _tap(tester, find.byKey(const ValueKey('workout-activity')));
      await tester.tap(find.text('Running').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('workout-duration')),
        '30',
      );
      await tester.enterText(find.byKey(const ValueKey('workout-kcal')), '280');
      await _tap(tester, find.byKey(const ValueKey('workout-save')));

      expect(find.text('Workout saved'), findsOneWidget);
      expect(services.state.workouts.length, before + 1);
      final saved = services.state.workouts.last;
      expect(saved.activity, 'Running');
      expect(saved.minutes, 30);
      expect(saved.kcalBurned, 280);

      await _tap(tester, find.byKey(const ValueKey('workout-saved-ok')));
      expect(find.text('S05 Home'), findsOneWidget);
      expect(services.state.workouts.length, before + 1);
    });

    testWidgets('edit keeps the same id; delete can be undone', (
      tester,
    ) async {
      final services = await _open(tester, AppRoutes.history);
      final state = services.state;
      final original = state.workouts.first;
      final count = state.workouts.length;

      await _push(
        tester,
        AppRoutes.workoutEditor,
        WorkoutEditorArguments(entry: original),
      );
      expect(find.text('Edit Workout'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('workout-kcal')), '300');
      await _tap(tester, find.byKey(const ValueKey('workout-save')));
      await _tap(tester, find.byKey(const ValueKey('workout-saved-ok')));
      expect(state.workouts.length, count);
      final edited = state.workouts.firstWhere((w) => w.id == original.id);
      expect(edited.kcalBurned, 300);

      await _push(
        tester,
        AppRoutes.workoutEditor,
        WorkoutEditorArguments(entry: edited),
      );
      await _tap(tester, find.byKey(const ValueKey('workout-delete')));
      await _tap(tester, find.byKey(const ValueKey('workout-delete-confirm')));
      expect(state.workouts.any((w) => w.id == original.id), isFalse);

      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();
      expect(state.workouts.where((w) => w.id == original.id), hasLength(1));
    });

    testWidgets('Back with unsaved changes asks before discarding', (
      tester,
    ) async {
      await _open(tester, AppRoutes.history);
      await _push(
        tester,
        AppRoutes.workoutEditor,
        WorkoutEditorArguments(date: _today),
      );
      await tester.enterText(
        find.byKey(const ValueKey('workout-duration')),
        '45',
      );
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Add Workout'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Add Workout'), findsNothing);
    });
  });

  group('S12 Appearance', () {
    testWidgets('mode and accent apply immediately to the shared state', (
      tester,
    ) async {
      final services = await _open(tester, AppRoutes.appearance);
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(services.state.profile.themeMode, ThemeMode.dark);

      await _tap(tester, find.byKey(const ValueKey('accent-Blue')));
      expect(services.state.profile.accentColor, const Color(0xFF1570EF));
      expect(
        Theme.of(tester.element(find.text('Appearance'))).brightness,
        Brightness.dark,
      );
    });
  });

  group('No overflow on small and large phones', () {
    for (final size in const [Size(320, 568), Size(430, 932)]) {
      for (final route in [
        AppRoutes.foodList,
        AppRoutes.workoutEditor,
        AppRoutes.appearance,
      ]) {
        testWidgets('$route at ${size.width.toInt()} px with large text', (
          tester,
        ) async {
          _useScreen(tester, size, textScale: 1.3);
          await _open(tester, route);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
