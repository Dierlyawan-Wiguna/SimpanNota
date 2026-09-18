# Architecture: SimpanNota (Digital Receipt & Warranty Manager)

Build a modern, cross-platform mobile application named **SimpanNota** (Digital Receipt & Warranty Manager).

## Purpose
Help individual users, office workers, and household managers easily secure purchase receipts, track warranty expiration timelines, and organize repair claim documents digitally without relying on fragile physical paper receipts. The application runs with a cloud backend powered by Supabase for authentication, PostgreSQL database storage, and file bucket management, coupled with scheduled local device notifications to alert users before warranties expire.

## Tech Stack
* **Client / Mobile Framework:** Flutter (Dart)
* **State Management:** Flutter Riverpod (`flutter_riverpod`)
* **Backend-as-a-Service (BaaS):** Supabase
  * **Authentication:** Supabase Auth (Email & Password)
  * **Database:** PostgreSQL with Row Level Security (RLS)
  * **File Storage:** Supabase Storage (Private Bucket: `receipts` via Signed URLs)
* **Local Notifications:** `flutter_local_notifications` + `timezone`
* **Hardware Integration:** `image_picker` (Camera & Gallery)
* **Design System:** Material Design 3 (Indonesian UI localization)

## Code & Architecture Rules
* Keep application architecture modular using a feature-first approach (`core`, `features/auth`, `features/receipts`).
* Strictly enforce manual input for product data and purchase dates. **Do not implement OCR (Optical Character Recognition) automatic scanning.**
* Enforce Supabase Row Level Security (RLS) on database tables and Storage Objects so users can strictly access only their own records and photos.
* **Naming Conventions:**
  * **PostgreSQL:** Use `snake_case` for tables, columns, and foreign keys.
  * **Dart Models & Services:** Use `camelCase` for variables, properties, getters, and methods.
  * **Classes, Enums & Widgets:** Use `PascalCase` across the entire codebase.
* Storage Bucket `receipts` must be **Private**. Do NOT expose public image URLs. Client apps must request short-lived Signed URLs for rendering photos.
* Keep UI presentation cleanly separated from data layers using Riverpod Providers/Notifiers.
* Keep UI messages, validation prompts, labels, and dialogs in **Indonesian language**.

---

### 1. User (Supabase Auth Entity)
* Mapping:
  * Dart: `id` (String), `email` (String), `createdAt` (DateTime)
  * PostgreSQL (`auth.users`): `id` (uuid), `email` (varchar), `created_at` (timestamptz)

### 2. Category (Domain Enum)
Valid stored categories:
* `elektronik` (Elektronik)
* `kendaraan` (Kendaraan)
* `pakaian` (Pakaian)
* `perabotan` (Perabotan)
* `lainnya` (Lainnya)

*(Catatan: Opsi "Semua" murni filter antarmuka UI dan DILARANG disimpan ke kolom `category` database).*

### 3. WarrantyStatus (Computed / Virtual Domain Enum)
Status garansi **tidak disimpan statis di database**, melainkan dihitung otomatis (*computed property*) di sisi aplikasi dari `tanggalBeli + durasiGaransiBulan`:
* `ACTIVE`: Sisa masa garansi > 7 hari (Badge Hijau `#2E7D32`).
* `EXPIRING_SOON`: Sisa masa garansi antara 1 sampai 7 hari (Badge Oranye `#ED6C02`).
* `EXPIRED`: Tanggal sekarang sudah melewati masa garansi (Badge Abu-abu/Merah `#D32F2F`).

### 4. Receipt (Nota Belanja & Garansi)
Mapping kolom database ke properti Dart:

| Field Dart (`camelCase`) | Kolom Postgres (`snake_case`) | Tipe Data Postgres | Batasan & Validasi |
| :--- | :--- | :--- | :--- |
| `id` | `id` | `UUID` | Primary Key, `default gen_random_uuid()` |
| `userId` | `user_id` | `UUID` | Foreign Key `auth.users(id)` **ON DELETE CASCADE** |
| `namaBarang` | `nama_barang` | `TEXT` | NOT NULL, min 1 karakter |
| `namaToko` | `nama_toko` | `TEXT` | NOT NULL, min 1 karakter |
| `tanggalBeli` | `tanggal_beli` | `DATE` | NOT NULL, tidak boleh melebihi tanggal hari ini |
| `durasiGaransiBulan`| `durasi_garansi_bulan`| `INTEGER` | NOT NULL, **CHECK (durasi_garansi_bulan > 0)** |
| `fotoPath` | `foto_path` | `TEXT` | Relatif path di bucket privat (misal: `{user_id}/{uuid}.jpg`) |
| `kategori` | `kategori` | `TEXT` | NOT NULL, CHECK IN ('elektronik', 'kendaraan', 'pakaian', 'perabotan', 'lainnya') |
| `createdAt` | `created_at` | `TIMESTAMPTZ` | NOT NULL, `default now()` |

