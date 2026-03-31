## Fastcheck Projesi

Bu repo, çoklu frontend ve backend bileşenlerinden oluşan bir örnek projedir.

### Reponun İndirilmesi ve Çalıştırılması

- **Repo’yu ilk kez alma (`clone`)**:
  ```bash
  git clone <BU_REPO_URLU>
  cd fastcheck
  ```
- **Var olan projeyi güncelleme (`pull`)**:
  ```bash
  git pull
  ```
  `git pull`, reponun zaten klonlandığı bir klasörde, uzak repodaki son değişiklikleri yerel projenize çeker (özellikle ekip/collab ortamında kullanılır).
- **Backend / frontend başlatma**: Her klasörün içinde kendi `README` veya dokümantasyonuna göre bağımlılıkları yükleyip (`npm install`, `pip install` vb.) ilgili komutla (`npm run dev`, `python main.py` vb.) çalıştırın.

### Klasör Yapısı

- **backend/**: API, veritabanı erişimi ve sunucu tarafı iş mantığını barındırır.
- **frontend/**: Web tarayıcısı için geliştirilmiş kullanıcı arayüzü kodlarını içerir.
- **frontend_mobile/**: Mobil uygulama arayüzü (ör. React Native, Flutter vb.) için kullanılan kodları içerir.
- **ai/**: Makine öğrenimi / yapay zeka modelleri, veri işleme ve ilgili yardımcı betikleri tutar.

### Mobil / Backend Bağlantısı

- Mobil uygulama `frontend_mobile/lib/core/constants/api_constants.dart` içindeki `DEV_MACHINE_IP` değişkenine göre backend’e bağlanır.  
  - iOS simülatörü için varsayılan `127.0.0.1` yeterlidir.  
  - Android emülatörü için `10.0.2.2` otomatik seçilir.  
  - Fiziksel cihaz kullanıyorsanız backend çalışan makinenin LAN IP adresini `flutter run --dart-define=DEV_MACHINE_IP=192.168.x.x` ile geçin.
- Backend CORS politikası `app.cors.allowed-origins` environment değişkeni ile ayarlanabilir (örn. `http://localhost:3000,http://127.0.0.1:5173`). Varsayılan değer tüm origin’leri kabul eder ve mobil geliştirme sırasında ek yapılandırma gerektirmez.

### Backend API Dokümantasyonu ve Seed Verileri

- Spring Boot uygulaması ayağa kalktığında OpenAPI dokümanı `http://localhost:8080/swagger-ui/index.html` adresinde yayınlanır. Bu sözleşme mobil istemcinin `ApiConstants` dosyası ile birebir uyumludur.
- H2 üzerinde hızlı demo verileri oluşturmak için `backend/fastcheck/docs/seeds/h2-demo-data.sql` dosyasını kullanabilirsiniz. Script içinde örnek admin / öğretmen / öğrenci / veli hesapları ve ilişkili okul/sınıf kayıtları bulunmaktadır.
