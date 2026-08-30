## 1. Executive Summary & Core Context

**Kita Story** adalah Couple Lifestyle Super-App berbasis Flutter dan Supabase yang dirancang dengan arsitektur modular (*Feature-First Clean Architecture*), antarmuka pastel yang imut (*Cute & Soft Aesthetics*), serta sistem gamifikasi (*Point Ledger & Activity Logging*) yang terintegrasi di seluruh fiturnya.

---

## 2. Core Modules & User Stories

### A. Auth & Partner Management (`lib/features/auth`, `lib/features/profile`)
* **Autentikasi & Akun:** Login/Register via Supabase Auth. Setiap pengguna memiliki profil di `app_users` dengan saldo `points`, foto profil, dan relasi pasangan `partner_id`.
* **Partner Connection:** Menghubungkan akun dengan pasangan sehingga fitur bersama (Catatan Bersama, Pengingat Bersama, dsb.) dapat diakses dua arah secara *real-time*.

### B. Book Tracker & Library (`lib/features/books`)
* **Koleksi & Pelacakan:** Menambah buku, mencatat progres halaman bacaan (`current_page` / `total_pages`), ulasan & rating bintang, serta sinopsis.
* **Karakter & Role Grouping:** Mendaftarkan karakter buku dengan foto, sifat (*traits*), serta pengelompokan role (*Main, Detective, Victim, Supporting*, dll).
* **Catatan & Galeri Buku:** Menyimpan catatan halaman buku (*Book Notes*) dan foto kutipan bacaan (*Book Snippets*).

### C. Resep Masakan / Cooking Diary (`lib/features/recipes`)
* **Manajemen Resep:** Menambah dan mengedit resep masakan dengan estimasi durasi memasak, jumlah porsi, daftar bahan (*ingredients*), serta langkah-langkah memasak (*instructions*).
* **Pratinjau Foto:** Menampilkan foto hasil masakan dengan *interactive pinch & zoom*.

### D. Pengingat & Agenda Bersama (`lib/features/reminders`)
* **Notifikasi Berjenjang:** Menjadwalkan pengingat dengan notifikasi lokal bertahap (1 Bulan -> 1 Minggu -> 3 Hari -> 1 Hari -> 1 Jam -> Hari H).
* **Pengingat Bersama Pasangan:** Opsi *Shared Reminder* agar pengingat tersinkronisasi dan dapat diselesaikan bersama pasangan.

### E. Catatan Bersama & Checklist Kolaboratif (`lib/features/notes`)
* **Tipe Catatan Fleksibel:** Catatan teks biasa atau daftar tugas interaktif (*interactive checklist*).
* **Kolaborasi Penuh (*Shared Notes*):** Berbagi catatan dengan pasangan di mana kedua pihak dapat mengedit, menambah item checklist, mencentang, dan menghapus bersama.
* **Drag-and-Drop Reordering:** Mengatur urutan kartu catatan secara bebas dengan penyimpanan urutan lokal & server.

### F. Liburan & Itinerary Perjalanan (`lib/features/vacations`)
* **Kalender & Timeline Interaktif:** Menjadwalkan liburan, memilih rentang tanggal, melihat kalender bulanan dengan penanda tanggal aktif dan liburan yang sedang berlangsung.
* **Timeline Kegiatan Harian:** Mengatur detail aktivitas per hari liburan (waktu mulai - selesai, judul, deskripsi kegiatan) dengan visual timeline garis berakar dan badge waktu oranye.
* **Smart Filtering & Sorting:** Tab *Semua*, *Sedang Berjalan*, dan *Selesai*. Pengurutan otomatis memprioritaskan liburan yang sedang berlangsung -> mendekati hari H -> masa depan -> selesai ditaruh di bagian terbawah.

### G. Gamifikasi & Activity Ledger (`lib/core/services/activity_log_service.dart`)
* **Poin Otomatis:** Setiap aktivitas produktif dan kolaboratif menghasilkan poin yang dicatat secara atomik ke tabel `app_users.points` dan `user_point_logs`.

---

## 3. Technical Stack & Architecture

* **Frontend Framework:** Flutter (Dart)
* **State Management:** Provider (`ChangeNotifierProvider`, `Consumer`)
* **Navigation & Routing:** `go_router`
* **Backend & Database:** Supabase (PostgreSQL, Row Level Security, Auth, Storage)
* **Design Guidelines:** Pastel Aesthetics, Soft Shadows, Dynamic Spring Animations, Anti-Overflow Responsive Extents

---

## 4. Struktur Folder Clean Architecture

