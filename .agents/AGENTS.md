# Kita Story Agent Rules & Knowledge Base

Selamat datang di repositori **Kita Story**! Dokumen ini adalah panduan lengkap arsitektur, standar kode, desain UI/UX, konvensi database, dan pengetahuan seluruh fitur untuk setiap AI Agent yang bekerja di proyek ini.

---

## 1. 🏗️ Arsitektur & State Management

* **Feature-First Clean Architecture**: Setiap fitur berada di dalam `lib/features/{nama_fitur}/` yang memiliki sub-struktur rapi:
  * `models/` - Data models & serialization (`fromJson`, `toJson`, `copyWith`).
  * `repositories/` - Data access layer yang berinteraksi langsung dengan Supabase.
  * `providers/` - State management menggunakan `ChangeNotifier`.
  * `widgets/` - Komponen UI spesifik untuk fitur tersebut (bottom sheets, cards, toggles).
  * `ui/` - Layar utama (Screens / Pages).
  * `utils/` - Helper dan parser spesifik fitur (e.g. `note_format_helper.dart`).
* **State Management (`Provider`)**:
  * Gunakan `ChangeNotifierProvider` dan `Consumer` untuk data global aplikasi.
  * Gunakan `setState` **hanya** untuk state lokal/ephemeral antarmuka (form input controller, seleksi tab/bottom sheet, filter pencarian lokal).
  * **Penting**: Filter pencarian pada halaman *list* harus dilakukan di tingkat *widget* (`_filterItems(provider.items)`) berbasis `_searchController.text`, hindari menyimpan string query pencarian fana ke dalam state global provider untuk mencegah *stale search query*.
* **Backend (`Supabase`)**:
  * Gunakan Supabase via `SupabaseNetwork.client`. **Dilarang keras menggunakan Firebase**.
  * File storage diunggah ke bucket `kita-story-bucket` (sub-folder: `covers`, `avatars`, `recipes`, `snippets`).
* **Navigasi & Routing (`go_router`)**:
  * Gunakan `context.push`, `context.go`, `context.pop`, `context.canPop()`. Dilarang menggunakan `Navigator.push` standar kecuali untuk `showModalBottomSheet` / `showDialog`.

---

## 2. 🎨 Desain UI/UX, Estetika & Konvensi Layar (Wajib Diikuti)

* **Tema Estetika**: Pastel, lembut (*soft*), imut (*cute*), modern, dan elegan.
* **Palet Warna Utama (`AppColors` di `lib/core/theme/app_colors.dart`)**:
  * Background Utama: `const Color(0xFFFCFCFD)` / `const Color(0xFFFFF6F8)` (Soft Pinkish/Off-White).
  * Warna Teks Utama: `const Color(0xFF1E293B)` (Slate Dark).
  * Warna Aksen/Maroon: `const Color(0xFF6B4454)` (Deep Maroon).
  * Warna Aksen Oranye: `const Color(0xFFFF7A00)` / `const Color(0xFFFF8A00)` (Vibrant Pastel Orange).
  * Warna Aksen Biru: `const Color(0xFF0088FF)` (Pastel Blue).
  * Warna Border Standar: `const Color(0xFFE2E8F0)` tebal `1.1px` / `1.2px`.
* **Standard Header Bar & Search Bar (Wajib Seragam di Seluruh Layar List)**:
  * **Header Bar**:
    * Sisi Kiri: `IconButton(icon: Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B), size: 22), onPressed: () => context.pop())`.
    * Tengah: `Expanded(child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.3)))`.
    * Sisi Kanan: `const SizedBox(width: 48)` (sebagai penyeimbang simetris tombol kembali).
  * **Permanent Search Bar** (Langsung di bawah Header Bar):
    * Tinggi: `48px`, latar putih bersih, `BorderRadius.circular(12)`, border `Color(0xFFE2E8F0)` lebar `1.1px`.
    * Ikon pencarian `Icons.search_rounded` abu-abu (`Color(0xFF94A3B8)`), tombol hapus teks (`close_rounded`) jika teks terisi, dan pemfilteran instan *real-time*.
* **Standard Bottom Sheet**:
  * Gunakan `showModalBottomSheet` dengan latar transparan, sudut atas melengkung `BorderRadius.vertical(top: Radius.circular(24))`, dan *drag handle* di bagian tengah atas (`38px x 4.5px`, `Color(0xFFCBD5E1)`).
