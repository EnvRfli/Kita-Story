import 'package:flutter/material.dart';

import '../repositories/game_2048_repository.dart';
import '../utils/game_2048_formatters.dart';
import 'game_2048_tile_widget.dart';

class Game2048HistoryBottomSheet extends StatelessWidget {
  const Game2048HistoryBottomSheet({
    required this.entries,
    required this.currentUserId,
    super.key,
  });

  final List<Game2048LeaderboardEntry> entries;
  final String? currentUserId;

  static Future<void> show(
    BuildContext context, {
    required List<Game2048LeaderboardEntry> entries,
    required String? currentUserId,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Game2048HistoryBottomSheet(
          entries: entries,
          currentUserId: currentUserId,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final validEntries = entries.where((entry) => entry.score > 0).toList();
    final ranking = _bestPerUser(validEntries);
    final history = List<Game2048LeaderboardEntry>.of(validEntries)
      ..sort((left, right) => right.completedAt.compareTo(left.completedAt));
    final hasPartner =
        validEntries.map((entry) => entry.userId).toSet().length > 1;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .88,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
        decoration: const BoxDecoration(
          color: Color(0xFFFCFCFD),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: validEntries.isEmpty
            ? const _EmptyHistory()
            : ListView(
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text('🏆', style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Papan Skor 2048',
                              style: TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasPartner
                                  ? 'Rekor terbaik kalian berdua'
                                  : 'Rekor terbaikmu sejauh ini',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded,
                            size: 20, color: Color(0xFF64748B)),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...ranking.indexed.map(
                    (item) => _RankRow(
                      rank: item.$1 + 1,
                      entry: item.$2,
                      currentUserId: currentUserId,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Text(
                        '10 Permainan Terakhir',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${history.take(10).length}',
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...history.take(10).map(
                        (entry) => _RunRow(
                          entry: entry,
                          currentUserId: currentUserId,
                        ),
                      ),
                ],
              ),
      ),
    );
  }

  static List<Game2048LeaderboardEntry> _bestPerUser(
    Iterable<Game2048LeaderboardEntry> entries,
  ) {
    final valid = entries.where((e) => e.score > 0);
    final sorted = Game2048Repository.sortLeaderboard(valid);
    final seenUsers = <String>{};
    return [
      for (final entry in sorted)
        if (seenUsers.add(entry.userId)) entry,
    ];
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF5FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0088FF).withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🎮', style: TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum Ada Riwayat Skor',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Mainkan game 2048 dan raih skor tertinggimu bersama pasangan!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
              ),
            ],
          ),
        ),
      );
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.entry,
    required this.currentUserId,
  });

  final int rank;
  final Game2048LeaderboardEntry entry;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final isMe = entry.userId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: isMe
            ? const LinearGradient(
                colors: [Color(0xFFF0F7FF), Color(0xFFE8F2FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFFF0F5), Color(0xFFFFEBF2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMe ? const Color(0xFFCCE4FF) : const Color(0xFFFFD1E1),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (isMe ? const Color(0xFF0088FF) : const Color(0xFFFF69B4))
                .withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: rank == 1
                  ? const LinearGradient(
                      colors: [Color(0xFFFFE082), Color(0xFFFFCA28)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (rank == 1
                          ? const Color(0xFFFFB300)
                          : const Color(0xFF94A3B8))
                      .withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                rank == 1 ? '👑' : '#$rank',
                style: TextStyle(
                  fontSize: rank == 1 ? 20 : 15,
                  fontWeight: FontWeight.w900,
                  color: rank == 1
                      ? const Color(0xFF78350F)
                      : const Color(0xFF475569),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _entryName(entry, currentUserId),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Game2048TileWidget.colorFor(entry.highestTile),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Ubin ${entry.highestTile} • ${entry.movesCount} langkah',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                format2048Score(entry.score),
                style: const TextStyle(
                  color: Color(0xFF0088FF),
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                  letterSpacing: -0.4,
                ),
              ),
              const Text(
                'poin',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RunRow extends StatelessWidget {
  const _RunRow({required this.entry, required this.currentUserId});

  final Game2048LeaderboardEntry entry;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDF2F7), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Miniature Playful Tile
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Game2048TileWidget.colorFor(entry.highestTile),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: Game2048TileWidget.colorFor(entry.highestTile)
                        .withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '${entry.highestTile}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _entryName(entry, currentUserId),
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.touch_app_rounded,
                          size: 12.5, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 3),
                      Text(
                        '${entry.movesCount} langkah',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Text('•',
                            style: TextStyle(
                                color: Color(0xFFCBD5E1), fontSize: 11)),
                      ),
                      const Icon(Icons.timer_outlined,
                          size: 12.5, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 3),
                      Text(
                        format2048Duration(entry.durationSeconds),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF5FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    format2048Score(entry.score),
                    style: const TextStyle(
                      color: Color(0xFF0088FF),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _timeAgo(entry.completedAt),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

String _entryName(Game2048LeaderboardEntry entry, String? currentUserId) {
  final name = entry.userName?.trim().isNotEmpty == true
      ? entry.userName!.trim()
      : 'Pemain';
  return entry.userId == currentUserId ? '$name (Kamu)' : name;
}

String _timeAgo(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  if (difference.inDays > 30) {
    return '${difference.inDays ~/ 30} bln lalu';
  } else if (difference.inDays > 0) {
    return '${difference.inDays} hr lalu';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} jam lalu';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} mnt lalu';
  } else {
    return 'Baru saja';
  }
}
