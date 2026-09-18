import 'package:flutter/material.dart';

import '../repositories/game_2048_repository.dart';
import '../utils/game_2048_formatters.dart';

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
    final ranking = _bestPerUser(entries);
    final history = List<Game2048LeaderboardEntry>.of(entries)
      ..sort((left, right) => right.completedAt.compareTo(left.completedAt));
    final hasPartner = entries.map((entry) => entry.userId).toSet().length > 1;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .86,
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
        decoration: const BoxDecoration(
          color: Color(0xFFFCFCFD),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: entries.isEmpty
            ? const _EmptyHistory()
            : ListView(
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Papan skor 2048',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasPartner
                        ? 'Rekor terbaik kalian berdua'
                        : 'Rekor terbaikmu sejauh ini',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),
                  ...ranking.indexed.map(
                    (item) => _RankRow(
                      rank: item.$1 + 1,
                      entry: item.$2,
                      currentUserId: currentUserId,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '10 permainan terakhir',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
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
    final sorted = Game2048Repository.sortLeaderboard(entries);
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
          padding: const EdgeInsets.symmetric(vertical: 46),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.emoji_events_outlined,
                  size: 44, color: Color(0xFFA07BFE)),
              SizedBox(height: 12),
              Text('Belum ada permainan selesai',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w800,
                  )),
              SizedBox(height: 6),
              Text('Mulai permainan pertama kalian, yuk!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B))),
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
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: entry.userId == currentUserId
              ? const Color(0xFFF2ECFF)
              : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE8E3F2)),
        ),
        child: Row(children: [
          SizedBox(
            width: 28,
            child: Text('#$rank',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, color: Color(0xFFA07BFE))),
          ),
          const Icon(Icons.person_rounded, color: Color(0xFF64748B)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(_entryName(entry, currentUserId),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Color(0xFF1E293B), fontWeight: FontWeight.w800)),
          ),
          Text(format2048Score(entry.score),
              style: const TextStyle(
                  color: Color(0xFF6B4454), fontWeight: FontWeight.w900)),
        ]),
      );
}

class _RunRow extends StatelessWidget {
  const _RunRow({required this.entry, required this.currentUserId});

  final Game2048LeaderboardEntry entry;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          const Icon(Icons.grid_4x4_rounded, color: Color(0xFFA07BFE)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_entryName(entry, currentUserId),
                    style: const TextStyle(
                        color: Color(0xFF1E293B), fontWeight: FontWeight.w700)),
                Text(
                    'Tile ${entry.highestTile} • ${format2048Duration(entry.durationSeconds)}',
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ),
          Text(format2048Score(entry.score),
              style: const TextStyle(
                  color: Color(0xFF6B4454), fontWeight: FontWeight.w900)),
        ]),
      );
}

String _entryName(Game2048LeaderboardEntry entry, String? currentUserId) {
  final name = entry.userName?.trim().isNotEmpty == true
      ? entry.userName!.trim()
      : 'Pemain';
  return entry.userId == currentUserId ? '$name (Kamu)' : name;
}
