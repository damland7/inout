# Account screens and shared state (Hüseyin Vakkasoğlu)

## What is in this package

| File | What it does |
| --- | --- |
| `lib/shared/placeholder_data.dart` | Typed demo data: demo profile, 7 days of meals and workouts (totals match the Step 2.1 PDF), 8 foods with network images, activity list, `newEntryId()` |
| `lib/shared/app_state.dart` | `InOutState`, the production `AppState`: single source of truth, add/edit by id without duplicates, remove + restore for UNDO, date and tab selection, UI-only login, sign-up and logout |
| `lib/shared/app_services.dart` | `createAppServices()`: production state plus calculations, validators and chart (preview versions until Berre's are merged) |
| `lib/shared/widgets/form_widgets.dart` | `AppTextField` (label, helper, inline error, show/hide password), `AppButton` (primary, outline, danger, text, loading), `StepLabel` |
| `lib/features/account/` | S01 Login, S02 Sign Up, S03 Forgot Password, S04 Goal Setup, shared layout and `accountRoutes` |
| `lib/main_account.dart` | Runs the account flow: `flutter run -t lib/main_account.dart` |
| `test/account_state_test.dart`, `test/account_screens_test.dart` | State rules, validation limits, navigation, 320/360/430 px and large-text overflow checks |

## How teammates use it

- **Routes (Bedirhan):** pass `featureRoutes: accountRoutes` to `InOutApp`. In the final `main.dart` use `createAppServices()` and `initialRoute: AppRoutes.login`.
- **Home and meals (Damla):** read and change data only through `AppScope.of(context).state`. Use `newEntryId('meal')` for new entries. For UNDO, keep the removed entry and call `restoreMeal` / `restoreWorkout`; restoring twice never duplicates. `InOutState.mealsOn(date)` and `workoutsOn(date)` return one day's entries. Use `AppTextField` and `AppButton` in the meal form.
- **Theme, validators, chart (Berre):** replace the three `TODO(Berre)` values in `app_services.dart`. Add the logo at `assets/images/logo.png` (S01 shows an icon until then). To remember the theme on the phone, pass `onAppearanceChanged` to `InOutState`.

## Behaviour

- Login is UI-only: any valid email and password open the demo account (Berre Demirvakkas, goal 2,000 kcal). Firebase Authentication comes in Step 3.
- Sign Up creates an empty account in memory; the password is never stored.
- Logging in and finishing Goal Setup clear the back stack, so Back never returns to the account screens.
- Logging out clears the account and its entries but keeps theme and accent.
- `selectDate` never goes past today.
