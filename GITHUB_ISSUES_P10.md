# Daftar GitHub Issues - SimpanNota Release Candidate (Pertemuan 10)

Dokumen ini memuat daftar **10 GitHub Issues** (5 Bug / Edge Cases Nyata + 5 Usulan Peningkatan Fitur / Enhancements) untuk aplikasi **SimpanNota** pada tahap Release Candidate (Pertemuan 10).

---

## Ringkasan 10 Issues

| No | Tipe | Label | Prioritas | Judul Issue | Modul Terkait |
|:---:|:---:|:---:|:---:|:---|:---|
| 1 | **Bug** | `bug`, `high-priority` | Tinggi | `[BUG] Offline SQLite Synchronization Fails Silently During Network Flap or Expired Auth Session` | `ReceiptRepository` / SQLite |
| 2 | **Bug** | `bug`, `high-priority` | Tinggi | `[BUG] Unbounded Receipt Image Size Causes HTTP 413 and App Memory Spikes on High-Resolution Camera Photos` | Image Picker / Supabase Storage |
| 3 | **Bug** | `bug`, `medium-priority` | Sedang | `[BUG] Telegram Bot API Fails with HTTP 400/403 when User Has Never Started the Bot` | Edge Function / Telegram Bot |
| 4 | **Bug** | `bug`, `medium-priority` | Sedang | `[BUG] Warranty Expiration Calculation Timezone Shift (UTC vs Device Local Midnight)` | Domain `Receipt` |
| 5 | **Bug** | `bug`, `medium-priority` | Sedang | `[BUG] Receipt Form Input State Lost on Screen Orientation Change or Split-Screen Mode` | `AddReceiptScreen` UI |
| 6 | **Feature** | `enhancement` | Sedang | `[ENH] Automated Receipt OCR and Smart Expense Attribute Extraction` | ML Kit / Vision AI |
| 7 | **Feature** | `enhancement` | Sedang | `[ENH] Export Receipts & Warranty Proof Archive to Structured PDF / CSV Report` | Export Module / PDF |
| 8 | **Feature** | `enhancement` | Rendah | `[ENH] Warranty Claim Service Center Locator & Claim History Tracker` | Domain `Claim` / Geolocator |
| 9 | **Feature** | `enhancement` | Rendah | `[ENH] Biometric Re-Authentication Guard for Critical Actions (Delete Receipt)` | Security / `LocalAuth` |
| 10 | **Feature** | `enhancement` | Sedang | `[ENH] Real-time Multi-Device Sync via Supabase Realtime Channels` | Supabase Realtime |

---

## Rincian Lengkap Setiap Issue

### 1. [BUG] Offline SQLite Synchronization Fails Silently During Network Flap or Expired Auth Session
* **Tipe:** Bug (`bug`, `high-priority`)
* **Modul:** `lib/features/receipts/services/receipt_repository.dart`, `lib/core/local/database_helper.dart`
* **Deskripsi:**  
  Ketika pengguna membuat nota dalam kondisi offline (tanpa koneksi internet), nota berhasil disimpan di SQLite lokal dengan integer ID lokal. Namun saat perangkat kembali online, jika koneksi internet mengalami ketidakstabilan (*network flap*) atau token JWT Supabase telah kedaluwarsa (HTTP 401), proses sinkronisasi berhenti seketika tanpa ada antrean pengulangan (*retry queue* dengan exponential backoff), tanpa status penanda di kartu nota UI (`sync_status`), dan tanpa notifikasi yang memberitahu pengguna bahwa datanya belum terunggah ke *cloud*.
* **Langkah Reproduksi:**
  1. Matikan koneksi internet (Wi-Fi & Data Seluler) pada perangkat.
  2. Buka aplikasi SimpanNota, tambahkan 2 buah nota baru.
  3. Hubungkan kembali internet dengan bandwidth sangat rendah atau dalam kondisi sesi token habis.
  4. Amati dashboard: tidak ada indikator apakah nota sudah tersinkronisasi atau masih lokal.
