# Lab 4 — Güvensiz token saklama

**Branch:** `lab/keychain` · **Çözüm:** `solution/keychain`

## Öğrenme hedefi

Hassas bir verinin cihazda nerede ve nasıl saklandığını incelemek, UserDefaults ile Keychain farkını görmek, loglarda gizli bilgi sızıntısını bulmak ve güvenli saklamaya geçişi testle doğrulamak.

## Başlangıç durumu

- Giriş yapınca sahte bir token üretilir ve `SecureStorage` protokolü üzerinden saklanır.
- `KeychainStorage` sınıfı projede hazırdır ama bir ekip arkadaşı "debug ederken kolay okunsun" diye geçici bir çözüm bırakmıştır.

## Yeniden üretim

1. `lab/keychain` branch'ini açın, çalıştırın, demo / demo123 ile giriş yapın.
2. Uygulamanın veri klasörünü bulun ve tercihler dosyasını okuyun:
   ```sh
   DATA=$(xcrun simctl get_app_container booted sezgin.ciftci.ProductionLab data)
   plutil -p "$DATA/Library/Preferences/sezgin.ciftci.ProductionLab.plist"
   ```
3. Logları izleyin ve tekrar giriş yapın:
   ```sh
   xcrun simctl spawn booted log stream --level info \
     --predicate 'subsystem == "com.productionlab.ios" AND category == "Authentication"'
   ```
   (Console.app'te de simülatörü seçip `subsystem:com.productionlab.ios` ile filtreleyebilirsiniz.)

## Beklenen / gözlenen davranış

| Beklenen | Gözlenen |
|---|---|
| Token yalnızca Keychain'de bulunur. Plist'te `auth.token` yoktur. Loglarda token görünmez. | `auth.token` değeri plist'te düz metin olarak durur. Log satırında token açıkça yazılır. |

UserDefaults şifrelenmemiş bir plist dosyasıdır; cihaz yedeklerine girer ve dosya sistemine erişen herkes okuyabilir.

## Önerilen araçlar

- `xcrun simctl get_app_container`, `plutil -p`
- Console.app / `log stream`
- `KeychainStorage.swift` ve `SecureStorage` protokolü

## İpuçları

1. Uygulama hangi `SecureStorage` implementasyonunu kullanıyor? Bu karar nerede veriliyor?
2. `privacy: .public` OSLog'a ne söyler? Varsayılan gizlilik seviyesi nedir? Token'ı loglamak zaten gerekli mi?
3. Düzeltmeden önce giriş yapmış kullanıcıların plist'inde eski token kalır. Uygulama güncellendiğinde bu artık ne yapılmalı?
4. `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` ne anlama gelir? Neden "ThisDeviceOnly"?

## Doğrulama

```sh
xcodebuild test -project ProductionLab.xcodeproj -scheme ProductionLab \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:ProductionLabTests/TokenSecurityTests \
  -only-testing:ProductionLabTests/KeychainStorageTests
```

- Testler geçmeli.
- Giriş sonrası plist'te `auth.token` olmamalı (eski kurulumdan kalan değer de silinmiş olmalı).
- Log akışında token görünmemeli.
- Uygulamayı kapatıp açınca oturum Keychain'den geri yüklenmeli.

Çözüm ve açıklama: `solution/keychain` branch'inde `Workshop/Solutions/04-keychain.md`.
