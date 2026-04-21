# Demo Uyeler

Bu dosya, sunum icin hazirlanan kalici demo kullanicilarini ve senaryolarini listeler.

## Kalicilik

- Demo veriler PostgreSQL uzerine yazilir.
- `docker-compose.yml` icindeki `postgres_data` volume'u sayesinde Raspberry Pi yeniden baslasa bile veriler kaybolmaz.
- Uygulama yeniden ayaga kalktiginda `DemoDataInitializer` sadece eksik demo verileri tamamlar; mevcut verileri sifirlamaz.

## Demo Giris Bilgileri

Tum demo kullanicilar icin parola aynidir:

```text
Demo123!
```

Kullanicilar:

- Admin
  - E-posta: `demo.admin@fastcheck.app`
  - Ad Soyad: `Sema Kaya`
- Ogretmen
  - E-posta: `demo.ogretmen@fastcheck.app`
  - Ad Soyad: `Mert Yildirim`
- Veli
  - E-posta: `demo.veli@fastcheck.app`
  - Ad Soyad: `Zeynep Aydin`
- Ogrenci 1
  - E-posta: `demo.ogrenci1@fastcheck.app`
  - Ad Soyad: `Ayse Aydin`
- Ogrenci 2
  - E-posta: `demo.ogrenci2@fastcheck.app`
  - Ad Soyad: `Can Demir`

## Kurulan Demo Yapisı

- Okul: `Izmir Basari Anadolu Lisesi`
- Sinif: `12-A Sayisal`
- Ogretmen `Mert Yildirim` bu sinifin ogretmenidir.
- `Ayse Aydin` ve `Can Demir` ayni sinifin ogrencileridir.
- `Zeynep Aydin` veli hesabi her iki ogrenciye de baglidir.

## Hazir Sinavlar

### 1. Hazir Sonuclu Sinav

- Sinav adi: `TYT Matematik Deneme 1`
- Durum: `READY`
- Toplam puan: `40`
- Icerik:
  - 2 ogrenci icin eslesmis 2 sinav gorseli
  - 4 adet degerlendirilmis soru
  - her ogrenci icin hazir sonuc kaydi

Beklenen sunum akisi:

- Ogretmen girisi ile sinif, ogrenciler ve hazir sinav gorulur.
- Sinav detayinda ogrenci eslesmeleri, sorular ve puanlar gorulur.
- Ogrenci girisi ile kendi sinav listesi ve soru bazli sonuclari gorulur.
- Veli girisi ile bagli ogrenciler ve onlarin son sinav performansi gorulur.

### 2. Taslak Sinav

- Sinav adi: `AYT Geometri Tarama 2`
- Durum: `DRAFT`

Bu sinav dashboard ve liste ekranlarinda "hazirlaniyor / taslak" senaryosunu gostermek icin eklenmistir.

## Rol Bazli Sunum Notlari

### Admin

- Kullanici yonetimi ve sistemdeki demo hesaplari gosterilebilir.
- Okul ile kullanicilar arasindaki baglar gosterilebilir.

### Ogretmen

- Kendi okulu ve sinifi bagli gelir.
- Sinif ogrencileri hazir gelir.
- Biri tamamlanmis, biri taslak olmak uzere iki sinav gorur.

### Ogrenci

- Kendi sinifina bagli sinavlari gorur.
- `TYT Matematik Deneme 1` icin soru ve puan detaylarini acabilir.

### Veli

- Iki ogrenciye baglidir.
- Her ogrencinin sinav ozetini ve ilgili soru detaylarini gorebilir.

## Teknik Not

Demo veriler `backend/fastcheck/src/main/java/com/fastcheck/fastcheck/config/DemoDataInitializer.java`
icinde uretilir. Bu yapi PostgreSQL uzerinde calisir ve Raspberry Pi yeniden basladiginda veri kaybi yasamadan devam eder.
