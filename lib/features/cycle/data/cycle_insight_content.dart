import '../models/cycle_summary.dart';

class CycleInsightContent {
  static const Map<CyclePhase, List<String>> owner = {
    CyclePhase.menstrual: [
      'Kram hari ini wajar. Coba kompres hangat 15 menit dan kurangi kafein.',
      'Zat besi sedang banyak keluar. Pilih bayam, telur, atau daging merah hari ini.',
      'Energi tubuh rendah — jalan santai sudah cukup, tidak perlu olahraga berat.',
    ],
    CyclePhase.follicular: [
      'Estrogen naik. Ini waktu terbaik memulai proyek atau olahraga intensitas tinggi.',
      'Mood biasanya lebih cerah. Manfaatkan untuk bertemu orang atau belajar hal baru.',
      'Tubuh lebih kuat hari ini — coba latihan kekuatan 20–30 menit.',
    ],
    CyclePhase.ovulation: [
      'Masa subur puncak. Libido dan kepercayaan diri biasanya meningkat.',
      'Jadwalkan presentasi atau negosiasi penting hari ini — komunikasi sedang tajam.',
      'Perbanyak air putih dan serat agar energi tetap stabil sepanjang hari.',
    ],
    CyclePhase.luteal: [
      'Progesteron naik. Kurangi gula dan kafein untuk meredam mood swing.',
      'Tidur 7–8 jam sangat membantu. Coba matikan layar 30 menit sebelum tidur.',
      'Batasi komitmen berat; sisipkan jalan santai atau journaling sore ini.',
    ],
  };

  static const Map<CyclePhase, List<String>> partner = {
    CyclePhase.menstrual: [
      'Siapkan kompres hangat atau teh jahe tanpa diminta.',
      'Ambil alih pekerjaan rumah yang berat hari ini.',
      'Validasi perasaannya dulu, jangan buru-buru memberi solusi.',
    ],
    CyclePhase.follicular: [
      'Ajak dia melakukan aktivitas baru atau kencan ringan.',
      'Dukung idenya dan beri apresiasi spesifik hari ini.',
      'Energinya sedang naik — ajak olahraga atau jalan sore bersama.',
    ],
    CyclePhase.ovulation: [
      'Rencanakan kencan romantis; energi dan mood-nya sedang tinggi.',
      'Bicarakan hal penting hari ini — komunikasinya biasanya lebih terbuka.',
      'Beri pujian tulus; kepercayaan dirinya sedang meningkat.',
    ],
    CyclePhase.luteal: [
      'Bersabar dengan mood yang berubah; hindari konflik besar.',
      'Siapkan camilan sehat dan tanyakan apa yang dia butuhkan.',
      'Quality time tenang lebih berarti daripada rencana yang padat.',
    ],
  };

  static const List<String> lateOwner = [
    'Haid belum juga datang? Catat hari pertama saat mulai agar prediksi kembali akurat.',
    'Keterlambatan bisa dipengaruhi stres, tidur, atau berat badan. Jangan panik dulu.',
    'Jika terlambat lebih dari 2 minggu, pertimbangkan konsultasi ke tenaga kesehatan.',
  ];

  static const List<String> latePartner = [
    'Dia sedang menunggu haidnya. Tanyakan kabar dengan lembut, tanpa menekan.',
    'Bantu kurangi beban hari ini dan hindari komentar soal berat badan.',
    'Jika dia cemas, temani konsultasi atau cari informasi bersama.',
  ];
}
