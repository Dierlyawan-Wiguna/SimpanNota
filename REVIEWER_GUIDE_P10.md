# PANDUAN PENGUJIAN & RELEASE CANDIDATE (REVIEWER GUIDE - PRAKTIKUM 10)
## Aplikasi SimpanNota — Tahap Release Candidate (RC) & Runtime Diagnostics

Dokumen panduan ini disusun sebagai laporan komprehensif bagi Dosen Penguji / Reviewer dalam memverifikasi deliverable **Praktikum 10 (Release Candidate)** pada aplikasi **SimpanNota**, yang mencakup:
1. **Sistem Runtime Logging & Tracing Terstruktur (`AppLogger` & `SystemLogScreen`)**
2. **Global Uncaught Error Handling & Tracing di Mode Release**
3. **Persiapan & Eksekusi Build APK Release Candidate (`app-release.apk`)**
4. **Audit Kode & Pembuatan 10 GitHub Issues (5 Bug Nyata + 5 Feature Enhancements)**
5. **Verifikasi Kualitas Kode (`flutter analyze` 0 issues & `flutter test` 100% passed)**

---

## 📋 Ringkasan Eksekutif & Status Akhir

| Parameter | Status / Nilai | Keterangan |
|:---|:---|:---|
| **Versi Aplikasi** | `1.0.0-rc.1+1` | Terdefinisi di `pubspec.yaml` (Release Candidate) |
| **Flutter Analyze** | **0 Issues / Bersih (No issues found!)** | Tidak ada lint warning, deprecated code, atau error |
| **Flutter Test** | **63 / 63 Tests Passed (100% Green)** | Seluruh unit test dan widget test lulus sempurna |
| **Target Build APK** | `build/app/outputs/flutter-apk/app-release.apk` | Release APK siap install di perangkat Android fisik (58.8 MB) |
| **System Logger** | Aktif di Memory & SQLite (`system_logs`) | Rotasi otomatis maksimal 500 log terbaru |
| **GitHub Issues** | **10 Issues Lengkap** | 5 Bug Nyata + 5 Feature Enhancements di `GITHUB_ISSUES_P10.md` |

---

## 1. Arsitektur Runtime Logging & Tracing (`AppLogger` + Log Viewer)

### A. Latar Belakang Masalah
Pada mode **Release APK** di perangkat fisik pengguna atau dosen penguji:
* `debugPrint` bawaan Flutter dinonaktifkan secara default oleh compiler dan tidak tersimpan di memori perangkat.
* Jika terjadi error jaringan (misalnya Supabase timeout, token kedaluwarsa, atau masalah izin kamera), aplikasi tampak diam atau hanya menampilkan pesan generik tanpa jejak error (*stack trace*) yang bisa diinspeksi.

### B. Solusi: `AppLogger` Service (`lib/core/services/app_logger.dart`)
Kami membangun sistem logging modular dan thread-safe:
1. **4 Tingkatan Log (Log Levels):**
   * `INFO`: Informasi alur operasional normal (login sukses, memuat nota, membuka Telegram).
   * `WARNING`: Kondisi non-fatal (aplikasi Telegram belum terpasang, upload foto fallback ke path lokal).
   * `ERROR`: Kegagalan operasional (gagal autentikasi Supabase, gagal insert nota, socket error).
   * `FATAL`: Crash atau error tak tertangani (*uncaught exception*) pada platform/framework.
2. **Double-Tier Storage Strategy:**
   * **In-Memory Buffer:** Menyimpan 500 log terbaru di RAM menggunakan `ValueNotifier<List<LogEntry>>` untuk rendering instan dan reaktif di layar UI tanpa membebani I/O disk.
   * **Persistent SQLite Storage:** Menyimpan log ke tabel `system_logs` di database SQLite lokal (`lib/core/local/database_helper.dart`). Dilengkapi mekanisme **rotasi otomatis** (`DELETE FROM system_logs WHERE id NOT IN (SELECT id FROM system_logs ORDER BY id DESC LIMIT 500)`) agar ukuran file database tetap ringan (< 1 MB).
3. **Penyaringan Data Sensitif Otomatis (Sanitization):**
   * Method `AppLogger.sanitize(input)` secara otomatis mendeteksi dan mengganti kata sandi, token otentikasi, API Key, dan anon key dengan label `[REDACTED]`. Kredensial pengguna dijamin aman dari kebocoran log.

