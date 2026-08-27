# Authentication Feature

## Overview
Modul Autentikasi menangani sistem *Login/Register* (Email & Password), penyediaan Session via Supabase Auth, serta sinkronisasi data *user* lokal ke tabel `app_users`.

## Schema Database Terkait
```sql
CREATE TABLE app_users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT,
    photo_url TEXT,
    points INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);
```

## Komponen
1. **Model (`user_model.dart`)**: 
   Memetakan *field* `id`, `email`, `displayName`, `photoUrl`, dan `points`.
2. **Repository (`auth_repository.dart`)**:
   - `signIn()` & `signUp()`: Berinteraksi dengan `_client.auth`.
   - `ensureUserRecord()`: *Trigger* manual (jika tidak menggunakan PostgreSQL *trigger*) untuk memastikan `auth.users` ter-duplikasi ke tabel `app_users` untuk keperluan relasi dan fitur *points*.
3. **Provider (`auth_provider.dart`)**:
   - Menyimpan *state* user saat ini (`UserModel`).
   - Menyediakan metode `signOut()`.
4. **UI**:
   - `splash_screen.dart`: Cek session awal, lalu *redirect* ke `/home` jika ada, atau `/login` jika tidak.
   - `login_screen.dart`: UI minimalis untuk memasukkan email dan password.

## Gamification (Points)
Setiap aksi (contoh: tambah buku) memanggil fungsi SQL (RPC):
```sql
CREATE OR REPLACE FUNCTION increment_points(user_id UUID, point_amount INT)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE app_users SET points = points + point_amount WHERE id = user_id;
END;
$$;
```
