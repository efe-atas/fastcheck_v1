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