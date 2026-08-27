# Books Feature (Book Tracker)

## Overview
Modul "My Library" untuk melacak progres bacaan, menulis ulasan personal (*Our Thoughts*), mendaftarkan karakter buku, dan menulis catatan bersama (*Shared Notes*).

## Schema Database Terkait
Modul ini bersifat sangat relasional. Semuanya merujuk ke tabel utama `books`.

```sql
-- Tabel Induk
CREATE TABLE books (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    author TEXT,
    personal_rating INT,
    personal_review TEXT,
    synopsis TEXT,
    cover_url TEXT,
    total_pages INT NOT NULL DEFAULT 0,
    current_page INT DEFAULT 0,
    added_by UUID REFERENCES app_users(id),
    last_updated_by UUID REFERENCES app_users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Tabel Relasi
CREATE TABLE genres (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    created_by UUID REFERENCES app_users(id)
);

CREATE TABLE book_genres (
    book_id UUID REFERENCES books(id) ON DELETE CASCADE,
    genre_id INT REFERENCES genres(id) ON DELETE CASCADE,
    PRIMARY KEY (book_id, genre_id)
);

CREATE TABLE characters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    book_id UUID REFERENCES books(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    role TEXT, -- Main, Side, Cameo
    photo_url TEXT,
    added_by UUID REFERENCES app_users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE book_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    book_id UUID REFERENCES books(id) ON DELETE CASCADE,
    page_number INT,
    note_text TEXT NOT NULL,
    added_by UUID REFERENCES app_users(id),
    created_at TIMESTAMP DEFAULT NOW()
);
```

## Alur Kerja (Workflow)
1. **Daftar Buku (`book_list_screen.dart`)**:
   Menampilkan daftar buku secara global melalui `BookProvider.fetchBooks()`. Menggunakan *refresh indicator*.
2. **Tambah / Edit Buku (`add_book_screen.dart`)**:
   - Jika menerima rute dengan objek `BookModel` (via `go_router` extra), form akan masuk ke *Edit Mode* (Auto-fill nyala).
   - Saat di-submit, akan menyimpan Data Buku utama (dan *genre*). Fitur ini memiliki konsep **Atomic-like Save**.
3. **Detail Buku (`book_detail_screen.dart`)**:
   - Karena kerumitan tabel (Characters, Notes, Genres), halaman ini me- *load* datanya sendiri (*local state*) di `initState` lewat `BookRepository`.
   - Menggunakan pendekatan **BottomSheet** interaktif. Apabila user menekan `+ Add Note`, sebuah *sheet* akan naik tanpa mengubah layar, mengirim data insert ke Supabase, dan idealnya me-*refresh* list *Notes* di *local state*.