* **Expected Behavior:**  
  Nota yang belum tersinkronisasi memiliki penanda ikon *cloud-offline* di kartu nota, dan sistem sinkronisasi otomatis mengulang pengiriman (*retry*) di latar belakang saat koneksi stabil.
* **Actual Behavior:**  
  Proses sinkronisasi gagal secara *silent*, pengguna mengira data sudah aman di cloud padahal masih tersimpan lokal saja.
* **Acceptance Criteria:**
  - Tambahkan kolom `sync_status TEXT DEFAULT 'synced'` (`pending_upload`, `synced`, `failed`) pada SQLite.
  - Tampilkan badge status sinkronisasi pada UI kartu nota di `HomeScreen`.
  - Catat log peringatan ke `AppLogger.warning('SYNC', ...)` saat sinkronisasi tertunda.

---

### 2. [BUG] Unbounded Receipt Image Size Causes HTTP 413 and App Memory Spikes on High-Resolution Camera Photos
* **Tipe:** Bug (`bug`, `high-priority`)
* **Modul:** `lib/features/receipts/presentation/screens/add_receipt_screen.dart`, `lib/features/receipts/services/receipt_repository.dart`
* **Deskripsi:**  
  Kamera ponsel modern rata-rata menghasilkan foto resolusi tinggi (12 MP hingga 108 MP) dengan ukuran file 8 MB – 25 MB per lembar struk. Saat ini `image_picker` menyimpan foto mentah dan langsung diunggah ke Supabase Storage tanpa kompresi klien (*client-side compression*). Pada jaringan seluler 3G/4G, pengunggahan foto berukuran belasan megabyte memicu HTTP 413 (*Payload Too Large*), *socket timeout*, pemborosan kuota pengguna, dan lonjakan memori RAM (*OutOfMemory*).
* **Langkah Reproduksi:**
  1. Ambil foto nota dengan kamera ponsel beresolusi tinggi (rasio 4:3 resolusi penuh).
  2. Klik tombol "Simpan Nota".
  3. Periksa waktu unggah dan konsumsi kuota jaringan.
* **Expected Behavior:**  
  Foto struk otomatis dikompresi di sisi klien sebelum disimpan atau diunggah (resolusi maksimal 1920x1080, format JPEG kualitas 80–85%, ukuran file < 1.5 MB) dengan teks yang tetap terbaca jelas.
* **Actual Behavior:**  
  File gambar mentah 15 MB langsung diunggah, mengakibatkan waktu simpan lama atau gagal *timeout*.
* **Acceptance Criteria:**
  - Integrasikan kompresi gambar pra-unggah (misalnya `image` atau opsi `imageQuality: 85` pada `ImagePicker`).
  - Ukuran file hasil kompresi dijamin tidak melebihi 2 MB.

---

### 3. [BUG] Telegram Bot API Fails with HTTP 400/403 when User Has Never Started the Bot
* **Tipe:** Bug (`bug`, `medium-priority`)
* **Modul:** `supabase/functions/send-warranty-reminder/index.ts`, `lib/features/receipts/presentation/screens/receipt_detail_screen.dart`
* **Deskripsi:**  
  Sesuai kebijakan privasi Telegram Bot API, sebuah bot tidak dapat mengirimkan pesan ke akun pengguna jika pengguna tersebut belum pernah menekan tombol `/start` pada bot tersebut. Jika pengguna mengisi **Telegram Chat ID** angka yang valid dari `@userinfobot`, namun belum pernah memulai obrolan dengan bot SimpanNota, request pengiriman pengingat dari Edge Function akan mengembalikan HTTP 400 (`Bad Request: chat not found`) atau HTTP 403 (`Forbidden: bot was blocked by the user`).
* **Langkah Reproduksi:**
  1. Masukkan Telegram Chat ID pada form profil.
  2. Pastikan akun Telegram tersebut belum pernah menekan `/start` pada bot pengingat.
  3. Jalankan pengiriman pengingat dari Edge Function.
* **Expected Behavior:**  
  Aplikasi menyediakan tautan langsung `https://t.me/<BOT_NAME>?start=setup` dan tombol "Uji Koneksi Bot", serta Edge Function mencatat status kegagalan pengiriman secara informatif ke tabel log.
