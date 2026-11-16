# Lab 6 — Paylaşılan değişebilir durum (data race)

**Branch:** `lab/concurrency-data-race` · **Çözüm:** `solution/concurrency-data-race`

## Öğrenme hedefi

Swift 6'nın derleme zamanı veri yarışı kontrollerini okumak, `@unchecked Sendable`'ın bu kontrolü nasıl kapattığını görmek, Thread Sanitizer ile çalışma zamanında yarışı yakalamak ve durumu `actor` ile korumak.

## Başlangıç durumu

- Mock API'ye yapılan istekleri sayan bir `RequestTracker` eklenmiştir; toplam Diagnostics ekranında görünür.
- Diagnostics'te aynı anda 200 istek gönderen bir **Stres testi** düğmesi vardır.
- Derleyici `RequestTracker` için hata verdiğinde bir ekip arkadaşı hatayı `@unchecked Sendable` ile susturmuştur.

## Yeniden üretim

1. `lab/concurrency-data-race` branch'ini açın, çalıştırın, giriş yapın.
2. Settings → Diagnostics → **Stres testi (200 eşzamanlı istek)** düğmesine birkaç kez basın.
3. "Toplam istek" değerinin her seferinde tam 200 artıp artmadığına bakın.
4. Thread Sanitizer'ı açın: Product → Scheme → Edit Scheme → Run (ve Test) → Diagnostics → **Thread Sanitizer**. Tekrar çalıştırıp düğmeye basın.
5. `RequestTracker`'daki `@unchecked` kelimesini silip derleyin.

## Beklenen / gözlenen davranış

| Beklenen | Gözlenen |
|---|---|
| Her basışta sayaç tam 200 artar. TSan uyarı vermez. Derleyici hata vermez. | Sayaç zaman zaman 200'den az artar (kayıp güncelleme). TSan `Data race in RequestTracker.record()` raporlar. `@unchecked` silinince derleme hatası çıkar. |

Kayıp güncelleme her seferinde görünmeyebilir; data race'ler doğası gereği rastgeledir. TSan ve derleyici ise her seferinde yakalar.

## Önerilen araçlar

- Swift 6 derleyici tanıları (Issue navigator, `⌘5`)
- **Thread Sanitizer** (scheme diagnostics) veya:
  ```sh
  xcodebuild test ... -enableThreadSanitizer YES -only-testing:ProductionLabTests/RequestTrackerTests
  ```
- `RequestTrackerTests`

## İpuçları

1. `@unchecked Sendable` derleyiciye ne söz verir? Bu söz burada tutuluyor mu?
2. `MockPortfolioAPIClient`'ın metotları hangi thread'lerde çalışır? Aynı anda kaç tane çalışabilir?
3. `totalRequests += 1` tek bir işlem midir? (oku → artır → yaz)
4. Projede zaten bir `actor` örneği var: `MockScenarioController`. Aynı yaklaşım burada uygulanabilir mi?
5. Bir sınıfı `actor` yapınca onu çağıran kodda neler değişir?

## Doğrulama

```sh
xcodebuild test -project ProductionLab.xcodeproj -scheme ProductionLab \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -enableThreadSanitizer YES \
  -only-testing:ProductionLabTests/RequestTrackerTests
```

- Test geçmeli, TSan uyarısı olmamalı.
- Projede `@unchecked Sendable` kalmamalı ve derleme uyarısız olmalı.
- Stres testi her basışta sayacı tam 200 artırmalı.

Çözüm ve açıklama: `solution/concurrency-data-race` branch'inde `Workshop/Solutions/06-concurrency-data-race.md`.