* **Pemotongan Gambar (*Image Cropper*)**:
  * Gunakan `ImageCropDialog` murni Flutter (`lib/core/widgets/image_crop_dialog.dart`).
  * **Dilarang** menambahkan native image cropper plugin untuk menghindari `MissingPluginException`.
  * Rasio 1:1 persegi, auto-cover clamping, `BoxFit.contain` tanpa distorsi, garis bantu grid 3x3.

---

## 3. 📂 Ringkasan Seluruh Modul & Fitur

### A. Autentikasi & Profil (`lib/features/auth`, `lib/features/profile`)
* Autentikasi Supabase Email/Password.
* Manajemen profil pasangan (`partner_id`) untuk kolaborasi dua arah.
* Fitur Fit & Crop foto profil interaktif (`ImageCropDialog`).
* Saldo poin pengguna di `app_users.points`.

### B. Buku & Perpustakaan (`lib/features/books`)
* Koleksi buku dengan progres halaman bacaan (`current_page` / `total_pages`), ulasan & rating bintang 1-5, sinopsis.
* Karakter buku dengan foto, sifat (*traits*), dan *role grouping* (*Main, Detective, Victim, Supporting*, dll).
* Catatan per halaman (*Book Notes*) dan cuplikan foto bacaan (*Book Snippets*).

### C. Resep Masakan (`lib/features/recipes`)
* Buku resep masakan dengan durasi memasak, porsi, daftar bahan (*ingredients*), langkah instruksi (*instructions*).
* Pratinjau foto masakan dengan interaksi *pinch-to-zoom*.
* Filter pencarian real-time dan opsi bottom sheet seragam.

### D. Pengingat & Notifikasi (`lib/features/reminders`)
* Notifikasi berjenjang lokal (1 Bulan -> 1 Minggu -> 3 Hari -> 1 Hari -> 1 Jam -> Hari H).
* Pengingat pribadi dan bersama pasangan (*Shared Reminder*).

### E. Catatan & Checklist Kolaboratif (`lib/features/notes`)
* Mode catatan teks biasa atau checklist interaktif (*interactive checklist*).
* Reordering kartu catatan dengan *drag-and-drop* dan penyimpanan urutan atomik ke server.
* **Fitur Salin/Ekspor WhatsApp**: Mengekspor catatan dengan format judul tebal `*Judul*` dan item checklist tercoret `- ~item selesai~`.
* **Fitur Impor Catatan Teks**: `NoteImportBottomSheet` mendeteksi judul, format checklist `~teks~`, `[x]`, dengan opsi *Append* atau *Replace*.

### F. Liburan & Itinerary (`lib/features/vacations`)
* Perencanaan liburan dengan rentang tanggal kalender, status liburan aktif/mendatang/selesai.
* Timeline agenda harian (waktu mulai-selesai, deskripsi, status selesai) dengan visual garis berakar.

### G. Gamifikasi & Activity Ledger (`lib/features/history`, `lib/core/services/activity_log_service.dart`)
* Setiap tindakan menghasilkan poin otomatis yang dicatat ke `app_users.points` dan tabel `user_point_logs`.
* Layar Riwayat (`history_screen.dart`) menampilkan log aktivitas secara kronologis dengan pencarian real-time.

---

## 4. 🗄️ Operasi Database & Keamanan

1. **Operasi Atomik Berjenjang**:
   * Simpan entitas induk terlebih dahulu untuk memperoleh `UUID`, kemudian simpan entitas anak (relasi *foreign key*).
2. **Atribusi Pengguna**:
   * Setiap *insert* row wajib menyertakan `added_by` yang merujuk pada `SupabaseNetwork.client.auth.currentUser!.id`.
   * Pada pembaruan row, sertakan `last_updated_by`.
3. **Penyelarasan Poin**:
   * Selalu gunakan `ActivityLogService.recordActivityAndAddPoints(...)` untuk memastikan poin dan log riwayat tersimpan secara sinkron.

---

## 5. 🛠️ Alur Kerja & Referensi

* Sebelum membuat atau memodifikasi modul baru, selalu periksa [`spec.md`](file:///c:/Users/CAS-NB-0024/personal_project/Kita-Story/spec.md).
* Pastikan menjalankan `dart analyze lib/` setelah melakukan perubahan kode untuk menjamin **0 Error, 0 Warning**.
