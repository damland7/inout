import 'formatters.dart';
import 'models.dart';

/// Typed placeholder data for Step 2.2.
///
/// The numbers match the Step 2.1 wireframes (sample user Berre Demirvakkas,
/// goal 2,000 kcal). Dates are relative to "today", so the demo always shows
/// the last seven days. Firebase replaces this data in Step 3.
abstract final class PlaceholderData {
  static const demoName = 'Berre Demirvakkas';
  static const demoEmail = 'berre.demirvakkas@sabanciuniv.edu';
  static const defaultGoalKcal = 2000;

  static UserProfile demoProfile(DateTime today) => UserProfile(
    name: demoName,
    email: demoEmail,
    dailyGoalKcal: defaultGoalKcal,
    createdAt: DateTime(today.year, today.month),
  );

  /// Common foods for S06 Food List. The images are network images.
  static const List<FoodItem> foods = [
    FoodItem(
      name: 'Lentil soup',
      servingLabel: '1 bowl (250 g)',
      kcalPerServing: 180,
      imageUrl: 'https://placehold.co/160x160/png?text=Lentil+soup',
    ),
    FoodItem(
      name: 'Menemen',
      servingLabel: '1 portion (200 g)',
      kcalPerServing: 290,
      imageUrl: 'https://placehold.co/160x160/png?text=Menemen',
    ),
    FoodItem(
      name: 'Chicken wrap',
      servingLabel: '1 wrap (220 g)',
      kcalPerServing: 450,
      imageUrl: 'https://placehold.co/160x160/png?text=Chicken+wrap',
    ),
    FoodItem(
      name: 'Simit',
      servingLabel: '1 piece (100 g)',
      kcalPerServing: 280,
      imageUrl: 'https://placehold.co/160x160/png?text=Simit',
    ),
    FoodItem(
      name: 'White rice',
      servingLabel: '1 plate (150 g)',
      kcalPerServing: 195,
      imageUrl: 'https://placehold.co/160x160/png?text=White+rice',
    ),
    FoodItem(
      name: 'Plain yogurt',
      servingLabel: '1 cup (200 g)',
      kcalPerServing: 120,
      imageUrl: 'https://placehold.co/160x160/png?text=Plain+yogurt',
    ),
    FoodItem(
      name: 'Apple',
      servingLabel: '1 medium (180 g)',
      kcalPerServing: 95,
      imageUrl: 'https://placehold.co/160x160/png?text=Apple',
    ),
    FoodItem(
      name: 'Banana',
      servingLabel: '1 medium (120 g)',
      kcalPerServing: 105,
      imageUrl: 'https://placehold.co/160x160/png?text=Banana',
    ),
  ];

  /// Activities for the S08 dropdown. Calories burned are entered by the user.
  static const List<String> activities = [
    'Walking',
    'Running',
    'Cycling',
    'Swimming',
    'Gym workout',
    'Football',
    'Yoga',
    'Other',
  ];

