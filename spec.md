## 1. Executive Summary & Core Context (IMPORTANT FOR AGENT)

Proyek ini adalah pembuatan Couple Lifestyle Super-App berbasis Flutter dan Supabase. 

**PERHATIAN UNTUK AGENT:** Aplikasi ini BUKAN sekadar aplikasi pencatat buku. Ini adalah aplikasi modular yang ke depannya akan berisi puluhan modul (Resep Makanan, Travel Planning, Keuangan/Savings, dll). 

Tugas utama Anda saat ini adalah membangun fondasi Clean Architecture (Core: Theme, Network, Utils, Auth) yang sepenuhnya agnostik/independen, lalu mengimplementasikan Modul 1: Book Tracker. Desain UI harus bernuansa pastel (soft color), imut, dan interaktif.

## 2. Core User Stories (Fase 1 - Book & Auth)

*   **Auth:** Pengguna dapat login sederhana menggunakan Nama dan Password.
*   **Book Management:** Pengguna dapat menambah, mengedit, dan melihat daftar buku (termasuk cover image dari Supabase Storage). Semua aksi mencatat ID pengguna yang melakukan (added_by/updated_by).
*   **Book Notes (Baru):** Pengguna dapat menambahkan catatan spesifik pada halaman tertentu (Misal: "Halaman 152: Adegan pengakuan cinta").
*   **Dynamic Tags:** Pengguna dapat membuat Genre Buku dan Sifat Karakter (Traits) baru secara dinamis, yang ditampilkan sebagai pills/chips.
*   **Character Dex:** Pengguna dapat mendaftarkan karakter yang terikat pada satu buku, beserta foto, peran, halaman kemunculan, dan menghubungkannya dengan banyak Traits (Relasi Many-to-Many).
*   **Gamification:** Setiap aksi create/update memicu penambahan poin untuk Leaderboard.

## 3. Technical Stack & Architecture

*   **Frontend:** Flutter
*   **State Management:** Provider
*   **Routing:** go_router
*   **Backend & DB:** Supabase (PostgreSQL, Auth, Storage)
*   **Architecture:** Feature-First Clean Architecture


## 4. Struktur folder clean architecture

lib/
├── core/
│   ├── theme/           # Warna soft/pastel, typography, custom shapes
│   ├── utils/           # Helper format tanggal, image picker, dll
│   └── network/         # Konfigurasi Supabase Client
├── features/
│   ├── auth/            # Fitur Login Sederhana
│   │   ├── models/
│   │   ├── providers/
│   │   ├── repositories/
│   │   ├── widgets/     # Reusable custom widgets fitur auth
│   │   └── ui/
│   ├── books/           # Fitur Utama Fase 1
│   │   ├── models/      # BookModel, CharacterModel, GenreModel
│   │   ├── providers/   # BookProvider (memanggil repository)
│   │   ├── repositories/# BookRepository (operasi CRUD ke Supabase)
│   │   ├── widgets/     # Reusable widgets, cards, & bottom sheets buku
│   │   └── ui/          # BookListScreen, BookDetailScreen, AddBookScreen
│   ├── home/            # Fitur Halaman Utama
│   │   ├── widgets/
│   │   └── ui/
│   └── leaderboard/     # Fitur Gamifikasi



## 5. Tema Design (Pastel Aesthetic)

* Warna utama: soft pink (#FFD1DC), soft blue (#ADD8E6), mint green (#98FB98), soft yellow (#FFFACD), dan lavender (#E6E6FA).
* font : inter, roboto, poppins
* ikon : material icons, fontawesome
* shadow : box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);

## 6. Mermaid diagram ERD

erDiagram
    APP_USERS ||--o{ BOOKS : "manages"
    APP_USERS ||--o{ BOOK_NOTES : "writes"
    BOOKS ||--o{ BOOK_NOTES : "has"
    BOOKS ||--o{ CHARACTERS : "contains"
    BOOKS ||--o{ BOOK_GENRES : "has"
    GENRES ||--o{ BOOK_GENRES : "belongs to"
    CHARACTERS ||--o{ CHARACTER_TRAITS : "has"
    TRAITS ||--o{ CHARACTER_TRAITS : "belongs to"

    BOOKS {
        UUID id PK
        TEXT title
        INT current_page
    }
    BOOK_NOTES {
        UUID id PK
        UUID book_id FK
        INT page_number
        TEXT note_text
    }
    CHARACTERS {
        UUID id PK
        UUID book_id FK
        TEXT name
    }
    TRAITS {
        UUID id PK
        TEXT name
    }


## 7. Database Schema (Supabase SQL)

```sql
-- 1. Core & Users
CREATE TABLE app_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  birthdate DATE,
  points INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Books Module
CREATE TABLE books (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  author TEXT,
  personal_rating INT CHECK (personal_rating >= 1 AND personal_rating <= 5),
  personal_review TEXT,
  synopsis TEXT,
  cover_url TEXT,
  total_pages INT NOT NULL,
  current_page INT DEFAULT 0,
  added_by UUID REFERENCES app_users(id),
  last_updated_by UUID REFERENCES app_users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Notes Module (Many-to-One dengan Books)
CREATE TABLE book_notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  page_number INT NOT NULL,
  note_text TEXT NOT NULL,
  added_by UUID REFERENCES app_users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Dynamic Tags (Genres, Traits, Character Roles)
CREATE TABLE genres (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  created_by UUID REFERENCES app_users(id)
);

CREATE TABLE traits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  created_by UUID REFERENCES app_users(id)
);

CREATE TABLE character_roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  created_by UUID REFERENCES app_users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Pivot Table Buku <-> Genre
CREATE TABLE book_genres (
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  genre_id UUID REFERENCES genres(id) ON DELETE CASCADE,
  PRIMARY KEY (book_id, genre_id)
);

-- 6. Characters Module
CREATE TABLE characters (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  photo_url TEXT,
  gender TEXT,
  role TEXT,
  first_appearance_page INT,
  added_by UUID REFERENCES app_users(id)
);

-- 7. Pivot Table Karakter <-> Traits
CREATE TABLE character_traits (
  character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
  trait_id UUID REFERENCES traits(id) ON DELETE CASCADE,
  PRIMARY KEY (character_id, trait_id)
);

-- 8. Book Snippets (Quotes & Memorable Moments)
CREATE TABLE book_snippets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  caption TEXT,
  page_number INT,
  added_by UUID REFERENCES app_users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. Gamification & Activity Ledger
CREATE TABLE user_point_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  points_earned INT NOT NULL,
  reference_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_user_point_logs_created_at ON user_point_logs (created_at DESC);