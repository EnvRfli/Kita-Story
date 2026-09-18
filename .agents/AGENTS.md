# Day Tale Agent Rules & Knowledge Base

Selamat datang di repositori **Day Tale**! Dokumen ini adalah panduan lengkap arsitektur, standar kode, desain UI/UX, konvensi database, dan pengetahuan seluruh fitur untuk setiap AI Agent yang bekerja di proyek ini.

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

### G. Keuangan & Budgeting Tracker (`lib/features/finances`)
* Kartu saldo total gradien ungu 3D dengan kalkulasi otomatis baris bawah *Sisa bulan ini* berbasis sisa kuota budget yang bersifat bulanan (`Total Budget Bulanan - Total Pengeluaran Bulanan Terkait`).
* Kartu ganda pemasukan (toska) dan pengeluaran (koral) per periode berjalan.
* **Card Carousel Kategori & Budget (`FinanceExpenseCarousel`)**:
  * Menggabungkan *Donut Chart* Kategori Pengeluaran (Slide 1) dan *Budget Overview Slide* (Slide 2) dengan indikator titik animasi halus.
* **Fitur Budgeting & Anggaran Kategori (`FinanceBudgetModel`, `budget_list_screen.dart`, `finance_budgets`)**:
  * Fleksibilitas periode: Bulanan (default per tanggal 1 atau custom payday), Mingguan, Harian, atau Rentang Tanggal Kustom.
  * Dukungan **Budget Bersama** pasangan dengan badge hati biru pastel.
  * **Auto-Renew Rollover (Per Jam 00:00 / Ganti Hari)**: Menghitung rentang siklus aktif baru secara instan tanpa lag cron server.
  * **Rekomendasi Belanja Harian (*Daily Safe-to-Spend*)**: Menghitung `sisa budget / sisa hari` untuk menjaga ritme belanja pengguna.
  * **Status Visual 3 Tahap**: Aman (<80%), Waspada (80%-100%), Overbudget (>100%).
  * **Push Notification Lokal Otomatis**: Notifikasi instan via `NotificationService` saat transaksi dicatat dan mencapai threshold 80% atau 100% (dengan flag pencegah notifikasi ganda per siklus).
  * Gamifikasi: `+5 Poin` saat membuat budget baru (`add_budget`).
* **Android Home Screen AppWidget (2x2)**: Widget homescreen native kompak 2x2 dengan gradasi ungu 3D, fokus privasi (menampilkan sisa budget bulanan tanpa saldo keseluruhan), dan tombol aksi cepat (*Quick Actions*) `+ Pendapatan` / `+ Pengeluaran` murni tanpa aset PNG yang terhubung via deep link ke modal form transaksi.

### H. Brankas Kredensial & PIN Keamanan (`lib/features/credentials`, `lib/core/services/encryption_service.dart`)
* **Autentikasi PIN Keamanan 6 Digit (`PinAuthBottomSheet`, `user_security_pins`)**:
  * Desain titik-titik rata tengah dengan animasi *peek* (angka muncul sekilas lalu kembali menjadi titik).
  * Input angka murni (*number only*), auto-reset input jika salah memasukkan PIN.
  * Hashing satu arah aman dengan salt per user (SHA-256) di tabel `user_security_pins`.
* **Field Kredensial Murni Dinamis (`CredentialField`)**:
  * Tidak ada field *hardcoded* (username/password wajib). Pengguna bebas menyimpan 1 nilai (misal: *SSH IP*, *PIN*) atau multi-nilai (misal: *Email + Password + Token*).
  * Form minimalis: Field Tetap hanya **Judul** (*required*) dan **Keterangan** (*opsional*).
  * Tombol `+ Tambah Field Baru` menambahkan kartu field kustom dinamis secara instan.
  * *Auto-obscure*: Jika label mengandung kata *sandi*, *pass*, *pin*, atau *secret*, nilai otomatis disamarkan (*obscured*).
