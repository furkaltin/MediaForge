# MediaForge: Teknik Bağlam

## Geliştirme Ortamı

- **İşletim Sistemi:** macOS 15.0 Sequoia ve üzeri
- **Geliştirme Dili:** Swift 5.9+
- **UI Framework:** SwiftUI
- **IDE:** Xcode 15+
- **Versiyon Kontrol:** Git (GitHub repository)
- **Dağıtım Formatları:** DMG ve PKG

## Mimari Yapı

MediaForge, MVVM (Model-View-ViewModel) mimari desenini kullanmaktadır. Bu yapı, arayüz (View) ile mantık/veri işleme (Model) katmanlarını birbirinden ayırarak, ViewModel aracılığıyla iletişim kurulmasını sağlar.

### Ana Bileşenler

1. **Models:** Temel veri yapıları ve iş mantığı
   - Disk.swift - Disk ve depolama ortamlarını temsil eder
   - FileTransfer.swift - Dosya transferi operasyonlarını yönetir
   - TransferPreset.swift - Önceden tanımlanmış transfer ayarları
   - CameraFormat.swift - Desteklenen kamera formatları ve özellikleri
   - CustomElement.swift - Özelleştirilebilir UI bileşenleri için model
   - MediaForgeViewModel.swift - Ana uygulama verileri ve mantığını yöneten sınıf

2. **Views:** Kullanıcı arayüzü bileşenleri
   - ContentView.swift - Ana uygulama görünümü
   - DisksView.swift - Disk yönetimi görünümü
   - TransfersView.swift - Transfer izleme ve yönetimi
   - SettingsView.swift - Uygulama ayarları
   - TransferPresetsView.swift - Preset yönetimi
   - ElementReviewPanelView.swift - Medya inceleme paneli

3. **Helpers:** Yardımcı sınıflar ve yöneticiler
   - DiskManager.swift - Fiziksel diskleri algılama ve izleme
   - FileTransferManager.swift - Dosya transfer operasyonlarını yönetme
   - MediaHashList.swift - MHL (Media Hash List) oluşturma ve yönetme
   - XXHasher.swift - xxHash algoritması implementasyonu

## Teknik Detaylar

### Disk Yönetimi
- macOS Disk Arbitration framework kullanılarak disk algılama
- Dosya sistemi erişimi için FileManager API'leri
- Disk bilgilerini almak için IOKit ve DiskArbitration çağrıları

### Dosya Transferi
- Çoklu thread yapısı ile paralel işlem yeteneği
- Checkpoint yönetimi ile transfer kesilmesi durumunda kurtarma
- Progress API ile ilerleme takibi
- Transfer kuyruk sistemi

### Doğrulama ve Checksums
- xxHash64 (varsayılan, hızlı doğrulama için)
- MD5 (daha kapsamlı doğrulama için)
- SHA-256 (maksimum güvenlik için)
- MHL (Media Hash List) üretimi ve doğrulaması

### Performans Optimizasyonu
- Büyük dosyalar için buffered I/O işlemleri
- İşlem önceliklendirme (QoS) kullanımı
- Disk ve CPU kaynakları için akıllı dengeleme
- Minimal memory footprint için optimize edilmiş yapı

### Metadata İşleme
- Görüntü formatları için ExifTool entegrasyonu
- Video formatları için MediaInfo entegrasyonu
- Kamera modeline özel metadata çıkarma
- Metadata önizleme ve düzenleme

## Teknik Zorluklar ve Çözümler

### Zorluk 1: Disk Erişim İzinleri
**Problem:** macOS, güvenlik nedeniyle harici disklere tam erişim için kullanıcı izni gerektiriyor.
**Çözüm:** İlk kullanımda tam disk erişimi izni isteme, izin reddedildiğinde kullanıcı dostu bir hata mesajı gösterme ve ayarlardan izin verilmesi için rehberlik etme.

### Zorluk 2: Büyük Dosya Transferleri
**Problem:** Büyük medya dosyaları (özellikle RAW formatlar) transfer sırasında bellek sorunlarına neden olabilir.
**Çözüm:** Chunk-based transfer sistemi, bellek kullanımını sınırlayan stream işleme.

### Zorluk 3: Transfer Kesintileri
**Problem:** Ağ kesintileri, disk çıkarılması gibi durumlarda veri kaybı riski.
**Çözüm:** Her transfer için checkpoint takibi, kesinti sonrası kaldığı yerden devam edebilme, transfer durumunun düzenli olarak kaydedilmesi.

## Üçüncü Parti Bağımlılıklar

- **ExifTool:** Fotoğraf metadata işleme
- **MediaInfo:** Video metadata işleme
- **Sparkle:** Otomatik güncelleme sistemi
- **KeychainAccess:** Güvenli kimlik bilgisi depolama
- **Alamofire:** Ağ istekleri (gelecekteki bulut entegrasyonu için)

## Teknik Geliştirme Yol Haritası

1. **Temel Altyapı**
   - Disk algılama ve izleme sistemi
   - Temel dosya transfer motoru
   - Checksum doğrulama altyapısı

2. **Temel Özellikler**
   - Çoklu kaynak ve hedef desteği
   - Transfer önizleme ve ilerleme izleme
   - Basit raporlama sistemi

3. **Gelişmiş Özellikler**
   - Metadata yönetimi
   - Gelişmiş filtreleme ve arama
   - Preset ve otomasyon

4. **İleri Düzey Özellikler**
   - Uzaktan izleme
   - Bulut entegrasyonu
   - AI tabanlı içerik analizi 