```
lib/
├── core/
│   ├── network/            # Konfigurasi Supabase Client
│   ├── router/             # Konfigurasi go_router
│   ├── services/           # ActivityLogService, NotificationService, SupabaseStorageService, GeminiOcrService
│   ├── theme/              # AppColors, AppTheme, Gradients
│   ├── utils/              # AppSnackBar, Helpers
│   └── widgets/            # GradientAvatar, BouncyPressable, Reusable UI
├── features/
│   ├── auth/               # Autentikasi & Registrasi
│   ├── books/              # Library, Progres, Karakter, Snippet, Notes
│   ├── history/            # Riwayat & Log Aktivitas Pengguna
│   ├── home/               # Dashboard Utama & Partner Home
│   ├── notes/              # Catatan Pribadi & Bersama, Checklist
│   ├── profile/            # Pengaturan Akun & Profil Pasangan
│   ├── recipes/            # Resep Masakan & Panduan Memasak
│   ├── reminders/          # Pengingat, Notifikasi, & Agenda
│   └── vacations/          # Liburan, Kalender, & Itinerary Kegiatan
```

---

## 5. Matriks Poin & Gamifikasi (`user_point_logs`)

| Menu | Aktivitas | `activity_type` | Poin | Judul Log | Deskripsi Log |
| :--- | :--- | :--- | :---: | :--- | :--- |
| **Buku** | Tambah Buku Baru | `add_book` | **`+10`** | `Menambah Buku Baru 📖` | `Menambahkan buku "[Judul]"` |
| **Buku** | Update Halaman Bacaan | `update_progress` | **`+5`** | `Melanjutkan Membaca 🔖` | `Mencapai halaman [Hal] pada buku "[Judul]"` |
| **Buku** | Tamat Membaca Buku | `finish_book` | **`+30`** | `Menamatkan Buku 🏆` | `Menyelesaikan membaca buku "[Judul]"` |
| **Buku** | Tulis Ulasan & Rating | `review_book` | **`+5`** | `Menulis Ulasan Buku ⭐` | `Memberikan [Rating]★ pada "[Judul]"` |
| **Buku** | Tambah Catatan Buku | `add_note` | **`+3/catatan`** | `Menambah Catatan 📝` | `Menambahkan [N] catatan pada buku "[Judul]"` |
| **Buku** | Tambah Karakter Buku | `add_character` | **`+5`** | `Menambah Tokoh Karakter 🎭` | `Mendaftarkan tokoh "[Nama]" pada buku "[Judul]"` |
| **Buku** | Tambah Galeri Foto | `add_snippet` | **`+5`** | `Menambah Cuplikan Foto 📸` | `Menyimpan cuplikan foto halaman [Hal] pada buku "[Judul]"` |
| **Resep** | Buat Resep Baru | `add_recipe` | **`+10`** | `Menulis Resep Baru 🍳` | `Menulis resep "[Judul]" ([Durasi], [Porsi])` |
| **Resep** | Perbarui Resep | `update_recipe` | **`+3`** | `Memperbarui Resep 📝` | `Memperbarui resep masakan "[Judul]"` |
| **Pengingat** | Buat Pengingat Pribadi | `add_reminder` | **`+5`** | `Membuat Pengingat ⏰` | `Membuat pengingat "[Judul]" untuk [Tanggal]` |
| **Pengingat** | Buat Pengingat Bersama | `add_shared_reminder`| **`+10`** | `Membuat Pengingat Bersama 💕`| `Berbagi pengingat "[Judul]" dengan pasangan` |
| **Pengingat** | Selesaikan Pengingat | `complete_reminder` | **`+10`** | `Menyelesaikan Pengingat ✅` | `Menyelesaikan pengingat "[Judul]"` |
| **Catatan** | Buat Catatan Pribadi | `add_note` | **`+5`** | `Membuat Catatan Baru 📝` | `Membuat catatan "[Judul]"` |
| **Catatan** | Buat Catatan Bersama | `add_shared_note` | **`+10`** | `Membuat Catatan Bersama 👥` | `Berbagi catatan "[Judul]" dengan pasangan` |
| **Catatan** | Selesaikan Catatan | `complete_note` | **`+10`** | `Menyelesaikan Catatan 🎉` | `Menyelesaikan seluruh isi catatan "[Judul]"` |
| **Catatan** | Centang Item Checklist | `check_note_item` | **`+1`** | `Checklist Selesai ☑️` | `Mencentang "[Item]" pada catatan "[Judul]"` |
| **Liburan** | Buat Jadwal Liburan | `add_vacation` | **`+10`** | `Menambah Liburan Baru ✈️` | `Menjadwalkan liburan "[Judul]" ([Tgl Mulai] - [Tgl Selesai])` |
| **Liburan** | Tambah Agenda Kegiatan | `add_vacation_activity` | **`+3`** | `Menambah Agenda Liburan 🏖️` | `Menambahkan agenda "[Aktivitas]" pada liburan "[Judul Liburan]"` |
| **Liburan** | Selesaikan Agenda | `complete_vacation_activity` | **`+2`** | `Agenda Selesai ✅` | `Menyelesaikan agenda "[Aktivitas]" pada liburan "[Judul Liburan]"` |
| **Profil** | Ganti Foto Profil | `update_avatar` | **`+5`** | `Ganti Foto Profil 🖼️` | `Memperbarui foto profil akun` |

