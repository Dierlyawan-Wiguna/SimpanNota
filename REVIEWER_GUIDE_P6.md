# Implementasi Integrasi API & Unit Testing (Pertemuan 6)

Dokumen ini disusun sebagai panduan *checklist* bagi dosen/reviewer untuk memudahkan proses evaluasi tugas Pertemuan 6 pada proyek **SimpanNota**.

---

## 🌐 1. Koneksi ke API, Parsing Data, & 5 State UI

Integrasi API berbasis HTTP telah diimplementasikan secara *vertical slice* menggunakan arsitektur repositori yang memisahkan logika *network* dari antarmuka (UI).

- **Operasi HTTP (GET & POST):** Terletak pada file `lib/features/receipts/services/receipt_repository.dart`. 
  * Fungsi `getReceipts()` melakukan *request* `http.get()` ke Mock REST API, sedangkan fungsi penambahan data menggunakan `http.post()`. Repository juga menyertakan logika *Error Handling* untuk memunculkan Exception khusus (contoh: status HTTP 500 atau 404).
- **Parsing Data Model (JSON):** Terletak pada file `lib/features/receipts/domain/receipt.dart`.
  * Kelas `Receipt` dilengkapi dengan `factory Receipt.fromJson()` dan method `toJson()` yang kokoh (memiliki *fallback* nilai *default*) untuk memastikan *parsing* berjalan aman dari *crash* bila ada *field* tipe data API yang hilang.
- **Implementasi 5 State UI:** Terhubung pada file `lib/features/receipts/presentation/screens/home_screen.dart`.
  * UI telah dikonfigurasi reaktif menggunakan Riverpod untuk menangani 5 kondisi wajib dari API secara nyata: **Loading** (CircularProgressIndicator), **Success** (Menampilkan list nota), **Empty** (Pesan list kosong), **Error** (Pesan gagal memuat), dan tombol **Retry** (Coba Lagi) untuk memicu ulang *fetch* API.

---

## 🧪 2. Implementasi Unit Test

Aplikasi ini telah memuat berkas Unit Test khusus (menggunakan `http/testing.dart` dengan *MockClient*) untuk menguji logika koneksi API dan respon Model secara lokal tanpa memanggil *endpoint* internet yang asli. 

**Lokasi File Test:** `test/receipt_api_test.dart`

Berikut adalah 6 buah skenario (Test Blocks) yang telah dibuat:
1. **Model valid:** Memastikan fungsi `fromJson` berhasil mem-parsing JSON utuh.
2. **Model invalid:** Memastikan model aman dari *crash* dan memberikan *default fallback* bila ada *field* JSON yang salah tipe/hilang.
3. **API sukses:** Menguji kelancaran `getReceipts()` mengembalikan List data saat respon status 200 OK.
4. **Data kosong:** Menguji API berhasil mengembalikan list `[]` ketika respon 200 OK berisi *array* kosong.
5. **HTTP gagal:** Menguji kemunculan leparan *Exception* ketika HTTP merespon dengan status 404/500 Server Error.
6. **JSON rusak:** Menguji aplikasi tidak rusak/berhenti saat API merespon *malformed JSON* (string terpotong/cacat), melainkan melempar `Exception` yang jelas ke UI.

---

### 💻 Cara Menguji Unit Test (Untuk Reviewer)
Reviewer dapat membuktikan keberhasilan (Passed) dari keenam poin Unit Test di atas secara instan, cukup dengan menyalin dan menjalankan perintah terminal tunggal di bawah ini:

```bash
flutter test test/receipt_api_test.dart