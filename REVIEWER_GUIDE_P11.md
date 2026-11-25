# 📘 Panduan Penguji (Reviewer Guide) - Tugas Pertemuan 11
**Aplikasi:** SimpanNota (Smart Receipt & Warranty Tracker)  
**Peran:** Senior Flutter DevOps & QA Automation Engineer  
**Status Pipeline:** ✅ 211 Unit & Widget Tests PASSED (100% Green) | 0 Linter Issues  

---

## 1. Ikhtisar Alur Branching (`v1.0_dev` ➔ `V1.1`)

Proyek SimpanNota menerapkan standar **Git Branching Strategy** untuk memastikan stabilitas kode produksi:

```
[main] ───────────────────────────────────────────────────────────────────────────── (Baseline P10)
   \
    └── [v1.0_dev] (Under Testing / Bug Fixing) ─────────────────────────────────── (v1.0.1-dev.1+2)
            ├── Perbaikan 3 Bug Kritis (Issue 2, 4, 3)
            ├── Ekspansi Suite Unit & Widget Test hingga 211 Tests
            ├── Setup Gated CI/CD Pipeline (.github/workflows/ci_cd_pipeline.yml)
            \
             └── [V1.1] (Live Release / Production Ready) ───────────────────────── (v1.1.0+3)
                     └── Siap Deploy Otomatis via GitHub Release ke Pengguna Publik
```

1. **Branch `v1.0_dev` (Development & Staging):**
   - **Tujuan:** Cabang kerja untuk perbaikan bug (*bug fixing*), implementasi validator, refactoring, dan pengujian mendalam (*under testing*).
   - **Versi:** `1.0.1-dev.1+2` (tercatat pada `pubspec.yaml`).
   - **CI/CD Behavior:** Jika di-push ke GitHub, pipeline CI/CD memicu build APK dan merilisnya sebagai **Pre-release (Staging Test)** untuk pengujian internal.

2. **Branch `V1.1` (Live Production Release):**
   - **Tujuan:** Cabang rilis resmi (*production release candidate*) yang bersih dari segala bug dan diverifikasi oleh seluruh 211 unit test.
   - **Versi:** `1.1.0+3` (tercatat pada `pubspec.yaml`).
   - **CI/CD Behavior:** Pipeline CI/CD memvalidasi seluruh 211 test hijau $\rightarrow$ melakukan otomatisasi *build release APK* $\rightarrow$ mempublikasikan **Live GitHub Release** lengkap dengan file `app-release.apk`.

---

## 2. Rincian 3 Bug Kritis yang Diperbaiki (Berdasarkan `GITHUB_ISSUES_P10.md`)

### 🛠️ Bug 1 (Issue 2): Unbounded Receipt Image Size & Format Validation
- **Modul:** `lib/core/utils/file_upload_validator.dart`, `lib/features/receipts/presentation/screens/add_receipt_screen.dart`
- **Permasalahan:** Kamera resolusi tinggi menghasilkan foto struk 8 MB–25 MB tanpa validasi batas ukuran file dan format ekstensi, yang dapat memicu HTTP 413 (*Payload Too Large*), *OutOfMemory*, atau unggahan format berbahaya.
- **Solusi Rekayasa:**
  - Dibuat kelas utilitas domain murni `FileUploadValidator` yang memvalidasi ekstensi berkas yang didukung (`.jpg`, `.jpeg`, `.png`, `.webp`, `.heic`), batas ukuran maksimal 10 MB (rekomendasi transfer seluler 2 MB), sanitasi nama berkas dari karakter ilegal sistem file, dan deteksi MIME type.
  - Diintegrasikan langsung pada handler kamera dan galeri (`_pickImage` dan `_pickWarrantyCardImage`) di `AddReceiptScreen`, dilengkapi feedback visual *SnackBar* merah jika berkas tidak valid serta audit log ke `AppLogger`.

### 🛠️ Bug 2 (Issue 4): Warranty Expiration Calculation Timezone Shift
- **Modul:** `lib/features/receipts/domain/receipt.dart`
- **Permasalahan:** Perhitungan selisih sisa hari garansi menggunakan `expirationDate.difference(DateTime.now()).inDays` yang membandingkan timestamp dengan jam/menit/detik mentah. Pada rentang waktu tengah malam (pukul 23:55 vs 00:05 WIB atau UTC vs Local), nilai `remainingDays` bergeser 1 hari lebih cepat/lambat (*floating timezone offset*).
- **Solusi Rekayasa:**
  - Menambahkan method normalisasi tanggal statis `Receipt.normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day)` yang memangkas komponen jam, menit, detik, dan milidetik (*date-only local midnight*).
  - Menambahkan getter `remainingDays` dan method komparasi `remainingDaysAsOf(DateTime referenceDate)` serta `statusAsOf(DateTime referenceDate)` untuk evaluasi status garansi yang konsisten dan akurat pada tanggal kalender.

