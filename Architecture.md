# Architecture: SimpanNota (Digital Receipt & Warranty Manager)

Build a modern, cross-platform mobile application named **SimpanNota** (Digital Receipt & Warranty Manager).

## Purpose
Help individual users, office workers, and household managers easily secure purchase receipts, track warranty expiration timelines, and organize repair claim documents digitally without relying on fragile physical paper receipts. The application runs with a cloud backend powered by Supabase for authentication, PostgreSQL database storage, and file bucket management, coupled with scheduled local device notifications to alert users before warranties expire.

## Tech Stack
* **Client / Mobile Framework:** Flutter (Dart)
* **Backend-as-a-Service (BaaS):** Supabase
  * **Authentication:** Supabase Auth (Email & Password)
  * **Database:** PostgreSQL with Row Level Security (RLS)
  * **File Storage:** Supabase Storage (Bucket: `receipts`)
* **Local Notifications:** `flutter_local_notifications` + `timezone`
* **Hardware Integration:** `image_picker` (Camera & Gallery)
* **Design System:** Material Design 3 (Indonesian UI localization)

## Code & Architecture Rules
* Keep application architecture modular using a feature-first approach (`core`, `features/auth`, `features/receipts`).
* Strictly enforce manual input for product data and purchase dates. **Do not implement OCR (Optical Character Recognition) automatic scanning.**
* Enforce Supabase Row Level Security (RLS) so users can strictly create, view, update, and delete only their own records.
* Use PascalCase for Classes, Models, Enums, and Flutter Widgets.
* Use camelCase for methods, variables, parameters, and database column mappings in Dart models.
* Use snake_case for PostgreSQL database tables and columns in Supabase.
* Keep UI presentation cleanly separated from service/data layer logic.
* Keep UI messages, validation prompts, labels, and dialogs in **Indonesian language**.

---

## Main Entities

### 1. User (Supabase Auth Entity)
* `Id` (UUID, Primary Key)
* `Email` (String)
* `CreatedAt` (Timestamp with Timezone)

### 2. Category (Domain Enum)
* `Semua`
* `Elektronik`
* `Kendaraan`
* `Pakaian`
* `Perabotan`
* `Lainnya`

### 3. WarrantyStatus (Domain Enum)
* `ACTIVE` (Active warranty, remaining time > 7 days) - Green badge
* `EXPIRING_SOON` (Remaining warranty <= 7 days) - Orange badge
* `EXPIRED` (Warranty period ended) - Red / Grey badge

### 4. Receipt
* `Id` (UUID, Primary Key)
* `UserId` (UUID, Foreign Key referencing `auth.users.id`)
* `NamaBarang` (String, required)
* `NamaToko` (String, required)
* `TanggalBeli` (Date, required)
* `DurasiGaransiBulan` (Integer, required)
* `FotoUrl` (String, optional public URL from Supabase Storage)
* `Kategori` (String, required)
* `CreatedAt` (Timestamp with Timezone, default `now()`)

---

## Database Rules & Security (Supabase PostgreSQL)
* Table name: `receipts`.
* Primary key `id` defaults to `gen_random_uuid()`.
* Foreign key `user_id` defaults to `auth.uid()`.
* **Row Level Security (RLS)** must be enabled:
  ```sql
  alter table receipts enable row level security;

  create policy "Users can view and manage their own receipts"
  on receipts for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
  ```
* Deleting a receipt record must trigger deletion of the associated physical receipt photo in Supabase Storage (`receipts` bucket).

---

## Application Features

### 1. Authentication (Supabase Auth)
* Email and Password sign-up and sign-in with client-side validation.
* Auth state gate (`AuthGate`) listening to `onAuthStateChange` stream:
  * Redirects authenticated sessions directly to `HomeScreen`.
  * Redirects unauthenticated / logged-out sessions to `AuthScreen`.
* Sign-out trigger in the main AppBar.

### 2. Dashboard & Search (Home Screen)
* Category filtering using interactive horizontal choice chips (`Semua`, `Elektronik`, `Kendaraan`, `Pakaian`, `Perabotan`, `Lainnya`).
* Real-time search bar filtering receipts by `NamaBarang` or `NamaToko`.
* Calculated warranty status display on receipt cards:
  * Calculates expiration date: `TanggalBeli + DurasiGaransiBulan`.
  * Computes remaining days and applies color badge (`Aktif`, `Hampir Habis`, `Kedaluwarsa`).
* Empty state feedback when no receipts match the active filter or when the database is empty.
* Pull-to-refresh (`RefreshIndicator`) to sync data with Supabase.

### 3. Manual Receipt Recording (Add Receipt Screen)
* Form inputs: Nama Barang, Nama Toko, Kategori (Dropdown), Tanggal Beli (`showDatePicker`), and Durasi Garansi (in months, with quick-select options like 6, 12, 24 months).
* Strict validation preventing empty submissions.
* Camera & Gallery picker via `image_picker`.
* Image preview box and upload handler sending compressed image files to the Supabase `receipts` storage bucket.

### 4. Detail, Zoom & Deletion
* Full receipt detail view displaying metadata, days remaining, and expiration dates.
* Interactive zoomable receipt photo preview using `InteractiveViewer`.
* Delete confirmation dialog before permanently removing database rows and storage files.

### 5. Local Notification Reminders
* Service class initializing `flutter_local_notifications` and timezone data.
* Automatically schedules local device notifications upon receipt creation:
  * **H-7 Notification:** 7 days prior to warranty expiration.
  * **H-1 Notification:** 1 day prior to warranty expiration.
* Notification copy: `"Garansi [Nama Barang] akan segera habis dalam [X] hari!"`.
* Cancels scheduled notification IDs when the corresponding receipt is deleted.

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
        screens/
          auth_screen.dart
        services/
          auth_service.dart
      receipts/
        enums/
          warranty_status.dart
        models/
          receipt_model.dart
        screens/
          home_screen.dart
          add_receipt_screen.dart
          receipt_detail_screen.dart
        services/
          receipt_service.dart
          storage_service.dart
        widgets/
          receipt_card.dart
          category_chips.dart
    main.dart
  pubspec.yaml
  README.md
```

---

## UI Requirements
* Follow Material Design 3 guidelines.
* Primary theme colors: Deep Navy / Teal with neutral card surfaces.
* Status badge color rules:
  * **Aktif (Active):** Green (`#2E7D32`)
  * **Hampir Habis (Expiring Soon <= 7 Days):** Orange (`#ED6C02`)
  * **Kedaluwarsa (Expired):** Grey / Red (`#D32F2F`)
* Indonesian language localization for all buttons, inputs, alerts, and navigation labels.

---

## Deliverables
* Complete Flutter source code following feature-first structure.
* SQL migration script defining tables, storage buckets, and RLS policies for Supabase.
* `.env.example` containing `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
* Release APK build (`build/app/outputs/flutter-apk/app-release.apk`) targeted for deployment milestone.
* Comprehensive documentation and weekly progress log.