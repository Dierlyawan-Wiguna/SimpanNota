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

Project Simpan Nota
Nama: Dierlyawan Wiguna
NIM: 2410101013
