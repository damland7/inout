import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_routes.dart';
import '../../shared/contracts.dart';
import '../../shared/formatters.dart';
import '../../shared/models.dart';
import '../../shared/placeholder_data.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/widgets/form_widgets.dart';

/// S08 Add / Edit Workout.
///
/// The user picks an activity and enters the duration and the calories
/// burned (for example from a smart watch); the app does not estimate them.
/// Route argument: `WorkoutEditorArguments(entry:, date:)`. With an entry the
/// screen is in edit mode and saving keeps the same id.
class WorkoutEditorScreen extends StatefulWidget {
  const WorkoutEditorScreen({super.key});

  @override
  State<WorkoutEditorScreen> createState() => _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends State<WorkoutEditorScreen> {
  final _form = GlobalKey<FormState>();
  final _minutes = TextEditingController();
  final _kcal = TextEditingController();

  WorkoutEntry? _editing;
  String? _activity;
  late DateTime _date;
  late DateTime _today;
  bool _initialized = false;
  bool _submitted = false;
  bool _busy = false;
  bool _closing = false;

  // Values when the screen opened, to detect unsaved changes.
  String? _startActivity;
  String _startMinutes = '';
  String _startKcal = '';
  late DateTime _startDate;

  bool get _isEdit => _editing != null;

  bool get _dirty =>
      _activity != _startActivity ||
      _minutes.text != _startMinutes ||
      _kcal.text != _startKcal ||
      _date != _startDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = AppScope.of(context).state;
    final argument = ModalRoute.of(context)?.settings.arguments;
    final args = argument is WorkoutEditorArguments ? argument : null;
    _today = state.today;
    _editing = args?.entry;
    final entry = _editing;
    if (entry != null) {
      _activity = entry.activity;
      _minutes.text = entry.minutes.toString();
      _kcal.text = kcal(entry.kcalBurned);
      _date = calendarDate(entry.date);
    } else {
      _date = calendarDate(args?.date ?? state.selectedDate);
    }
    if (_date.isAfter(_today)) _date = _today;
    _startActivity = _activity;
    _startMinutes = _minutes.text;
    _startKcal = _kcal.text;
    _startDate = _date;
    _minutes.addListener(_changed);
    _kcal.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _minutes.dispose();
    _kcal.dispose();
    super.dispose();
  }

  List<String> get _activities {
    final list = [...PlaceholderData.activities];
    final current = _activity;
    if (current != null && !list.contains(current)) list.insert(0, current);
    return list;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_today.year - 1, _today.month, _today.day),
      lastDate: _today,
      helpText: 'Workout date',
    );
    // Cancel returns null and keeps the date that was there.
    if (picked != null && mounted) {
      setState(() => _date = calendarDate(picked));
    }
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.pop(context);
  }

  Future<void> _back() async {
    if (_busy) return;
    if (!_dirty) {
      _close();
      return;
    }
    _busy = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('This workout has not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    _busy = false;
    if (discard == true) _close();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _submitted = true);
    if (!_form.currentState!.validate()) return;
    final minutes = int.tryParse(_minutes.text.trim());
    final burned = double.tryParse(_kcal.text.trim());
    final activity = _activity;
    if (minutes == null || burned == null || activity == null) return;

    // Guard against a double tap creating two entries.
    setState(() => _busy = true);
    final entry = WorkoutEntry(
      id: _editing?.id ?? newEntryId('workout'),
      activity: activity,
      minutes: minutes,
      kcalBurned: burned,
      date: _date,
    );
    AppScope.of(context).state.saveWorkout(entry);
    _startActivity = _activity;
    _startMinutes = _minutes.text;
    _startKcal = _kcal.text;
    _startDate = _date;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline),
        title: Text(_isEdit ? 'Workout updated' : 'Workout saved'),
        content: Text(
          '$activity ($minutes min, ${kcal(burned)} kcal) was '
          '${_isEdit ? 'updated' : 'added'} on ${dayLabel(_date)}.',
        ),
        actions: [
          FilledButton(
            key: const ValueKey('workout-saved-ok'),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _closing = true;
    AppRoutes.openHome(context, date: _date);
  }

  Future<void> _delete() async {
    final entry = _editing;
    if (entry == null || _busy) return;
    _busy = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete workout?'),
        content: Text(
          '${entry.activity} (${kcal(entry.kcalBurned)} kcal) will be '
          'removed from ${dayLabel(entry.date)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('workout-delete-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    _busy = false;
    if (!mounted) return;
    if (confirmed != true) return;
    final state = AppScope.of(context).state;
    final messenger = ScaffoldMessenger.of(context);
    state.removeEntry(entry.id);
    _closing = true;
    AppRoutes.openHome(context, date: entry.date);
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Workout deleted'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => state.restoreWorkout(entry),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validators = AppScope.of(context).validators;
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_dirty || _closing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Workout' : 'Add Workout'),
          leading: BackButton(onPressed: _back),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenMargin),
                child: Form(
                  key: _form,
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        key: const ValueKey('workout-activity'),
                        initialValue: _activity,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Activity',
                        ),
                        hint: const Text('Choose an activity'),
                        items: [
                          for (final activity in _activities)
                            DropdownMenuItem(
                              value: activity,
                              child: Text(activity),
                            ),
                        ],
                        validator: validators.activity,
                        onChanged: (value) => setState(() => _activity = value),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        key: const ValueKey('workout-duration'),
                        label: 'Duration',
                        controller: _minutes,
                        hintText: 'e.g. 30',
                        suffixText: 'min',
                        helperText: '1 to 600 minutes',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        validator: validators.duration,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        key: const ValueKey('workout-kcal'),
                        label: 'Calories burned',
                        controller: _kcal,
                        hintText: 'e.g. 280',
                        suffixText: 'kcal',
                        helperText:
                            'From your watch or fitness app (1 to 3,000)',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]'),
                          ),
                          LengthLimitingTextInputFormatter(7),
                        ],
                        validator: validators.caloriesBurned,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DateField(date: _date, onTap: _pickDate),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Burned calories are added to your daily '
                              'balance: Remaining = Goal − Eaten + Burned.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        key: const ValueKey('workout-save'),
                        label: _isEdit ? 'Save Changes' : 'Save Workout',
                        onPressed: _busy ? null : _save,
                      ),
                      if (_isEdit) ...[
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          key: const ValueKey('workout-delete'),
                          label: 'Delete Workout',
                          variant: AppButtonVariant.danger,
                          onPressed: _busy ? null : _delete,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey('workout-date'),
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
    child: InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Date',
        suffixIcon: Icon(Icons.calendar_today_outlined),
      ),
      child: Text('${dayLabel(date)} ${date.year}'),
    ),
  );
}
