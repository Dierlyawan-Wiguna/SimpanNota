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