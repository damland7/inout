import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_routes.dart';
import '../../shared/contracts.dart';
import '../../shared/widgets/form_widgets.dart';
import 'account_layout.dart';

/// S04 Goal Setup (step 2 of 2). Asks for the daily calorie goal right after
/// Sign Up. There is no back arrow: the account already exists.
class GoalSetupScreen extends StatefulWidget {
  const GoalSetupScreen({super.key});

  static const quickPicks = [1800, 2000, 2200, 2500];

  @override
  State<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends State<GoalSetupScreen> {
  final _form = GlobalKey<FormState>();
  final _goal = TextEditingController(text: '2000');
  bool _submitted = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _goal.addListener(_refreshChips);
  }

  void _refreshChips() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _goal.removeListener(_refreshChips);
    _goal.dispose();
    super.dispose();
  }

  void _start() {
    if (_saving) return;
    setState(() => _submitted = true);
    if (!_form.currentState!.validate()) return;
    final goal = int.tryParse(_goal.text.trim());
    if (goal == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final state = AppScope.of(context).state;
    state.updateProfile(name: state.profile.name, dailyGoalKcal: goal);
    AppRoutes.openHome(context);
  }

  static String _thousands(int value) => value >= 1000
      ? '${value ~/ 1000},${(value % 1000).toString().padLeft(3, '0')}'
      : '$value';

  @override
  Widget build(BuildContext context) {
    final validators = AppScope.of(context).validators;
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: AccountLayout(
          children: [
            const SizedBox(height: 16),
            const StepLabel('Step 2 of 2'),
            const SizedBox(height: 4),
            Text(
              'Set your daily goal',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How many calories do you want to eat per day? Home shows how '
              'much of this goal is left.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _form,
              autovalidateMode: _submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: AppTextField(
                key: const ValueKey('goal-field'),
                label: 'Daily calorie goal',
                hintText: 'e.g. 2000',
                suffixText: 'kcal',
                helperText: 'Between 1,200 and 5,000 kcal',
                controller: _goal,
                validator: validators.dailyGoal,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _start(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Quick pick', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in GoalSetupScreen.quickPicks)
                  ChoiceChip(
                    key: ValueKey('goal-chip-$value'),
                    label: Text(_thousands(value)),
                    showCheckmark: false,
                    selected: _goal.text.trim() == '$value',
                    onSelected: (_) => _goal.text = '$value',
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('You can change your goal later in Profile.'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Start Tracking',
              loading: _saving,
              onPressed: _start,
            ),
          ],
        ),
      ),
    );
  }
}
