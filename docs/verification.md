# Verification evidence — Bedirhan Ceylan's package

Checks below were run against Bedirhan Ceylan's package on 13 November 2026. Pending integration/device items make no pass claim.

## Revision and environment

| Field | Recorded evidence |
| --- | --- |
| Verification date/time | 2026-11-13, approximately 14:14–14:17 UTC |
| Branch and verified application-source commit | `feature/bedirhan-history-profile`, `805be76e433faf4166287a30f6c30947b06bf27e` (commit 7; commit 8 adds documentation and the separately tested push tool) |
| Working-tree scope | Application source and screenshot evidence committed through commit 7; final documentation/tooling prepared separately |
| Flutter/Dart version | Flutter 3.47.8 stable / Dart 3.13.7 |
| Host/platform | macOS, Darwin arm64; Flutter's headless Darwin engine used for widget tests |

## Automated checks

Run from the package root. Record the exit status and concise result after each command completes.

| Check | Command | Result |
| --- | --- | --- |
| Formatting | `dart --suppress-analytics format --output=none --set-exit-if-changed lib test tool` | Exit 0; 13 files checked, 0 changes |
| Static analysis | `flutter analyze --no-pub /tmp/cs310_validation/inout` | Exit 0; no issues. `lib`, `test` and `tool` copied and verified byte for byte; direct analysis in the original Unicode/space path encountered an SDK protocol issue |
| Standard Flutter test command | `flutter test --no-pub` | Environment blocked before any test: sandbox denied binding `127.0.0.1`; this command did not pass |
| Actual Flutter widget tests | Headless `flutter_tester` with the port-free temporary suite described below | Exit 0; **12/12 passed**, including real widget interactions |
| Review-tool tests | `python3 -m unittest discover -s test_tools -v` | Exit 0; **21 tests passed**, 8.247 seconds |
| Debug bundle | `flutter build bundle --debug --no-pub` | Exit 0 for `lib/main.dart` |

The temporary runner `/tmp/cs310_foundation_runtime/offline_suite.dart` imports the actual `test/profile_history_test.dart`, declares its complete test suite with `test_api` and runs every test through Flutter's test binding without the CLI's localhost socket. It asserts that the number of passing tests equals the declared suite count. It was compiled with `flutter build bundle --debug --no-pub --target /tmp/cs310_foundation_runtime/offline_suite.dart`, then executed with the SDK's `flutter_tester`, `FLUTTER_TEST=true`, `--disable-vm-service`, `--use-test-fonts` and `--enable-software-rendering`. The final run printed `RESULT: 12/12 full-suite tests passed`. This environment-specific runner is not a replacement for the normal `flutter test` command on teammates' machines.

The ordinary Dart command tried to write telemetry outside the permitted directory. Passing `--suppress-analytics` allowed the format check to complete. SDK/cache copies were isolated under `/tmp/cs310_foundation_runtime`; no installed SDK was modified.

## UI and navigation evidence

- [x] S09 rolling last seven calendar days and selected-day Home navigation; New Year boundary, chart chronological order, newest-first rows and empty-state action verified by widget tests. Preview averages are 1849 eaten, 237 burned, 5/7 on target.
- [x] S10 profile rendered and visually inspected; logout cancel/confirm and private-stack clearing tested. Logged-out entry has Login as its only route. Reset/About are UI-only demo actions.
- [x] S11 validation, shared-state save, preserved email, Keep editing/Discard and repeated clean Back tested. Save snackbar is implemented.
- [x] Portrait widths 320, 360 and 430, text scale 1.6 and actual 280 px keyboard inset tested; Save is scrolled into view and tapped above the keyboard.
- [ ] Android emulator or iOS simulator launch; record device, platform version and command.

Actual Flutter-rendered previews were visually inspected: [History](previews/history.png), [Profile](previews/profile.png), [Edit Profile](previews/edit-profile.png). These use a fixed preview date of 7 November 2026 and temporary theme/chart adapters; they are not final group submission screenshots. Capture entry point: `tool/capture_previews.dart`.

## Scope and limitations

Bedirhan's S09/S10/S11 module is implemented. Other owners' screens, shared production implementations, real History chart and bottom navigation/Home shell remain deliberate placeholders in this package. `lib/preview/` adapters are temporary integration aids.

Headless widget tests and a debug bundle build do not establish an Android/iOS simulator run. Device checks remain pending until direct evidence is recorded. Integration checks and the final group PDF remain pending until the teammates' modules are available.

## Commit and push review

| Review item | Evidence |
| --- | --- |
| Actual author/committer and per-person counts | First seven new commits verified as `Bedirhan Ceylan <bedirhancceylan@gmail.com>` for both fields, without attribution trailers. The same identity is required for final commit 8 and verified after creation |
| Proposed local commits, reviewed one at a time | Eight meaningful task groups: scaffold; contracts/adapters; routes; History; Profile; Edit Profile; tests/previews; documentation/push checks |
| Exact branch/HEAD and final diff | Application-source SHA above; obtain final documentation commit SHA using `git rev-parse HEAD` and inspect `git diff origin/main..HEAD` before push |
| Remote starting ref and SHA | `origin/main` and local `main`: `baac4c7c48e0e687d3bd5ce43b2632312ad953d8`; origin URL `https://github.com/damland7/inout.git`. Feature branch is local and unpublished; these are cached refs, not a fresh remote review |
| Explicit approval after showing the actual commit list | Pending; no push performed or approval recorded here |

The coordination target is eight meaningful commits per member, with final actual max-min <= 1. Empty, backdated or artificial commits do not satisfy that target.
