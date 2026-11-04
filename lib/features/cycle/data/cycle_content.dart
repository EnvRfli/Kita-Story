import '../models/cycle_summary.dart';

class PhaseContent {
  final String tagline;
  final String hormoneSummary;
  final List<String> predictedMoods;
  final List<String> commonSymptoms;
  final int energyLevel;
  final List<String> bodyTips;
  final List<String> foodTips;
  final List<String> activityTips;
  final List<String> avoidTips;
  final List<String> partnerTips;
  final List<String> partnerAvoidTips;

  const PhaseContent({
    required this.tagline,
    required this.hormoneSummary,
    required this.predictedMoods,
    required this.commonSymptoms,
    required this.energyLevel,
    required this.bodyTips,
    required this.foodTips,
    required this.activityTips,
    required this.avoidTips,
    required this.partnerTips,
    required this.partnerAvoidTips,
  });
}

class CycleContent {
  static const Map<CyclePhase, PhaseContent> phases = {
    CyclePhase.menstrual: PhaseContent(
      tagline: 'Tubuh sedang beristirahat. Pelan-pelan saja hari ini.',
      hormoneSummary:
          'Estrogen dan progesteron turun, sehingga energi biasanya paling rendah dan tubuh lebih sensitif.',
      predictedMoods: ['Sensitif', 'Mudah lelah', 'Ingin dipeluk'],
      commonSymptoms: [
        'Kram perut',
        'Nyeri punggung',
        'Sakit kepala',
        'Kembung',
        'Mudah lelah',
      ],
      energyLevel: 2,
      bodyTips: [
        'Tempelkan kompres hangat di perut bawah selama 15–20 menit untuk meredakan kram.',
        'Tidur 7–8 jam dan beri jeda istirahat singkat di siang hari.',
        'Coba yoga lembut atau peregangan ringan untuk mengurangi tegang di punggung.',
        'Pakai pakaian yang longgar dan nyaman agar perut tidak tertekan.',
        'Minum air putih cukup; dehidrasi bisa memperparah sakit kepala.',
        'Pijat lembut perut dengan gerakan melingkar searah jarum jam.',
      ],
      foodTips: [
        'Makan makanan kaya zat besi: bayam, daging merah tanpa lemak, kacang-kacangan.',
        'Tambahkan vitamin C dari jeruk atau tomat agar zat besi lebih mudah diserap.',
        'Kurangi garam untuk menekan rasa kembung.',
        'Batasi kafein dan minuman bersoda sementara waktu.',
        'Pilih camilan hangat seperti sup atau bubur agar perut lebih nyaman.',
        'Konsumsi pisang dan alpukat untuk membantu meredakan kram.',
      ],
      activityTips: [
        'Jalan kaki santai 10–15 menit di pagi hari.',
        'Lakukan yoga restoratif atau latihan pernapasan.',
        'Tunda olahraga intensitas tinggi sampai energi kembali.',
        'Buat daftar tugas ringan saja, jangan memaksakan target besar.',
        'Dengarkan tubuh: kalau lelah, istirahat itu produktif.',
        'Habiskan waktu dengan aktivitas tenang seperti membaca atau journaling.',
      ],
      avoidTips: [
        'Hindari olahraga berat saat kram sedang kuat.',
        'Jangan kurang tidur dua malam berturut-turut.',
        'Hindari alkohol dan rokok karena memperlambat pemulihan.',
      ],
      partnerTips: [
        'Siapkan kompres hangat atau teh jahe tanpa perlu diminta.',
        'Bantu pekerjaan rumah yang paling melelahkan hari ini.',
        'Validasi perasaannya: "Aku di sini, kamu nggak harus kuat sendirian."',
        'Tanyakan dengan tenang: "Apa yang paling membantu kamu sekarang?"',
        'Siapkan camilan atau makanan hangat kesukaannya.',
        'Peluk atau temani tanpa harus banyak bicara.',
      ],
      partnerAvoidTips: [
        'Jangan bercanda soal PMS atau suasana hatinya.',
        'Hindari membawa konflik besar ke hari ini.',
        'Jangan menyuruhnya "tinggal semangat" tanpa membantu secara nyata.',
      ],
    ),
    CyclePhase.follicular: PhaseContent(
      tagline: 'Energi mulai naik. Waktu yang tepat untuk memulai hal baru.',
      hormoneSummary:
          'Estrogen meningkat dan memuncak menjelang ovulasi, membuat mood dan stamina biasanya lebih baik.',
      predictedMoods: ['Ceria', 'Percaya diri', 'Termotivasi'],
      commonSymptoms: ['Keputihan bening', 'Energi meningkat', 'Kulit lebih cerah'],
      energyLevel: 4,
      bodyTips: [
        'Manfaatkan energi tinggi untuk olahraga kardio atau latihan kekuatan.',
        'Mulai rutinitas perawatan kulit yang lebih konsisten.',
        'Jaga hidrasi karena tubuh lebih aktif bergerak.',
        'Catat ide-ide baru saat kepala terasa jernih.',
        'Rencanakan olahraga bersama pasangan atau teman agar lebih seru.',
        'Beri waktu untuk hobi yang butuh fokus dan kreativitas.',
      ],
      foodTips: [
        'Perbanyak protein tanpa lemak untuk mendukung pemulihan otot.',
        'Isi piring dengan sayur berwarna dan biji-bijian utuh.',
        'Konsumsi buah segar sebagai sumber energi alami.',
        'Tambahkan fermented food seperti yogurt untuk kesehatan pencernaan.',
        'Jangan lewatkan sarapan di hari dengan aktivitas padat.',
        'Cukupi asupan air, terutama sebelum dan sesudah olahraga.',
      ],
      activityTips: [
        'Jadwalkan proyek atau presentasi penting di fase ini.',
        'Coba kelas olahraga baru atau tantangan fisik ringan.',
        'Atur pertemuan sosial yang kamu tunggu-tunggu.',
        'Selesaikan tugas yang butuh konsentrasi tinggi.',
        'Rapikan rencana mingguan saat motivasi sedang bagus.',
        'Luangkan waktu untuk belajar keterampilan baru.',
      ],
      avoidTips: [
        'Jangan mengabaikan sinyal lelah meski energi sedang tinggi.',
        'Hindari jadwal terlalu padat tanpa waktu istirahat.',
        'Jangan melewatkan makan karena terlalu bersemangat beraktivitas.',
      ],
      partnerTips: [
        'Ajak dia melakukan aktivitas baru atau kencan yang seru.',
        'Dukung ide dan rencananya, beri apresiasi atas usahanya.',
        'Manfaatkan energi positifnya untuk menyelesaikan hal bersama.',
        'Tanyakan rencana yang ingin dia mulai dan bantu mewujudkannya.',
        'Beri pujian yang spesifik, bukan sekadar "kamu hebat".',
        'Rencanakan waktu berkualitas di luar rumah.',
      ],
      partnerAvoidTips: [
        'Jangan menahan semangatnya dengan terlalu banyak kekhawatiran.',
        'Hindari mengabaikan ajakannya karena sibuk.',
        'Jangan membuat janji yang tidak bisa ditepati.',
      ],
    ),
    CyclePhase.ovulation: PhaseContent(
      tagline: 'Puncak energi dan kepercayaan diri. Masa paling subur.',
      hormoneSummary:
          'Lonjakan LH memicu ovulasi. Estrogen tinggi, libido dan rasa percaya diri biasanya meninggi.',
      predictedMoods: ['Bersemangat', 'Percaya diri', 'Mood stabil'],
      commonSymptoms: [
        'Keputihan seperti putih telur',
        'Libido meningkat',
        'Suhu tubuh sedikit naik',
        'Nyeri ringan di satu sisi perut',
      ],
      energyLevel: 5,
      bodyTips: [
        'Gunakan energi puncak untuk olahraga intensitas tinggi bila nyaman.',
        'Jaga hidrasi ekstra, terutama saat berkeringat banyak.',
        'Perhatikan lendir serviks; keputihan bening seperti putih telur adalah normal.',
        'Jadwalkan aktivitas sosial yang penting di sekitar masa ini.',
        'Tetap dengarkan tubuh jika muncul nyeri ovulasi ringan.',
        'Gunakan pakaian dalam berbahan breathable.',
      ],
      foodTips: [
        'Makan makanan kaya antioksidan: beri, brokoli, dan sayuran hijau.',
        'Cukupi protein untuk mendukung aktivitas fisik yang lebih tinggi.',
        'Tambahkan lemak sehat dari alpukat, kacang, atau minyak zaitun.',
        'Minum air lebih banyak dari biasanya.',
        'Batasi makanan olahan agar energi tetap stabil.',
        'Konsumsi makanan kaya zinc seperti biji labu dan telur.',
      ],
      activityTips: [
        'Jadwalkan presentasi, negosiasi, atau wawancara di fase ini.',
        'Coba latihan interval atau angkat beban bila sudah terbiasa.',
        'Rencanakan waktu berdua yang romantis dengan pasangan.',
        'Selesaikan keputusan penting saat kepala terasa jernih.',
        'Ambil inisiatif untuk kegiatan sosial yang kamu inginkan.',
        'Manfaatkan rasa percaya diri untuk mencoba hal baru.',
      ],
      avoidTips: [
        'Jangan memaksakan olahraga berat bila ada nyeri ovulasi.',
        'Hindari dehidrasi saat aktivitas tinggi.',
        'Jangan mengabaikan kebutuhan istirahat meski energi terasa penuh.',
      ],
      partnerTips: [
        'Rencanakan kencan atau momen romantis tanpa menunggu dia meminta.',
        'Bicarakan hal penting saat komunikasinya sedang stabil.',
        'Beri ruang untuk energinya yang tinggi tanpa menahan.',
        'Apresiasi penampilan dan usahanya hari ini.',
        'Luangkan waktu berdua yang benar-benar bebas distraksi.',
        'Ingat bahwa masa subur bukan satu-satunya alasan untuk dekat.',
      ],
      partnerAvoidTips: [
        'Jangan menganggap mood baik berarti semua masalah selesai.',
        'Hindari menjadikan masa subur sebagai tekanan.',
        'Jangan mengabaikan komunikasi soal kenyamanan bersama.',
      ],
    ),
    CyclePhase.luteal: PhaseContent(
      tagline: 'Energi menurun perlahan. Beri ruang untuk diri sendiri.',
      hormoneSummary:
          'Progesteron naik lalu turun menjelang haid. Fluktuasi ini sering memicu PMS, ngidam, dan mood naik-turun.',
      predictedMoods: [
        'Mudah tersinggung',
        'Cemas',
        'Mood naik-turun',
        'Ingin ngemil',
      ],
      commonSymptoms: [
        'Kembung',
        'Nyeri payudara',
        'Jerawat',
        'Ngidam',
        'Sulit tidur',
        'Mudah lelah',
      ],
      energyLevel: 3,
      bodyTips: [
        'Tidur 7–8 jam dan kurangi layar sebelum tidur.',
        'Lakukan jalan santai atau yoga untuk membantu relaksasi.',
        'Kurangi garam dan gula untuk menekan kembung serta ngidam.',
        'Coba journaling singkat untuk mengenali pola mood.',
        'Beri jeda di antara tugas-tugas berat.',
        'Hangatkan tubuh dengan mandi air hangat sebelum tidur.',
      ],
      foodTips: [
        'Pilih camilan sehat seperti buah, kacang, atau yogurt.',
        'Tambahkan magnesium dari bayam, almond, dan pisang.',
        'Cukupi vitamin B6 dari kentang, pisang, dan ayam.',
        'Batasi kafein agar tidur lebih mudah.',
        'Makan dalam porsi kecil tapi sering untuk menjaga energi.',
        'Hindari makanan sangat asin di minggu ini.',
      ],
      activityTips: [
        'Pilih olahraga ringan seperti jalan kaki atau berenang.',
        'Batasi komitmen berat di hari-hari menjelang haid.',
        'Siapkan waktu tenang untuk diri sendiri tanpa rasa bersalah.',
        'Selesaikan tugas kecil agar ruang terasa lebih lega.',
        'Lakukan peregangan 5 menit saat mulai tegang.',
        'Jadwalkan malam tanpa agenda untuk memulihkan energi.',
      ],
      avoidTips: [
        'Hindari konflik besar saat mood sedang sensitif.',
        'Jangan memaksakan olahraga berat bila tubuh lelah.',
        'Hindari begadang dan konsumsi kafein berlebihan.',
      ],
      partnerTips: [
        'Bersabar dan dengarkan tanpa langsung memberi solusi.',
        'Hindari membawa konflik besar selama fase ini.',
        'Bantu siapkan camilan sehat atau makanan yang dia sukai.',
        'Tawarkan quality time yang tenang, bukan agenda padat.',
        'Validasi perasaannya: "Aku paham ini bukan kamu, ini hormon."',
        'Bantu pekerjaan rumah agar dia bisa istirahat lebih awal.',
      ],
      partnerAvoidTips: [
        'Jangan menanggapi sensitivitasnya dengan defensif.',
        'Hindari komentar soal berat badan atau ngidam.',
        'Jangan memaksa dia tetap ceria saat tidak nyaman.',
      ],
    ),
  };

  static PhaseContent forPhase(CyclePhase phase) =>
      phases[phase] ?? phases[CyclePhase.follicular]!;

  /// Rotates [source] so each day of the phase shows a different set of tips.
  static List<String> rotatingTips(
    List<String> source,
    int dayIndex, {
    int count = 3,
  }) {
    if (source.isEmpty) return const [];
    final safeCount = count.clamp(1, source.length);
    final start = (dayIndex - 1) % source.length;
    return List.generate(
      safeCount,
      (index) => source[(start + index) % source.length],
    );
  }
}
