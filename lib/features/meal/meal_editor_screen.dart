import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_routes.dart';
import '../../shared/contracts.dart';
import '../../shared/formatters.dart';
import '../../shared/models.dart';
import '../../shared/placeholder_data.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/widgets/form_widgets.dart';
import '../food/food_list_screen.dart' show FoodImage;

/// S07 Add / Edit Meal.
///
/// Route argument: [MealEditorArguments]. A common [FoodItem] pre-fills the
/// name and calories; an existing [MealEntry] opens edit mode and keeps its id.
class MealEditorScreen extends StatefulWidget {
  const MealEditorScreen({super.key});

  @override
  State<MealEditorScreen> createState() => _MealEditorScreenState();
}

class _MealEditorScreenState extends State<MealEditorScreen> {
  final _form = GlobalKey<FormState>();
  final _foodName = TextEditingController();
  final _kcalPerServing = TextEditingController();

  MealEntry? _editing;
  FoodItem? _sourceFood;
  double _servings = 1;
  MealType _mealType = MealType.breakfast;
  late DateTime _date;
  late DateTime _today;
  bool _initialized = false;
  bool _submitted = false;
  bool _busy = false;
  bool _closing = false;

  String _startName = '';
  String _startKcal = '';
  double _startServings = 1;
  MealType _startMealType = MealType.breakfast;
  late DateTime _startDate;

  bool get _isEdit => _editing != null;

  bool get _dirty =>
      _foodName.text != _startName ||
      _kcalPerServing.text != _startKcal ||
      _servings != _startServings ||
      _mealType != _startMealType ||
      _date != _startDate;

  double get _parsedKcal => double.tryParse(_kcalPerServing.text.trim()) ?? 0;

  double get _total => _parsedKcal * _servings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final state = AppScope.of(context).state;
    final argument = ModalRoute.of(context)?.settings.arguments;
    final args = argument is MealEditorArguments ? argument : null;
    _today = state.today;
    _editing = args?.entry;
    _sourceFood = args?.food;

