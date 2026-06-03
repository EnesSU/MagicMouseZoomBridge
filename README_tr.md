<div align="center">
  <img src="MagicMouseZoomBridge/Assets.xcassets/AppIcon.appiconset/mac512.png" alt="Magic Mouse Zoom Bridge Icon" width="200" height="auto" />
  
  # 🚀 Magic Mouse Zoom Bridge
  
  **Magic Mouse'unuzu akıcı, trackpad tarzı bir kıstırarak yakınlaştırma (pinch-to-zoom) canavarına dönüştürün.**
  
  [![macOS](https://img.shields.io/badge/macOS-12.0+-black.svg?logo=apple)](#)
  [![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg?logo=swift)](#)
  [![License](https://img.shields.io/badge/Lisans-Açık%20Kaynak-blue.svg)](#)

  <br>

  [English](README.md) • [🇹🇷 Türkçe](README_tr.md)

</div>

<br>

> 🤖 **Not:** Bu proje yapay zeka kullanılarak geliştirilmiştir.

**Magic Mouse Zoom Bridge**, dikey kaydırma (scroll) hareketlerini anında gerçek ve yerel **kıstırarak yakınlaştırma (pinch-to-zoom) jestlerine** dönüştüren, hafif ve düşük seviyeli bir arka plan macOS aracıdır.

**FreeCAD, KiCad, CAD araçları, 3D görüntüleyiciler** gibi profesyonel tasarım yazılımları kullanıyorsanız veya klavye kısayollarına (örneğin `Cmd` + `+`) bağlı kalmadan **Fotoğraflar** ve **Önizleme (Preview)** uygulamasında yüksek çözünürlüklü görselleri akıcı bir şekilde yakınlaştırmak istiyorsanız, aradığınız araç tam olarak budur!

---

## ✨ Özellikler

- ⚙️ **%100 Yerel Jest Simülasyonu:** Tuş atamaları (kısayol) yapmıyoruz. Standart `scroll-wheel` (kaydırma tekerleği) olaylarını doğrudan CoreGraphics `IOHIDEventPhase` dizilerine (Began, Changed, Ended) çeviriyoruz.
- 🧈 **Pürüzsüz ve Kesintisiz Yakınlaştırma (Zoom):** Fare yüzeyinden doğrudan trackpad'lerdeki gibi gerçek ve kesintisiz yakınlaştırmanın keyfini çıkarın!
- 🎛️ **Yüksek Oranda Özelleştirilebilir:** Kod üzerinden ölü bölgeleri (dead-zones), hassasiyeti, hız sınırlarını kolayca ayarlayın ve yakınlaştırma yönünü tersine çevirin!
- 🌍 **Evrensel Uygulama Desteği:** Safari, Önizleme, Xcode, Figma, AutoCAD ve trackpad yakınlaştırma jestlerini destekleyen neredeyse tüm yerleşik macOS uygulamalarıyla sorunsuz çalışır.

---

## 📦 Kurulum ve Derleme

Önceden derlenmiş bir ikili (binary) dosyayı indirebilir ya da kaynak koddan kendiniz derleyebilirsiniz.

### 1. Seçenek: Hazır Sürümü İndirin
1. GitHub'daki [Releases](#) sekmesine gidin.
2. `MagicMouseZoomBridge.app.zip` dosyasını indirin, arşivden çıkarın ve `/Applications` (Uygulamalar) klasörünüze taşıyın.

### 2. Seçenek: Kaynak Koddan Derleyin
1. Bu depoyu (repository) bilgisayarınıza klonlayın.
2. Xcode'da `MagicMouseZoomBridge.xcodeproj` dosyasını açın.
3. Derleyip çalıştırın (`Cmd + R`) veya kendi uygulamanızı dışa aktarmak için **Product > Archive** seçeneğini kullanın.

---

## 🎮 Nasıl Kullanılır

Uygulama macOS menü çubuğunda sessize arka planda çalışır.

1. **Option (`⌥`)** tuşuna basılı tutun.
2. Magic Mouse'unuzda hafifçe yukarı veya aşağı kaydırın.
3. Etkin uygulamanın akıcı bir şekilde yakınlaşıp uzaklaşmasını izleyin! 🚀
4. Normal kaydırma işlevine anında dönmek için Option tuşunu bırakmanız yeterlidir.

---

## 🔒 İzinler ve Güvenlik

Bu araç genel donanım girişlerini dinleyip araya girerek gönderilen sistem düzeyindeki sentetik trackpad olayları oluşturduğundan, kullanımı için macOS tarafında açıkça izin vermeniz gereklidir. Uygulamayı ilk başlattığınızda şunlara izin vermeniz istenecektir:

- 👁️ **Erişilebilirlik (Accessibility):** Düşük seviyeli sentetik macOS trackpad jest olayları oluşturmak ve sisteme göndermek için gereklidir.
- ⌨️ **Giriş İzleme (Input Monitoring):** İşletim sistemi işlemeden önce fare kaydırma (scroll) verilerini araya girip alan Düşük Seviyeli bir Olay İzleyicisi (Event Tap) kurmak için gereklidir.

*Bu izinler **Sistem Ayarları > Gizlilik ve Güvenlik** bölümünden yönetilebilir.*

---

## 🧠 Kaputun Altında (Teknik Detaylar)

Uygulama, düşük seviyeli bir CoreGraphics olay dinleyicisi (`CGEventTapCreate`) kullanır. `kCGEventScrollWheel` olaylarını dinler ve `Option` tuşu basılıyken sistemdeki orijinal fare olayını yok eder (kullanır). Aynı esnada, Yakınlaştırma (Zoom) için Apple'ın Gizli Özel Arayüzlerini (`113`) kullanarak sentetik `kCGEventGesture (Type 29)` olayları oluşturur ve bu haraketleri donanım HID Fazlarına (`Began=1`, `Changed=2`, `Ended=4`) hatasız bir şekilde eşler.

> **⚠️ Apple Gizli (Özel) API'leri Hakkında Not:** Bu uygulama, ham sistem trackpad olayları oluşturmak için belgelenmemiş (undocumented) CoreGraphics SPI'lerinden yararlanır. Açık kaynaklı kullanım için tamamen yasal ve yaygın olmakla birlikte, macOS'un gelecekteki çok büyük güncellemelerinde davranışları değişebilir.