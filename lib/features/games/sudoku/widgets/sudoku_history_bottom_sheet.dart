import 'package:flutter/material.dart';
import 'package:kita_story/features/games/sudoku/utils/sudoku_formatters.dart';

class SudokuHistoryEntry {
  final String userId;
  final String userName;
  final String? photoUrl;
  final int durationSeconds;
  final DateTime completedAt;

  const SudokuHistoryEntry({
    required this.userId,
    required this.userName,
    this.photoUrl,
    required this.durationSeconds,
    required this.completedAt,
  });
}

class SudokuHistoryBottomSheet extends StatelessWidget {
  final String difficulty;
  final String currentUserId;
  final List<SudokuHistoryEntry> entries;

  const SudokuHistoryBottomSheet({
    super.key,
    required this.difficulty,
    required this.currentUserId,
    required this.entries,
  });

  List<SudokuHistoryEntry> get _ranking {
    final bestByUser = <String, SudokuHistoryEntry>{};
    for (final entry in entries) {
      final current = bestByUser[entry.userId];
      if (current == null || entry.durationSeconds < current.durationSeconds) {
        bestByUser[entry.userId] = entry;
      }
    }
    final result = bestByUser.values.toList();
    result.sort((a, b) => a.durationSeconds.compareTo(b.durationSeconds));
    return result;
  }

  List<SudokuHistoryEntry> get _recent {
    final result = entries.toList();
    result.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return result.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD76A), Color(0xFFFF9A3D)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leaderboard $difficulty',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Text(
                          'Waktu tercepat kamu dan pasangan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: entries.isEmpty
                  ? const _EmptyHistory()
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        ..._ranking.indexed.map(
                          (item) => _RankingCard(
                            rank: item.$1 + 1,
                            entry: item.$2,
                            isCurrentUser: item.$2.userId == currentUserId,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Riwayat Terbaru',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._recent.map(
                          (entry) => _HistoryRow(
                            entry: entry,
                            isCurrentUser: entry.userId == currentUserId,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  final int rank;
  final SudokuHistoryEntry entry;
  final bool isCurrentUser;

  const _RankingCard({
    required this.rank,
    required this.entry,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: rank == 1
            ? const LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFFF3D1)],
              )
            : null,
        color: rank == 1 ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank == 1 ? const Color(0xFFFFD76A) : const Color(0xFFE8EDF4),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: rank == 1
                    ? const Color(0xFFE49400)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
          _Avatar(entry: entry),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isCurrentUser ? '${entry.userName} (Kamu)' : entry.userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ),
          Text(
            formatSudokuDuration(entry.durationSeconds),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0088FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final SudokuHistoryEntry entry;
  final bool isCurrentUser;

  const _HistoryRow({required this.entry, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final date = entry.completedAt.toLocal();
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          _Avatar(entry: entry, size: 32),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentUser ? '${entry.userName} (Kamu)' : entry.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatSudokuDuration(entry.durationSeconds),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF7A00),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final SudokuHistoryEntry entry;
  final double size;

  const _Avatar({required this.entry, this.size = 38});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = entry.photoUrl != null && entry.photoUrl!.isNotEmpty;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFE6F4FF),
      backgroundImage: hasPhoto ? NetworkImage(entry.photoUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              entry.userName.isEmpty ? '?' : entry.userName[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF0088FF),
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(28, 24, 28, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_empty_rounded,
              size: 48, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          Text(
            'Belum ada penyelesaian',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF475569),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Jadilah yang pertama menyelesaikan level ini!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
