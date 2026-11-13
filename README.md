# InOut — CS310 Group 8

Personal calorie tracker. This branch contains **Bedirhan Ceylan's Step 2.2 package**.
GitHub: [bedirhancceylan](https://github.com/bedirhancceylan).

## Authoritative design and ownership

Use the 18-page CS310_Group8_Step2.1.pdf, dated 8 November 2026, especially page 18.
The older 15-screen social design is superseded.

| Member | Screens | Shared work |
| --- | --- | --- |
| Hüseyin Vakkasoğlu | S01 Login, S02 Sign Up, S03 Forgot Password, S04 Goal Setup | Models, placeholder data, state, form widgets |
| Damla Kandemir | S05 Home, S07 Add/Edit Meal | Setup, README, bottom navigation/+ menu, display widgets |
| Berre Özçanak | S06 Food List, S08 Add/Edit Workout, S12 Appearance | Theme/Inter/logo, calculations/validation, History chart |
| Bedirhan Ceylan | S09 History, S10 Profile, S11 Edit Profile | Routes/placeholders, responsive testing, final PDF/screenshots/submission coordination |

## Implemented here

- S09 History: last seven calendar days, average metrics, newest-first day rows, selected-day Home navigation, empty state and Food List action.
- S10 Profile: initials/name/email/goal/theme/member-since, Edit/Appearance routes, password-reset demo dialog, About and confirmed logout clearing the private back stack.
- S11 Edit Profile: name/goal form, read-only email, injected inline validation, shared-state save, snackbar and discard/keep-editing handling.
- All 12 route names, typed form arguments and placeholders for teammates.
- Contracts for state/calculation/validation/theme/chart integration.
- Own-screen tests and commit-review tooling.

The production models/state/forms implementation belongs to Hüseyin; production calculations/validators/theme/chart belong to Berre. `lib/preview/` contains isolated temporary adapters to run this package. The chart slot and bottom navigation/Home shell are deliberate placeholders. Berre supplies the real chart and Damla supplies the real shell. Other owners' screens and shared implementations are not complete in this branch.

## Run the own-screen preview

SDK used: **Flutter 3.47.8 stable / Dart 3.13.7**.
Dart package identifier: inout_app; display name: InOut.

```sh
flutter pub get
flutter run
flutter run --dart-define=PREVIEW_SCREEN=profile
```

Default opens History; the second command opens Profile and its Edit flow.
For Android/iOS, select an installed emulator/simulator using flutter devices and flutter run -d DEVICE_ID.
Generated platform scaffolding is included to run this isolated package; Damla remains the final project-setup owner.
No Firebase, real authentication or email delivery is implemented in Step 2.2.

## Shared interfaces

Read [docs/step2_contract.md](docs/step2_contract.md) and `lib/shared/contracts.dart` before integration.
- AppScope.of(context) -> AppServices.
- AppState: profile/logs/today/selectedDate/activeTab and mutations.
- AppCalculations: per-serving meals, user-entered workout burn and seven-day history.
- AppValidators: PDF rules; goal 1200..5000, signup password >=6.
- HistoryChartBuilder: chronological seven days and current goal.
- InOutApp accepts featureRoutes, homeBuilder and themeBuilder.
- Damla's shell consumes state.activeTab and reuses HistoryScreen/ProfileScreen.
- Theme colours/styles are read through Theme.of; production Inter/assets are Berre's task.

Remaining = Goal - Eaten + Burned. No BMR, MET, macros, social feed or Monday-Sunday weekly summary.

## Verify

```sh
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze --no-pub
flutter test --no-pub
python3 -m unittest discover -s test_tools -v
flutter build bundle --debug --no-pub
```

See [docs/verification.md](docs/verification.md) for recorded evidence and pending checks. A bundle build/headless widget test is not an Android/iOS simulator run.

## Commits and push review

Eight meaningful task commits per member are the coordination target, not a grading quota. At final team review the largest and smallest actual member counts should differ by at most one. Never create empty/backdated/artificial commits.

The current package is on local branch `feature/bedirhan-history-profile`; it has not been published, and `main` is unchanged. Local commits are reviewed one at a time. Push still requires showing the actual commit list and receiving explicit approval.

```sh
git config core.hooksPath .githooks
python3 scripts/push_review.py --local --base origin/main
```

Before push, show real authors/count/branch/SHA/diff/tests and obtain owner approval.
--local uses cached refs and does not approve a push.
--record fetches current refs, requires a clean worktree, runs Flutter analysis/tests and asks for exact typed approval. Each checkout must install the hook. Never bypass it.

Teammates branch from the coordinator's published starting commit after its remote branch and SHA are verified. Until then, do not assume this local feature branch exists remotely. Author and committer must match each member's actual GitHub account; no automatic co-author trailer.

## Submission

[docs/submission_checklist.md](docs/submission_checklist.md) tracks the final group deliverable.
The final PDF is prepared after the three teammates' screens, chart/theme/assets and shared implementations are integrated.
Follow the syllabus's contribution and AI-use rules; every member must understand and explain submitted work.
