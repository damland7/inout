# Berre — S06/S08/S12 ve shared visual/calculation services

GitHub: `berreozcanak`. Önce [00_shared_start.md](00_shared_start.md), PDF sayfa 18 ve Step 2.2 yönergesini oku.
Branch: `feature/food-workout-appearance`. Ortak başlangıç commit'ini yayımlanmış varsayma; koordinatörün remote branch'ini ve başlangıç SHA'sını doğruladıktan sonra branch aç.

## Ortak services

- `AppCalculations`: meal = kcalPerServing × servings; eaten = günün meal toplamı; burned = kullanıcının girdiği kcalBurned toplamı; remaining = goal - eaten + burned; onTarget = remaining >= 0.
- History: bugünle biten son 7 takvim günü; data oldest-first, UI rows newest-first. Pazartesi-Pazar haftası, BMR, MET veya sosyal özellik yok.
- `AppValidators`: required name, valid email, Login required password, signup >= 6, confirm same, goal 1200..5000, food name, kcal per serving 1..5000, activity, duration integer 1..600, burned 1..3000; NaN/infinity reddedilir.
- Reusable History chart: 7 eaten bars, dashed goal line, within/over legend, shared on-target colours, theme/reactive goal, empty-safe.
- Chart, Bedirhan `historyChartBuilder` injection'ına teslim edilir; ikinci History screen yazılmaz. Mevcut chart ve `lib/preview/` calculation/theme/validation adaptörleri geçicidir; tamamlanmış production implementation sayılmaz.

## S06

- Typed common `FoodItem(name, servingLabel, kcalPerServing, imageUrl)`.
- Case-insensitive search, no result + custom food.
- Gerçek `Image.network` + loading/error placeholder, bounded row image, source/license.
- Food select/custom → Damla S07, `MealEditorArguments(food:, date:)` ile.
- Arama/list position dönüşte korunur; live food API gerekmez.

## S08

- Activity, duration, burned, date; calories kullanıcının watch/numeric estimate değerinden girilir.
- Weight/MET/BMR fields yok.
- Add/Edit aynı ID; inline validation; date cancel; unsaved draft için Keep Editing/Discard.
- Valid Save → tek entry → Workout Saved AlertDialog → OK → Home; double tap duplicate yaratmaz.
- Edit/Delete, Damla display dialog/undo ve Hüseyin state ile entegre edilir.

## S12/theme/assets

- System/Light/Dark; Red/Blue/Green/Purple/Orange; selected ring/tick.
- Save button yok; changes immediate whole app, local persistence/restart.
- `SharedThemeBuilder` ve profile appearance/`AppState` kullanılır.
- Primary `#B42332`, pale `#FCE8EB`, surface `#F7F3F4`, text `#344054`, help `#667085`, error `#B42318`, dark background `#0F1218`, dark cards `#1A1F29`.
- Typography 28/24/20, body 16/help 14, spacing 8 grid/margin 16, controls 12/cards 16, tap 48.
- Gerçek Inter font files + license + pubspec family/weights; local logo asset Hüseyin Login'e teslim edilir.
- Semantic theme colour roles; screen'lerin içine fixed colour dağıtma.
- Hüseyin state ve Damla startup ile preference restore bağlanır.

## Sekiz gerçek commit

1. Theme.
2. Appearance UI.
3. Persistence.
4. Calculations/validators.
5. History chart.
6. Food List.
7. Workout.
8. Font/logo/assets + integration tests.

Gerçek iş karşılanmışsa boş commit yaratma; kalan gerçek işe göre planı düzelt. Testler ilgili iş sırasında yazılır.

## Kabul

- 180 × 2 = 360; 280 + 163 = 443; 2000 - 1195 + 443 = 1248; 2000 - 835 + 443 = 1608.
- Goal update sonrası chart/History, calendar boundary, numeric limits.
- Food search/image error, Workout edit/save/dialog/draft.
- Bütün ekranlarda dark/light/accent, persisted restart, actual font/logo.
- 320/360/430 genişlik, büyük text, keyboard; analyze/test/emulator.
- [00_shared_start.md](00_shared_start.md) gerçek count/author/push onayı kontrolü olmadan push yok.
