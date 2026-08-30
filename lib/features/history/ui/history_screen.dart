import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/activity_log_model.dart';
import '../providers/history_provider.dart';
import '../widgets/history_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().fetchLogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ActivityLogModel> _filterLogs(List<ActivityLogModel> logs) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return logs;

    return logs.where((log) {
      final titleMatch = log.title.toLowerCase().contains(query);
      final descMatch = log.description.toLowerCase().contains(query);
      final userMatch = log.userName?.toLowerCase().contains(query) ?? false;
      return titleMatch || descMatch || userMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Header Bar
            Container(
              color: const Color(0xFFFCFCFD),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF1E293B),
                      size: 22,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      }
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Riwayat',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balances leading back button
                ],
              ),
            ),

            // 2. Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari riwayat...',
                    hintStyle: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF94A3B8),
                              size: 16,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // 2. Activity Logs List
            Expanded(
              child: Consumer<HistoryProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF8A00),
                      ),
                    );
                  }

                  if (provider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Color(0xFFF43F5E),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.errorMessage!,
                            style: const TextStyle(color: Color(0xFF64748B)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.fetchLogs(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF8A00),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  }

                  final logs = _filterLogs(provider.logs);

                  if (logs.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => provider.fetchLogs(isRefresh: true),
                      color: const Color(0xFFFF8A00),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 80),
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7ED),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFFEDD5),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.history_rounded,
                                      size: 36,
                                      color: Color(0xFFFF8A00),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.trim().isNotEmpty
                                      ? 'Tidak ada riwayat yang cocok'
                                      : 'Belum Ada Riwayat Aktivitas',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _searchController.text.trim().isNotEmpty
                                      ? 'Coba gunakan kata kunci pencarian yang lain.'
                                      : 'Aktivitas membaca, resep, catatan, dan pengingat akan tercatat di sini.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.fetchLogs(isRefresh: true),
                    color: const Color(0xFFFF8A00),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      itemCount: logs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return HistoryCard(log: log);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