### 🛠️ Bug 3 (Issue 3 / Profil): Telegram Chat ID Sanitization & Connectivity Testing
- **Modul:** `lib/features/profile/domain/profile_validator.dart`, `lib/core/services/telegram_service.dart`
- **Permasalahan:** Chat ID Telegram yang valid untuk supergroup/channel berupa integer bertanda minus (misal: `-1001234567890`) sebelumnya ditolak oleh regex yang hanya mengizinkan angka positif. Pengguna juga kerap salah memasukkan `@username` alih-alih numeric ID, serta belum ada mekanisme pengujian koneksi bot.
- **Solusi Rekayasa:**
  - Memperbarui validasi di `ProfileValidator.validateTelegramChatId` dengan regex `^-?[0-9]{5,16}$` yang mendukung ID akun pribadi (positif) maupun ID grup/channel (negatif), serta menambahkan validasi deteksi prefix `@` dengan pesan bantuan informatif.
  - Menambahkan method sanitasi `ProfileValidator.sanitizeTelegramChatId` untuk pembersihan spasi ekstra.
  - Menambahkan fitur `TelegramService.testBotConnection` untuk memverifikasi kesiapan bot Telegram sebelum pengiriman pengingat berkala, serta menyamarkan token/ID pada log menggunakan `maskSensitiveData` (*security redaction*).

---

## 3. Rekapitulasi Suite 211 Unit & Widget Tests

Seluruh suite pengujian dieksekusi dengan perintah:
```powershell
flutter test --reporter expanded
```
**Hasil:** `00:21 +211: All tests passed!` (100% Hijau / Lulus).

| No | File Pengujian | Jumlah Test | Fokus & Cakupan Pengujian |
|:---:|:---|:---:|:---|
| 1 | `test/warranty_logic_test.dart` | **37** | Boundary testing sisa hari garansi, normalisasi *date-only* tengah malam, transisi status H-30, H-7, H-1, H-0, H+1, tahun kabisat (29 Feb), garansi multi-tahun (120 bulan), dan serialisasi entity `Receipt`. |
| 2 | `test/file_upload_validator_test.dart` | **19** | Validasi whitelist format ekstensi (JPG, PNG, WEBP, HEIC), penolakan file berbahaya/dokumen (EXE, APK, PDF, ZIP), sanitasi nama berkas, deteksi MIME type, batas buffer memori, dan batas ukuran 10 MB. |
| 3 | `test/models/user_profile_model_test.dart` | **19** | Model `UserProfile`, inisial nama majemuk (*multi-word initials*), pembedaan Google OAuth vs Email provider, format tanggal bahasa Indonesia, `copyWith`, dan deserialisasi JSON snake_case & camelCase. |
| 4 | `test/core/theme_and_constants_test.dart` | **21** | Nilai warna `AppColors` (Light & Dark Mode), enum `Category` bahasa Indonesia, enum `WarrantyStatus`, konfigurasi `SupabaseConstants`, dan URI validation. |
| 5 | `test/notifier_state_test.dart` | **24** | State management Riverpod: `SearchQueryNotifier`, `SortOptionNotifier`, `SelectedCategoryNotifier`, immutability `AddReceiptState`, serta filtering & sorting `FilteredReceiptListProvider`. |
| 6 | `test/validators_test.dart` | **16** | Validasi input murni email, password, konfirmasi password, normalisasi nomor telepon Indonesia (+62 / 08), dan Telegram Chat ID (positif, negatif grup, sanitasi). |
| 7 | `test/core/services/telegram_service_test.dart` | **14** | Format pesan pengingat markdown, mock HTTP client untuk respons 200 (Success), 400 (Chat Not Found), 403 (Bot Blocked), 401 (Invalid Token), 500 (Error), network error, dan sanitasi data sensitif log. |
| 8 | `test/receipt_api_test.dart` | **10** | Mock REST API repository `ReceiptRepository`, deserialisasi JSON API, mapping Supabase table snake_case, dan penanganan malformed JSON. |
| 9 | `test/app_logger_test.dart` | **7** | Rotasi log in-memory maksimal 500 entri, sanitasi kata sandi & token API `[REDACTED]`, ekspor log terstruktur, dan `SystemLogScreen` widget UI. |
| 10 | `test/telegram_reminder_test.dart` | **5** | Integrasi UI tombol Telegram, penanganan skema URL `tg://msg`, dialog fallback, dan banner info. |
| 11 | `test/widgets/profile_form_test.dart` | **6** | Widget testing `ProfileForm`: input nama, telepon, Telegram Chat ID, validasi error inline, tombol submit, dan indikator loading. |
| 12 | `test/screens/add_receipt_screen_test.dart` | **15** | Widget testing form input nota, date picker, kamera, input hari & bulan garansi, validasi form kosong, dan indikator loading simpan. |
| 13 | `test/location_and_auth_test.dart` | **8** | Pengujian integrasi widget `WelcomeScreen`, `AuthScreen`, dan alur autentikasi biometrik. |
| 14 | `test/advanced_features_test.dart` | **3** | Notifikasi lokal `NotificationService`, inisialisasi singleton, dan auth widget. |
| 15 | `test/advanced_ui_ux_test.dart` | **7** | Kriteria UI/UX lanjutan: responsivitas adaptif (Grid vs List), aksesibilitas semantik label, keyboard-safe UI, dan dark mode. |
| **TOTAL** | **15 File Pengujian** | **211 Tests** | **✅ 100% Lulus (`All tests passed!`)** |

