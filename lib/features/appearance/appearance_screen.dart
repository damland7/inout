import 'package:flutter/material.dart';

import '../../shared/contracts.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

/// S12 Appearance — opened from Profile.
///
/// The user chooses System, Light or Dark mode and one of five accent
/// colours. There is no Save button: every change is applied to the whole
/// app immediately through `AppState.updateAppearance`.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context).state;
    final profile = state.profile;
    final theme = Theme.of(context);

    void apply({ThemeMode? mode, Color? accent}) => state.updateAppearance(
      mode: mode ?? profile.themeMode,
      accent: accent ?? profile.accentColor,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              children: [
                Text('Theme', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'System follows your phone’s light or dark setting.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<ThemeMode>(
                  key: const ValueKey('appearance-mode'),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {profile.themeMode},
                  onSelectionChanged: (selection) =>
                      apply(mode: selection.first),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Accent colour', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Used for buttons, links and highlights.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final option in accentOptions)
                      _AccentSwatch(
                        option: option,
                        selected:
                            option.color.toARGB32() ==
                            profile.accentColor.toARGB32(),
                        onTap: () => apply(accent: option.color),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Preview', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                const _PreviewCard(),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Changes are applied right away.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AccentOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '${option.name} accent',
      child: InkWell(
        key: ValueKey('accent-${option.name}'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSpacing.tapTarget,
              height: AppSpacing.tapTarget,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.onSurface
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: option.color,
                  shape: BoxShape.circle,
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ExcludeSemantics(
              child: Text(option.name, style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Remaining today', style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '1,248 kcal',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: () {}, child: const Text('Sample button')),
          ],
        ),
      ),
    );
  }
}
