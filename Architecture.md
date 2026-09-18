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

## Main Entities & Mapping

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

*(Note: The "Semua" option is purely a UI filter state and must NEVER be stored in the database `category` column).*

### 3. WarrantyStatus (Computed / Virtual Domain Enum)
Warranty status is **not stored statically in the database**. It is dynamically computed on the client side from `tanggalBeli + durasiGaransiBulan`:
* `ACTIVE`: Remaining warranty period > 7 days (Green Badge `#2E7D32`).
* `EXPIRING_SOON`: Remaining warranty period between 1 and 7 days (Orange Badge `#ED6C02`).
* `EXPIRED`: Current date has passed the warranty end date (Grey/Red Badge `#D32F2F`).

### 4. Receipt
Database column to Dart property mapping:

| Dart Field (`camelCase`) | Postgres Column (`snake_case`) | Postgres Data Type | Constraints & Validations |
| :--- | :--- | :--- | :--- |
| `id` | `id` | `UUID` | Primary Key, `default gen_random_uuid()` |
| `userId` | `user_id` | `UUID` | Foreign Key `auth.users(id)` **ON DELETE CASCADE** |
| `namaBarang` | `nama_barang` | `TEXT` | NOT NULL, min 1 character |
| `namaToko` | `nama_toko` | `TEXT` | NOT NULL, min 1 character |
| `tanggalBeli` | `tanggal_beli` | `DATE` | NOT NULL, cannot exceed current date |
| `durasiGaransiBulan`| `durasi_garansi_bulan`| `INTEGER` | NOT NULL, **CHECK (durasi_garansi_bulan > 0)** |
| `fotoPath` | `foto_path` | `TEXT` | Relative path in private bucket (e.g., `{user_id}/{uuid}.jpg`) |
| `kategori` | `kategori` | `TEXT` | NOT NULL, CHECK IN ('elektronik', 'kendaraan', 'pakaian', 'perabotan', 'lainnya') |
| `createdAt` | `created_at` | `TIMESTAMPTZ` | NOT NULL, `default now()` |

---

## Database Rules & Security (Supabase PostgreSQL)
### 1. Table Schema & Constraints
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

-- Enable RLS on receipts table
alter table receipts enable row level security;