### C. Global Error Catching (`lib/main.dart`)
Seluruh error tak tertangkap dicegat di tiga tingkatan:
```dart
// 1. Error visual pada Flutter Widget Tree
FlutterError.onError = (FlutterErrorDetails details) {
  FlutterError.presentError(details);
  AppLogger.fatal('FLUTTER_ERROR', details.exceptionAsString(), details.exception, details.stack);
};

// 2. Error asynchronous pada Platform / Engine Dispatcher
PlatformDispatcher.instance.onError = (error, stack) {
  AppLogger.fatal('PLATFORM_ERROR', error.toString(), error, stack);
  return true;
};

// 3. Error tak tertangani pada Dart Execution Zone
runZonedGuarded<Future<void>>(() async {
  // Inisialisasi & runApp
}, (error, stack) {
  AppLogger.fatal('ZONE_ERROR', error.toString(), error, stack);
});
```

### D. Layar Diagnostik: `SystemLogScreen` (`lib/features/profile/presentation/screens/system_log_screen.dart`)
Dapat diakses langsung dari aplikasi melalui menu **Profil -> Log Sistem & Diagnostik**:
* **Filter Level:** Chip filter interaktif (`ALL`, `INFO`, `WARNING`, `ERROR`, `FATAL`).
* **Pencarian Real-Time:** Filter berdasarkan kata kunci modul atau isi pesan.
* **Salin Semua Log (Copy All):** Menyalin seluruh log terformat ke clipboard untuk pelaporan bug.
* **Bersihkan Log (Clear Logs):** Menghapus riwayat log dari memori dan database SQLite.
* **Detail Error BottomSheet:** Mengetuk baris log membuka detail lengkap waktu milidetik, pesan, error description, dan stack trace dengan format monospace.
* **Aksesibilitas:** Seluruh tombol dilengkapi widget `Semantics` untuk pembaca layar (TalkBack).

---

## 2. Persiapan & Hasil Build APK Release Candidate

### A. Audit Konfigurasi Rilis Android
1. **`android/app/src/main/AndroidManifest.xml`:**
   * Izin lengkap: `INTERNET`, `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, `USE_EXACT_ALARM`, `SCHEDULE_EXACT_ALARM`, `CAMERA`, `ACCESS_FINE_LOCATION`, `USE_BIOMETRIC`.
   * **Package Visibility `<queries>`:** Menambahkan intent scheme `tg` dan `https` agar deteksi ketersediaan aplikasi Telegram via `canLaunchUrl(Uri.parse('tg://resolve'))` berfungsi akurat di Android 11+ (API 30 ke atas).
   * Label aplikasi: `android:label="SimpanNota"`.
2. **`android/app/proguard-rules.pro` (R8 / ProGuard):**
   * Mengamankan kelas Supabase, Gotrue, Postgrest, SQLite (`com.tekartik.sqflite`), Biometrik (`androidx.biometric`), dan Notifikasi (`flutterlocalnotifications`) agar tidak terhapus atau rusak akibat *code shrinking/obfuscation* pada mode rilis.
3. **`pubspec.yaml`:**
   * Versi diperbarui menjadi `1.0.0-rc.1+1`.
   * Aset `.env` dideklarasikan agar terbawa ke dalam bundle APK jika file konfigurasi lokal tersedia.

### B. Artefak APK Rilis
Perintah build rilis dieksekusi:
```bash
flutter build apk --release
```
* **Lokasi File APK:** `build/app/outputs/flutter-apk/app-release.apk`
* **Ukuran File APK:** **58.8 MB**
* **Target Arsitektur:** Universal APK (dukungan arm64-v8a, armeabi-v7a, x86_64)
* **Status Build:** **SUCCESS (Exit Code 0)** via Gradle task `assembleRelease`

### C. Cara Menginstal & Menguji APK pada Ponsel Android
1. Sambungkan ponsel Android ke komputer dengan USB Debugging aktif.
2. Jalankan perintah:
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```
   *(Atau kirim file `app-release.apk` ke ponsel melalui Google Drive / WhatsApp / kabel data, lalu buka file APK untuk menginstalnya secara langsung).*
3. Buka aplikasi **SimpanNota**, masuk ke menu **Profil**, lalu buka **Log Sistem & Diagnostik** untuk memverifikasi pencatatan tracing saat runtime.

