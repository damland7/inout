# Hüseyin — S01-S04 ve shared state

GitHub: `huseyinvk`. Önce [00_shared_start.md](00_shared_start.md), PDF sayfa 18 ve Step 2.2 yönergesini oku.
Kendi `feature/account-state` branch'inde çalış; ortak başlangıç commit'ini yayımlanmış varsayma. Koordinatörün remote branch'ini ve başlangıç SHA'sını doğruladıktan sonra branch aç.

## Ekranlar

- **S01 Login:** local logo (Berre asset'i), email/password, show/hide, inline errors; Log In → Home stack temizliği; Sign Up/Forgot linkleri.
- **S02 Sign Up:** full name/email/password/confirm; required name, valid email, password >= 6, matching confirmation; valid → Goal Setup. Password modelde veya logda saklanmaz.
- **S03 Forgot Password:** Login email prefill, inline validation, valid gönderimde neutral confirmation dialog, Back to Login. Gerçek email servisi Step 3; UI demo gerçek gönderim diye anlatılmaz.
- **S04 Goal Setup:** 1200..5000 kcal, quick pick 1800/2000/2200/2500; Start Tracking → Home stack temizliği; Back arrow yok.

## Shared work

- AppState/DTO sözleşmelerini production implementation ile tamamla. Placeholder data typed olsun; geçici `lib/preview/` adaptörleri tamamlanmış production state sayılmaz.
- Tek source of truth; profile/goal değişikliği bütün ekranlara bildirilir; aynı ID ile update duplicate yaratmaz.
- Meal/workout add/update/remove/restore ve 4 saniyelik undo'ya uygun immutable snapshot erişimi sağlanır.
- `selectDate`/`selectTab`/`registerProfile`/`logIn`/`logOut`; logout private profile/logları temizler.
- Appearance state değişimini Berre persistence katmanıyla bağla.
- Reusable form fields/buttons: label/helper/error/keyboard/password visibility/loading/disabled/dispose.
- Berre validators/theme kullanılır; ikinci kalıcı validator/calculation sistemi yazılmaz.

## Sekiz gerçek commit

1. Models + typed fixtures.
2. AppState/mutations/session.
3. Common form widgets.
4. Login.
5. Sign Up.
6. Forgot Password/dialog.
7. Goal Setup/stack.
8. Integration tests/actual notes.

Mevcut iş karşılanıyorsa boş commit oluşturulmaz; kalan gerçek işe göre plan düzeltilir. Testler ilgili iş sırasında yazılır.

## Kabul

- 5 karakter signup password reddedilir, 6 karakter kabul edilir; goal 1199/5001 reddedilir, 1200/5000 kabul edilir; blank name/email ve confirm mismatch kontrol edilir.
- State consumer güncellemesi, aynı ID ile update, undo/session reset ve Login'e Back olmaması doğrulanır.
- 320/360/430 genişlik, büyük text, keyboard; `flutter analyze`/`flutter test` ve emulator/simulator doğrulanır.
- [00_shared_start.md](00_shared_start.md) içindeki gerçek commit count/author/push onayı kontrolü yapılmadan push yok.