    final entry = _editing;
    if (entry != null) {
      _foodName.text = entry.foodName;
      _kcalPerServing.text = _numberText(entry.kcalPerServing);
      _servings = entry.servings;
      _mealType = entry.mealType;
      _date = calendarDate(entry.date);
    } else {
      final food = _sourceFood;
      if (food != null) {
        _foodName.text = food.name;
        _kcalPerServing.text = _numberText(food.kcalPerServing);
      }
      _mealType = _defaultMealType(DateTime.now().hour);
      _date = calendarDate(args?.date ?? state.selectedDate);
    }
    if (_date.isAfter(_today)) _date = _today;
    _rememberStartValues();
    _foodName.addListener(_changed);
    _kcalPerServing.addListener(_changed);
  }

  static MealType _defaultMealType(int hour) {
    if (hour < 11) return MealType.breakfast;
    if (hour < 16) return MealType.lunch;
    if (hour < 21) return MealType.dinner;
    return MealType.snack;
  }

  static String _numberText(double value) =>
      value == value.roundToDouble() ? value.round().toString() : '$value';

  void _rememberStartValues() {
    _startName = _foodName.text;
    _startKcal = _kcalPerServing.text;
    _startServings = _servings;
    _startMealType = _mealType;
    _startDate = _date;
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _foodName.dispose();
    _kcalPerServing.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_today.year - 1, _today.month, _today.day),
      lastDate: _today,
      helpText: 'Meal date',
    );
    if (picked != null && mounted) {
      setState(() => _date = calendarDate(picked));
    }
  }

  void _changeServings(double amount) {
    final next = (_servings + amount).clamp(0.5, 20).toDouble();
    if (next != _servings) setState(() => _servings = next);
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('This meal has not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            key: const ValueKey('meal-discard-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
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
    final perServing = double.tryParse(_kcalPerServing.text.trim());
    final name = _foodName.text.trim();
    if (perServing == null || name.isEmpty) return;

    setState(() => _busy = true);
    final entry = MealEntry(
      id: _editing?.id ?? newEntryId('meal'),
      foodName: name,
      kcalPerServing: perServing,
      servings: _servings,
      mealType: _mealType,
      date: _date,
    );
    AppScope.of(context).state.saveMeal(entry);
    _rememberStartValues();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline),
        title: Text(_isEdit ? 'Meal updated' : 'Meal saved'),
        content: Text(
          '$name (${_servingsText(_servings)}, ${kcal(_total)} kcal) was '
          '${_isEdit ? 'updated' : 'added to ${_mealType.label}'} on '
          '${dayLabel(_date)}.',
        ),
        actions: [
          FilledButton(
            key: const ValueKey('meal-saved-ok'),
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this meal?'),
        content: Text(
          '${entry.foodName} (${_servingsText(entry.servings)}, '
          '${kcal(entry.kcalPerServing * entry.servings)} kcal) will be '
          'removed from ${entry.mealType.label}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('meal-delete-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    _busy = false;
    if (!mounted || confirmed != true) return;

    final state = AppScope.of(context).state;
    final messenger = ScaffoldMessenger.of(context);
    state.removeEntry(entry.id);
    _closing = true;
    AppRoutes.openHome(context, date: entry.date);
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Meal deleted'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => state.restoreMeal(entry),
        ),
      ),
    );
  }

  static String _servingsText(double value) {
    final number = value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return '$number ${value == 1 ? 'serving' : 'servings'}';
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
          title: Text(_isEdit ? 'Edit Meal' : 'Add Meal'),
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
                      if (_sourceFood case final food?) ...[
                        _FoodSource(food: food),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      AppTextField(
                        key: const ValueKey('meal-name'),
                        label: 'Food name',
                        controller: _foodName,
                        hintText: 'e.g. Homemade pasta',
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [LengthLimitingTextInputFormatter(80)],
                        validator: validators.foodName,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        key: const ValueKey('meal-kcal'),
                        label: 'Calories per serving',
                        controller: _kcalPerServing,
                        hintText: 'e.g. 180',
                        suffixText: 'kcal',
                        helperText: 'Between 1 and 5,000 kcal',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          LengthLimitingTextInputFormatter(7),
                        ],
                        validator: validators.caloriesPerServing,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ServingsField(
                        servings: _servings,
                        onDecrease: _servings <= 0.5
                            ? null
                            : () => _changeServings(-0.5),
                        onIncrease: _servings >= 20
                            ? null
                            : () => _changeServings(0.5),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<MealType>(
                        key: const ValueKey('meal-type'),
                        initialValue: _mealType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Meal type',
                        ),
                        items: [
                          for (final type in MealType.values)
                            DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _mealType = value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DateField(date: _date, onTap: _pickDate),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        key: const ValueKey('meal-total'),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Total',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              '${kcal(_total)} kcal',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        key: const ValueKey('meal-save'),
                        label: _isEdit ? 'Save Changes' : 'Save Meal',
                        onPressed: _busy ? null : _save,
                      ),
                      if (_isEdit) ...[
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          key: const ValueKey('meal-delete'),
                          label: 'Delete Meal',
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

class _FoodSource extends StatelessWidget {
  const _FoodSource({required this.food});

  final FoodItem food;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        FoodImage(url: food.imageUrl, label: food.name),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(food.name, style: theme.textTheme.titleMedium),
              Text(
                '${food.servingLabel} · from Common foods',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServingsField extends StatelessWidget {
  const _ServingsField({
    required this.servings,
    required this.onDecrease,
    required this.onIncrease,
  });

  final double servings;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = servings == servings.roundToDouble()
        ? servings.round().toString()
        : servings.toStringAsFixed(1);
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Servings',
        helperText: '0.5 to 20, in steps of 0.5',
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.outlined(
            key: const ValueKey('meal-servings-decrease'),
            tooltip: 'Decrease servings',
            onPressed: onDecrease,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 88,
            child: Text(
              value,
              key: const ValueKey('meal-servings'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
          ),
          IconButton.outlined(
            key: const ValueKey('meal-servings-increase'),
            tooltip: 'Increase servings',
            onPressed: onIncrease,
            icon: const Icon(Icons.add),
          ),
        ],
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
    key: const ValueKey('meal-date'),
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
