# SimpanNota - Digital Receipt & Warranty Manager

Aplikasi mobile universal untuk menyimpan struk belanja fisik, melacak tanggal kedaluwarsa garansi produk, dan mengamankan bukti klaim perbaikan.

## Perencanaan Proyek (12 Pertemuan)

### 1. Deskripsi Masalah
Masyarakat sering gagal melakukan klaim garansi karena struk fisik/kartu garansi kertas hilang, rusak, atau tintanya memudar seiring waktu. Tidak ada wadah penyimpanan digital sederhana khusus untuk mendata inventaris barang bergaransi beserta tanggal kedaluwarsanya.

### 2. Profil Target Pengguna
* **Primer:** Masyarakat umum, pekerja kantoran, dan kepala keluarga (usia 22–60 tahun).
* **Karakteristik:** Memiliki ponsel pintar, sering kerepotan menyimpan kertas nota belanja kecil, dan ingin mengamankan hak klaim garansi produk.

### 3. Manfaat Aplikasi
* **Kemudahan Klaim Garansi:** Semua bukti pembelian tersimpan digital dalam satu tempat.
* **Bebas Struk Pudar:** Menghilangkan ketergantungan pada kertas fisik yang mudah rusak.
* **Manajemen Aset Pribadi:** Membantu mengetahui kapan masa garansi barang berharga akan habis.

### 4. Daftar Fitur Inti
* **Unggah Foto Nota/Kartu Garansi:** Mengambil foto struk belanja menggunakan kamera HP atau memilih dari galeri.
* **Pencatatan Detail Produk:** Input manual nama barang, toko, tanggal pembelian, dan durasi garansi.
* **Pengingat Kedaluwarsa Garansi:** Notifikasi otomatis di HP ketika masa garansi akan habis (H-7 atau H-1).
* **Daftar & Kategori Barang:** Mengelompokkan barang berdasarkan kategori (Elektronik, Kendaraan, Pakaian, dll) dengan fitur pencarian.

### 5. Fitur yang Tidak Dikerjakan (Out of Scope)
* **OCR (Optical Character Recognition) Otomatis:** Input nama dan tanggal tetap manual (tidak discan otomatis oleh AI).
* **Sinkronisasi Cloud Skala Besar:** Data hanya disimpan di database lokal ponsel (SQLite/Room/Firebase dasar 1 akun).
* **Integrasi E-Receipt Otomatis:** Tidak terhubung dengan sistem kasir toko ritel eksternal.

### 6. Kriteria Aplikasi Dinyatakan Berhasil
* **Fungsional:** Pengguna berhasil mengambil foto nota, mengisi data garansi, dan menyimpannya tanpa eror.
* **Navigasi:** Pengguna dapat mencari barang berdasarkan kategori dalam waktu kurang dari 5 detik.
* **Notifikasi:** Sistem pengingat waktu garansi berfungsi memberikan notifikasi lokal di perangkat secara tepat.

### Project Simpan Nota
* **Nama:** Dierlyawan Wiguna
* **NIM:** 2410101013

---

## 🚀 Panduan Menjalankan Proyek (Dosen, Reviewer & Pengembang)

Proyek **SimpanNota** dibangun dengan arsitektur toleran (*fault-tolerant*), sehingga dapat langsung dijalankan oleh Dosen/Reviewer **tanpa konfigurasi yang rumit**.

### 📋 Prasyarat Lingkungan
* Flutter SDK (Versi `>= 3.13.0`)
* Dart SDK (Versi `>= 3.13.0`)
* Android Device / Emulator / Chrome Browser

---

### 🔹 Opsi 1: Menjalankan Langsung (Mode Evaluasi Cepat - Tanpa Setup Supabase)
> **Rekomendasi untuk Dosen / Reviewer**: Anda tidak perlu mendaftar atau menyetel backend Supabase. Aplikasi otomatis mendeteksi ketiadaan konfigurasi cloud dan langsung beralih ke **Database SQLite Lokal ponsel**.

1. Buka folder proyek di terminal, lalu unduh dependensi:
   ```bash
   flutter pub get
   ```
2. Jalankan aplikasi pada perangkat/emulator:
   ```bash
   flutter run
   ```
3. **Fitur yang Langsung Dapat Dinilai:**
   - Tambah nota dengan foto dari Galeri / Kamera fisik.
   - Perhitungan otomatis sisa hari dan status masa garansi (Aktif, Segera Habis, Kedaluwarsa).
   - Pengelompokan & Filter Cepat (Elektronik, Kendaraan, Pakaian, Perabotan, Lainnya).
   - Pencarian real-time nama barang dan nama toko.
   - Toggle Tema Terang & Mode Gelap (Dark Mode).
   - Layar adaptif (List di HP, Grid di layar lebar/tablet).

---

### 🔹 Opsi 2: Menjalankan Pengujian Otomatis (Code Review & Testing)
Dosen/Reviewer dapat memverifikasi kualitas kode dan kelulusan seluruh modul pengujian melalui terminal:

1. **Analisis Statis Kode (Harus 0 issues / Bersih):**
   ```bash
   flutter analyze
   ```
2. **Menjalankan Seluruh Unit & Widget Tests (46/46 Passed - 100% Green):**
   ```bash
   flutter test
   ```
3. **Dokumentasi Lengkap Praktikum:**
   - Panduan UI/UX Lanjutan: [REVIEWER_GUIDE_P8.md](file:///e:/Project%20SimpanNota/SimpanNota/REVIEWER_GUIDE_P8.md)
   - Panduan Refactoring & Testing DRY / SoC: [REVIEWER_GUIDE_P9.md](file:///e:/Project%20SimpanNota/SimpanNota/REVIEWER_GUIDE_P9.md)
   - Spesifikasi Arsitektur Sistem: [Architecture.md](file:///e:/Project%20SimpanNota/SimpanNota/Architecture.md)

---

### 🔹 Opsi 3: Menjalankan dengan Backend Cloud Supabase (Opsional)
Jika Dosen/Reviewer atau Pengembang ingin menguji sinkronisasi cloud:
1. Salin file template environment:
   ```bash
   cp .env.example .env
   ```
2. Isi kredensial Supabase Anda di dalam file `.env`:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```
3. Jalankan aplikasi dengan parameter environment:
   ```bash
   flutter run --dart-define-from-file=.env
   ```
*(Untuk pengembang internal dengan file kredensial lokal aktif, cukup jalankan `flutter run` atau tekan `F5` di VS Code).*

