# Ortak başlangıç ve bağımlılıklar

Kaynak: güncel 18 sayfalık Step 2.1 PDF, sayfa 18 ve [12 ekranlık sözleşme](../step2_contract.md). Eski 15 ekranlık sosyal tasarım geçerli değildir. Chat'te verilen ayrıntılı kişisel promptlar bu dosyayla birlikte kullanılır.

1. Damla ortak Flutter temelini doğrular; mevcut scaffold'ı yeniden üretmez.
2. Hüseyin modeller/state/form widget arayüzleri, Berre theme/calculation/validation/chart arayüzleri, Bedirhan routes/placeholders işini paralel yürütür.
3. Sözleşmeler sabitlenince dört kişi ekranları paralel geliştirir.
4. Başka ekran hazır değilse route placeholder kullanılır; ikinci implementasyon oluşturulmaz.
5. Final screenshot/PDF, bütün paketlerin entegrasyonundan sonra Bedirhan Ceylan tarafından hazırlanır.

Bedirhan'ın S09/S10/S11 modülü uygulanmıştır. Diğer sahiplerin ekranları, gerçek chart ve bottom navigation/Home shell bu pakette bilinçli placeholder'dır. `lib/preview/` geçici adaptörler içerir; bu adaptörler diğer sahiplerin tamamlanmış production kodu sayılmaz.

## Sözleşmeler

`lib/shared/models.dart`:

- `UserProfile(name, email, dailyGoalKcal, themeMode, accentColor, createdAt)`
- `MealEntry(id, foodName, kcalPerServing, servings, mealType, date)`
- `WorkoutEntry(id, activity, minutes, kcalBurned, date)`
- `FoodItem(name, servingLabel, kcalPerServing, imageUrl)`

`lib/shared/contracts.dart`: `AppState`, `AppCalculations`, `AppValidators`, `AppServices`, `AppScope`, `HistoryChartBuilder`, `SharedThemeBuilder`.

Bunlar entegrasyon sözleşmesidir; `lib/preview/` adaptörleri production shared work olarak teslim edilmez. Sözleşme değişiklikleri koordinatör ve consumer sahipleriyle kararlaştırılır.

- `AppRoutes.openHome(context, date:)` seçili günü ve `MainTab.home` değerini ayarlar, Home shell'e gider.
- `AppRoutes.openMainTab(context, tab)` ortak shell'i açar; Damla `state.activeTab` değerini tüketir.
- `MealEditorArguments(entry:, food:, date:)`, `WorkoutEditorArguments(entry:, date:)`, `ForgotPasswordArguments(email)` kullanılır.
- S06 girişinde seçili gün `DateTime` argument olabilir; S07 için `FoodItem`/custom food ve gün aktarılır.

Remaining = goal - eaten + kullanıcının girdiği burned. History, bugünle biten son 7 takvim günüdür. BMR, MET, sosyal özellik veya Pazartesi-Pazar haftası eklenmez.

## Bağımlılıklar

Hüseyin'in giriş ekranları Damla Home shell ve Berre theme/validators ile entegre edilir.

Damla Home/Meal, Hüseyin state/models ve Berre calculations/validators kullanır; Food List/Workout route'ları Berre'ye, History/Profile tab'ları Bedirhan'a aittir.

Berre state için Hüseyin'e, food seçiminin meal editor dönüşü için Damla'ya bağlıdır; chart'ı Bedirhan'a injected widget olarak verir.

Bedirhan History için shared state/calculations/chart; Profile/Edit için profile state/validators/theme; Home geçişi için Damla shell; Appearance için Berre route'unu kullanır.

Tam ekran bitişi beklenmeden interface ve placeholder ile başlanır.

## Başlangıç branch'i ve commit/push

Bedirhan'ın paketi şu anda yerel `feature/bedirhan-history-profile` branch'indedir; henüz yayımlanmamıştır ve `main` değişmemiştir. Ortak başlangıç branch'inin ve SHA'nın remote'da yayımlandığı doğrulanmadan `origin/feature/bedirhan-history-profile` veya başka bir başlangıç ref'i varmış gibi çalışılmaz. Her üye koordinatörün doğrulanmış, yayımlanmış başlangıç commit'inden kendi branch'ini açar.

Step 2 referans baseline: `baac4c7c48e0e687d3bd5ce43b2632312ad953d8`. Bu referans, güncel feature branch'inin yayımlandığı anlamına gelmez.

- Hedef kişi başına 8 anlamlı commit; finalde gerçek en yüksek ve en düşük üye sayısı arasındaki fark en fazla 1.
- Boş, backdated veya sırf sayı artıran commit yok. Kalan gerçek işe göre commit planı düzenlenir.
- Kendi author/email hesabını doğrula; otomatik co-author trailer ekleme.
- Yerel commit'ler tek tek gözden geçirilir. Push öncesi fresh remote kontrolü, kendi gerçek commit listesi, dört kişilik doğrulanmış sayaç, branch/HEAD, diff ve test sonuçları kullanıcıya gösterilir.
- Erişilmeyen veya pushlanmamış arkadaş çalışması tahmin edilmez. Açık push onayı olmadan push yok.
- Hook kurulumu her checkout'ta yereldir: `git config core.hooksPath .githooks`.

Doğrulama sonuçları ve henüz yapılmamış kontroller [verification.md](../verification.md) dosyasında tutulur.
