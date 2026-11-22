import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../formatters.dart';
import '../models.dart';
import '../theme/app_spacing.dart';

/// Matches `HistoryChartBuilder`; pass it to `AppServices`.
Widget buildHistoryChart(
  BuildContext context,
  List<HistoryDay> chronologicalDays,
  int dailyGoalKcal,
) => HistoryChart(days: chronologicalDays, goalKcal: dailyGoalKcal);

/// S09 bar chart: calories eaten on each of the last seven days, a dashed
/// goal line and a legend. Bars over the goal are drawn in red.
class HistoryChart extends StatelessWidget {
  const HistoryChart({super.key, required this.days, required this.goalKcal});

  /// Oldest day first.
  final List<HistoryDay> days;
  final int goalKcal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final within = theme.colorScheme.primary.withValues(alpha: 0.45);
    final over = theme.colorScheme.primary;
    final overDays = days.where((d) => !d.onTarget).length;
    return Card(
      key: const ValueKey('history-chart'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calories eaten', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              label:
                  'Bar chart of calories eaten in the last ${days.length} days. '
                  '$overDays of ${days.length} days were over the '
                  '$goalKcal kcal goal.',
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: CustomPaint(
                  painter: _BarsPainter(
                    days: days,
                    goal: goalKcal.toDouble(),
                    within: within,
                    over: over,
                    goalLine: theme.colorScheme.onSurface,
                    labelStyle: theme.textTheme.bodySmall!.copyWith(
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                _LegendDot(color: within, label: 'Within goal'),
                _LegendDot(color: over, label: 'Over goal'),
                _LegendDash(
                  color: theme.colorScheme.onSurface,
                  label: 'Goal ${_thousands(goalKcal)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _thousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: AppSpacing.xs),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _LegendDash extends StatelessWidget {
  const _LegendDash({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 16,
        height: 10,
        child: CustomPaint(painter: _DashPainter(color)),
      ),
      const SizedBox(width: AppSpacing.xs),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(6, y), paint);
    canvas.drawLine(Offset(10, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) => old.color != color;
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.days,
    required this.goal,
    required this.within,
    required this.over,
    required this.goalLine,
    required this.labelStyle,
  });

  final List<HistoryDay> days;
  final double goal;
  final Color within;
  final Color over;
  final Color goalLine;
  final TextStyle labelStyle;

  static const _labelHeight = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty || size.width <= 0) return;
    final chartHeight = size.height - _labelHeight;
    final highest = days.fold<double>(goal, (m, d) => math.max(m, d.eaten));
    // 10 % headroom so the tallest bar and the goal line never touch the top.
    final scale = highest <= 0 ? 0.0 : chartHeight / (highest * 1.1);

    final slot = size.width / days.length;
    final barWidth = math.min(28.0, slot * 0.6);
    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final centre = slot * i + slot / 2;
      final height = day.eaten * scale;
      if (height > 0) {
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(
            centre - barWidth / 2,
            chartHeight - height,
            barWidth,
            height,
          ),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );
        canvas.drawRRect(rect, Paint()..color = day.onTarget ? within : over);
      }
      _label(
        canvas,
        weekdays[day.date.weekday - 1].substring(0, 1),
        centre,
        chartHeight + 4,
      );
    }

    // Dashed goal line.
    final goalY = chartHeight - goal * scale;
    final paint = Paint()
      ..color = goalLine
      ..strokeWidth = 1.2;
    const dash = 5.0, gap = 4.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, goalY),
        Offset(math.min(x + dash, size.width), goalY),
        paint,
      );
    }
    // Baseline.
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      Paint()
        ..color = goalLine.withValues(alpha: 0.2)
        ..strokeWidth = 1,
    );
  }

  void _label(Canvas canvas, String text, double centreX, double top) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(centreX - painter.width / 2, top));
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) =>
      old.days != days ||
      old.goal != goal ||
      old.within != within ||
      old.over != over ||
      old.goalLine != goalLine;
}
