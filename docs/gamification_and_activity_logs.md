# Dokumentasi Arsitektur: Gamifikasi & Activity Point Ledger (Kita Story)

Dokumen ini menjelaskan arsitektur gamifikasi, sistem pencatatan aktivitas (*Activity & Point Logs*), skema database, serta panduan integrasi ke seluruh fitur aplikasi **Kita Story**.

---

## 🎯 1. Konsep & Arsitektur Utama

1. **Prinsip Atomic-Like Update**:
   * Setiap aktivitas yang menghasilkan poin akan secara bersamaan mencatat entri log ke tabel `user_point_logs` dan menambahkan saldo poin di tabel profil pengguna `app_users.points`.
2. **Pusat Layanan Terpusat (`ActivityLogService`)**:
   * Seluruh repository (`BookRepository`, `RecipeRepository`, `ReminderRepository`, `NoteRepository`, `AuthRepository`) tidak lagi mengelola penambahan poin secara terpisah.
   * Cukup panggil `ActivityLogService.recordActivityAndAddPoints(...)` dengan parameter yang terstandardisasi.
3. **Fail-Safe Fallback**:
   * Layanan mencoba memanggil *stored procedure* RPC Supabase `record_activity_and_add_points` terlebih dahulu.
   * Jika RPC belum terpasang atau gagal, layanan secara otomatis melakukan *direct fallback*: `INSERT` ke `user_point_logs` dan `UPDATE` ke `app_users.points` tanpa memutus jalannya aplikasi.

---

## 📊 2. Matriks Aktivitas, Poin & Log Tracer

| Menu | Aktivitas Pengguna | `activity_type` | Poin | Judul Log | Deskripsi Log |
| :--- | :--- | :--- | :---: | :--- | :--- |
| **Buku** | Tambah Buku Baru | `add_book` | **`+10`** | `Menambah Buku Baru 📖` | `Menambahkan buku "[Judul]"` |
| **Buku** | Update Halaman Bacaan | `update_progress` | **`+5`** | `Update Bacaan 📑` | `Membaca "[Judul]" hingga hal. [Halaman]` |
| **Buku** | Tamat Membaca Buku | `finish_book` | **`+30`** | `Tamat Membaca Buku 🎉` | `Menyelesaikan buku "[Judul]"` |
| **Buku** | Tulis Ulasan & Rating | `review_book` | **`+5`** | `Menulis Ulasan Buku ⭐` | `Memberikan [Rating]★ pada "[Judul]"` |
| **Buku** | Tambah Catatan Buku | `add_book_note` | **`+3/catatan`** | `Menulis Catatan Buku 📝` | `Menambahkan [N] catatan pada "[Judul]"` |
| **Buku** | Tambah Karakter Buku | `add_character` | **`+5`** | `Mendaftarkan Karakter 🎭` | `Menambahkan karakter "[Nama]" ([Role])` |
| **Buku** | Tambah Galeri Foto | `add_snippet` | **`+5`** | `Menambah Galeri Buku 🖼️` | `Mengunggah foto bacaan pada "[Judul]"` |
| **Resep** | Buat Resep Baru | `add_recipe` | **`+10`** | `Menambah Resep Baru 🍳` | `Menulis resep "[Judul]" ([Durasi], [Porsi])` |
| **Resep** | Perbarui Resep | `update_recipe` | **`+3`** | `Memperbarui Resep 📝` | `Memperbarui resep masakan "[Judul]"` |
| **Pengingat** | Buat Pengingat Pribadi | `add_reminder` | **`+5`** | `Membuat Pengingat ⏰` | `Membuat pengingat "[Judul]" untuk [Tanggal]` |
| **Pengingat** | Buat Pengingat Bersama | `add_shared_reminder`| **`+10`** | `Membuat Pengingat Bersama 💕`| `Berbagi pengingat "[Judul]" dengan pasangan` |
| **Pengingat** | Selesaikan Pengingat | `complete_reminder` | **`+10`** | `Menyelesaikan Pengingat ✅` | `Menyelesaikan pengingat "[Judul]"` |
| **Catatan** | Buat Catatan Pribadi | `add_note` | **`+5`** | `Membuat Catatan Baru 📝` | `Membuat catatan "[Judul]"` |
| **Catatan** | Buat Catatan Bersama | `add_shared_note` | **`+10`** | `Membuat Catatan Bersama 👥` | `Berbagi catatan "[Judul]" dengan pasangan` |
| **Catatan** | Selesaikan Catatan | `complete_note` | **`+10`** | `Menyelesaikan Catatan 🎉` | `Menyelesaikan seluruh isi catatan` |
| **Catatan** | Centang Item Checklist | `check_note_item` | **`+1`** | `Checklist Selesai ☑️` | `Mencentang item checklist` |
| **Profil** | Ganti Foto Profil | `update_avatar` | **`+5`** | `Ganti Foto Profil 🖼️` | `Memperbarui foto profil akun` |

---

## 🗄️ 3. Skema Database & RLS (Supabase)

```sql
-- 1. Buat Tabel user_point_logs
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

-- 2. Index Performa
CREATE INDEX IF NOT EXISTS idx_user_point_logs_user_id ON user_point_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_user_point_logs_created_at ON user_point_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_point_logs_activity_type ON user_point_logs(activity_type);

-- 3. Row Level Security (RLS)
ALTER TABLE user_point_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own or partner point logs"
ON user_point_logs FOR SELECT
USING (
  auth.uid() = user_id
  OR EXISTS (
    SELECT 1 FROM app_users 
    WHERE app_users.id = auth.uid() 
    AND (app_users.partner_id = user_point_logs.user_id)
  )
);

CREATE POLICY "Users can insert own point logs"
ON user_point_logs FOR INSERT
WITH CHECK (auth.uid() = user_id);
```

---

## 🔍 4. Contoh Kueri Tracing Log

```sql
-- Melihat 20 Log Aktivitas Terbaru Beserta Nama Pengguna
SELECT 
  l.created_at,
  u.name,
  l.title,
  l.description,
  l.points_earned,
  l.activity_type
FROM user_point_logs l
JOIN app_users u ON u.id = l.user_id
ORDER BY l.created_at DESC
LIMIT 20;

-- Rekap Perolehan Poin Berdasarkan Jenis Aktivitas
SELECT 
  activity_type,
  COUNT(*) AS frekuensi,
  SUM(points_earned) AS total_poin
FROM user_point_logs
GROUP BY activity_type
ORDER BY total_poin DESC;
```
