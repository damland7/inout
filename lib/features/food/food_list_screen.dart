import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../shared/contracts.dart';
import '../../shared/formatters.dart';
import '../../shared/models.dart';
import '../../shared/placeholder_data.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/widgets/form_widgets.dart';

/// S06 Food List — first step of adding a meal.
///
/// The user searches the common foods (network images) and taps one to open
/// S07 with the name and calories filled in, or adds a custom food.
/// Route argument: the day to log on (`DateTime`); defaults to the day
/// selected on Home.
class FoodListScreen extends StatefulWidget {
  const FoodListScreen({super.key, this.foods = PlaceholderData.foods});

  final List<FoodItem> foods;

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final query = _search.text.trim();
      if (query != _query) setState(() => _query = query);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  DateTime _logDate(BuildContext context) {
    final argument = ModalRoute.of(context)?.settings.arguments;
    if (argument is DateTime) return calendarDate(argument);
    return AppScope.of(context).state.selectedDate;
  }

  List<FoodItem> get _matches {
    if (_query.isEmpty) return widget.foods;
    final query = _query.toLowerCase();
    return widget.foods
        .where((food) => food.name.toLowerCase().contains(query))
        .toList();
  }

  void _openEditor(FoodItem? food) {
    Navigator.pushNamed(
      context,
      AppRoutes.mealEditor,
      arguments: MealEditorArguments(food: food, date: _logDate(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matches = _matches;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Meal')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.sm,
                AppSpacing.screenMargin,
                AppSpacing.sm,
              ),
              child: TextField(
                key: const ValueKey('food-search'),
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search foods',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: _search.clear,
                        ),
                ),
              ),
            ),
            Expanded(
              child: matches.isEmpty
                  ? _NoResults(
                      query: _query,
                      onAddCustom: () => _openEditor(null),
                    )
                  : ListView(
                      key: const PageStorageKey('food-list'),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenMargin,
                        AppSpacing.sm,
                        AppSpacing.screenMargin,
                        AppSpacing.lg,
                      ),
                      children: [
                        Text(
                          _query.isEmpty ? 'COMMON FOODS' : 'RESULTS',
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (final food in matches)
                          _FoodRow(food: food, onTap: () => _openEditor(food)),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Can’t find your food?',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          key: const ValueKey('add-custom-food'),
                          label: '+ Add custom food',
                          variant: AppButtonVariant.outline,
                          onPressed: () => _openEditor(null),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Food photos are placeholder images from placehold.co.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({required this.food, required this.onTap});
  final FoodItem food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('food-${food.name}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              FoodImage(url: food.imageUrl, label: food.name),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.name, style: theme.textTheme.titleMedium),
                    Text(food.servingLabel, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${kcal(food.kcalPerServing)} kcal',
                style: theme.textTheme.titleSmall,
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Network food photo with a fixed size. While loading, or if the photo
/// cannot be loaded, a grey placeholder keeps the row the same height.
class FoodImage extends StatelessWidget {
  const FoodImage({super.key, required this.url, required this.label});
  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = AppSpacing.foodImage;
    Widget placeholder({bool failed = false}) => Container(
      width: size,
      height: size,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        failed ? Icons.no_food_outlined : Icons.restaurant,
        size: 24,
        color: scheme.onSurfaceVariant,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'Photo of $label',
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder(),
        errorBuilder: (context, error, stackTrace) =>
            placeholder(failed: true),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query, required this.onAddCustom});
  final String query;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No foods match “$query”',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Check the spelling or add the food yourself.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const ValueKey('add-custom-food'),
            label: '+ Add custom food',
            variant: AppButtonVariant.outline,
            onPressed: onAddCustom,
          ),
        ],
      ),
    );
  }
}