---

## 6. Database Schema (Supabase PostgreSQL)

```sql
-- 1. Core Users Table
CREATE TABLE IF NOT EXISTS app_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  password_hash TEXT NOT NULL DEFAULT 'managed_by_supabase_auth',
  birthdate DATE,
  points INTEGER NOT NULL DEFAULT 0,
  photo_url TEXT,
  partner_id UUID REFERENCES app_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Books Module
CREATE TABLE IF NOT EXISTS books (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  author TEXT,
  personal_rating INTEGER CHECK (personal_rating >= 1 AND personal_rating <= 5),
  personal_review TEXT,
  synopsis TEXT,
  cover_url TEXT,
  total_pages INTEGER NOT NULL DEFAULT 0,
  current_page INTEGER NOT NULL DEFAULT 0,
  added_by UUID REFERENCES app_users(id) ON DELETE CASCADE,
  last_updated_by UUID REFERENCES app_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS genres (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  created_by UUID REFERENCES app_users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS book_genres (
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  genre_id UUID REFERENCES genres(id) ON DELETE CASCADE,
  PRIMARY KEY (book_id, genre_id)
);

CREATE TABLE IF NOT EXISTS characters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  role TEXT,
  photo_url TEXT,
  gender TEXT,
  first_appearance_page INTEGER,
  added_by UUID REFERENCES app_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS traits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  created_by UUID REFERENCES app_users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS character_traits (
  character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
  trait_id UUID REFERENCES traits(id) ON DELETE CASCADE,
  PRIMARY KEY (character_id, trait_id)
);

CREATE TABLE IF NOT EXISTS book_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  page_number INTEGER NOT NULL DEFAULT 0,
  note_text TEXT NOT NULL,
  added_by UUID REFERENCES app_users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS book_snippets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  caption TEXT,
  page_number INTEGER,
  added_by UUID REFERENCES app_users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Recipes Module
CREATE TABLE IF NOT EXISTS recipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  cooking_duration TEXT NOT NULL,
  portion_size TEXT NOT NULL,
  ingredients JSONB NOT NULL DEFAULT '[]'::jsonb,
  instructions JSONB NOT NULL DEFAULT '[]'::jsonb,
  added_by UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  last_updated_by UUID REFERENCES app_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Reminders Module
CREATE TABLE IF NOT EXISTS reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  target_date TIMESTAMPTZ NOT NULL,
  has_custom_time BOOLEAN NOT NULL DEFAULT false,
  reminder_lead_time TEXT NOT NULL DEFAULT 'on_time',
  is_shared BOOLEAN NOT NULL DEFAULT false,
  partner_id UUID REFERENCES app_users(id) ON DELETE SET NULL,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  added_by UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  last_updated_by UUID REFERENCES app_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. Notes & Checklists Module
CREATE TABLE IF NOT EXISTS notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'text',
  content TEXT,
  color TEXT NOT NULL DEFAULT 'pink',
  is_completed BOOLEAN NOT NULL DEFAULT false,
  completed_at TIMESTAMPTZ,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_shared BOOLEAN NOT NULL DEFAULT false,
  partner_id UUID REFERENCES app_users(id) ON DELETE SET NULL,
  added_by UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  last_updated_by UUID REFERENCES app_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS note_checklist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id UUID NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
  item_text TEXT NOT NULL,
  is_checked BOOLEAN NOT NULL DEFAULT false,
  sort_order INTEGER NOT NULL DEFAULT 0,
  checked_by UUID REFERENCES app_users(id) ON DELETE SET NULL,
  checked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. Vacations Module
CREATE TABLE IF NOT EXISTS vacations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_shared BOOLEAN NOT NULL DEFAULT true,
  partner_id UUID REFERENCES app_users(id) ON DELETE SET NULL,
  added_by UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  last_updated_by UUID REFERENCES app_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_vacations_added_by ON vacations(added_by);
CREATE INDEX IF NOT EXISTS idx_vacations_partner_id ON vacations(partner_id);
CREATE INDEX IF NOT EXISTS idx_vacations_dates ON vacations(start_date, end_date);

CREATE TABLE IF NOT EXISTS vacation_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vacation_id UUID NOT NULL REFERENCES vacations(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  activity_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  sort_order INTEGER NOT NULL DEFAULT 0,
  added_by UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  last_updated_by UUID REFERENCES app_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_vacation_activities_vacation_id ON vacation_activities(vacation_id);
CREATE INDEX IF NOT EXISTS idx_vacation_activities_date ON vacation_activities(activity_date, start_time);

-- 7. Gamification & Activity Ledger
CREATE TABLE IF NOT EXISTS user_point_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  points_earned INTEGER NOT NULL,
  reference_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_point_logs_user_id ON user_point_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_user_point_logs_created_at ON user_point_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_point_logs_activity_type ON user_point_logs(activity_type);
```