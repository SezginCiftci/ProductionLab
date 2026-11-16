# ProductionLab Workshop

Her lab, `main`'den açılmış bağımsız bir branch'tir. İçinde **bilerek konulmuş tek bir problem** vardır. Lab'ler birbirine bağlı değildir; herhangi birinden başlayabilirsiniz.

## Branch'ler

| Branch | İçerik |
|---|---|
| `main` | Temiz, hatasız temel sürüm. Tüm testler geçer. |
| `starter` | Katılımcının başlangıç noktası (`main` ile aynı). |
| `lab/<ad>` | Problemli sürüm. İlgili regresyon testi **başarısız** olur. |
| `solution/<ad>` | `lab/<ad>` + çözüm commit'i + `Workshop/Solutions/<ad>.md`. Testler geçer. |

## Lab listesi

| # | Lab | Branch | Konu | Araçlar |
|---|---|---|---|---|
| 1 | [Crash](Labs/01-crash.md) | `lab/crash` | Force unwrap ile çökme | Debugger, LLDB, breakpoint, crash raporu |
| 2 | [Performans (CPU)](Labs/02-performance.md) | `lab/performance` | Sıralamada gereksiz pahalı hesaplama | Instruments → Time Profiler, Hangs |
| 3 | [Bellek](Labs/03-memory.md) | `lab/memory` | Detay ekranında retain cycle | Memory Graph, Allocations |
| 4 | [Keychain](Labs/04-keychain.md) | `lab/keychain` | Token UserDefaults'ta ve logda | simctl, Console.app, Keychain |
| 5 | [Stale response](Labs/05-concurrency-stale-response.md) | `lab/concurrency-stale-response` | Eski cevap yeniyi eziyor | Async test, Task iptali |
| 6 | [Data race](Labs/06-concurrency-data-race.md) | `lab/concurrency-data-race` | Paylaşılan değişebilir durum | Swift 6 tanıları, Thread Sanitizer |
| 7 | [Cancellation](Labs/07-concurrency-cancellation.md) | `lab/concurrency-cancellation` | İptal hata gibi gösteriliyor | Task iptali, OSLog |

## Çalışma akışı

```sh
git switch lab/crash            # lab'i aç
# Workshop/Labs/01-crash.md yönergesini izle, problemi bul ve düzelt
xcodebuild test -project ProductionLab.xcodeproj -scheme ProductionLab \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:<yönergedeki test>   # yeşile dönmeli

git diff lab/crash solution/crash # kendi çözümünü örnek çözümle kıyasla
git switch solution/crash         # örnek çözüm + açıklama (Workshop/Solutions)
```

Swift Testing'de tek bir test seçerken fonksiyon adının sonuna `()` eklenir ve argüman tırnak içine alınır: `"-only-testing:ProductionLabTests/DashboardViewModelTests/cancelKeepsCacheWithoutError()"`. XCTest testlerinde (UI testleri, `PerformanceTests`) parantez kullanılmaz.

Kendi değişikliklerinizle başka bir lab'e geçmeden önce `git stash` veya `git restore .` kullanın.

## Genel notlar

- Uygulama tamamen çevrimdışıdır. Demo hesabı: **demo / demo123**.
- Mock API senaryosu ve 1.000 / 5.000 kayıtlık veri setleri **Settings → Diagnostics** ekranından seçilir (yalnızca Debug).
- Demo verisini sıfırlamak için uygulamayı simülatörden silin.
- Lab branch'leri yalnızca eğitim içindir ve hiçbir zaman dağıtılmaz. Kasıtlı hatalar `main`'de ve Release yapılandırmasında yoktur.
- Profiling (Instruments) varsayılan olarak **Release** ile yapılır; Debug ölçümleri optimizasyon olmadığı için daha yavaştır. Mümkünse fiziksel cihazda ölçün.
- Şema değişikliği yoktur: SwiftData modeli tüm branch'lerde aynıdır, branch değiştirmek veriyi bozmaz.
