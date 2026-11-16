# Lab 7 — İptal edilen istek hata gibi görünüyor

**Branch:** `lab/concurrency-cancellation` · **Çözüm:** `solution/concurrency-cancellation`

## Öğrenme hedefi

Cooperative cancellation'ı (iş birliğine dayalı iptal) anlamak: iptal edilen bir görevin beklemeyi hemen bırakması, `CancellationError`'ın yukarı taşınması, iptalin kullanıcıya hata olarak gösterilmemesi ve sunucu hatası olarak loglanmaması.

## Başlangıç durumu

- Dashboard'da yenileme sürerken sol üstte **Vazgeç** düğmesi görünür; önbellekteki veri ekranda kalır.
- **Yavaş cevap** senaryosunda istek 8 sn sürer.

## Yeniden üretim

1. `lab/concurrency-cancellation` branch'ini açın, çalıştırın, giriş yapın.
2. Settings → Diagnostics → **Yavaş cevap (8 sn)** seçin.
3. Dashboard → **Refresh** → hemen **Vazgeç**.
4. 10 saniye bekleyin. Bu sırada Networking loglarını izleyin:
   ```sh
   xcrun simctl spawn booted log stream --level info \
     --predicate 'subsystem == "com.productionlab.ios" AND category == "Networking"'
   ```

## Beklenen / gözlenen davranış

| Beklenen | Gözlenen |
|---|---|
| Vazgeç'e basınca istek hemen biter. Ekranda hata çıkmaz, önbellek olduğu gibi kalır. Log'da hata satırı olmaz. | ~8 sn sonra turuncu bir hata mesajı belirir (`CancellationError`). Log'da "Refresh başarısız" diye **error** seviyesinde satır görünür. İstek iptale rağmen sonuna kadar beklemiştir. |

## Önerilen araçlar

- `MockPortfolioAPIClient.waitForResponse` ve `DashboardViewModel.performRefresh`
- Networking logları, Xcode konsolu
- `MockAPIClientTests`, `DashboardViewModelTests`, `DashboardUITests`

## İpuçları

1. `Task.sleep` iptal edildiğinde ne yapar? Sonucu `try?` ile yutulursa ne olur?
2. Bekleme sürse bile repository neden veritabanına yazmıyor? Hangi satır bunu sağlıyor ve hangi hatayı fırlatıyor?
3. `catch` bloklarının sırası önemli mi? İptal ile gerçek bir hatayı nasıl ayırt edersiniz?
4. Kullanıcı "vazgeç" dediyse bu bir hata mıdır? Log seviyesi ne olmalı?

## Doğrulama

```sh
xcodebuild test -project ProductionLab.xcodeproj -scheme ProductionLab \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  "-only-testing:ProductionLabTests/MockAPIClientTests/cancellationThrowsCancellationError()" \
  "-only-testing:ProductionLabTests/DashboardViewModelTests/cancelKeepsCacheWithoutError()" \
  -only-testing:ProductionLabUITests/DashboardUITests/testCancellingSlowRefreshShowsNoError
```

- Üç test de geçmeli; `cancellationThrowsCancellationError` saniyeler değil milisaniyeler içinde bitmeli.
- Uygulamada Vazgeç sonrası hata görünmemeli, logda iptal yalnızca debug seviyesinde (ya da hiç) görünmeli.

Çözüm ve açıklama: `solution/concurrency-cancellation` branch'inde `Workshop/Solutions/07-concurrency-cancellation.md`.