  /// Seven days of meals ending today. Daily totals:
  /// today 1,195 · −1 1,980 · −2 2,050 · −3 1,720 · −4 1,940 · −5 2,210 · −6 1,850.
  static List<MealEntry> demoMeals(DateTime today) {
    final meals = <MealEntry>[];
    void add(
      int daysAgo,
      String name,
      double kcal,
      MealType type, [
      double servings = 1,
    ]) {
      final date = _day(today, daysAgo);
      meals.add(
        MealEntry(
          id: 'demo-meal-$daysAgo-${meals.length}',
          foodName: name,
          kcalPerServing: kcal,
          servings: servings,
          mealType: type,
          date: date,
        ),
      );
    }

    // Today: 290 + 360 + 450 + 95 = 1,195
    add(0, 'Menemen', 290, MealType.breakfast);
    add(0, 'Lentil soup', 180, MealType.lunch, 2);
    add(0, 'Chicken wrap', 450, MealType.lunch);
    add(0, 'Apple', 95, MealType.snack);
    // 1 day ago: 400 + 825 + 660 + 95 = 1,980
    add(1, 'Simit', 280, MealType.breakfast);
    add(1, 'Plain yogurt', 120, MealType.breakfast);
    add(1, 'White rice', 195, MealType.lunch);
    add(1, 'Chicken wrap', 450, MealType.lunch);
    add(1, 'Lentil soup', 180, MealType.lunch);
    add(1, 'Köfte with bulgur', 660, MealType.dinner);
    add(1, 'Apple', 95, MealType.snack);
    // 2 days ago: 400 + 630 + 820 + 200 = 2,050
    add(2, 'Simit', 280, MealType.breakfast);
    add(2, 'Plain yogurt', 120, MealType.breakfast);
    add(2, 'Chicken wrap', 450, MealType.lunch);
    add(2, 'Lentil soup', 180, MealType.lunch);
    add(2, 'Pasta bolognese', 820, MealType.dinner);
    add(2, 'Banana', 105, MealType.snack);
    add(2, 'Apple', 95, MealType.snack);
    // 3 days ago: 290 + 555 + 770 + 105 = 1,720
    add(3, 'Menemen', 290, MealType.breakfast);
    add(3, 'Lentil soup', 180, MealType.lunch, 2);
    add(3, 'White rice', 195, MealType.lunch);
    add(3, 'Grilled salmon', 770, MealType.dinner);
    add(3, 'Banana', 105, MealType.snack);
    // 4 days ago: 570 + 645 + 620 + 105 = 1,940
    add(4, 'Menemen', 290, MealType.breakfast);
    add(4, 'Simit', 280, MealType.breakfast);
    add(4, 'Chicken wrap', 450, MealType.lunch);
    add(4, 'White rice', 195, MealType.lunch);
    add(4, 'Köfte with bulgur', 620, MealType.dinner);
    add(4, 'Banana', 105, MealType.snack);
    // 5 days ago: 400 + 630 + 820 + 360 = 2,210
    add(5, 'Simit', 280, MealType.breakfast);
    add(5, 'Plain yogurt', 120, MealType.breakfast);
    add(5, 'Lentil soup', 180, MealType.lunch);
    add(5, 'Chicken wrap', 450, MealType.lunch);
    add(5, 'Pasta bolognese', 820, MealType.dinner);
    add(5, 'Banana', 105, MealType.snack);
    add(5, 'Apple', 95, MealType.snack);
    add(5, 'Chocolate bar', 160, MealType.snack);
    // 6 days ago: 290 + 645 + 700 + 215 = 1,850
    add(6, 'Menemen', 290, MealType.breakfast);
    add(6, 'White rice', 195, MealType.lunch);
    add(6, 'Chicken wrap', 450, MealType.lunch);
    add(6, 'Grilled salmon', 700, MealType.dinner);
    add(6, 'Apple', 95, MealType.snack);
    add(6, 'Plain yogurt', 120, MealType.snack);
    return meals;
  }

  /// Workouts with user-entered calories. Daily totals:
  /// today 443 · −1 420 · −2 0 · −3 163 · −4 350 · −5 0 · −6 280.
  static List<WorkoutEntry> demoWorkouts(DateTime today) {
    final workouts = <WorkoutEntry>[];
    void add(int daysAgo, String activity, int minutes, double kcal) {
      workouts.add(
        WorkoutEntry(
          id: 'demo-workout-$daysAgo-${workouts.length}',
          activity: activity,
          minutes: minutes,
          kcalBurned: kcal,
          date: _day(today, daysAgo),
        ),
      );
    }

    add(0, 'Running', 30, 280);
    add(0, 'Walking', 40, 163);
    add(1, 'Running', 45, 420);
    add(3, 'Walking', 40, 163);
    add(4, 'Cycling', 50, 350);
    add(6, 'Running', 30, 280);
    return workouts;
  }

  static DateTime _day(DateTime today, int daysAgo) =>
      calendarDate(DateTime(today.year, today.month, today.day - daysAgo));
}

int _idCounter = 0;

/// Creates a unique id for a new meal or workout entry.
String newEntryId(String prefix) {
  _idCounter++;
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_idCounter';
}
