# MediaForge: Sistem Desenleri

Bu doküman, MediaForge uygulamasının mimari desenlerini, kod organizasyonunu ve temel yapıtaşlarını tanımlar.

## Mimari Desen: MVVM (Model-View-ViewModel)

MediaForge, aşağıdaki temel bileşenlere sahip MVVM (Model-View-ViewModel) mimarisini kullanmaktadır:

### Model
- Veri yapısını ve iş mantığını temsil eder
- Veri işleme ve depolama sorumluluğuna sahiptir
- Doğrudan arayüzle etkileşime girmez

### View
- Kullanıcı arayüzünü temsil eder
- SwiftUI bileşenlerinden oluşur
- ViewModel'daki verileri görüntüler ve kullanıcı etkileşimlerini ViewModel'a iletir

### ViewModel
- View ile Model arasında aracı görevi görür
- Arayüzün ihtiyaç duyduğu verileri hazırlar
- Kullanıcı etkileşimlerini işler
- @Published özellikleri ile View'ların dinamik olarak güncellenmesini sağlar

```
+-------------------+       +-------------------+       +-------------------+
|                   |       |                   |       |                   |
|       View        |<----->|    ViewModel     |<----->|      Model        |
|                   |       |                   |       |                   |
+-------------------+       +-------------------+       +-------------------+
      ^                            ^                           ^
      |                            |                           |
      |                            |                           |
+----------------------------------------------------------------------+
|                                                                      |
|                 DisksView <--> MediaForgeViewModel <--> Disk         |
|                                                                      |
+----------------------------------------------------------------------+
```

## Temel Veri Modelleri

### Disk
- Bir fiziksel veya sanal diski temsil eder
- Disk özellikleri (ad, yol, boyut, boş alan, vb.) içerir
- Disk türü (kaynaklar veya hedefler) bilgisini saklar

### FileTransfer
- Bir dosya transfer işlemini temsil eder
- Kaynak ve hedef yolları içerir
- Transfer durumu, ilerleme ve hata bilgilerini saklar
- Transfer seçenekleri ve yapılandırmasını barındırır

### TransferPreset
- Önceden tanımlanmış transfer yapılandırmalarını temsil eder
- Adlandırma kuralları, klasör yapıları, doğrulama yöntemleri gibi ayarları içerir
- Tekrar kullanılabilir transfer profilleri sağlar

## Yönetici Sınıflar ve Desenleri

MediaForge, sistemin farklı yönlerini yönetmek için özel yönetici sınıflar kullanır:

### DiskManager
- **Sorumluluk:** Disk algılama, izleme ve erişim
- **Desen:** Singleton (tüm uygulama için tek örnek)
- **Özellikler:**
  - Disk durumu değişikliklerini izler
  - Disk bağlama/çıkarma olaylarını bildirir
  - Disk bilgilerini toplar ve sunar

### FileTransferManager
- **Sorumluluk:** Dosya transferi operasyonları
- **Desen:** Singleton ve Façade (çeşitli alt sistemlerin basitleştirilmiş arayüzü)
- **Özellikler:**
  - Transfer kuyruk yönetimi
  - Paralel transfer yönetimi
  - Checksum doğrulama
  - Hata işleme ve kurtarma

## Veri Akışı Desenleri

### Reaktif Güncelleme
MediaForge, SwiftUI'nin @State, @Published, @ObservedObject gibi özelliklerini kullanarak reaktif veri akışını destekler. Veriler değiştiğinde, ilgili arayüz bileşenleri otomatik olarak güncellenir.

### Publisher-Subscriber Deseni
NotificationCenter aracılığıyla uygulama içi olaylar için Publisher-Subscriber deseni kullanılır. Bu, farklı bileşenler arasında gevşek bağlantı sağlar.

## Eşzamanlılık Desenleri

### İş Parçacığı Güvenli Veri Erişimi
FileTransferManager, birden fazla transfer işlemini paralel olarak yürütürken iş parçacığı (thread) güvenliğini sağlayan yapılar kullanır:

- DispatchQueue: Belirli görevleri farklı kuyruklar üzerinde çalıştırmak için
- Actor yapıları: İş parçacığı güvenli erişim için (Swift 5.5+)
- Atomik işlemler: Paylaşılan durumlar için güvenli erişim

### Asenkron İşlemler
Dosya sistem erişimi, checksum hesaplama gibi yoğun işlemler arka plan iş parçacıklarında asenkron olarak gerçekleştirilir:

- Task ve async/await: Modern asenkron programlama için (Swift 5.5+)
- Completion handlers: Geriye dönük uyumluluk için
- Progress nesneleri: İlerleme izleme ve iptal desteği için

## Hata İşleme Desenleri

### Result Tipi
Hata işleme için Result<Success, Failure> türü kullanılır, bu da başarı ve başarısızlık durumlarını net bir şekilde ifade etmeyi sağlar.

### Hiyerarşik Hata Tipleri
Her bileşen kendi hata tipleri kümesine sahiptir, bunlar hataların daha açıklayıcı ve spesifik olmasını sağlar:

```swift
enum DiskError: Error {
    case accessDenied
    case notMounted
    case insufficientSpace
    // ...
}

enum TransferError: Error {
    case sourceNotFound
    case destinationNotWritable
    case checksumMismatch(expected: String, actual: String)
    // ...
}
```

## UI Desenleri

### Kompozisyon
SwiftUI görünümleri, daha küçük, yeniden kullanılabilir bileşenlerden oluşturulur:

```swift
struct DiskView: View {
    var disk: Disk
    
    var body: some View {
        VStack {
            DiskIconView(type: disk.type)
            DiskInfoView(name: disk.name, path: disk.path)
            DiskCapacityView(used: disk.usedSpace, total: disk.totalSpace)
        }
    }
}
```

### Adaptif Arayüz
Arayüz, farklı ekran boyutlarına ve düzenlerine uyum sağlar:

- GeometryReader: Dinamik boyutlandırma için
- Koşullu görünümler: Farklı durumlar için uygun UI gösterimi
- Dinamik yazı tipi boyutları: Erişilebilirlik için

## Dosya ve Klasör Yapısı

MediaForge projesi aşağıdaki mantıksal klasör yapısını kullanır:

```
MediaForge/
├── MediaForgeApp.swift       # Uygulama giriş noktası
├── ContentView.swift         # Ana uygulama görünümü
├── Models/                   # Veri modelleri
│   ├── Disk.swift
│   ├── FileTransfer.swift
│   ├── TransferPreset.swift
│   ├── CameraFormat.swift
│   ├── CustomElement.swift
│   └── MediaForgeViewModel.swift
├── Views/                    # UI bileşenleri
│   ├── DisksView.swift
│   ├── TransfersView.swift
│   ├── SettingsView.swift
│   └── ...
├── Helpers/                  # Yardımcı sınıflar
│   ├── DiskManager.swift
│   ├── FileTransferManager.swift
│   ├── MediaHashList.swift
│   └── XXHasher.swift
└── Resources/                # Kaynaklar ve varlıklar
    ├── Assets.xcassets
    └── ...
```

Bu sistem desenleri, MediaForge uygulamasının ölçeklenebilir, sürdürülebilir ve test edilebilir olmasını sağlar. Proje geliştikçe, bu desenler yeni gereksinimlere uyum sağlayacak şekilde güncellenecektir. 