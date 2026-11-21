import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inout_app/shared/app_state.dart';
import 'package:inout_app/shared/models.dart';
import 'package:inout_app/shared/placeholder_data.dart';

final _today = DateTime(2026, 11, 20);

InOutState _state({bool loggedIn = true, bool seed = true}) =>
    InOutState(clock: () => _today, loggedIn: loggedIn, seedDemoData: seed);

MealEntry _meal(String id, {double kcal = 100, double servings = 1}) =>
    MealEntry(
      id: id,
      foodName: 'Test food',
      kcalPerServing: kcal,
      servings: servings,
      mealType: MealType.lunch,
      date: _today,
    );

double _eaten(InOutState s, DateTime day) => s
    .mealsOn(day)
    .fold(0.0, (sum, m) => sum + m.kcalPerServing * m.servings);

double _burned(InOutState s, DateTime day) =>
    s.workoutsOn(day).fold(0.0, (sum, w) => sum + w.kcalBurned);

void main() {
  group('placeholder data', () {
    test('matches the Step 2.1 wireframe totals', () {
      final s = _state();
      expect(s.profile.name, PlaceholderData.demoName);
      expect(s.profile.dailyGoalKcal, 2000);
      const eaten = [1195.0, 1980.0, 2050.0, 1720.0, 1940.0, 2210.0, 1850.0];
      const burned = [443.0, 420.0, 0.0, 163.0, 350.0, 0.0, 280.0];
      for (var i = 0; i < 7; i++) {
        final day = DateTime(2026, 11, 20 - i);
        expect(_eaten(s, day), eaten[i], reason: 'eaten $i days ago');
        expect(_burned(s, day), burned[i], reason: 'burned $i days ago');
      }
      expect(2000 - _eaten(s, _today) + _burned(s, _today), 1248);
    });

    test('food list has network images and activities end with Other', () {
      expect(PlaceholderData.foods, hasLength(8));
      expect(
        PlaceholderData.foods.every((f) => f.imageUrl.startsWith('https://')),
        isTrue,
      );
      expect(PlaceholderData.activities.last, 'Other');
    });

    test('newEntryId never repeats', () {
      final ids = {for (var i = 0; i < 100; i++) newEntryId('meal')};
      expect(ids, hasLength(100));
    });
  });

  group('entries', () {
    test('saving with the same id updates instead of duplicating', () {
      final s = _state(seed: false);
      s.saveMeal(_meal('a', kcal: 100));
      s.saveMeal(_meal('a', kcal: 250));
      expect(s.meals, hasLength(1));
      expect(s.meals.single.kcalPerServing, 250);
    });

    test('remove then restore brings back exactly one copy', () {
      final s = _state(seed: false);
      final meal = _meal('a');
      s.saveMeal(meal);
      s.removeEntry('a');
      expect(s.meals, isEmpty);
      s.restoreMeal(meal);
      s.restoreMeal(meal);
      expect(s.meals, hasLength(1));
    });

    test('deleting lentil soup gives the wireframe numbers', () {
      final s = _state();
      final lentil = s
          .mealsOn(_today)
          .firstWhere((m) => m.foodName == 'Lentil soup');
      s.removeEntry(lentil.id);
      expect(_eaten(s, _today), 835);
      expect(2000 - _eaten(s, _today) + _burned(s, _today), 1608);
    });

    test('workouts are saved, edited and removed by id', () {
      final s = _state(seed: false);
      final run = WorkoutEntry(
        id: 'w',
        activity: 'Running',
        minutes: 30,
        kcalBurned: 280,
        date: _today,
      );
      s.saveWorkout(run);
      s.saveWorkout(
        WorkoutEntry(
          id: 'w',
          activity: 'Running',
          minutes: 45,
          kcalBurned: 420,
          date: _today,
        ),
      );
      expect(s.workouts.single.kcalBurned, 420);
      s.removeEntry('w');
      expect(s.workouts, isEmpty);
    });

    test('lists returned to screens cannot be changed directly', () {
      final s = _state();
      expect(() => s.meals.clear(), throwsUnsupportedError);
      expect(() => s.workouts.clear(), throwsUnsupportedError);
    });

    test('every change notifies listeners', () {
      final s = _state(seed: false);
      var calls = 0;
      s.addListener(() => calls++);
      s.saveMeal(_meal('a'));
      s.removeEntry('a');
      s.removeEntry('missing'); // nothing removed: no notification
      s.updateProfile(name: 'New Name', dailyGoalKcal: 1900);
      expect(calls, 3);
    });
  });

  group('navigation state', () {
    test('selectDate stops at today and ignores the time of day', () {
      final s = _state();
      s.selectDate(DateTime(2026, 11, 18, 21, 30));
      expect(s.selectedDate, DateTime(2026, 11, 18));
      s.selectDate(DateTime(2026, 11, 25));
      expect(s.selectedDate, _today);
    });

    test('selectTab changes the active tab', () {
      final s = _state();
      s.selectTab(MainTab.history);
      expect(s.activeTab, MainTab.history);
    });
  });

  group('session', () {
    test('logIn opens the demo account on Home for today', () {
      final s = _state(loggedIn: false);
      expect(s.loggedIn, isFalse);
      expect(s.meals, isEmpty);
      s.selectTab(MainTab.profile);
      s.logIn();
      expect(s.loggedIn, isTrue);
      expect(s.profile.email, PlaceholderData.demoEmail);
      expect(s.meals, isNotEmpty);
      expect(s.activeTab, MainTab.home);
      expect(s.selectedDate, _today);
    });

    test('registerProfile starts an empty account with the default goal', () {
      final s = _state();
      s.registerProfile(name: '  Ada Lovelace ', email: ' ada@example.com ');
      expect(s.profile.name, 'Ada Lovelace');
      expect(s.profile.email, 'ada@example.com');
      expect(s.profile.dailyGoalKcal, 2000);
      expect(s.meals, isEmpty);
      expect(s.workouts, isEmpty);
      expect(s.loggedIn, isTrue);
    });

    test('logOut clears the account but keeps theme and accent', () {
      final s = _state();
      const blue = Color(0xFF2563EB);
      s.updateAppearance(mode: ThemeMode.dark, accent: blue);
      s.logOut();
      expect(s.loggedIn, isFalse);
      expect(s.meals, isEmpty);
      expect(s.workouts, isEmpty);
      expect(s.profile.email, isEmpty);
      expect(s.profile.themeMode, ThemeMode.dark);
      expect(s.profile.accentColor, blue);
    });

    test('appearance changes are reported for saving on the phone', () {
      ThemeMode? savedMode;
      final s = InOutState(
        clock: () => _today,
        onAppearanceChanged: (mode, accent) => savedMode = mode,
      );
      s.updateAppearance(mode: ThemeMode.light, accent: s.profile.accentColor);
      expect(savedMode, ThemeMode.light);
    });
  });
}
