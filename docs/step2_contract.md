# InOut Step 2.2 — authoritative 12-screen contract

Source: CS310_Group8_Step2.1.pdf, 18 pages, dated 8 November 2026. Page 18 and the user-supplied ownership screenshot are authoritative. The older 15-screen social design is superseded.

| Member | Screens | Shared work |
| --- | --- | --- |
| Hüseyin Vakkasoğlu | S01 Login, S02 Sign Up, S03 Forgot Password, S04 Goal Setup | Models, placeholder data, app state, common form widgets |
| Damla Kandemir | S05 Home, S07 Add/Edit Meal | Project setup, README/.gitignore, bottom navigation/+ menu, display widgets |
| Berre Özçanak | S06 Food List, S08 Add/Edit Workout, S12 Appearance | Theme/Inter/logo, calculations/validators, History chart widget |
| Bedirhan Ceylan | S09 History, S10 Profile, S11 Edit Profile | Routes/placeholders, small/large-screen testing, final PDF/screenshots/submission |

## Binding behavior
- Remaining = dailyGoalKcal - eaten + burned.
- Burned is the sum of user-entered WorkoutEntry.kcalBurned. No BMR/MET or social feature.
- Meal total = kcalPerServing * servings.
- Goal 1200..5000; signup password >=6 characters.
- History: last 7 calendar days ending today; newest-first day rows; eaten chart plus dashed goal line. Averages and on-target count come from Berre's calculation service.
- Profile: name/email/goal/theme/member-since; initials avatar; Edit/Appearance/reset/About/logout.
- Edit Profile: required full name; email read-only; goal range; Save updates shared state and pops with snackbar. Back with changes asks Keep editing/Discard.
- Logout confirmation clears state and navigation stack to S01 Login.
- Light/dark/system and five accents are Berre's shared theme task. Own screens use Theme.of, never fixed screen colors.
- Bottom Home/History/Profile navigation, fixed + menu and tab Back behavior belong to Damla.

## Collaboration interfaces
lib/shared/models.dart and contracts.dart are minimal stable integration contracts, not a claim that Hüseyin/Berre's shared work is complete. Their production implementations replace the isolated lib/preview/ adapters. Common form widgets remain Hüseyin's task.
AppServices contains AppState, AppCalculations, AppValidators and HistoryChartBuilder.
AppScope.of(context) provides those services; it rebuilds dependents when state notifies.
Own screens never read preview implementations directly.
InOutApp(featureRoutes:, homeBuilder:, themeBuilder:) lets the three owners replace placeholders and supply their own shared implementations without rewriting routes.
AppRoutes.openHome selects the requested day/main tab and resets to Home; Damla's shell consumes state.activeTab.
A chart placeholder is intentionally injected in preview; the real chart belongs to Berre. The bottom navigation/Home shell is also a deliberate placeholder until Damla supplies it.

## Preview and completion
The generated platform scaffold is needed to run this isolated package. Final project setup ownership stays with Damla.
Default preview opens S09. PREVIEW_SCREEN=profile opens S10. Other screens are placeholders until their owners integrate them.
This is Bedirhan's package, not a finished milestone or final submission PDF.
The package currently lives on local branch feature/bedirhan-history-profile, which has not been published; main is unchanged. Teammates must verify the coordinator's published starting branch and SHA before branching from it.
