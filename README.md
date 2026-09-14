# 💕 Kita Story — Couple Lifestyle Super-App

**Kita Story** adalah aplikasi gaya hidup pasangan (*couple lifestyle super-app*) modern berbasis **Flutter** dan **Supabase**. Dirancang dengan arsitektur bersih (*Clean Architecture*), antarmuka pastel lembut nan imut (*Cute & Pastel Aesthetics*), serta sistem gamifikasi (*Gamification & Activity Ledger*) yang memberi poin di setiap aktivitas kolaboratif pasangan.

---

## 🌟 Fitur Utama

### 1. 🔐 Brankas Kredensial & Keamanan PIN (`lib/features/credentials`)
* **PIN Keamanan 6 Digit**: Layar input PIN titik-titik interaktif dengan animasi *peek* dan proteksi salt SHA-256.
* **Field Kredensial Murni Dinamis**: Form fleksibel tanpa batasan kolom kaku—dapat menyimpan single value (misal: SSH IP, PIN kartu) maupun multi-value (misal: Email + Password + Token).
* **Enkripsi Database Dua Arah (AES-256-CBC)**: Seluruh data kredensial disimpan terenkripsi di Supabase dan didekripsi otomatis saat dibuka di aplikasi.
* **Kredensial Bersama**: Opsi berbagi akun dengan pasangan secara aman dengan badge visual khusus.
* **Detail Ramping & Fitur Salin Cepat**: Modal detail dengan titik dua sejajar dan tombol salin ke clipboard dalam satu ketukan.

### 2. 📖 Buku & Perpustakaan Pribadi (`lib/features/books`)
* **Pelacakan Bacaan**: Progres halaman bacaan (*current page* / *total pages*), status baca, ulasan, rating bintang 1-5, dan sinopsis.
* **Karakter Buku**: Daftar tokoh karakter dengan foto, traits, dan pengelompokan role (*Main, Supporting, Detective, dll.*).
* **Catatan & Cuplikan**: Catatan per halaman dan galeri foto kutipan bacaan (*Book Snippets*).

### 3. 💰 Keuangan & Budgeting Tracker (`lib/features/finances`)
* **Kartu Saldo 3D**: Menampilkan akumulasi saldo total, toggle sembunyikan nominal, dan kalkulasi otomatis *Sisa Bersih Tabungan Bulan Ini*.
* **Ringkasan Pemasukan & Pengeluaran**: Kartu ringkasan terpisah dan Donut Chart kategori pengeluaran murni Flutter `CustomPainter`.
* **Pencatatan Transaksi**: Form transaksi dengan format rupiah otomatis dan modal detail untuk ubah/hapus.

### 4. 🍳 Resep Masakan / Cooking Diary (`lib/features/recipes`)
* **Manajemen Resep**: Panduan memasak lengkap dengan durasi, porsi, daftar bahan (*ingredients*), dan langkah-langkah (*instructions*).
* **Pratinjau Foto Interaktif**: Zoom foto masakan dengan interaksi *pinch-to-zoom*.

### 5. 📝 Catatan Bersama & Checklist Kolaboratif (`lib/features/notes`)
* **Dua Mode Catatan**: Catatan teks biasa atau checklist tugas interaktif.
* **Kolaborasi Real-time**: Catatan bersama pasangan dengan kemampuan centang bersama dan reordering *drag-and-drop*.
* **Ekspor & Impor Pintar**: Salin format tebal & coret WhatsApp (`*Judul*`, `- ~selesai~`) dan impor teks otomatis.

### 6. ⏰ Pengingat & Notifikasi Berjenjang (`lib/features/reminders`)
* **Notifikasi Lokal Bertahap**: Pengingat berjenjang (1 Bulan -> 1 Minggu -> 3 Hari -> 1 Hari -> 1 Jam -> Hari H).
* **Pengingat Bersama**: Pengingat sinkron dua arah bersama pasangan.

### 7. ✈️ Liburan & Itinerary Perjalanan (`lib/features/vacations`)
* **Kalender & Timeline Interaktif**: Penjadwalan liburan dengan rentang tanggal kalender dan filter status liburan.
* **Timeline Kegiatan Harian**: Agenda terperinci harian dengan garis berakar dan badge waktu oranye.

### 8. 🎮 Gamifikasi & Activity Ledger (`lib/features/history`)
* **Poin Otomatis**: Setiap aktivitas produktif dan kolaboratif menghasilkan poin yang dicatat ke saldo pengguna dan log riwayat.
* **Layar Riwayat Kronologis**: Riwayat seluruh aktivitas dengan pencarian lokal real-time dan ikon visual khusus per kategori.

---

## 🛠️ Tech Stack & Dependencies

* **Framework**: Flutter 3 (Dart SDK `>=3.0.0`)
* **State Management**: Provider (`ChangeNotifierProvider`, `Consumer`)
* **Navigation**: `go_router`
* **Backend & Database**: Supabase (PostgreSQL, Row Level Security, Auth, Storage)
* **Kriptografi & Keamanan**: `encrypt` (AES-256-CBC), `crypto` (SHA-256 Salted Hashing)
* **Penyimpanan Lokal**: `shared_preferences`
* **Notifikasi Lokal**: `flutter_local_notifications`

---

## 🏗️ Struktur Proyek (Clean Architecture)

```
lib/
├── core/
│   ├── network/            # Supabase Client configuration
│   ├── router/             # go_router configuration
│   ├── services/           # ActivityLogService, EncryptionService, NotificationService
│   ├── theme/              # AppColors, AppTheme, Gradients
│   ├── utils/              # AppSnackBar, Helpers
│   └── widgets/            # Pure Flutter ImageCropDialog, Avatars, Modals
├── features/
│   ├── auth/               # Autentikasi & Koneksi Pasangan
│   ├── books/              # Perpustakaan & Karakter Buku
│   ├── credentials/        # Brankas Kredensial & PIN Keamanan
│   ├── finances/           # Keuangan, Saldo, Donut Chart
│   ├── history/            # Riwayat Aktivitas & Gamifikasi
│   ├── home/               # Dashboard Utama & Profil Pasangan
│   ├── notes/              # Catatan & Checklist Kolaboratif
│   ├── profile/            # Pengaturan Profil & Avatar Cropper
│   ├── recipes/            # Resep Masakan & Detail
│   ├── reminders/          # Pengingat & Notifikasi Berjenjang
│   └── vacations/          # Liburan & Timeline Itinerary
```

---

## 🚀 Memulai (Getting Started)

1. **Clone repository**:
   ```bash
   git clone https://github.com/EnvRfli/Kita-Story.git
   cd Kita-Story
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Supabase**:
   Pastikan kredensial Supabase terpasang di `lib/core/network/supabase_client.dart` dan jalankan skema SQL yang ada di [spec.md](file:///c:/Users/CAS-NB-0024/personal_project/Kita-Story/spec.md#L130-L390).

4. **Jalankan analisis kode**:
   ```bash
   dart analyze lib/
   ```

5. **Jalankan aplikasi**:
   ```bash
   flutter run
   ```