* **Actual Behavior:**  
  Pengiriman pengingat gagal secara *silent* dan pengguna tidak pernah menerima notifikasi tanpa mengetahui penyebabnya.
* **Acceptance Criteria:**
  - Tambahkan tombol "Uji Kirim Pesan Bot" di `ProfileForm` untuk memvalidasi apakah pengguna sudah memulai bot.
  - Sediakan panduan visual interaktif yang mewajibkan penekanan `/start`.

---

### 4. [BUG] Warranty Expiration Calculation Timezone Shift (UTC vs Device Local Midnight)
* **Tipe:** Bug (`bug`, `medium-priority`)
* **Modul:** `lib/features/receipts/domain/receipt.dart` (`warrantyEndDate`, `remainingDays`, `isExpired`)
* **Deskripsi:**  
  Parsing tanggal pembelian `purchaseDate` tanpa normalisasi zona waktu (misalnya UTC vs WIB UTC+7) menyebabkan perhitungan selisih hari sisa garansi (`remainingDays`) bergeser 1 hari lebih cepat atau lebih lambat jika pengecekan dilakukan di sekitar jam 00:00–07:00 pagi.
* **Langkah Reproduksi:**
  1. Buat nota dengan tanggal pembelian hari ini dan durasi garansi 1 bulan.
  2. Ubah jam perangkat ke pukul 23:55, lalu ke 00:05 WIB.
  3. Periksa nilai `remainingDays` dan status kartu nota.
* **Expected Behavior:**  
  Perhitungan hari sisa garansi menormalisasi kedua tanggal ke *date-only* jam 00:00:00 lokal (`DateTime(d.year, d.month, d.day)`), sehingga pengurangan hari terjadi tepat di tengah malam tanggal kalender.
* **Actual Behavior:**  
  Pengurangan sisa hari menggunakan selisih durasi jam mentah, menyebabkan inkonsistensi status pada jam-jam transisi.
* **Acceptance Criteria:**
  - Terapkan normalisasi tanggal `DateUtils.dateOnly` pada perhitungan sisa hari di entity `Receipt`.
  - Tambahkan unit test perhitungan batas tengah malam lintas zona waktu.

---

### 5. [BUG] Receipt Form Input State Lost on Screen Orientation Change or Split-Screen Mode
* **Tipe:** Bug (`bug`, `medium-priority`)
* **Modul:** `lib/features/receipts/presentation/screens/add_receipt_screen.dart`
* **Deskripsi:**  
  Ketika pengguna sedang mengisi form tambah nota (nama barang, toko, tanggal, foto nota) dan perangkat ponsel dirotasi (dari Portrait ke Landscape) atau masuk ke mode *split-screen multitasking*, Android akan merekonstruksi Activity Flutter. Karena state form disimpan di controller lokal tanpa mekanisme restorasi state, seluruh isian form dan path foto sementara yang belum di-submit akan ter-reset menjadi kosong.
* **Langkah Reproduksi:**
  1. Buka layar Tambah Nota.
  2. Isi kolom nama barang, toko, dan ambil foto nota.
  3. Putar orientasi ponsel menjadi Landscape.
* **Expected Behavior:**  
  Isian nama barang, toko, dan foto yang telah diambil tetap utuh di layar.
* **Actual Behavior:**  
  Layar melakukan rebuild dan seluruh form kembali kosong.
* **Acceptance Criteria:**
  - Gunakan `RestorationMixin` atau simpan draf input di Riverpod `AddReceiptNotifier` agar tahan terhadap siklus hidup rotasi Android.

---

### 6. [ENH] Automated Receipt OCR and Smart Expense Attribute Extraction
* **Tipe:** Enhancement (`enhancement`, `medium-priority`)
* **Modul:** Fitur Kamera & Input Nota
* **Deskripsi:**  
  Mengintegrasikan teknologi *Optical Character Recognition* (OCR) *on-device* menggunakan Google ML Kit Text Recognition atau Gemini 1.5 Flash Vision. Saat pengguna memotret struk belanja, teks struk langsung diekstrak secara otomatis untuk mengisi nama toko, tanggal transaksi, nama barang, dan estimasi masa garansi tanpa perlu mengetik manual.
