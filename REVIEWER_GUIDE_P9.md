# PANDUAN PENGUJIAN & REFACTORING ARSITEKTUR (REVIEWER GUIDE - PRAKTIKUM 9)
## Aplikasi SimpanNota — Testing & Refactoring: DRY & Separation of Concerns

Dokumen panduan ini disusun sebagai laporan komprehensif bagi Dosen Penguji / Reviewer dalam memverifikasi hasil pelaksanaan **Testing dan Refactoring (Pertemuan 9)** pada aplikasi **SimpanNota**, dengan fokus utama pada:
1. **Avoid Duplikasi Code (DRY - Don't Repeat Yourself)**
2. **Pemisahan Tanggung Jawab (Separation of Concerns & Single Responsibility Principle)**
3. **Siklus 4 Langkah Aman (Safe 4-Step Refactoring Cycle with Atomic Commits)**

---

## 📋 Ringkasan Hasil Pengujian Akhir
- **Status `flutter analyze`**: **0 Issues / No issues found!** (Bersih dari error, warning, dan info deprecated).
- **Status `flutter test`**: **46/46 Unit & Widget Tests LULUS (100% Green)**.
- **Atomic Git Commits**: 5 tahapan commit terisolasi dan deskriptif.

---

## 1. Daftar Duplikasi Kode yang Dieliminasi (DRY)

Sebelum refactoring, audit kode menemukan sejumlah logika berulang lintas fitur (`features/auth`, `features/profile`, `features/receipts`, dan `core`):

### A. Aturan Validasi Input & Formatting Nomor Telepon
- **Sebelum**: Aturan regex validasi email, panjang kata sandi minimal 6 karakter, nama minimal 2 karakter, serta manipulasi string awalan telepon (`+62`, `08`, `62`) ditulis manual secara terpisah di `auth_screen.dart` dan `profile_screen.dart`.
- **Sesudah**: Diekstrak ke dalam modul pure function terpusat:
  - `lib/core/utils/input_validator.dart`: Validator generik lintas fitur (`validateEmail`, `validatePassword`, `validateConfirmPassword`, `validateName`, `normalizePhoneNumber`, `formatIndonesianPhone`, `validatePhoneNumber`).
  - `lib/features/profile/domain/profile_validator.dart`: Validator spesifik domain profil pengguna (`validateDisplayName`, `cleanPhoneForInput`, `validatePhoneNumber`, `validatePasswordChange`).

#### Perbandingan Kode (Sebelum vs Sesudah):
```dart
// ❌ SEBELUM (Duplikasi di auth_screen.dart & profile_screen.dart):
// Masing-masing file menulis regex dan logika pembersihan sendiri:
String clean = raw.replaceAll(RegExp(r'\D'), '');
if (clean.startsWith('62')) clean = clean.substring(2);
if (clean.startsWith('0')) clean = clean.substring(1);
if (clean.length < 9) {
  return 'Nomor minimal 9 digit';
}

// ✅ SESUDAH (Terpusat & Bersih di InputValidator):
final phoneError = InputValidator.validatePhoneNumber(rawPhone, isRequired: true);
final normalized = InputValidator.normalizePhoneNumber(rawPhone);
final formattedDisplay = InputValidator.formatIndonesianPhone(normalized);
```

---

### B. Panggilan API Supabase Auth & Metadata User
- **Sebelum**: `profile_screen.dart` memanggil `Supabase.instance.client.auth.updateUser(...)`, `UserAttributes(...)`, dan parsing metadata mentah `Map<String, dynamic>` secara langsung di dalam method UI.
- **Sesudah**: Diekstrak ke dalam data/service repository:
  - `lib/features/profile/services/profile_repository.dart`: Kelas `ProfileRepository` dan Riverpod provider `profileRepositoryProvider`.
  - `lib/features/profile/domain/user_profile.dart`: Immutable domain entity `UserProfile`.

#### Perbandingan Kode (Sebelum vs Sesudah):
```dart
// ❌ SEBELUM (profile_screen.dart memanggil Supabase langsung di UI):
await Supabase.instance.client.auth.updateUser(
  UserAttributes(
    data: {
      'full_name': name,
      'phone': cleanPhone,
    },
  ),
);

// ✅ SESUDAH (profile_screen.dart mendelegasikan ke ProfileRepository):
await ref.read(profileRepositoryProvider).updateProfile(
  displayName: data.name,
  phone: data.phone,
);
```

---

### C. Boilerplate Notifikasi UI (SnackBar)
- **Sebelum**: Penulisan widget `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))` berulang lebih dari 25 kali di berbagai layar dengan konfigurasi inline yang panjang (warna background, icon row, border radius, durasi, floating behavior).
- **Sesudah**: Dibuat utilitas UI terpusat di `lib/core/utils/app_snackbar.dart`:
  - `AppSnackBar.showSuccess(context, message)`
  - `AppSnackBar.showError(context, message)`
  - `AppSnackBar.showInfo(context, message)`
  - `AppSnackBar.showWarning(context, message)`

#### Perbandingan Kode (Sebelum vs Sesudah):
```dart
// ❌ SEBELUM (15+ baris boilerplate setiap kali menampilkan SnackBar):
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Row(
      children: [
        Icon(Icons.check_circle_outline, color: Colors.white),
        SizedBox(width: 8),
        Text('Profil berhasil diperbarui!'),
      ],
    ),
    backgroundColor: Colors.green.shade600,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
);

// ✅ SESUDAH (1 baris deklaratif dan seragam di seluruh aplikasi):
AppSnackBar.showSuccess(context, 'Profil berhasil diperbarui!');
```

---

## 2. Pemisahan Tanggung Jawab (Separation of Concerns & SRP)

Arsitektur fitur `profile` (`lib/features/profile/`) kini distrukturkan ulang secara ketat agar selaras dengan pola bersih (*Clean/Feature-First Architecture*) pada `lib/features/receipts/`:

```text
lib/features/profile/
├── domain/
│   ├── user_profile.dart           <-- Domain Entity (Data Contract)
│   └── profile_validator.dart      <-- Pure Validation Rules
├── services/
│   └── profile_repository.dart     <-- Data/API Layer (Supabase & Local)
└── presentation/
    ├── screens/
    │   └── profile_screen.dart     <-- Screen Orchestrator & Layout
    └── widgets/
        ├── profile_form.dart       <-- UI Form & State Controller
        └── password_form_dialog.dart <-- Password Form & State Controller
```

### Penjelasan Tanggung Jawab Tiap Komponen:

1. **`ProfileForm` (`lib/features/profile/presentation/widgets/profile_form.dart`)**:
   - **Tanggung Jawab Tunggal**: Menangani input pengguna, controller text field, validasi form lokal, dan status UI (loading state, error message, disabled state pada tombol).
   - **Batasan Tegas**: Tidak memiliki dependensi pada Supabase client atau network request langsung. Menggunakan callback deklaratif `onSubmit(ProfileFormData data)` dan `onCancel()`.
   - **Kemudahan Pemakaian**: Dilengkapi factory static helper `ProfileForm.showAsDialog(context, initialName, initialPhone, onSubmit)`.

2. **`PasswordFormDialog` (`lib/features/profile/presentation/widgets/password_form_dialog.dart`)**:
   - **Tanggung Jawab Tunggal**: Menangani formulir ubah kata sandi, visibility toggle sandi, validasi kesesuaian antara sandi baru dan konfirmasi sandi, serta status loading saat pengiriman.

3. **`ProfileValidator` (`lib/features/profile/domain/profile_validator.dart`)**:
   - **Tanggung Jawab Tunggal**: Berisi *pure functions* deterministik untuk memvalidasi nama pengguna, format nomor telepon Indonesia, dan aturan pergantian kata sandi.
   - **Batasan Tegas**: Tanpa referensi Flutter UI (`BuildContext`, `Widget`), murni menggunakan tipe data Dart dasar sehingga 100% dapat diuji melalui Unit Test murni tanpa overhead widget rendering.

4. **`ProfileRepository` (`lib/features/profile/services/profile_repository.dart`)**:
   - **Tanggung Jawab Tunggal**: Bertindak sebagai *Single Source of Truth* untuk interaksi data profil ke Supabase Auth, storage avatar, pergantian password, dan sign out.
   - **Batasan Tegas**: Terisolasi sepenuhnya dari `profile_screen.dart` dan dapat diinjeksi (*mockable*) pada unit testing menggunakan mock client.

5. **Pemecahan Fungsi-Fungsi Gemuk**:
   - Method `_editProfileDialog()` dan `_changePasswordDialog()` di `profile_screen.dart` yang sebelumnya memuat ratusan baris inline dialog tree kini dipangkas menjadi pemanggilan deklaratif modular masing-masing 15 baris kode.

---

## 3. Log Eksekusi Siklus 4 Langkah Aman (Safe 4-Step Cycle)

Seluruh proses refactoring dieksekusi secara bertahap melalui siklus 4 langkah aman:

```
[1. Tes Awal Lulus] ➔ [2. Pindahkan Satu Bagian] ➔ [3. Tes Ulang & Tambah Tes] ➔ [4. Atomic Commit]
```

### Riwayat Eksekusi Bertahap:

#### 🟢 Tahap 0: Baseline Tests & Baseline Green
- Mengatasi perbedaan environment test bawaan pada `ReceiptRepository` dan overflow viewport kecil pada `HomeScreen`.
- Menulis baseline test `test/profile_baseline_test.dart` (3 widget test kasus pengujian rendering profile, dialog ubah profile, dan dialog ubah sandi).
- **Hasil Test**: 32/32 tests passed.
- **Commit**: `e2f1add` — `test(profile): add baseline tests before refactoring`

#### 🟢 Tahap 1: Ekstraksi Modul Validasi (DRY Validation)
- Memindahkan aturan validasi ke `lib/core/utils/input_validator.dart` dan `lib/features/profile/domain/profile_validator.dart`.
- Menambahkan 8 unit test di `test/validators_test.dart`.
- Memperbarui `auth_screen.dart` dan `profile_screen.dart`.
- **Hasil Test**: 40/40 tests passed.
- **Commit**: `c4d2315` — `refactor(validation): extract input validation rules and eliminate duplication`

#### 🟢 Tahap 2: Ekstraksi Data Layer (ProfileRepository)
- Membuat domain entity `UserProfile` dan service `ProfileRepository`.
- Menambahkan 6 unit test di `test/profile_repository_test.dart` (dengan mock Supabase / offline fallback verification).
- Mengganti pemanggilan langsung Supabase di `profile_screen.dart` menjadi `ref.read(profileRepositoryProvider)`.
- **Hasil Test**: 46/46 tests passed.
- **Commit**: `774dcff` — `refactor(profile): extract profileRepository for API requests`

#### 🟢 Tahap 3: Ekstraksi UI & State Form (ProfileForm Widget)
- Membuat widget `ProfileForm` dan `PasswordFormDialog` di `lib/features/profile/presentation/widgets/`.
- Menambahkan 5 widget test di `test/widgets/profile_form_test.dart` (pengujian input awal, validasi lokal, loading state, tombol batal, dan callback submit).
- Memecah method dialog panjang di `profile_screen.dart`.
- **Hasil Test**: 46/46 tests passed.
- **Commit**: `7f9d9f7` — `refactor(profile): extract ProfileForm widget for UI state`

#### 🟢 Tahap 4: Eliminasi Duplikasi UI SnackBar & Pembersihan Lint Analyzer
- Membuat `AppSnackBar` di `lib/core/utils/app_snackbar.dart` dan mengonsolidasikan notifikasi feedback.
- Mengatasi seluruh 19 warning analyzer (unused imports, multiple underscores `_`, deprecated `activeColor`, deprecated `anonKey` -> `publishableKey`, dan async context safety).
- **Hasil Analyzer**: `No issues found!` (0 issues).
- **Hasil Test**: 46/46 tests passed.
- **Commit**: `97fe7e4` — `refactor: eliminate duplicated UI snackbars and resolve all analyzer warnings`

---

## 4. Panduan Verifikasi & Cara Menjalankan Uji Mandiri

Reviewer dapat memverifikasi seluruh hasil implementasi melalui langkah berikut:

### 1. Menjalankan Static Code Analysis (0 Issues)
Buka terminal pada root proyek dan jalankan:
```bash
flutter analyze
```
*Output yang diharapkan:*
```text
Analyzing SimpanNota...
No issues found! (ran in 3.2s)
```

### 2. Menjalankan Seluruh Automated Test Suite (100% Pass)
Jalankan seluruh test terintegrasi:
```bash
flutter test
```
*Output yang diharapkan:*
```text
00:12 +46: All tests passed!
```

### 3. Menjalankan Automated Test Fitur Baru & Refactoring Pertemuan 9 Secara Spesifik
- **Unit Test Validator Input (DRY):**
  ```bash
  flutter test test/validators_test.dart
  ```
- **Unit Test ProfileRepository:**
  ```bash
  flutter test test/profile_repository_test.dart
  ```
- **Widget Test Form Profil (ProfileForm):**
  ```bash
  flutter test test/widgets/profile_form_test.dart
  ```
- **Widget Test Baseline Profil:**
  ```bash
  flutter test test/profile_baseline_test.dart
  ```

---

## 5. Ringkasan File Baru & File yang Di-refactor

| No | File | Status | Deskripsi |
|---|---|---|---|
| 1 | `lib/core/utils/input_validator.dart` | **Baru** | Modul fungsi validasi input & formatting telepon terpusat (DRY) |
| 2 | `lib/core/utils/app_snackbar.dart` | **Baru** | Utilitas SnackBar feedback terpusat (DRY UI) |
| 3 | `lib/features/profile/domain/user_profile.dart` | **Baru** | Domain Entity pengguna (Data Contract) |
| 4 | `lib/features/profile/domain/profile_validator.dart` | **Baru** | Pure functions validator domain profil |
| 5 | `lib/features/profile/services/profile_repository.dart` | **Baru** | Data Repository interaksi Supabase/local |
| 6 | `lib/features/profile/presentation/widgets/profile_form.dart` | **Baru** | Widget Form UI & State controller |
| 7 | `lib/features/profile/presentation/widgets/password_form_dialog.dart` | **Baru** | Widget Form dialog ubah sandi |
| 8 | `lib/features/profile/presentation/screens/profile_screen.dart` | **Refactored** | Dipangkas & dipisahkan tanggung jawabnya ke widgets & repo |
| 9 | `lib/features/auth/presentation/screens/auth_screen.dart` | **Refactored** | Memanfaatkan validator terpusat & null-aware elements |
| 10 | `test/validators_test.dart` | **Baru** | 8 Unit test aturan validasi input & phone formatting |
| 11 | `test/profile_repository_test.dart` | **Baru** | 6 Unit test API & repository profil |
| 12 | `test/widgets/profile_form_test.dart` | **Baru** | 5 Widget test ProfileForm |
| 13 | `test/profile_baseline_test.dart` | **Baru** | 3 Widget test baseline profil sebelum refactor |
| 14 | `Architecture.md` | **Updated** | Dokumentasi struktur folder & arsitektur baru |
| 15 | `REVIEWER_GUIDE_P9.md` | **Baru** | Panduan pengujian & reviewer pertemuan 9 |