---

## Database Rules & Security (Supabase PostgreSQL)
### 1. Skema Tabel & Constraint
```sql
create table receipts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null default auth.uid(),
  nama_barang text not null,
  nama_toko text not null,
  tanggal_beli date not null,
  durasi_garansi_bulan integer not null check (durasi_garansi_bulan > 0),
  foto_path text,
  kategori text not null check (kategori in ('elektronik', 'kendaraan', 'pakaian', 'perabotan', 'lainnya')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS Receipts Table
alter table receipts enable row level security;

create policy "Users can view and manage their own receipts"
on receipts for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
```

### 2. Aturan Relasi User & Lifecycle
* Menggunakan **`ON DELETE CASCADE`**: Jika akun pengguna dihapus dari `auth.users`, seluruh entri nota miliknya di tabel `receipts` akan terhapus otomatis dari database.

### 3. Aturan Penyimpanan Berkas Privat (Storage Security)
* Bucket `receipts` disetel sebagai **PRIVATE** (Public access dimatikan).
* Berkas disimpan dalam format isolasi path per user: `${user_id}/${receipt_id}.jpg`.
* Kebijakan RLS Storage pada `storage.objects`:
  ```sql
  create policy "Users can access their own receipt photos"
  on storage.objects for all
  using (bucket_id = 'receipts' and auth.uid()::text = (storage.foldername(name))[1])
  with check (bucket_id = 'receipts' and auth.uid()::text = (storage.foldername(name))[1]);
  ```
* Aplikasi Flutter memuat foto nota menggunakan **Signed URL** sementara (`createSignedUrl(fotoPath, 3600)`) yang memiliki batas kedaluwarsa 60 menit.

---

## Backend Rules (Supabase & BaaS Logic)
* **Row-Level Security (RLS) Enforcement:** Seluruh query SELECT, INSERT, UPDATE, dan DELETE pada tabel maupun bucket storage wajib divalidasi via RLS berdasarkan token JWT `auth.uid()`.
* **Zero Leakage:** URL gambar publik dilarang keras. Pengambilan gambar harus melewati token autentikasi atau signed URL.
* **Storage Cascading Policy:** Jika sebuah nota dihapus lewat aplikasi, berkas gambar fisiknya pada Supabase Storage wajib ikut dihapus (`storage.from('receipts').remove([fotoPath])`).
* **Input Validation Enforcement:** Durasi garansi wajib diverifikasi bernilai $\ge 1$ bulan baik pada validasi form antarmuka maupun *CHECK constraint* di database.

---

## Frontend Pages

### 1. Auth Screen (Login & Register)
* Berisi toggle antara Login dan Register menggunakan Email & Password.
* Validasi email baku dan password minimal 6 karakter.
* `AuthGate` memantau status sesi Supabase dan mengarahkan ke `HomeScreen` jika login valid.

### 2. Home Screen (Dashboard & Search)
* Filter Chips: `Semua` (pilihan UI untuk reset filter), `Elektronik`, `Kendaraan`, `Pakaian`, `Perabotan`, `Lainnya`.
* Search bar reaktif untuk menyaring `namaBarang` dan `namaToko`.
* Komponen `ReceiptCard` menghitung status garansi secara dinamis via *getter* model Dart:
  ```dart
  DateTime get tanggalKedaluwarsa => tanggalBeli.add(Duration(days: durasiGaransiBulan * 30));
  int get sisaHari => tanggalKedaluwarsa.difference(DateTime.now()).inDays;
  WarrantyStatus get statusGaransi {
    if (sisaHari < 0) return WarrantyStatus.expired;
    if (sisaHari <= 7) return WarrantyStatus.expiringSoon;
    return WarrantyStatus.active;
  }
  ```
* Pull-to-refresh untuk menyinkronkan data dengan Supabase.

### 3. Add & Edit Receipt Screen
* Form input:
  * Nama Barang & Nama Toko (Validasi wajib isi).
  * Kategori (Dropdown pilihan kategori sah, tanpa opsi "Semua").
  * Tanggal Beli (`showDatePicker`, maksimal tanggal hari ini).
  * Durasi Garansi (Input integer > 0 dengan opsi cepat: 6, 12, 24 bulan).
* Integrasi Kamera & Galeri: Upload file gambar ke bucket privat dan simpan `fotoPath` relatifnya.
* Mode Edit: Form yang sama dapat digunakan untuk memperbarui data nota lama.

### 4. Receipt Detail Screen
* Menampilkan informasi rincian lengkap nota, sisa hari, dan status garansi aktif.
* Foto nota diambil menggunakan *Signed URL* dan ditampilkan dengan `InteractiveViewer` untuk fitur zoom.
* Aksi tombol Hapus: Konfirmasi dialog -> hapus notifikasi lokal -> hapus berkas gambar di Storage -> hapus baris data di PostgreSQL.
---