* **Acceptance Criteria:**
  - Tombol "Scan Cerdas (OCR)" pada kamera nota.
  - Parsing otomatis teks struk dengan akurasi pengenalan tanggal & nama toko minimal 85%.

---

### 7. [ENH] Export Receipts & Warranty Proof Archive to Structured PDF / CSV Report
* **Tipe:** Enhancement (`enhancement`, `medium-priority`)
* **Modul:** Fitur Ekspor & Laporan
* **Deskripsi:**  
  Menambahkan modul ekspor data nota dan garansi ke format PDF terstruktur (dilengkapi foto nota, nomor seri, informasi toko, dan barcode/QR) serta file CSV untuk kebutuhan rekapitulasi keuangan, klaim asuransi barang, atau pelaporan pajak.
* **Acceptance Criteria:**
  - Menu "Ekspor Laporan PDF" dan "Ekspor CSV" di halaman Profil atau Dashboard.
  - Dokumen PDF berisi daftar nota terpilih, ringkasan total nilai belanja, dan lampiran foto struk yang rapi.

---

### 8. [ENH] Warranty Claim Service Center Locator & Claim History Tracker
* **Tipe:** Enhancement (`enhancement`, `low-priority`)
* **Modul:** Layanan Purna Jual / Garansi
* **Deskripsi:**  
  Menambahkan fitur pelacakan riwayat klaim garansi (tanggal pengajuan klaim, nomor tiket servis, status servis: Diajukan / Dalam Perbaikan / Selesai) serta pencarian lokasi Service Center resmi terdekat menggunakan integrasi GPS `geolocator` dan Google Maps.
* **Acceptance Criteria:**
  - Tab "Riwayat Klaim" di layar detail nota.
  - Tombol "Cari Service Center Terdekat" yang membuka rute Google Maps berdasarkan lokasi pengguna saat ini.

---

### 9. [ENH] Biometric Re-Authentication Guard for Critical Actions (Delete Receipt)
* **Tipe:** Enhancement (`enhancement`, `low-priority`)
* **Modul:** Keamanan & `local_auth`
* **Deskripsi:**  
  Mewajibkan verifikasi biometrik (sidik jari / Face ID / PIN perangkat) sebelum pengguna dapat melakukan tindakan kritis yang bersifat destruktif atau permanen, seperti menghapus bukti nota pembelian atau mengubah kata sandi akun.
* **Acceptance Criteria:**
  - Dialog konfirmasi hapus nota meminta otentikasi biometrik melalui `LocalAuthentication`.
  - Jika otentikasi dibatalkan atau gagal, aksi hapus nota dibatalkan demi keamanan arsip bukti transaksi.

---

### 10. [ENH] Real-time Multi-Device Sync via Supabase Realtime Channels
* **Tipe:** Enhancement (`enhancement`, `medium-priority`)
* **Modul:** Sinkronisasi & WebSocket Supabase
* **Deskripsi:**  
  Menggunakan fitur Supabase Realtime Channels (`supabase.from('receipts').stream(primaryKey: ['id'])`) agar ketika pengguna menambahkan atau mengubah nota dari satu perangkat (misalnya tablet atau browser), data di ponsel Android langsung diperbarui secara instan (*real-time*) tanpa harus melakukan *pull-to-refresh* manual.
* **Acceptance Criteria:**
  - Listen ke stream `receipts` pada `ReceiptListNotifier`.
  - Pembaruan UI langsung terjadi saat ada perubahan data di sisi database remote Supabase.

---

## Script Eksekusi Otomatis ke GitHub CLI (`gh issue create`)

Salin dan jalankan script PowerShell berikut di terminal Anda untuk membuat ke-10 issue tersebut secara otomatis ke repositori GitHub:

