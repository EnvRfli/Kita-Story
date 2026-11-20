import 'package:flutter/material.dart';

import '../models/uno_card.dart';

Future<void> showUnoRulesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => const UnoRulesSheet(),
  );
}

class UnoRulesSheet extends StatelessWidget {
  const UnoRulesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFCFD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Cara Main UNO',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _RuleCard(
                    icon: Icons.style_rounded,
                    title: 'Deck & Pembagian',
                    body:
                        '116 kartu. Masing-masing pemain dapat 7 kartu. Kartu pertama wajib angka; '
                        'kartu aksi/wild diundi ulang. Giliran pertama dipilih acak.',
                  ),
                  _RuleCard(
                    icon: Icons.layers_rounded,
                    title: 'Tumpuk (Chain)',
                    body:
                        'Dalam satu giliran kamu bisa menumpuk beberapa kartu dengan kategori sama:\n'
                        '• angka sama beda warna,\n'
                        '• skip/reverse dengan skip/reverse,\n'
                        '• +1/+2 dengan +1/+2.\n'
                        'Kartu terakhir menentukan warna/angka yang harus dilawan. '
                        'Wild tidak bisa masuk tumpukan angka.',
                  ),
                  _RuleCard(
                    icon: Icons.block_rounded,
                    title: 'Skip & Reverse',
                    body:
                        'Di mode 2 pemain, reverse = skip. Tumpukan skip/reverse (berapa pun '
                        'kartunya) tetap memberi 1 extra turn, dan warna block lanjutan harus '
                        'sama (mis. red reverse → red skip). Kalau tidak bisa main saat extra '
                        'turn, ambil 1 kartu dan sisa extra turn hangus.',
                  ),
                  _RuleCard(
                    icon: Icons.add_circle_rounded,
                    title: 'Draw Stack (+1/+2)',
                    body:
                        'Kartu + bisa ditumpuk sendiri, lalu dioper ke lawan. Lawan hanya boleh balas '
                        'dengan +1 sesuai warna aktif atau +2 (pilih warna baru), lalu menumpuk lagi. '
                        'Skip/reverse tidak bisa dipakai untuk membalas draw. '
                        'Penalti menumpuk: +2 lalu +1 = draw 3, +2 lalu +2 = draw 4. '
                        'Yang menyerah draw total dan kehilangan giliran; pemain terakhir yang main '
                        'draw mulai giliran baru.',
                  ),
                  _RuleCard(
                    icon: Icons.palette_rounded,
                    title: 'Wild & Wild +2',
                    body:
                        'Wild dan wild +2 bisa dimainkan kapan saja. Setelah memilih warna, '
                        'lawan harus mengikuti warna tersebut. Wild tidak bisa ditumpuk dengan angka.',
                  ),
                  _RuleCard(
                    icon: Icons.touch_app_rounded,
                    title: 'Ambil Kartu',
                    body:
                        'Kamu boleh ambil 1 kartu di awal giliranmu, bahkan jika masih punya kartu '
                        'yang cocok. Kartu yang diambil tidak boleh langsung dimainkan, dan giliran '
                        'langsung pindah ke lawan.',
                  ),
                  _RuleCard(
                    icon: Icons.campaign_rounded,
                    title: 'UNO',
                    body:
                        'Saat kartu seorang pemain berkurang dari 2 menjadi 1, notifikasi UNO muncul '
                        'otomatis di tengah layar. Tidak ada tombol tangkap. Notifikasi tidak muncul '
                        'lagi kalau kartu memang sudah tinggal 1 sejak awal giliran.',
                  ),
                  _RuleCard(
                    icon: Icons.emoji_events_rounded,
                    title: 'Menang & Rematch',
                    body:
                        'Pemain pertama yang menghabiskan kartu menang. Kartu terakhir boleh apa saja. '
                        'Rematch harus disetujui dua-duanya lewat undangan baru.',
                  ),
                  _RuleCard(
                    icon: Icons.pause_circle_rounded,
                    title: 'Pause & Koneksi',
                    body:
                        'Pause dan resume harus disetujui dua-duanya. Kalau lawan hilang lebih dari '
                        '5 menit, pemain yang tersisa menang. Tidak ada serobot kartu di luar giliran.',
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Warna aktif:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _ColorDot(color: UnoColor.red),
                      _ColorDot(color: UnoColor.yellow),
                      _ColorDot(color: UnoColor.green),
                      _ColorDot(color: UnoColor.blue),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _RuleCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 21, color: const Color(0xFF334155)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final UnoColor color;

  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.lightColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.primaryColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            color.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color.darkColor,
            ),
          ),
        ],
      ),
    );
  }
}
