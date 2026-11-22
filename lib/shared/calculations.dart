import 'contracts.dart';
import 'formatters.dart';
import 'models.dart';

/// Calorie calculations shared by Home, History and the forms.
///
/// * meal total = kcal per serving × servings (180 × 2 = 360)
/// * burned = sum of the kcal the user entered for that day's workouts
/// * remaining = goal − eaten + burned (2,000 − 1,195 + 443 = 1,248)
/// * a day is on target when remaining ≥ 0
///
/// There is no BMR or MET formula: burned calories come from the user,
/// for example from a smart watch.
class InOutCalculations implements AppCalculations {
  const InOutCalculations();

  /// Number of days on the History screen, ending with today.
  static const historyLength = 7;

  @override
  double mealTotal(MealEntry meal) => meal.kcalPerServing * meal.servings;

  @override
  double eatenOn(DateTime date, List<MealEntry> meals) {
    final day = calendarDate(date);
    var total = 0.0;
    for (final meal in meals) {
      if (calendarDate(meal.date) == day) total += mealTotal(meal);
    }
    return total;
  }

  @override
  double burnedOn(DateTime date, List<WorkoutEntry> workouts) {
    final day = calendarDate(date);
    var total = 0.0;
    for (final workout in workouts) {
      if (calendarDate(workout.date) == day) total += workout.kcalBurned;
    }
    return total;
  }

  @override
  double remaining({
    required double goal,
    required double eaten,
    required double burned,
  }) => goal - eaten + burned;

  /// The last seven calendar days ending on [endingOn], oldest first.
  /// The History screen shows the rows newest first.
  @override
  HistoryReport history({
    required DateTime endingOn,
    required UserProfile profile,
    required List<MealEntry> meals,
    required List<WorkoutEntry> workouts,
  }) {
    final end = calendarDate(endingOn);
    final goal = profile.dailyGoalKcal.toDouble();
    final days = <HistoryDay>[];
    for (var i = historyLength - 1; i >= 0; i--) {
      // Building the date from parts keeps it correct across DST changes.
      final date = DateTime(end.year, end.month, end.day - i);
      final eaten = eatenOn(date, meals);
      final burned = burnedOn(date, workouts);
      final left = remaining(goal: goal, eaten: eaten, burned: burned);
      final hasEntries =
          meals.any((m) => calendarDate(m.date) == date) ||
          workouts.any((w) => calendarDate(w.date) == date);
      days.add(
        HistoryDay(
          date: date,
          eaten: eaten,
          burned: burned,
          remaining: left,
          hasEntries: hasEntries,
          onTarget: left >= 0,
        ),
      );
    }
    final totalEaten = days.fold<double>(0, (sum, d) => sum + d.eaten);
    final totalBurned = days.fold<double>(0, (sum, d) => sum + d.burned);
    return HistoryReport(
      days: days,
      averageEaten: totalEaten / historyLength,
      averageBurned: totalBurned / historyLength,
      daysOnTarget: days.where((d) => d.onTarget).length,
    );
  }
}
