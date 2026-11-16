# Lab 3 — Detay ekranında bellek sızıntısı

**Branch:** `lab/memory` · **Çözüm:** `solution/memory`

## Öğrenme hedefi

Memory Graph Debugger ile ekran kapandıktan sonra hayatta kalan nesneyi bulmak, sahiplik zincirini (kim kimi tutuyor) okumak ve `Task` + closure kaynaklı güçlü referans döngüsünü çözmek.

## Başlangıç durumu

- Holding detayında her saniye değişen "Canlı fiyat (simülasyon)" satırı vardır.
- Bir ekip arkadaşı canlı fiyatın ekran açılır açılmaz başlaması için güncellemeyi View'dan ViewModel'in `init`'ine taşımıştır.
- `HoldingDetailViewModel` `deinit` olduğunda `Diagnostics` kategorisinde debug log yazar.

## Yeniden üretim

1. `lab/memory` branch'ini açın, Debug ile çalıştırın.
2. **Holdings** → **DEMO1** detayına girin, geri dönün. Bunu 5 kez tekrarlayın.
3. Xcode debug çubuğundaki **Debug Memory Graph** düğmesine basın.
4. Sol listede filtreye `HoldingDetailViewModel` yazın.

## Beklenen / gözlenen davranış

| Beklenen | Gözlenen |
|---|---|
| Ekran kapanınca ViewModel silinir; Xcode konsolunda `HoldingDetailViewModel deinit` görünür. Memory Graph'ta 0 örnek kalır. | Her açılış bir örnek bırakır (≥ 5). `deinit` logu hiç görünmez. Kapalı ekranların canlı fiyat döngüsü arka planda çalışmaya devam eder. |

## Önerilen araçlar

- **Debug Memory Graph** (Xcode debug çubuğu)
- Instruments → **Allocations** (filtre: `HoldingDetailViewModel`, "Persistent" sütunu)
- Xcode konsolu veya:
  ```sh
  xcrun simctl spawn booted log stream --level debug \
    --predicate 'subsystem == "com.productionlab.ios" AND category == "Diagnostics"'
  ```

## İpuçları

1. Memory Graph'ta bir `HoldingDetailViewModel` örneğine tıklayın. Ona ok çizen (onu tutan) nesneler kimler?
2. ViewModel neyi tutuyor? O şey de ViewModel'i tutuyor mu? Bu bir döngü müdür?
3. `Task { ... }` closure'ı `self`'i nasıl yakalar? Görev ne zaman biter?
4. `[weak self]` tek başına yeterli mi? Döngünün içinde `self?.metot()` çağrıldığında metot bitene kadar ne olur?
5. SwiftUI'da View'ın ömrüne bağlı ve otomatik iptal edilen bir görev nasıl başlatılır?
6. Instruments **Leaks** her retain cycle'ı bulmaz; çalışan bir `Task` tarafından tutulan nesneler "sızıntı" olarak raporlanmayabilir. Memory Graph ve sahiplik ilişkilerini birlikte yorumlayın.

## Doğrulama

```sh
xcodebuild test -project ProductionLab.xcodeproj -scheme ProductionLab \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:ProductionLabTests/HoldingDetailViewModelTests
```

- Test geçmeli.
- Detayı 5 kez açıp kapattıktan sonra Memory Graph'ta `HoldingDetailViewModel` kalmamalı, konsolda 5 adet `deinit` logu görünmeli.
- Canlı fiyat ekran açıkken güncellenmeye devam etmeli.

Çözüm ve açıklama: `solution/memory` branch'inde `Workshop/Solutions/03-memory.md`.
