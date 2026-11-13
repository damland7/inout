# Damla — S05/S07 ve main shell

GitHub: `damland7`. Önce [00_shared_start.md](00_shared_start.md), PDF sayfa 18 ve Step 2.2 yönergesini oku.
Branch: `feature/home-meals`. Ortak başlangıç commit'ini yayımlanmış varsayma; koordinatörün remote branch'ini ve başlangıç SHA'sını doğruladıktan sonra branch aç. Var olan scaffold'ı silip yeniden oluşturma.

## Shared work

- Final project setup, dependencies/lockfile, README/run version, `.gitignore`.
- Home/History/Profile üç tab ve ayrı floating + menu; scroll state korunur. Mevcut bottom navigation/Home shell placeholder'ını production shell ile değiştir.
- History/Profile Android Back → Home; Home Back app'ten çıkar, Login'e açılmaz.
- + Add Meal → S06; Add Workout → S08; Cancel/outside/system Back tab/date/scroll değerlerini korur.
- `state.activeTab` tüketilir; Bedirhan `HistoryScreen`/`ProfileScreen` doğrudan kullanılır.
- Display cards/summary/empty/dialog/snackbar widget'ları ortak theme ile hazırlanır.

## S05

- Selected day, Today'de Next disabled, Back to today.
- Remaining = Goal - Eaten + Burned; burned, kullanıcının girdiği workout kcal toplamıdır. BMR/MET yok.
- Meals Breakfast/Lunch/Dinner/Snack grupları, totals ve workout listesi.
- Typed model nesnelerinden gerçek Card; entry'ye tap edit route'unu açar.
- Delete confirmation Cancel state'i değiştirmez; confirm shared state'i günceller.
- 4 saniyelik UNDO doğru ID/date/group ile duplicate olmadan restore eder.
- Boş gün: remaining = goal, eaten = 0, burned = 0 ve CTA.
- PDF örneği: 1195 - 360 = 835; 2000 - 835 + 443 = 1608.

## S07

- Add/Edit aynı screen; Food List argument `FoodItem` + date veya custom mode.
- Name, kcal per serving, servings stepper, meal type, date, live total.
- Name required; kcal 1..5000; servings 0.5..20, step 0.5; stepper sınırlarında ilgili kontrol disabled.
- Default meal type: 11'den önce Breakfast; 11..16 Lunch; 16..21 Dinner; diğer saatlerde Snack.
- Date Cancel draft'ı korur; Save öncesi state değişmez; edit aynı ID'yi korur.
- Valid form → tek state write → Meal Saved AlertDialog → OK → Home.
- Edit/Delete confirmation/undo ve unsaved Keep Editing/Discard.
- Hüseyin state/form widgets, Berre calculations/validators kullan; başkalarının ekranını kopyalama. `lib/preview/` adaptörleri diğer sahiplerin production implementation'ı değildir.

## Sekiz gerçek commit

1. Setup integration.
2. Shell/tabs/+.
3. Display widgets.
4. Home.
5. Delete/undo.
6. Add Meal.
7. Edit Meal/draft.
8. Integration tests/README.

Testler ilgili iş sırasında; son commit bütün akış testlerini tamamlar. Mevcut iş karşılanıyorsa boş commit oluşturulmaz; kalan gerçek işe göre plan düzeltilir.

## Kabul

- Dates, today arrow, Card list, delete cancel/confirm/undo ve aynı ID ile edit.
- Servings/kcal boundaries, NaN/infinity, live precision, dialog ve duplicate Save.
- Food/date Cancel, draft cancel, History shared totals ve tab scroll.
- 320/360/430 genişlik, büyük text, keyboard; analyze/test/emulator.
- [00_shared_start.md](00_shared_start.md) gerçek count/author/push onayı kontrolünden sonra feature branch push.
