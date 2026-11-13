import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../shared/contracts.dart';
import '../../shared/formatters.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final state = services.state;
    final report = services.calculations.history(
      endingOn: state.today,
      profile: state.profile,
      meals: state.meals,
      workouts: state.workouts,
    );
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const PageStorageKey('history-scroll'),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Last 7 days · ${dayLabel(report.days.first.date)} – '
              '${dayLabel(report.days.last.date)} ${state.today.year}',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            if (report.isEmpty) ...[
              const SizedBox(height: 40),
              Icon(Icons.history, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'No history yet',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your daily totals will appear here after you log meals or workouts.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.foodList,
                  arguments: state.today,
                ),
                child: const Text('Log a meal'),
              ),
            ] else ...[
              services.historyChartBuilder(
                context,
                report.days,
                state.profile.dailyGoalKcal,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 24,
                runSpacing: 20,
                alignment: WrapAlignment.spaceAround,
                children: [
                  _Metric(value: kcal(report.averageEaten), label: 'Avg eaten'),
                  _Metric(
                    value: kcal(report.averageBurned),
                    label: 'Avg burned',
                  ),
                  _Metric(
                    value: '${report.daysOnTarget}/${report.days.length}',
                    label: 'Days on target',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              for (final day in report.days.reversed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: InkWell(
                      key: ValueKey(
                        'history-day-${day.date.year}-${day.date.month}-${day.date.day}',
                      ),
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => AppRoutes.openHome(context, date: day.date),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: day.onTarget
                                        ? theme.colorScheme.tertiary
                                        : theme.colorScheme.error,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${dayLabel(day.date)}'
                                    '${calendarDate(day.date) == calendarDate(state.today) ? ' · Today' : ''}',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    day.remaining >= 0
                                        ? '${kcal(day.remaining)} left'
                                        : '${kcal(-day.remaining)} over',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      color: day.onTarget
                                          ? theme.colorScheme.tertiary
                                          : theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              day.hasEntries
                                  ? '${kcal(day.eaten)} eaten · ${kcal(day.burned)} burned'
                                  : 'No entries',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(value, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 4),
      Text(label),
    ],
  );
}
