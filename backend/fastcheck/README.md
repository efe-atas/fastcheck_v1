# FastCheck Backend API (Education Module)

Bu dokuman son eklenen egitim akis endpointlerini ozetler.

## Auth

- `POST /auth/register`
  - Sadece ilk kurulum admin olusturmak icin.
- `POST /auth/login`
- `POST /auth/refresh`
- `POST /auth/admin/users`
  - `ROLE_ADMIN` ile teacher/student/parent/admin hesap acma.

## Admin Endpoints

- `POST /v1/admin/schools`
  - Okul olusturur.
- `POST /v1/admin/users/{userId}/schools/{schoolId}`
  - Kullaniciyi okula baglar.
- `POST /v1/admin/parent-student-links`
  - Parent ile student iliskisi kurar.
- `GET /v1/admin/parents/{parentUserId}/students`
  - Parent'e bagli ogrencileri listeler.

## Teacher Endpoints

- `POST /v1/teacher/classes`
  - Ogretmen kendi okulunda sinif olusturur.
- `GET /v1/teacher/classes`
  - Ogretmenin siniflarini (`examCount` ile) listeler.
- `POST /v1/teacher/classes/{classId}/students`
  - Sinifa ogrenci ekler.
- `GET /v1/teacher/classes/{classId}/students`
  - Sinif roster (ogrenci listesi).
  - Query: `page` (default `0`), `size` (default `20`), `name` (opsiyonel ad-soyad arama).
- `POST /v1/teacher/classes/{classId}/exams`
  - Sinav olusturur.
- `GET /v1/teacher/classes/{classId}/exams`
  - Sinifin sinavlarini listeler.
- `POST /v1/teacher/exams/{examId}/images`
  - Sinav goruntulerini yukler, asenkron OCR tetikler.
- `GET /v1/teacher/exams/{examId}`
  - Sinav status + image status + OCR job status izleme.
- `GET /v1/teacher/dashboard`
  - Ogretmenin sinif/sinav toplamlari, son OCR durumlari ve eylem onerilerini dondurur.

## Student Endpoints

- `GET /v1/student/exams`
  - Ogrencinin sinifina ait tum sinavlar (`status` + `createdAt`) listesi.
  - Query: `page` (default `0`), `size` (default `20`), `examStatus` (opsiyonel: `DRAFT|PROCESSING|READY|FAILED`).
- `GET /v1/student/exams/{examId}/questions`
  - Sinav sorulari.
- `GET /v1/student/dashboard`
  - Toplam/durum bazli sinav sayilari ile son 5 sinavin basligi.

## Parent Endpoints

- `GET /v1/parent/students/{studentId}/exams`
  - Veliye bağlı öğrencinin sınavlarını listeler.
  - Query: `page` (default `0`), `size` (default `20`), `examStatus` (opsiyonel: `DRAFT|PROCESSING|READY|FAILED`).
- `GET /v1/parent/students/{studentId}/exams/{examId}/questions`
  - Bagli ogrencinin sinav sorulari.
- `GET /v1/admin/parents/{parentUserId}/students`
  - `ROLE_PARENT` kendi `parentUserId` degeri ile cagirdiginda kendi ogrencilerini gorebilir.
- `GET /v1/parent/dashboard`
  - Veliye bagli ogrencilerin ozet bilgisi (sinav toplamlari, son sinav durumu, `latestExamId`) ve kart listesi.

## File Endpoint

- `GET /files/{fileName}`
  - OCR servisi icin yuklenen gorsellerin public erisimi.

## Notes

- OCR akisi asenkron calisir ve `ExamStatus` ile takip edilir.
- `GET /v1/teacher/exams/{examId}` endpointi OCR job retry/error durumlarini da dondurur.
- Varsayilan local upload yolu: `app.files.storage-path` (`uploads/exams`).
- `mock-ocr` Spring profili ile (`SPRING_PROFILES_ACTIVE=mock-ocr`) FastAPI baglantisi olmadan demo OCR sonucu uretebilirsiniz.
- H2 demo verisi icin `docs/seeds/h2-demo-data.sql` dosyasini uygulayabilirsiniz.

## API Collections

- Postman collection: `docs/postman/FastCheck-Education.postman_collection.json`
- Insomnia export: `docs/insomnia/FastCheck-Education.insomnia.json`

Postman notu:
- `Auth -> Login` request'inde `Tests` scripti vardir.
- Basarili login sonrasi `accessToken` otomatik set edilir.
- `role` alanina gore otomatik olarak `adminToken`, `teacherToken`, `studentToken` veya `parentToken` collection variable'lari guncellenir.