```powershell
# 1. Pastikan Anda sudah login GitHub CLI (jalankan: gh auth login)

# Issue 1 (Bug)
gh issue create --title "[BUG] Offline SQLite Synchronization Fails Silently During Network Flap or Expired Auth Session" --label "bug" --body "## Description`nWhen receipts are created offline, mid-stream network drops or expired JWT cause sync to abort silently without retry or UI badge.`n`n## Acceptance Criteria`n- Add sync_status column to SQLite`n- Display offline badge on HomeScreen receipt card`n- Add exponential backoff retry worker"

# Issue 2 (Bug)
gh issue create --title "[BUG] Unbounded Receipt Image Size Causes HTTP 413 and App Memory Spikes on High-Resolution Camera Photos" --label "bug" --body "## Description`nModern cameras produce 15MB+ photos. Uploading uncompressed images causes HTTP 413 and OOM crashes.`n`n## Acceptance Criteria`n- Compress photos to max 1920x1080 and <1.5MB before upload`n- Ensure receipt text remains sharp and legible"

# Issue 3 (Bug)
gh issue create --title "[BUG] Telegram Bot API Fails with HTTP 400/403 when User Has Never Started the Bot" --label "bug" --body "## Description`nTelegram Bot API rejects messages to users who haven't pressed /start. Edge Function fails silently.`n`n## Acceptance Criteria`n- Provide direct t.me link and mandatory /start prompt`n- Add 'Test Bot Connection' button in ProfileForm"

# Issue 4 (Bug)
gh issue create --title "[BUG] Warranty Expiration Calculation Timezone Shift (UTC vs Device Local Midnight)" --label "bug" --body "## Description`nComparing purchaseDate with DateTime.now() without date-only normalization causes +/- 1 day shift around midnight in UTC+7.`n`n## Acceptance Criteria`n- Normalize dates using DateUtils.dateOnly`n- Add timezone midnight transition unit tests"

# Issue 5 (Bug)
gh issue create --title "[BUG] Receipt Form Input State Lost on Screen Orientation Change or Split-Screen Mode" --label "bug" --body "## Description`nRotating phone or entering split-screen mode destroys Activity and resets AddReceiptScreen input fields.`n`n## Acceptance Criteria`n- Preserve form draft state in Riverpod notifier across lifecycle changes"

# Issue 6 (Enhancement)
gh issue create --title "[ENH] Automated Receipt OCR and Smart Expense Attribute Extraction" --label "enhancement" --body "## Description`nIntegrate on-device ML Kit OCR or Gemini Vision to extract store name, date, and price automatically from receipt photo.`n`n## Acceptance Criteria`n- One-tap 'Scan Cerdas' button in receipt form"

# Issue 7 (Enhancement)
gh issue create --title "[ENH] Export Receipts & Warranty Proof Archive to Structured PDF / CSV Report" --label "enhancement" --body "## Description`nAllow users to export receipts and warranty details into PDF (with image thumbnails) and CSV for tax or insurance claim.`n`n## Acceptance Criteria`n- Export PDF & CSV options in Profile screen"

# Issue 8 (Enhancement)
gh issue create --title "[ENH] Warranty Claim Service Center Locator & Claim History Tracker" --label "enhancement" --body "## Description`nTrack warranty service claims and show nearby authorized service centers with Google Maps navigation using device GPS.`n`n## Acceptance Criteria`n- Claim history sub-screen`n- Maps route to nearest service center"

# Issue 9 (Enhancement)
gh issue create --title "[ENH] Biometric Re-Authentication Guard for Critical Actions (Delete Receipt)" --label "enhancement" --body "## Description`nRequire biometric scan before deleting receipts or resetting passwords to prevent accidental or unauthorized data loss.`n`n## Acceptance Criteria`n- Guard deleteReceipt with LocalAuthentication prompt"

# Issue 10 (Enhancement)
gh issue create --title "[ENH] Real-time Multi-Device Sync via Supabase Realtime Channels" --label "enhancement" --body "## Description`nImplement Supabase Realtime stream so changes on one device instantly reflect across all user devices without manual refresh.`n`n## Acceptance Criteria`n- Live reactive stream in ReceiptListNotifier"
```
