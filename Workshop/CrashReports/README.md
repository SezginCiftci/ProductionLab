# Crash raporları

Crash lab'inin örnek raporu `lab/crash` ve `solution/crash` branch'lerinde bu klasördedir (`ProductionLab-crash-lab.ips`). Rapor, `lab/crash` Debug derlemesi simülatörde çökertilerek üretilmiştir.

## Kendi raporunuzu üretmek

1. `lab/crash` branch'ini derleyip simülatöre kurun (`⌘R`), sonra Xcode'da **Stop** ile durdurun.
2. Uygulamayı simülatörün ana ekranından açın (debugger bağlı olmadan).
3. Activity → **Buy LEGACY7**'ye dokunun.
4. Rapor Mac'te oluşur: `~/Library/Logs/DiagnosticReports/ProductionLab-<tarih>.ips`. Xcode'da açmak için dosyaya çift tıklayın veya Window → Devices and Simulators → View Device Logs.

## Sembolleştirme (symbolication)

Simülatör raporları Mac'teki binary kullanılarak genellikle otomatik sembolleştirilir. Fiziksel cihaz veya dağıtılmış build raporlarında ise **aynı build'in dSYM'i** gerekir; farklı bir build'in dSYM'i (UUID eşleşmez) yanlış veya boş sonuç verir.

```sh
# Raporu üreten build'in dSYM'ini oluşturmak (Debug'da varsayılan 'dwarf', dSYM üretmez):
xcodebuild -project ProductionLab.xcodeproj -scheme ProductionLab -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  DEBUG_INFORMATION_FORMAT=dwarf-with-dsym build

# dSYM ve binary UUID'lerini raporun "usedImages" bölümündeki UUID ile karşılaştırın:
dwarfdump --uuid <DerivedData>/Build/Products/Debug-iphonesimulator/ProductionLab.app.dSYM

# Tek bir adresi elle çözmek:
atos -arch arm64 -o ProductionLab.app.dSYM/Contents/Resources/DWARF/ProductionLab \
  -l <yükleme adresi> <çerçeve adresi>
```

dSYM dosyaları `.gitignore` nedeniyle repoya eklenmez; gerektiğinde yukarıdaki komutla yeniden üretilir. Not: kod değiştikten sonra üretilen dSYM eski raporla eşleşmez.