create policy "Users can view and manage their own receipts"
on receipts for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
```

### 2. User Lifecycle & Relationship Rules
* Configured with **`ON DELETE CASCADE`**: When a user account is deleted from `auth.users`, all corresponding receipt records in the `receipts` table are automatically deleted.

### 3. Private File Storage Rules (Storage Security)
* Bucket `receipts` is set to **PRIVATE** (public access disabled).
* Files are isolated per user directory: `${user_id}/${receipt_id}.jpg`.
* Storage RLS policy on `storage.objects`:
  ```sql
  create policy "Users can access their own receipt photos"
  on storage.objects for all
  using (bucket_id = 'receipts' and auth.uid()::text = (storage.foldername(name))[1])
  with check (bucket_id = 'receipts' and auth.uid()::text = (storage.foldername(name))[1]);
  ```
* The Flutter application renders receipt photos using temporary **Signed URLs** (`createSignedUrl(fotoPath, 3600)`) with a 60-minute expiration lifespan.

---

## Backend Rules (Supabase & BaaS Logic)
* **Row-Level Security (RLS) Enforcement:** All SELECT, INSERT, UPDATE, and DELETE operations on tables and storage buckets must be authenticated and validated against `auth.uid()`.
* **Zero Leakage:** Public asset URLs are strictly prohibited. Image retrieval must always require valid auth sessions or signed URLs.
* **Storage Cascading Policy:** When a receipt record is deleted, its associated physical image in Supabase Storage must also be removed (`storage.from('receipts').remove([fotoPath])`).
* **Input Validation Enforcement:** Warranty duration must be strictly validated to be $\ge 1$ month across both client-side form logic and database CHECK constraints.

---

## Frontend Pages

### 1. Auth Screen (Login & Register)
* Single screen with a toggle between Login and Register tabs using Email and Password.
* Client-side validation: standard email pattern and password minimum length of 6 characters.
* `AuthGate` listens to Supabase auth state stream:
  * Redirects authenticated sessions directly to `HomeScreen`.
  * Redirects unauthenticated / logged-out sessions to `AuthScreen`.

### 2. Home Screen (Dashboard & Search)
* Interactive horizontal category filter chips: `Semua` (clears filter), `Elektronik`, `Kendaraan`, `Pakaian`, `Perabotan`, `Lainnya`.
* Real-time reactive search bar filtering by `namaBarang` or `namaToko`.
* `ReceiptCard` dynamically computes warranty status via Dart model getters:
  ```dart
  DateTime get tanggalKedaluwarsa => tanggalBeli.add(Duration(days: durasiGaransiBulan * 30));
  int get sisaHari => tanggalKedaluwarsa.difference(DateTime.now()).inDays;
  WarrantyStatus get statusGaransi {
    if (sisaHari < 0) return WarrantyStatus.expired;
    if (sisaHari <= 7) return WarrantyStatus.expiringSoon;
    return WarrantyStatus.active;
  }
  ```
* Pull-to-refresh (`RefreshIndicator`) to reload data from Supabase.
* Floating Action Button (FAB) navigating to `AddReceiptScreen`.
* Sign-out button located in the AppBar.

### 3. Add & Edit Receipt Screen
* Form inputs:
  * Product Name & Store Name (required validation).
  * Category (Dropdown menu containing valid categories, excluding "Semua").
  * Purchase Date (`showDatePicker`, capped at current date).
  * Warranty Duration (positive integer input with quick-select shortcuts: 6, 12, 24 months).
* Camera & Gallery integration: uploads chosen image to private bucket and records relative `fotoPath`.
* Reusable for Edit mode: pre-populates fields to update existing records.

### 4. Receipt Detail Screen
* Displays complete product details, remaining days, and active warranty status.
* Displays receipt image fetched via temporary Signed URL inside an `InteractiveViewer` for pinch-to-zoom support.
* Delete action flow: confirmation dialog -> cancel local notifications -> remove storage image -> delete database row.
---

## Local Notification System
## Local Notification System (Scheduling & Rescheduling Rules)
* Service class managing `flutter_local_notifications` and `timezone`.
* Unique Notification ID convention: uses deterministic integer hashing from `receipt.id` (e.g., `id.hashCode` for H-7 notification, and `id.hashCode + 1` for H-1 notification).
* **Rescheduling Rules (On Edit):**
  * When a user updates `tanggalBeli` or `durasiGaransiBulan`, the system must cancel existing notification IDs first.
  * Recompute expiration date and schedule new H-7 and H-1 local alerts.
* **Cancellation Rules (On Delete):**
  * When a receipt is deleted, the system immediately invokes `cancel(id.hashCode)` and `cancel(id.hashCode + 1)`.
* Notifications must not be scheduled if the target reminder date has already passed.

---

## UI Requirements
* Follow Material Design 3 guidelines.
* Primary theme colors: Deep Navy / Teal with neutral card surfaces.
* Warranty status badge colors:
  * **Active (Aktif):** Green (`#2E7D32`)
  * **Expiring Soon (Hampir Habis <= 7 Days):** Orange (`#ED6C02`)
  * **Expired (Kedaluwarsa):** Grey / Red (`#D32F2F`)
* Indonesian language localization for all user-facing labels, buttons, dialogs, and validation error messages.

---

## Deliverables
* Complete Flutter source code structured with Flutter Riverpod.
* Supabase SQL migration script covering tables, RLS policies, and private storage bucket permissions.
* `.env.example` containing `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
* Release APK binary (`SimpanNota-v1.0.0-Release.apk`) targeting the Week 8 deployment milestone.
* User Acceptance Testing (UAT) report and weekly project progress logs.
  
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
        dto/
          receipt_filter_dto.dart
          notification_payload_dto.dart
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
* All domain entities, enums, and data transfer contracts must reside under shared module paths: `lib/core/` and `lib/features/receipts/domain/`.
* UI modules (Screens & Widgets) are strictly forbidden from parsing raw Map/JSON responses directly from Supabase; all data must flow through shared domain models.
* Prevent duplicate property definitions between the service layer, Riverpod state notifiers, and presentation widgets.

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
* Define Dart entities (`ReceiptModel`, `WarrantyStatus`, `Category`) only once within their assigned domain directories.
* `ReceiptModel` serves as the single source of truth across UI screens (`HomeScreen`, `AddReceiptScreen`, `ReceiptDetailScreen`) and backend services (`ReceiptService`).
* Database serialization:
  * PostgreSQL response to Dart object: `ReceiptModel.fromMap(Map<String, dynamic> map)` handles `snake_case` to `camelCase` mapping.
  * Dart object to Supabase payload: `ReceiptModel.toMap()` outputs a `Map<String, dynamic>` using `snake_case` keys.
* Presentation widgets must consume immutable model instances rather than direct query results.
* `WarrantyStatus` is purely a computed client-side property, never parsed as a static database column.

---
