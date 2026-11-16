# Lab 5 — Stale response (istek yarışı)

**Branch:** `lab/concurrency-stale-response` · **Çözüm:** `solution/concurrency-stale-response`

## Öğrenme hedefi

Birbiriyle yarışan async isteklerde "son başlatılan kazanmalı" kuralını uygulamak; Task iptali ve iptal kontrolüyle eski cevabın yeni durumu ezmesini engellemek ve bunu async bir testle doğrulamak.

## Başlangıç durumu

- **Stale response demo** senaryosunda holdings istekleri sırayla döner:
  - **A:** 8 sn sonra, DEMO1 fiyatı 1.000 → Dashboard toplamı **188.375,70 $**
  - **B:** 500 ms sonra, DEMO1 fiyatı 1.200 → Dashboard toplamı **208.375,70 $**
- B, A'dan sonra başlatılır ama önce biter. Doğru son durum **B**'dir.

## Yeniden üretim

1. `lab/concurrency-stale-response` branch'ini açın, çalıştırın, giriş yapın.
2. Settings → Diagnostics → **Stale response demo** seçin.
3. Dashboard'a dönün, **Refresh**'e basın (A başlar).
4. 8 saniye dolmadan **Refresh**'e tekrar basın (B başlar).
5. Toplam değeri izleyin.

## Beklenen / gözlenen davranış

| Beklenen | Gözlenen |
|---|---|
| ~1 sn sonra toplam 208.375,70 olur ve öyle kalır. | Önce 208.375,70 görünür, birkaç saniye sonra eski A cevabı gelir ve toplam 188.375,70'e geri döner. Uygulamayı yeniden açınca da A değeri görünür, çünkü veritabanına da yazılmıştır. |

Lab bittikten sonra senaryoyu **Başarılı**'ya alıp bir kez yenileyin; DEMO1 normal değerine döner.

## Önerilen araçlar

- `DashboardViewModel.refresh()` ve `performRefresh()`
- `DashboardViewModelTests` (Swift Testing, async test)
- Networking logları (`category == "Networking"`): hangi istek ne zaman başladı/bitti

## İpuçları

1. İkinci Refresh'e basıldığında birinci isteğe ne oluyor? Hâlâ ihtiyaç var mı?
2. `Task.cancel()` çalışan kodu zorla durdurmaz. İptal edilen görev bunu nerede ve nasıl fark eder?
3. Cevap geldikten sonra, state'i güncellemeden önce "bu görev hâlâ geçerli mi?" diye sormanın bir yolu var mı?
4. Repository'deki `Task.checkCancellation()` veritabanına yazmayı nasıl engelliyor?

## Doğrulama

```sh
xcodebuild test -project ProductionLab.xcodeproj -scheme ProductionLab \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:ProductionLabTests/DashboardViewModelTests
```

- `staleResponseCannotOverwriteNewerResult` dahil tüm testler geçmeli.
- Uygulamada adım 3–5 tekrarlandığında toplam 208.375,70'te kalmalı; yeniden açılışta da aynı değer görünmeli.

Çözüm ve açıklama: `solution/concurrency-stale-response` branch'inde `Workshop/Solutions/05-concurrency-stale-response.md`.
