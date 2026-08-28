# Panduan Deploy & Optimasi Build (Ukuran Terkecil)

Dokumen ini berisi panduan lengkap untuk melakukan build dan deployment aplikasi **Kita Story** dengan ukuran file (*size*) sekecil mungkin.

---

## 1. Perintah Cepat (Quick Commands)

Agar tidak perlu mengetik panjang lebar, Anda dapat menggunakan script yang sudah disediakan di root project atau menjalankan perintah one-liner berikut di terminal:

### A. Menggunakan Helper Script
Cukup jalankan salah satu script berikut di PowerShell atau Command Prompt:
```powershell
# Build APK ARM64 (Terkecil untuk HP modern)
.\build_apk.ps1

# Atau menggunakan batch file di CMD / PowerShell
.\build_apk.bat
```

### B. Build Manual One-Liner

#### 1. Build APK Khusus ARM64 (Ukuran Paling Kecil untuk HP Modern)
```powershell
flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons --obfuscate --split-debug-info=build/app/outputs/symbols
```
*Output File:* `build/app/outputs/flutter-apk/app-release.apk`

#### 2. Build APK Terpisah per Arsitektur (Split per ABI)
Menghasilkan 3 file APK terpisah (`arm64-v8a`, `armeabi-v7a`, `x86_64`) untuk kompatibilitas penuh dengan ukuran masing-masing tetap sangat kecil:
```powershell
flutter build apk --release --split-per-abi --no-tree-shake-icons --obfuscate --split-debug-info=build/app/outputs/symbols
```
*Output Files:*
* `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (HP 64-bit)
* `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (HP 32-bit lama)
* `build/app/outputs/flutter-apk/app-x86_64-release.apk` (Emulator/Tablet x86)

#### 3. Build Android App Bundle (AAB - Rekomendasi Play Store)
Format resmi Play Store yang otomatis mengirimkan APK paling ringkas ke tiap HP pengguna:
```powershell
flutter build appbundle --release --no-tree-shake-icons --obfuscate --split-debug-info=build/app/outputs/symbols
```
*Output File:* `build/app/outputs/bundle/release/app-release.aab`

---

## 2. Penjelasan Flag & Optimasi Ukuran

| Flag / Parameter | Fungsi & Dampak pada Ukuran Aplikasi |
| :--- | :--- |
| `--release` | Mengompilasi kode dalam mode produksi AOT, menghapus debug checks, assertion, dan compiler overhead. |
| `--target-platform android-arm64` | Membatasi binary native C++/Rust/Dart hanya untuk arsitektur 64-bit (HP modern). Menghilangkan overhead multi-arch hingga ~50% ukuran APK. |
| `--no-tree-shake-icons` | Mencegah error build saat menggunakan font/ikon dinamis (seperti FontAwesome / CupertinoIcons) tanpa mengorbankan stabilitas. |
| `--obfuscate` | Mengaburkan nama class, method, dan field pada kode Dart yang dikompilasi sehingga kode lebih aman dan ukuran binary snapshot berkurang. |
| `--split-debug-info=<path>` | Mengeluarkan simbol debugging (*stack trace debug symbols*) dari binary APK ke folder terpisah (`build/app/outputs/symbols`), sangat signifikan memangkas ukuran APK. |

---

## 3. Checklist Sebelum Deploy ke Production

1. **Environment Variables (`.env`)**:
   Pastikan URL dan Anon Key Supabase sudah mengarah ke environment production/staging yang sesuai.
2. **Version Code & Name**:
   Tingkatkan versi di `pubspec.yaml` sebelum upload rilis baru:
   ```yaml
   version: 1.0.1+2 # version_name + version_code
   ```
3. **Keystore Signing (Opsional / Play Store)**:
   Untuk rilis publik, atur *key.properties* dan *signingConfigs* di `android/app/build.gradle`.
4. **Debug Symbols Backup**:
   Simpan folder `build/app/outputs/symbols` jika ingin melakukan *de-obfuscation* stack trace error dari Firebase Crashlytics atau Sentry di kemudian hari.
