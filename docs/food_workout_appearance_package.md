# Food, workout and appearance package (S06, S08, S12 + shared visuals)

Implemented by Berre Özçanak.

| File | What it does |
| --- | --- |
| `lib/shared/theme/app_colors.dart` | Shared palette, dark-mode colours and the five accents |
| `lib/shared/theme/app_text_styles.dart` | Text styles 28/24/20, body 16, help 14, Inter |
| `lib/shared/theme/app_spacing.dart` | 8 px grid, 16 px margin, 12/16 px radii, 48 px tap size |
| `lib/shared/theme/app_theme.dart` | `buildAppTheme(brightness, accent)` (a `SharedThemeBuilder`) |
| `assets/fonts/` | Inter Regular/Medium/SemiBold/Bold + SIL OFL licence |
| `lib/shared/calculations.dart` | `InOutCalculations`: meal total, eaten, burned, remaining, 7-day history |
| `lib/shared/validators.dart` | `InOutValidators`: every inline rule, NaN/infinity rejected |
| `lib/shared/widgets/history_chart.dart` | S09 bar chart with dashed goal line and legend |
| `lib/features/food/food_list_screen.dart` | S06 Food List: search, network images, no result, custom food |
| `lib/features/workout/workout_editor_screen.dart` | S08 Add/Edit Workout: inline errors, saved dialog, edit by id, delete + UNDO, discard dialog |
| `lib/features/appearance/appearance_screen.dart` | S12 Appearance: System/Light/Dark and accent, applied immediately |
| `lib/features/food_workout_appearance_routes.dart` | Routes for S06, S08, S12 |

## Integration

- `createAppServices()` now uses the production calculations, validators,
  chart and accent names; the `lib/preview/` adapters are only used by
  Bedirhan's preview (`lib/main_preview.dart`) and his tests.
- `lib/main.dart` is the real app: it opens S01 Log In with
  `themeBuilder: buildAppTheme` and the account + food/workout/appearance
  routes. S05 Home and S07 Add Meal still show placeholders until the Home
  package is merged; add `homeBuilder` and the S07 route there.
- Burned calories are entered by the user (no MET or BMR).

## Not done

- The appearance choice is not stored on the phone yet (no
  `shared_preferences` dependency was added before the deadline). The
  `InOutState.onAppearanceChanged` hook is ready for it.

## Checks

`flutter analyze` and `flutter test test/food_workout_appearance_test.dart`
cover calculations, validators, theme, S06 search and navigation, S08
validation/save/edit/delete/discard, S12 and 320/430 px screens with large text.
