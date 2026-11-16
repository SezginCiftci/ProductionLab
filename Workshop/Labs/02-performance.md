# Lab 2 — Holdings CPU problemi

**Branch:** `lab/performance` · **Çözüm:** `solution/performance`

## Öğrenme hedefi

Time Profiler ile ana thread'i meşgul eden fonksiyonu bulmak, algoritmik karmaşıklığı (O(n) yerine O(n²)) fark etmek ve iyileştirmeyi aynı veriyle **önce/sonra** ölçmek.

## Başlangıç durumu

- Holdings satırlarında her varlığın portföy ağırlığı (%) gösterilir.
- Bir ekip arkadaşı "Piyasa değeri" sıralamasını ağırlık üzerinden yapacak şekilde değiştirmiştir.

## Yeniden üretim

1. `lab/performance` branch'ini açın ve çalıştırın.
2. Settings → Diagnostics → Veri seti → **Performans (5.000 varlık)**.
3. **Holdings** sekmesi → Sırala → **Piyasa değeri**.
4. Arama kutusuna birkaç harf yazın, sıralamayı değiştirin.

## Beklenen / gözlenen davranış

| Beklenen | Gözlenen |
|---|---|
| Sıralama ve arama anında tepki verir. | Ekran birkaç saniye donar; her tuş vuruşunda takılma olur. |

20 kayıtlık normal veride problem fark edilmez. Bu yüzden performans problemleri gerçekçi veri boyutlarıyla test edilmelidir.

## Önerilen araçlar

- Instruments → **Time Profiler** (Product → Profile, `⌘I`)
- Instruments → **Hangs** (ana thread'in ne kadar süre bloklandığı)
- `PerformanceTests` (XCTest `measure`)

## Ölçüm prosedürü

1. **Önce:** Aynı simülatör/cihaz ve 5.000 kayıtla Time Profiler kaydı alın. Adım 3–4'ü tekrarlayın, kaydı durdurun.
2. Call Tree ayarları: **Invert Call Tree** ve **Hide System Libraries** işaretli. En çok zaman harcayan fonksiyonu bulun.
3. Ölçüm testini çalıştırıp ortalamayı not edin:
   ```sh
   xcodebuild test -project ProductionLab.xcodeproj -scheme ProductionLab \
     -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
     -only-testing:ProductionLabTests/PerformanceTests/testHoldingsSearchAndSortWith5000Holdings
   ```
   Sonuç: Xcode → Report navigator (`⌘9`) → test → "average".
4. Düzeltin.
5. **Sonra:** Aynı adımlarla yeniden kaydedin ve ölçün.
6. Farkı açıklayın: hangi fonksiyon kayboldu, kaç kez çağrılıyordu?

## İpuçları

1. Time Profiler'da en üstte hangi `HoldingsViewModel` metodu var? Kaç kez çağrıldığını düşünün: sıralama ~n·log(n) karşılaştırma yapar.
2. `weight(of:)` her çağrıda ne hesaplıyor? Bu değer varlıktan varlığa değişiyor mu?
3. `visibleHoldings` View'da kaç yerde okunuyor? Her okumada ne oluyor?
4. Ağırlığa göre sıralama ile piyasa değerine göre sıralama aynı sırayı mı verir?

Not: İyileşme için sabit bir yüzde beklenmez; makineye, Debug/Release'e ve cihaza göre değişir. Önemli olan aynı koşullarda yapılan karşılaştırmadır.

## Doğrulama

- 5.000 kayıtta sıralama ve arama gecikmesiz çalışmalı; Hangs kaydında uzun bloklanma görünmemeli.
- `PerformanceTests/testHoldingsSearchAndSortWith5000Holdings` ortalaması belirgin şekilde düşmeli.
- `ProductionLabTests/HoldingsViewModelTests` geçmeli (sıralama ve ağırlık sonuçları değişmemeli).

Çözüm ve açıklama: `solution/performance` branch'inde `Workshop/Solutions/02-performance.md`.