---

## 3. Rekapitulasi 10 GitHub Issues (5 Bug Found + 5 Feature Enhancements)

Dokumentasi lengkap mengenai detail teknis, langkah reproduksi, *expected vs actual behavior*, dan *acceptance criteria* telah dirangkum dalam file [GITHUB_ISSUES_P10.md](file:///e:/Project%20SimpanNota/SimpanNota/GITHUB_ISSUES_P10.md).

### Ringkasan Tabel:
| No | Judul Issue | Label | Prioritas | Status |
|:---:|:---|:---:|:---:|:---:|
| 1 | `[BUG] Offline SQLite Synchronization Fails Silently During Network Flap or Expired Auth Session` | `bug` | Tinggi | Siap Rilis / Logged |
| 2 | `[BUG] Unbounded Receipt Image Size Causes HTTP 413 and App Memory Spikes on High-Resolution Camera Photos` | `bug` | Tinggi | Siap Rilis / Logged |
| 3 | `[BUG] Telegram Bot API Fails with HTTP 400/403 when User Has Never Started the Bot` | `bug` | Sedang | Siap Rilis / Logged |
| 4 | `[BUG] Warranty Expiration Calculation Timezone Shift (UTC vs Device Local Midnight)` | `bug` | Sedang | Siap Rilis / Logged |
| 5 | `[BUG] Receipt Form Input State Lost on Screen Orientation Change or Split-Screen Mode` | `bug` | Sedang | Siap Rilis / Logged |
| 6 | `[ENH] Automated Receipt OCR and Smart Expense Attribute Extraction` | `enhancement` | Sedang | Usulan Fitur |
| 7 | `[ENH] Export Receipts & Warranty Proof Archive to Structured PDF / CSV Report` | `enhancement` | Sedang | Usulan Fitur |
| 8 | `[ENH] Warranty Claim Service Center Locator & Claim History Tracker` | `enhancement` | Rendah | Usulan Fitur |
| 9 | `[ENH] Biometric Re-Authentication Guard for Critical Actions (Delete Receipt)` | `enhancement` | Rendah | Usulan Fitur |
| 10 | `[ENH] Real-time Multi-Device Sync via Supabase Realtime Channels` | `enhancement` | Sedang | Usulan Fitur |

### Script GitHub CLI:
Jika GitHub CLI (`gh`) telah terpasang dan terautentikasi (`gh auth login`), seluruh 10 issue di atas dapat dibuat otomatis ke GitHub dengan menjalankan script yang tersedia di bagian akhir [GITHUB_ISSUES_P10.md](file:///e:/Project%20SimpanNota/SimpanNota/GITHUB_ISSUES_P10.md).

---

## 4. Panduan Verifikasi bagi Reviewer / Dosen Penguji

Untuk menguji seluruh deliverable Praktikum 10 pada repositori ini:

### 1. Jalankan Analisis Kode Statis:
```bash
flutter analyze
```
*Hasil yang diharapkan: `No issues found!` (0 issues).*

### 2. Jalankan Seluruh Test Suite:
```bash
flutter test
```
*Hasil yang diharapkan: Seluruh 63 tes lulus sempurna (`All tests passed!`), termasuk 9 tes baru di `test/app_logger_test.dart`.*

### 3. Jalankan Pengujian Khusus Runtime Logger:
```bash
flutter test test/app_logger_test.dart
```

### 4. Periksa File Artefak Release Candidate:
* File APK: [app-release.apk](file:///e:/Project%20SimpanNota/SimpanNota/build/app/outputs/flutter-apk/app-release.apk)
* Service Logger: [app_logger.dart](file:///e:/Project%20SimpanNota/SimpanNota/lib/core/services/app_logger.dart)
* UI Log Viewer: [system_log_screen.dart](file:///e:/Project%20SimpanNota/SimpanNota/lib/features/profile/presentation/screens/system_log_screen.dart)
* Aturan ProGuard: [proguard-rules.pro](file:///e:/Project%20SimpanNota/SimpanNota/android/app/proguard-rules.pro)
* Daftar GitHub Issues: [GITHUB_ISSUES_P10.md](file:///e:/Project%20SimpanNota/SimpanNota/GITHUB_ISSUES_P10.md)
* Dokumen Arsitektur: [Architecture.md](file:///e:/Project%20SimpanNota/SimpanNota/Architecture.md)
