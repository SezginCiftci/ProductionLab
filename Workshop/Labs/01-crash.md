# Lab 1 — Activity crash

**Branch:** `lab/crash` · **Çözüm:** `solution/crash`

## Öğrenme hedefi

Bir çökmenin çağrı yığınını (call stack) okumak, LLDB ile o andaki değerleri incelemek, uygun breakpoint türünü seçmek ve hatayı bir regresyon testiyle kalıcı olarak kapatmak.

## Başlangıç durumu

- Demo verisindeki bazı işlemler (`LEGACY7`, `LEGACY23`) kapanmış pozisyonlara aittir; `holdingID` değerleri `nil`'dir.
- `main`'de bu işlemlerin detayı "Bağlı bir varlık yok" yazar.

## Yeniden üretim

1. `lab/crash` branch'ini açın, uygulamayı Debug ile çalıştırın (`⌘R`).
2. demo / demo123 ile giriş yapın.
3. **Activity** sekmesinde listeyi kaydırıp **Buy LEGACY7** satırına dokunun.

## Beklenen / gözlenen davranış

| Beklenen | Gözlenen |
|---|---|
| Detay ekranı açılır, "Bağlı bir varlık yok" yazar. | Uygulama çöker. Xcode `Fatal error: Unexpectedly found nil while unwrapping an Optional value` ile durur. |

## Önerilen araçlar

- Xcode Debug navigator (`⌘7`): çağrı yığını
- LLDB: `bt`, `frame variable`, `po transaction`, `p transaction.holdingID`
- Breakpoint navigator (`⌘8`): koşullu breakpoint, Swift Error breakpoint
- `Workshop/CrashReports/` altındaki örnek crash raporu

## İpuçları

1. Xcode durduğunda Debug navigator'da **sizin modülünüze ait ilk satırı** bulun; sistem çerçeveleri (SwiftUI, libswiftCore) genelde sebep değildir.
2. O çerçeveyi seçip LLDB'de `po transaction` yazın. Hangi alan `nil`?
3. Hatalı satıra **koşullu breakpoint** koyun: sağ tık → Edit Breakpoint → Condition: `transaction.holdingID == nil`. Normal kayıtlarda durmaz, yalnızca sorunlu kayıtta durur.
4. "Swift Error Breakpoint" force unwrap çökmesini yakalar mı? Neden? (İpucu: `throw` ile runtime trap farklı şeylerdir.)
5. Uygulamayı Xcode'dan **değil**, simülatörde ana ekrandan açıp çökertin. Rapor `~/Library/Logs/DiagnosticReports/` altında `ProductionLab-*.ips` olarak oluşur. Örnek raporla karşılaştırın.

## Doğrulama

Düzeltmeden sonra:

```sh
xcodebuild test -project ProductionLab.xcodeproj -scheme ProductionLab \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:ProductionLabUITests/ActivityAndDiagnosticsUITests/testTransactionWithoutHoldingOpensSafely
```

- Test geçmeli.
- LEGACY7 ve LEGACY23 detayları açılmalı, normal işlemlerde Holding ID görünmeye devam etmeli.

Çözüm ve açıklama: `solution/crash` branch'inde `Workshop/Solutions/01-crash.md`.