---

## 4. Simulasi & Penjelasan Teknis "Unit Test Failed -> Efeknya Gimana"

Pertanyaan esensial QA: **"Jika ada 1 saja Unit Test yang gagal (Merah), apa efek berantainya pada pipeline dan aplikasi?"**

### A. Mekanisme Kegagalan pada Level Test Runner
1. Ketika sebuah pengujian unit mengalami kegagalan assertion (misalnya: `expect(daysLeft, 30)` tetapi mendapatkan `29`), Dart Test Framework akan melempar `TestFailure`.
2. Test runner `flutter test` mencatat kegagalan tersebut, memunculkan stack trace merah di konsol, dan mengakhiri proses dengan **Exit Code 1** (bukan 0).

### B. Efek Berantai pada Pipeline CI/CD GitHub Actions (*Gated Pipeline*)
Workflow `.github/workflows/ci_cd_pipeline.yml` dirancang menggunakan ketergantungan berantai (*job dependency*):

```
┌──────────────────────────────────────┐
│  Job 1: unit-test-200                │
│  (flutter analyze + flutter test)    │
└──────────────────┬───────────────────┘
                   │
         [ Apakah Status LULUS (0)? ]
          /                       \
     [ YA ]                      [ TIDAK (Exit Code 1) ]
        │                                  │
┌───────▼──────────────────────┐   ┌───────▼──────────────────────┐
│  Job 2: auto-build-apk       │   │  Job 2: auto-build-apk       │
│  (flutter build apk)         │   │  >>> STATUS: SKIPPED / BLOCKED│
└───────┬──────────────────────┘   └──────────────────────────────┘
        │                                  │
┌───────▼──────────────────────┐   ┌───────▼──────────────────────┐
│  Job 3: deploy-live-release  │   │  Job 3: deploy-live-release  │
│  (GitHub Release & Live APK) │   │  >>> STATUS: SKIPPED / BLOCKED│
└──────────────────────────────┘   └──────────────────────────────┘
```

1. **Job 1 (`unit-test-200`) GAGAL (Merah):**
   - Langkah `flutter test --reporter expanded` berhenti pada test yang gagal dan GitHub runner mencatat `Process completed with exit code 1`. Job ditandai tanda silang merah ❌.
2. **Job 2 (`auto-build-apk`) DIBLOKIR (`SKIPPED`):**
   - Karena Job 2 memiliki konfigurasi `needs: unit-test-200`, sistem GitHub Actions secara otomatis **MEMBATALKAN** eksekusi Job 2 tanpa kompilasi APK.
   - **Efek Nyata:** Tidak ada waktu CPU/runner terbuang sia-sia untuk mem-build kode yang rusak, dan file APK cacat tidak akan pernah diproduksi.
3. **Job 3 (`deploy-live-release`) DIBLOKIR (`SKIPPED`):**
   - Karena Job 3 memiliki konfigurasi `needs: [unit-test-200, auto-build-apk]`, proses rilis ke publik ditolak seketika.
   - **Efek Nyata:** Pengguna di branch **`V1.1` (Live)** terlindungi dari bug regresi. Kode yang bermasalah ditahan di branch staging `v1.0_dev` untuk diperbaiki oleh tim engineer.

---