* **Enkripsi Database Dua Arah (AES-256-CBC) (`EncryptionService`)**:
  * Standar industri brankas password (seperti Bitwarden / 1Password).
  * Seluruh data field dinamis dienkripsi ke kolom `encrypted_data` di tabel `user_credentials`.
  * Di server Supabase data berupa ciphertext aman (`<iv>:<ciphertext>`), dan didekripsi otomatis saat dibaca di aplikasi.
* **Kredensial Bersama Pasangan (*Shared Credential*)**:
  * Toggle "Kredensial Bersama" untuk membagikan akun/kredensial ke pasangan secara dua arah.
  * Badge visual "Bersama" (ikon hati biru pastel) pada kartu daftar dan modal detail.
* **Detail Bottom Sheet Ramping**:
  * Container field ramping berukuran ~46px (`minHeight: 46`, padding `vertical: 8`, `borderRadius: 12`) tanpa *touch target bloat*.
  * Tombol salin *copy* (`InkWell`) untuk menyalin nilai secara cepat dengan notifikasi `AppSnackBar`.
  * Tombol mata di pojok kanan atas untuk menyamarkan / membuka seluruh nilai sekaligus.
* **Aturan Gamifikasi Kredensial**:
  * **PENTING**: Gamifikasi **HANYA** berlaku saat **menambah kredensial baru** (`addCredential`):
    * Kredensial Bersama: **`+10 Poin`** (`activityType: 'add_shared_credential'`).
    * Kredensial Pribadi: **`+5 Poin`** (`activityType: 'add_credential'`).
  * Mengedit (`updateCredential`) dan Menghapus (`deleteCredential`) **TIDAK** memberikan/mengurangi poin dan **TIDAK** mencatat riwayat (sesuai instruksi pengguna).

### I. Gamifikasi & Activity Ledger (`lib/features/history`, `lib/core/services/activity_log_service.dart`)
* Setiap tindakan menghasilkan poin otomatis yang dicatat ke `app_users.points` dan tabel `user_point_logs`.
* Layar Riwayat (`history_screen.dart`) menampilkan log aktivitas secara kronologis dengan pencarian real-time.
* Kartu riwayat memiliki visual ikon spesifik (gembok ungu untuk kredensial, pesawat untuk liburan, buku untuk bacaan, centang untuk checklist).

---

## 4. 🗄️ Operasi Database & Keamanan

1. **Operasi Atomik Berjenjang**:
   * Simpan entitas induk terlebih dahulu untuk memperoleh `UUID`, kemudian simpan entitas anak (relasi *foreign key*).
2. **Atribusi Pengguna**:
   * Setiap *insert* row wajib menyertakan `added_by` yang merujuk pada `SupabaseNetwork.client.auth.currentUser!.id`.
   * Pada pembaruan row, sertakan `last_updated_by`.
3. **Penyelarasan Poin**:
   * Selalu gunakan `ActivityLogService.recordActivityAndAddPoints(...)` untuk memastikan poin dan log riwayat tersimpan secara sinkron.
4. **Keamanan Data Sensitif (Enkripsi vs Hashing)**:
   * **PIN Keamanan**: Gunakan *One-Way Hash* dengan salt (`user_security_pins.pin_hash`). Data tidak dapat dibalik.
   * **Data Kredensial / Password / Rekening**: Gunakan *Symmetric Encryption (AES-256-CBC)* via `EncryptionService` ke kolom `encrypted_data`. **Dilarang keras menyimpan password/PIN brankas dalam bentuk plain text**.

---

## 5. 🛠️ Alur Kerja & Referensi

* Sebelum membuat atau memodifikasi modul baru, selalu periksa [`spec.md`](file:///c:/Users/CAS-NB-0024/personal_project/Kita-Story/spec.md).
* Pastikan menjalankan `dart analyze lib/` setelah melakukan perubahan kode untuk menjamin **0 Error, 0 Warning**.

