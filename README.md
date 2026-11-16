# ProductionLab

Kurgusal bir yatırım portföyü üzerinden ileri iOS mühendisliği eğitimi için hazırlanmış, tamamen çevrimdışı çalışan uygulama. Gerçek servis, API anahtarı, üçüncü taraf bağımlılık veya Apple Developer üyeliği gerekmez.

Durum: **Faz 1–5 tamamlandı.** Workshop lab'leri için bkz. [Workshop/README.md](Workshop/README.md).

## Gereksinimler

- Xcode 26.x (Swift 6 dil modu), iOS 17.0+ deployment target
- iOS Simulator (doğrulama iOS 26.5 ve iOS 18.1 runtime'larında yapıldı)

## Çalıştırma

1. `ProductionLab.xcodeproj` dosyasını açın, `ProductionLab` scheme'ini ve bir iPhone simülatörünü seçin.
2. Simülatörde imzalama gerekmez. Fiziksel cihaz için Signing & Capabilities altında kendi Team'inizi seçin (Team ID projede hardcode edilmez).
3. Demo hesabı: **demo / demo123**. Token Keychain'de saklanır; uygulama yeniden açılınca oturum geri yüklenir, Settings → Çıkış yap ile silinir.

İlk açılışta `Resources/MockData` altındaki JSON fixture'larından 1 portföy, 20 varlık ve 40 işlem SwiftData'ya eklenir. Seed idempotent'tir; yeniden açılışta tekrar eklenmez.

## Mock API senaryoları

Settings → Diagnostics (yalnızca Debug) üzerinden seçilir ve bir sonraki istekte geçerli olur:

| Senaryo | Davranış |
|---|---|
| success | 500 ms sonra geçerli cevap |
| slowResponse | 8 sn sonra geçerli cevap |
| serverError | 500 ms sonra HTTP 503 (`AppError.server`) |
| emptyResponse | 500 ms sonra boş holdings dizisi |
| invalidJSON | `holdings_invalid.json` ile deterministik decoding hatası |
| staleResponse | Holdings istekleri sırayla A (8 sn, DEMO1 = 100.000) ve B (500 ms, DEMO1 = 120.000) döner |

İptal edilen istekler `CancellationError` yayar; sunucu hatası olarak gösterilmez veya loglanmaz. Stale response lab'i için `holdings_stale_a.json` (100.000) ve `holdings_stale_b.json` (120.000) hazırdır.

## Performans veri setleri

Settings → Diagnostics → Veri seti: **Normal (20)**, **1.000** veya **5.000** varlık. Performans setleri `PerformanceDataGenerator` ile deterministik üretilir ve bellekte **ayrı bir veritabanına** yazılır; diskteki normal veri değişmez. "Normal"e dönünce önceki veri aynen görünür. Seçimden sonra sekmeler yeniden kurulur ve Dashboard açılır. Bu modda refresh de aynı üretilmiş varlıkları döndürür.

## Build yapılandırması

`Configuration/` klasöründe:

| Dosya | İçerik |
|---|---|
| `Shared.xcconfig` | Version, build, bundle id, `INFOPLIST_FILE` |
| `Debug.xcconfig` | Ana ekran adı **PL Debug**, `APP_ENVIRONMENT = Debug · Offline mock API` |
| `Release.xcconfig` | Ana ekran adı **ProductionLab**, `APP_ENVIRONMENT = Release · Offline mock API` |
| `Info.plist` | `AppEnvironment = $(APP_ENVIRONMENT)` (Settings → Ortam satırı) |

Bu ayarlar app target'ının Build Settings'inden kaldırıldı; target'a elle yazılan değer xcconfig'i ezeceği için değişiklikler xcconfig dosyalarında yapılmalıdır. Diagnostics bağlantısı `#if DEBUG` ile yalnızca Debug'da görünür.

## Testler

```sh
# Hepsi (unit + UI)
xcodebuild test -project ProductionLab.xcodeproj -scheme ProductionLab \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Sadece unit/integration
xcodebuild test ... -only-testing:ProductionLabTests

# Sadece UI
xcodebuild test ... -only-testing:ProductionLabUITests
```

Xcode'da: `⌘U` hepsini çalıştırır; Test navigator'dan (`⌘6`) tek dosya/test seçilebilir.

**Unit ve integration testleri (`ProductionLabTests`, Swift Testing + XCTest)**

| Dosya | Kapsam |
|---|---|
| `PortfolioCalculatorTests` | Piyasa değeri, maliyet, kâr/zarar, yüzde, boş portföy, sıfır maliyet |
| `MockAPIClientTests` | success, slowResponse, emptyResponse, serverError (503), invalidJSON, iptal, istek ortasında senaryo değişimi, stale A/B fixture'ları |
| `DashboardViewModelTests` | idle → loading → loaded / failed, önbellek koruma, stale response, iptal, son 5 işlem |
| `AuthenticationTests` | Doğru/yanlış giriş, token formatı, restore, logout, storage hataları; `LoginViewModel` |
| `SwiftDataTests` | İlk seed, tekrar seed olmaması, mapping, refresh ile güncelleme (kopya yok), hata ve iptalde önbellek korunması |
| `FeatureViewModelTests` | Holdings arama/sıralama (doğal sıralama dahil), Activity filtreleri |
| `KeychainStorageTests` | Gerçek Keychain'de kaydet/oku/güncelle/sil (ayrı servis adıyla) |
| `DataSetTests` | 1.000/5.000 sete geçiş, normale dönüşte verinin değişmemesi, üretecin deterministik olması |
| `PerformanceTests` (XCTest) | 5.000 kayıtta `measure` ile özet hesabı ve sıralama süresi (1.000 kayıt) |

**UI testleri (`ProductionLabUITests`, XCUITest)**

| Dosya | Kapsam |
|---|---|
| `LoginUITests` | Giriş/çıkış, hatalı şifre, boş alanlarda buton pasif, yeniden açılışta oturumun geri gelmesi |
| `DashboardUITests` | Refresh sonrası "Son yenileme", serverError'da önbellek + hata mesajı, Diagnostics'ten senaryo değiştirip toparlanma |
| `HoldingsUITests` | 20 kayıt, isimle büyük/küçük harf duyarsız arama, boş sonuç, Z–A sıralama, detay ekranı |
| `ActivityAndDiagnosticsUITests` | holdingID'siz işlem detayı (crash lab regresyonu), Sell filtresi, Settings Debug bilgileri, veri seti değişimi |

Testler internete, gerçek kullanıcı oturumuna veya önceki simülatör durumuna bağlı değildir. ViewModel testleri fake repository'ler (`TestHelpers.swift`) ve `InMemorySecureStorage` kullanır. UI testleri şu launch argümanlarıyla çalışır (`UITestHelpers.swift`):

| Argüman | Etki |
|---|---|
| `-ui-testing` | Veriler bellekte, her açılışta temiz seed |
| `-reset-session` | Açılışta Keychain'deki token silinir |
| `-mock-scenario <ad>` | Mock API bu senaryoyla başlar (ör. `serverError`) |

Her UI kontrolünün sabit bir `accessibilityIdentifier`'ı vardır (ör. `dashboard.totalValue`, `holdings.row.DEMO1`). Sayılar yerel ayara göre "1.000" veya "1,000" görünebileceği için testler etiketteki rakamları karşılaştırır.

Demo verisini sıfırlamak için uygulamayı simülatörden silin.

## Mimari

```
ProductionLabApp → AppDependencyContainer → SwiftUI View
                                          → @Observable @MainActor ViewModel
                                          → Repository protocol (@MainActor)
                                              ├─ MockPortfolioAPIClient → DTO → Domain
                                              └─ SwiftData mainContext → Entity → Domain
```

Klasörler: `App/`, `Core/{Networking,Persistence,Security,Logging,Utilities}`, `Domain/`, `Data/{DTO,Mappers,Repositories}`, `Features/*`, `Resources/MockData/`.

## Teknik notlar ve kararlar

- **Proje ayarları:** Xcode şablonundaki `SWIFT_VERSION = 5.0` → `6.0`, deployment target `26.5` → `17.0` yapıldı, hardcode edilmiş `DEVELOPMENT_TEAM` kaldırıldı. `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` ve `SWIFT_APPROACHABLE_CONCURRENCY` kaldırıldı; `@MainActor` ve `actor` kodda açıkça yazılır.
- **SwiftData:** Repository'ler `@MainActor` ve `modelContainer.mainContext` kullanır. `ModelContext` başka bir thread'e/actor'e geçmez. Demo veri boyutu için yeterli ve en sade yaklaşım budur.
- **Refresh:** fetch → decode → `Task.checkCancellation()` → upsert (aynı id varsa güncelle, yoksa ekle) → tek `save()`. `save` başarısız olursa `rollback()` yapılır. Hata veya iptalde önbellek değişmez.
- **emptyResponse:** Upsert kayıt silmediği için boş cevap mevcut önbelleği silmez; Dashboard kayıtlı veriyi göstermeye devam eder.
- **Stale response koruması:** `DashboardViewModel` yeni refresh başlatırken öncekini iptal eder ve sonuç gelince `Task.isCancelled` kontrol eder. Böylece geç dönen eski cevap yeni sonucun üzerine yazamaz.
- **Hata mesajları:** `AppError` (`LocalizedError`) ve JSON decode hataları `error.localizedDescription` ile gösterilir. `CancellationError` hata olarak gösterilmez.
- **Kimlik doğrulama:** `AuthenticationService` `@Observable`'dır; `isLoggedIn` değişince `RootView` Login/Dashboard arasında geçer. Token `KeychainStorage` ile `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` erişilebilirliğinde saklanır (iCloud senkronu/paylaşım yok). Şifre saklanmaz, token loglanmaz. `OSStatus` hataları `KeychainError` ile okunur mesaja çevrilir.
- **Veri seti değişimi:** `AppDependencyContainer` `@Observable`'dır; veri seti değişince repository'ler yeni `ModelContext` ile oluşturulur ve `RootView` `.id(dataSet)` ile sekmeleri yeniden kurar.
- Demo kolaylığı için `Double` kullanılır; gerçek finansal uygulamada `Decimal` tercih edilmelidir.

## Workshop

Lab'ler `lab/*`, örnek çözümler `solution/*` branch'lerindedir. `starter` katılımcı başlangıç noktasıdır (`main` ile aynı). Yönergeler: [Workshop/README.md](Workshop/README.md).

```sh
git branch --list 'lab/*' 'solution/*'
git switch lab/crash
```

## Bilinen sınırlamalar / sonraki işler

- Faz 6: Temiz klon ile uçtan uca kontrol (fresh clone, Debug/Release, testler, lab'ler).