## 5. Struktur Konfigurasi CI/CD Pipeline (`.github/workflows/ci_cd_pipeline.yml`)

Workflow CI/CD diatur secara profesional dengan 3 gated jobs:

```yaml
name: SimpanNota CI/CD Pipeline (200 UT -> Auto Build -> Deploy Live)

on:
  push:
    branches: [ v1.0_dev, main, V1.1 ]
  pull_request:
    branches: [ v1.0_dev, main, V1.1 ]

jobs:
  unit-test-200:
    name: 1. Unit & Widget Testing (200+ Test Cases)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: 'temurin', java-version: '17' }
      - uses: subosito/flutter-action@v2
        with: { channel: 'stable', cache: true }
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --reporter expanded

  auto-build-apk:
    name: 2. Auto Build Release APK
    needs: unit-test-200
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: 'temurin', java-version: '17' }
      - uses: subosito/flutter-action@v2
        with: { channel: 'stable', cache: true }
      - name: Persiapkan .env
        run: |
          if [ -f .env.example ]; then cp .env.example .env; fi
      - run: flutter pub get
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v4
        with:
          name: app-release-apk
          path: build/app/outputs/flutter-apk/app-release.apk

  deploy-live-release:
    name: 3. Deploy Live Release & GitHub Artifact
    needs: [unit-test-200, auto-build-apk]
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with: { name: app-release-apk, path: release-artifacts }
      - name: Tentukan Metadata Rilis
        id: release_meta
        run: |
          BRANCH="${GITHUB_REF#refs/heads/}"
          if [ "$BRANCH" = "V1.1" ]; then
            echo "tag_name=v1.1.0-live" >> $GITHUB_OUTPUT
            echo "release_name=SimpanNota V1.1 Live Release (Production)" >> $GITHUB_OUTPUT
            echo "is_prerelease=false" >> $GITHUB_OUTPUT
          else
            echo "tag_name=v1.0.1-dev-${{ github.run_number }}" >> $GITHUB_OUTPUT
            echo "release_name=SimpanNota v1.0_dev Staging (Under Testing)" >> $GITHUB_OUTPUT
            echo "is_prerelease=true" >> $GITHUB_OUTPUT
          fi
      - uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ steps.release_meta.outputs.tag_name }}
          name: ${{ steps.release_meta.outputs.release_name }}
          prerelease: ${{ steps.release_meta.outputs.is_prerelease == 'true' }}
          files: release-artifacts/app-release.apk
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 6. Checklist Pengambilan Screenshot Progress untuk Dikumpulkan

Gunakan panduan berikut untuk mengambil screenshot bukti pengerjaan:

- [ ] **Screenshot 1: Hasil `flutter analyze`**
  - Jalankan: `flutter analyze`
  - Bukti: Teks `Analyzing SimpanNota... No issues found!`.
- [ ] **Screenshot 2: Hasil Eksekusi 211 Unit & Widget Tests**
  - Jalankan: `flutter test`
  - Bukti: Baris ringkasan `00:20 +211: All tests passed!`.
- [ ] **Screenshot 3: Daftar Branch Git Aktif**
  - Jalankan: `git branch -a`
  - Bukti: Terlihat branch `v1.0_dev` dan `V1.1`.
- [ ] **Screenshot 4: Konfigurasi CI/CD Pipeline**
  - Tampilkan file `.github/workflows/ci_cd_pipeline.yml` pada IDE atau GitHub repository.
- [ ] **Screenshot 5: Dashboard GitHub Actions (Setelah Push)**
  - Tampilkan halaman *Actions* di GitHub dengan 3 kotak hijau berantai:
    1. `1. Unit & Widget Testing (200+ Test Cases)` ✅
    2. `2. Auto Build Release APK` ✅
    3. `3. Deploy Live Release & GitHub Artifact` ✅
- [ ] **Screenshot 6: Halaman GitHub Releases**
  - Tampilkan halaman *Releases* di repository yang memuat rilis `SimpanNota V1.1 Live Release` beserta file lampiran `app-release.apk`.

---

## 7. Instruksi `git push` ke GitHub Remote

Untuk mengunggah seluruh branch ke repository GitHub Anda, jalankan perintah berikut:

```powershell
# 1. Pastikan commit pada branch V1.1 sudah rapi
git checkout V1.1
git push -u origin V1.1

# 2. Unggah branch v1.0_dev
git checkout v1.0_dev
git push -u origin v1.0_dev
```

Setelah perintah di atas dijalankan, GitHub Actions akan langsung memicu otomatisasi pipeline CI/CD pada kedua branch secara independen!
