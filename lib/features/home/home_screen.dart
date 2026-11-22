import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../shared/contracts.dart';
import '../../shared/formatters.dart';
import '../../shared/models.dart';
import '../../shared/theme/app_spacing.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';

/// S05 Home and the shared three-tab shell.
///
/// Home reads every value from [AppState]. History and Profile stay mounted in
/// the indexed stack, so switching tabs preserves their scroll positions.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context).state;
    final tab = state.activeTab;
    return PopScope(
      canPop: tab == MainTab.home,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && state.activeTab != MainTab.home) {
          state.selectTab(MainTab.home);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: tab.index,
          children: const [_HomeTab(), HistoryScreen(), ProfileScreen()],
        ),
        floatingActionButton: tab == MainTab.home
            ? FloatingActionButton(
                key: const ValueKey('home-add'),
                tooltip: 'Add meal or workout',
                onPressed: () => _showAddMenu(context),
                child: const Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          key: const ValueKey('main-navigation'),
          selectedIndex: tab.index,
          onDestinationSelected: (index) {
            state.selectTab(MainTab.values[index]);
          },
          destinations: const [
            NavigationDestination(
              key: ValueKey('nav-home'),
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              key: ValueKey('nav-history'),
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'History',
            ),
            NavigationDestination(
              key: ValueKey('nav-profile'),
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showAddMenu(BuildContext context) async {
  final date = AppScope.of(context).state.selectedDate;
  final route = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          0,
          AppSpacing.screenMargin,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add to ${dayLabel(date)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              key: const ValueKey('home-add-meal'),
              leading: const Icon(Icons.restaurant_outlined),
              title: const Text('Add Meal'),
              subtitle: const Text('Pick a food or add your own'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, AppRoutes.foodList),
            ),
            ListTile(
              key: const ValueKey('home-add-workout'),
              leading: const Icon(Icons.directions_run_outlined),
              title: const Text('Add Workout'),
              subtitle: const Text('Enter calories from your watch'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, AppRoutes.workoutEditor),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ),
  );
  if (route == null || !context.mounted) return;
  final arguments = route == AppRoutes.foodList
      ? date
      : WorkoutEditorArguments(date: date);
  await Navigator.pushNamed(context, route, arguments: arguments);
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final state = services.state;
    final date = calendarDate(state.selectedDate);
    final meals = state.meals
        .where((meal) => calendarDate(meal.date) == date)
        .toList(growable: false);
    final workouts = state.workouts
        .where((workout) => calendarDate(workout.date) == date)
        .toList(growable: false);
    final eaten = services.calculations.eatenOn(date, meals);
    final burned = services.calculations.burnedOn(date, workouts);
    final goal = state.profile.dailyGoalKcal.toDouble();
    final remaining = services.calculations.remaining(
      goal: goal,
      eaten: eaten,
      burned: burned,
    );
    final today = calendarDate(state.today);
    final isToday = date == today;
    final hasEntries = meals.isNotEmpty || workouts.isNotEmpty;
    return SafeArea(
      child: ListView(
        key: const PageStorageKey('home-scroll'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.sm,
          AppSpacing.screenMargin,
          104,
        ),
        children: [
          _DateBar(date: date, today: today),
          if (!isToday)
            Align(
              alignment: Alignment.center,
              child: TextButton(
                key: const ValueKey('home-back-today'),
                onPressed: () => state.selectDate(today),
                child: const Text('Back to today'),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          _BalanceCard(
            goal: goal,
            eaten: eaten,
            burned: burned,
            remaining: remaining,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!hasEntries)
            const _EmptyDay()
          else ...[
            _SectionHeader(label: 'Meals', total: eaten),
            const SizedBox(height: AppSpacing.sm),
            for (final type in MealType.values)
              _MealGroup(
                type: type,
                meals: meals.where((meal) => meal.mealType == type).toList(),
              ),
            const SizedBox(height: AppSpacing.md),
            _SectionHeader(label: 'Workouts', total: burned),
            const SizedBox(height: AppSpacing.sm),
            if (workouts.isEmpty)
              Text(
                'No workouts logged yet',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              for (final workout in workouts) _WorkoutCard(workout: workout),
          ],
        ],
      ),
    );
  }
}

class _DateBar extends StatelessWidget {
  const _DateBar({required this.date, required this.today});

  final DateTime date;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context).state;
    final isToday = date == today;
    return Row(
      children: [
        IconButton(
          key: const ValueKey('home-date-previous'),
          tooltip: 'Previous day',
          onPressed: () =>
              state.selectDate(DateTime(date.year, date.month, date.day - 1)),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            '${isToday ? 'Today, ' : ''}${dayLabel(date)}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(
          key: const ValueKey('home-date-next'),
          tooltip: 'Next day',
          onPressed: isToday
              ? null
              : () => state.selectDate(
                  DateTime(date.year, date.month, date.day + 1),
                ),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.goal,
    required this.eaten,
    required this.burned,
    required this.remaining,
  });

  final double goal;
  final double eaten;
  final double burned;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final over = remaining < 0;
    final color = over ? theme.colorScheme.error : theme.colorScheme.primary;
    final progress = goal <= 0 ? 0.0 : (eaten / goal).clamp(0.0, 1.0);
    return Card(
      key: const ValueKey('home-balance'),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(over ? 'Over goal' : 'Remaining'),
            Text(
              '${_displayKcal(over ? -remaining : remaining)} kcal',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${_displayKcal(goal)} goal − ${_displayKcal(eaten)} eaten + '
              '${_displayKcal(burned)} burned',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _BalanceMetric(value: goal, label: 'Goal'),
                ),
                Expanded(
                  child: _BalanceMetric(value: eaten, label: 'Eaten'),
                ),
                Expanded(
                  child: _BalanceMetric(value: burned, label: 'Burned'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({required this.value, required this.label});

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        _displayKcal(value),
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: const ValueKey('home-empty'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No entries yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Tap + to log your first meal or workout for this day.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.total});

  final String label;
  final double total;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(label, style: Theme.of(context).textTheme.titleLarge),
      ),
      Text('${_displayKcal(total)} kcal'),
    ],
  );
}

class _MealGroup extends StatelessWidget {
  const _MealGroup({required this.type, required this.meals});

  final MealType type;
  final List<MealEntry> meals;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final total = meals.fold<double>(
      0,
      (sum, meal) => sum + services.calculations.mealTotal(meal),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  type.label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text('${_displayKcal(total)} kcal'),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No ${type.label.toLowerCase()} logged yet',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            for (final meal in meals) _MealCard(meal: meal),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});

  final MealEntry meal;

  @override
  Widget build(BuildContext context) {
    final total = AppScope.of(context).calculations.mealTotal(meal);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('home-meal-${meal.id}'),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.mealEditor,
          arguments: MealEditorArguments(entry: meal, date: meal.date),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: Row(
            children: [
              Icon(
                Icons.restaurant_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.foodName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_servings(meal.servings)} serving${meal.servings == 1 ? '' : 's'} × '
                        '${_displayKcal(meal.kcalPerServing)} kcal',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                _displayKcal(total),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.workout});

  final WorkoutEntry workout;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('home-workout-${workout.id}'),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.workoutEditor,
        arguments: WorkoutEditorArguments(entry: workout, date: workout.date),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.md),
        child: Row(
          children: [
            Icon(
              Icons.directions_run_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.activity,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${workout.minutes} min',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            Text(
              _displayKcal(workout.kcalBurned),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );
}

String _servings(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

String _displayKcal(double value) => value.round().toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (match) => '${match[1]},',
);
