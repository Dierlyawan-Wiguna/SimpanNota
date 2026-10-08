# Implementasi Local Data & Persistence (Pertemuan 5)

Dokumen ini disusun sebagai panduan bagi dosen/reviewer untuk memudahkan proses pemeriksaan tugas Pertemuan 5 pada proyek **SimpanNota**. Seluruh fungsionalitas CRUD (Create, Read, Update, Delete) kini telah diimplementasikan menggunakan arsitektur *Local Data Persistence* dengan SQLite (melalui package `sqflite` dan `path`).

---

## 📍 Posisi Code (Sesuai Instruksi)

Berikut adalah daftar lokasi file kunci yang menangani implementasi basis data lokal, *state management*, hingga antarmuka pengguna (UI).

### 1. Data Model (Entitas)
Mengubah struktur data agar dapat diubah ke dalam bentuk Map (JSON) dan sebaliknya, sehingga kompatibel dengan format tabel SQLite.
- **File:** `lib/features/receipts/domain/receipt.dart`
- **Fungsi Utama:** `toMap()` dan `fromMap(Map<String, dynamic> map)`

### 2. Local Data / Storage
Kelas *Database Helper* yang mengelola koneksi langsung ke SQLite, pembuatan tabel, serta eksekusi *query* CRUD secara mandiri.
- **File:** `lib/core/local/database_helper.dart`
- **Fungsi CRUD:** 
  - **Create:** `insertReceipt(Receipt receipt)`
  - **Read:** `getReceipts()`
  - **Update:** `updateReceipt(Receipt receipt)`
  - **Delete:** `deleteReceipt(int id)`

### 3. State Management / Repository Penghubung
Bertindak sebagai jembatan yang menghubungkan instruksi dari antarmuka (UI) menuju operasi *Database Helper*, sekaligus menangani status asinkron (Loading, Data, Error) menggunakan Riverpod.
- **Repository:** `lib/features/receipts/services/receipt_repository.dart`
- **State Notifier:** 
  - `lib/features/receipts/presentation/controllers/receipt_list_notifier.dart` *(Mengelola Read, Delete, Filter, dan Pencarian)*
  - `lib/features/receipts/presentation/controllers/add_receipt_notifier.dart` *(Mengelola logika form Create dan Update)*

### 4. UI (Frontend) Pemicu CRUD
Antarmuka interaktif yang dipicu oleh tindakan pengguna untuk memanggil fungsi *State Management*.
- **Read (Dashboard):** `lib/features/receipts/presentation/screens/home_screen.dart` *(Menampilkan list nota dari SQLite).*
- **Create & Update (Form):** `lib/features/receipts/presentation/screens/add_receipt_screen.dart` *(Form dinamis untuk tambah & ubah nota).*
- **Delete (Detail Nota):** `lib/features/receipts/presentation/screens/receipt_detail_screen.dart` *(Ikon Hapus yang akan memicu `deleteReceipt`).*

---

## 🧪 Panduan Persistence Test

Untuk membuktikan bahwa data nota benar-benar tersimpan ke dalam penyimpanan fisik perangkat (persistence) dan bukan sekadar berada di dalam memori sementara (RAM), Anda dapat melakukan skenario 3 langkah berikut:

1. **Tambahkan Data Baru**
   Buka aplikasi dan buat satu nota baru (misal: "Laptop Baru"). Isi detailnya, lalu tekan "Simpan". Pastikan nota tersebut muncul di daftar halaman Dashboard.
2. **Matikan Aplikasi Secara Paksa (Force Close)**
   Tutup paksa aplikasi dengan cara mengusapnya (swipe) dari daftar aplikasi terbaru (Recent Apps/Task Manager) di emulator atau perangkat fisik Anda. Pastikan proses aplikasi benar-benar terhenti.
3. **Verifikasi Keutuhan Data**
   Buka kembali aplikasi SimpanNota. Data "Laptop Baru" yang Anda buat pada langkah pertama harus tetap muncul dan bertahan di halaman Dashboard, membuktikan bahwa aplikasi sukses melakukan inisialisasi ulang data langsung dari database SQLite lokal.

---
*Terima kasih telah melakukan peninjauan (review) pada tugas ini.*
