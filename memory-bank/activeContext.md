# MediaForge: Aktif Bağlam

Bu doküman, MediaForge projesi üzerinde şu anda çalışılan konuları, alınan son kararları ve bir sonraki adımları özetler. Bu doküman, geliştirme süreci boyunca sürekli güncellenecektir.

## Güncel Durum

MediaForge projesi, temel yapısı kurulmuş ancak geliştirmeye ihtiyaç duyan bir faz içindedir. Kod tabanının temel bileşenleri (Models, Views, Helpers) tanımlanmış olsa da, birçok fonksiyon tamamlanmamış veya optimize edilmemiştir.

### Mevcut Durum Özeti
- Temel UI çerçevesi ve MVVM mimarisi oluşturuldu
- Disk algılama ve bilgi toplama mekanizması mevcut
- Basit dosya transferi yeteneği oluşturuldu
- Temel ayarlar, presetler ve tercihler yapısı mevcut
- Proje MacOS Sequoia (15.0+) hedeflenerek geliştirilmekte

## Aktif Çalışma Alanları

### UI İyileştirmeleri
- **Durum:** Çalışma devam ediyor
- **Öncelik:** Yüksek
- **Hedef:** MacOS Sequoia'nın modern tasarım diline uygun, estetik ve fonksiyonel bir kullanıcı arayüzü
- **Yapılacaklar:**
  - Glassmorphism efektlerinin geliştirilmesi
  - Dinamik renk şeması ve tema desteği
  - Animasyon ve geçiş efektlerinin iyileştirilmesi
  - Erişilebilirlik özelliklerinin entegrasyonu

### Disk Yönetimi İyileştirmeleri
- **Durum:** Çalışma devam ediyor
- **Öncelik:** Yüksek
- **Hedef:** Daha güvenilir ve bilgilendirici disk algılama sistemi
- **Yapılacaklar:**
  - Disk izleme mekanizmasının güçlendirilmesi
  - Disk izinleri yönetiminin geliştirilmesi
  - Disk etiketleme ve kategorileme sisteminin eklenmesi
  - Disk hızı ve performans metriklerinin eklenmesi

### Dosya Transferi Optimizasyonu
- **Durum:** Çalışma devam ediyor
- **Öncelik:** Çok Yüksek
- **Hedef:** Daha hızlı, güvenilir ve sağlam transfer sistemi
- **Yapılacaklar:**
  - Paralel transfer yeteneğinin geliştirilmesi
  - Daha fazla checksum algoritması desteği
  - Transfer kesintilerinden kurtarma mekanizması
  - İlerleme izleme ve raporlama iyileştirmeleri

## Son Alınan Kararlar

1. **UI Yaklaşımı:** Modern MacOS Sequoia stiline uygun glassmorphism efektleri kullanılacak. Sidebar ve ana içerik alanı için yarı saydam, bulanıklaştırılmış arka plan efektleri uygulanacak.

2. **Mimari Yapı:** MVVM mimarisi korunacak, ancak reaktif programlama prensipleri daha etkin kullanılacak. Özellikle Combine framework'ünün daha fazla entegrasyonu sağlanacak.

3. **Performans Hedefleri:** Büyük dosya transferleri için bellek tüketimini en aza indirmek için chunk-based transfer stratejisi benimsenecek. 4K RAW video dosyaları gibi büyük medya dosyaları için bile düşük bellek ayak izi hedeflenecek.

4. **Doğrulama Stratejisi:** Varsayılan olarak xxHash64 kullanılacak (hız/güvenilirlik dengesi için), ancak kullanıcılara MD5 ve SHA-256 gibi daha güçlü alternatifler sunulacak.

## Teknik Borçlar ve Zorluklar

1. **Disk İzinleri:** macOS'un sıkı güvenlik politikaları nedeniyle, tam disk erişimi için daha akıllı bir izin yönetimi mekanizması gerekiyor.

2. **Bellek Yönetimi:** Büyük dosya transferleri sırasında bellek kullanımı sorunları gözlemlendi. Bu, özellikle birden fazla paralel transfer yapılırken daha belirgin hale geliyor.

3. **UI Performansı:** Yoğun transfer işlemleri sırasında UI tepki süresi düşüyor. SwiftUI ile arka plan iş yüklerinin daha iyi izolasyonu gerekiyor.

4. **Test Kapsamı:** Şu anda test kapsama oranı düşük. Özellikle dosya transferi ve doğrulama bileşenleri için daha kapsamlı birim testleri gerekiyor.

## Bir Sonraki Adımlar

### Kısa Vadeli (1-2 Hafta)
1. UI modernizasyonu: MacOS Sequoia tasarım diline uygun arayüz güncellemeleri
2. Disk yöneticisi iyileştirmeleri: Daha güvenilir algılama ve izleme
3. Transfer motoru optimizasyonları: Paralel transfer ve hata kurtarma

### Orta Vadeli (2-4 Hafta)
1. Metadata görüntüleme ve yönetim sisteminin geliştirilmesi
2. Gelişmiş filtreleme ve arama yeteneklerinin eklenmesi
3. Transfer preset sisteminin genişletilmesi

### Uzun Vadeli (1-2 Ay)
1. Bulut depolama entegrasyonu (S3, Google Drive, vb.)
2. Uzaktan izleme ve bildirim sistemi
3. AI destekli içerik analizi ve organizasyon

## Güncel Çalışma Odağı

Şu anda, geliştirme odağı aşağıdaki konulardadır:
1. Temel UI bileşenlerinin modernizasyonu ve MacOS Sequoia stiline uyarlanması
2. Disk yönetimi ve izleme sisteminin güçlendirilmesi
3. Dosya transfer motorunun optimizasyonu ve güvenilirliğinin artırılması

Bu doküman, projenin ilerlemesi ve yeni kararlar alındıkça güncellenecektir. 