## Local Notification System
* Service class mengelola `flutter_local_notifications` dan zona waktu `timezone`.
* Aturan Penjadwalan Unik: Gunakan integer hash berbasis `receipt.id` untuk ID notifikasi (contoh: `id.hashCode` untuk H-7, dan `id.hashCode + 1` untuk H-1).
* **Aturan Reschedule (Edit Data):**
  * Ketika pengguna mengubah `tanggalBeli` atau `durasiGaransiBulan`, sistem wajib membatalkan (*cancel*) ID notifikasi lama terlebih dahulu.
  * Menghitung ulang tanggal kedaluwarsa baru, lalu menjadwalkan ulang (*reschedule*) notifikasi lokal H-7 dan H-1.
* **Aturan Pembatalan (Hapus Data):**
  * Ketika nota dihapus, sistem langsung memanggil `cancel(id.hashCode)` dan `cancel(id.hashCode + 1)`.
* Notifikasi tidak akan dijadwalkan jika tanggal target (H-7 / H-1) sudah berada di masa lampau.

---

## UI Requirements
* Mengikuti pedoman Material Design 3.
* Palet warna utama: Deep Navy / Teal dengan permukaan kartu bernuansa netral.
* Aturan warna badge status garansi:
  * **Aktif (Active):** Hijau (`#2E7D32`)
  * **Hampir Habis (Expiring Soon <= 7 Hari):** Oranye (`#ED6C02`)
  * **Kedaluwarsa (Expired):** Abu-abu / Merah (`#D32F2F`)
* Lokalisasi antarmuka bahasa Indonesia untuk seluruh tombol, input, peringatan, dan label navigasi.

---

## Deliverables
* Berkas kode sumber Flutter lengkap dengan integrasi Flutter Riverpod.
* Skrip migrasi SQL Supabase (Tabel, RLS Policies, Storage bucket permissions).
* Berkas `.env.example` untuk `SUPABASE_URL` dan `SUPABASE_ANON_KEY`.
* Berkas rilis APK (`SimpanNota-v1.0.0-Release.apk`) pada milestone Minggu ke-8.
* Lembar pengujian UAT dan laporan berkala mingguan.
  
---

## Client Project Structure
```text
simpan_nota/
  android/
  ios/
  lib/
    core/
      constants/
        supabase_constants.dart
        app_colors.dart
      services/
        notification_service.dart
      widgets/
        auth_gate.dart
    features/
      auth/
        presentation/
          controllers/auth_controller.dart
          screens/auth_screen.dart
        services/
          auth_service.dart
      receipts/
        domain/
          category.dart
          warranty_status.dart
          receipt_model.dart
        presentation/
          controllers/receipt_controller.dart
          screens/
            home_screen.dart
            add_receipt_screen.dart
            receipt_detail_screen.dart
          widgets/
            receipt_card.dart
            category_chips.dart
        services/
          receipt_service.dart
          storage_service.dart
    main.dart
  pubspec.yaml
  README.md
```
---

## Core Shared Package & Module Requirements
* Seluruh model domain, enumerasi, dan kontrak transfer data ditempatkan pada modul bersama di bawah `lib/core/` dan `lib/features/receipts/domain/`.
* Modul UI (Screens & Widgets) dilarang memanipulasi *payload* mentah Map/JSON dari Supabase secara langsung; seluruh data wajib dipetakan melalui model entitas bersama.
* Hindari duplikasi definisi properti antara lapisan servis (*service layer*), pengelola *state* (Riverpod), dan tampilan antarmuka.

## Example Shared Files
```text
lib/
  core/
    constants/
      app_colors.dart
      supabase_constants.dart
  features/
    receipts/
      domain/
        category.dart
        warranty_status.dart
        receipt_model.dart
      dto/
        receipt_filter_dto.dart
        notification_payload_dto.dart
```

---

## Model Rules
* Definisikan entitas Dart (`ReceiptModel`, `WarrantyStatus`, `Category`) hanya satu kali pada lokasi domain yang telah ditentukan.
* Model `ReceiptModel` bertindak sebagai representasi data tunggal yang digunakan bersama oleh antarmuka pengguna (`HomeScreen`, `AddReceiptScreen`, `ReceiptDetailScreen`) dan servis data (`ReceiptService`).
* Serialisasi database:
  * Pemetaan dari kueri PostgreSQL Supabase ke objek Dart dilakukan melalui metode pabrik `ReceiptModel.fromMap(Map<String, dynamic> map)` (konversi `snake_case` Postgres ke `camelCase` Dart).
  * Konversi objek Dart ke format *payload* Supabase dilakukan melalui metode `ReceiptModel.toMap()` (mengembalikan format `snake_case`).
* Komponen widget tampilan murni menerima objek model yang bersifat *immutable*, bukan kueri langsung dari database.
* Status garansi (`WarrantyStatus`) merupakan *computed property* murni di sisi client, bukan kolom yang diparsing dari database.

---
