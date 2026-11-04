import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/poop_log_model.dart';
import '../providers/toilet_provider.dart';
import '../widgets/add_poop_bottom_sheet.dart';
import '../widgets/couple_last_poop_card.dart';
import '../widgets/poop_detail_bottom_sheet.dart';
import '../widgets/poop_log_card.dart';

class ToiletScreen extends StatefulWidget {
  final String? partnerId;
  final String? partnerName;
  final bool isReadOnly;

  const ToiletScreen({
    super.key,
    this.partnerId,
    this.partnerName,
    this.isReadOnly = false,
  });

  @override
  State<ToiletScreen> createState() => _ToiletScreenState();
}

class _ToiletScreenState extends State<ToiletScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final myUid = auth.currentUserProfile?.id;
    final partnerId = widget.partnerId ?? auth.partnerProfile?.id;

    await context.read<ToiletProvider>().fetchPoopLogs(
          targetUserId: widget.isReadOnly ? partnerId : myUid,
          partnerId: partnerId,
        );
  }

  List<PoopLogModel> _filterLogs(
    List<PoopLogModel> allLogs, {
    required String? targetUserId,
  }) {
    final query = _searchController.text.trim().toLowerCase();

    return allLogs.where((log) {
      if (targetUserId != null &&
          targetUserId.isNotEmpty &&
          log.userId != targetUserId) {
        return false;
      }

      if (query.isEmpty) return true;
      final locMatch = log.locationName.toLowerCase().contains(query);
      final addrMatch =
          (log.locationAddress ?? '').toLowerCase().contains(query);
      final noteMatch = (log.note ?? '').toLowerCase().contains(query);
      final stoolMatch = log.stoolTypeShort.toLowerCase().contains(query);

      return locMatch || addrMatch || noteMatch || stoolMatch;
    }).toList();
  }

  Future<void> _openAddSheet() async {
    await AddPoopBottomSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUserProfile;
    final partnerUser = auth.partnerProfile;

    final myUid = currentUser?.id;
    final partnerUid = widget.partnerId ?? partnerUser?.id;
    final activeUserId = widget.isReadOnly ? partnerUid : myUid;

    final partnerName = widget.partnerName?.isNotEmpty == true
        ? widget.partnerName!
        : (partnerUser?.name.isNotEmpty == true ? partnerUser!.name : null);

    final headerTitle = widget.isReadOnly
        ? (partnerName != null ? 'Toilet $partnerName' : 'Toilet Pasangan')
        : 'Toilet';

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: Consumer<ToiletProvider>(
        builder: (context, provider, _) {
          final userLogs = _filterLogs(
            provider.logs,
            targetUserId: activeUserId,
          );
          final latestLog = provider.latestLogForUser(activeUserId);
          final todayCount = provider.todayCountForUser(activeUserId);

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. Standard Symmetric Header Bar
                Container(
                  color: const Color(0xFFFCFCFD),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
                      Expanded(
                        child: Text(
                          headerTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // 2. Permanent Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: _buildSearchField(),
                ),

                // 3. Main Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: const Color(0xFFFF7A00),
                    backgroundColor: Colors.white,
                    child: provider.isLoading && provider.logs.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF7A00),
                              ),
                            ),
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 95),
                            children: [
                              // Compact Playful Status Card
                              CoupleLastPoopCard(
                                latestLog: latestLog,
                                todayCount: todayCount,
                              ),
                              const SizedBox(height: 14),

                              if (userLogs.isEmpty)
                                _searchController.text.trim().isNotEmpty
                                    ? _buildNoSearchResultsState()
                                    : _buildEmptyState()
                              else
                                ...userLogs.map(
                                  (log) => PoopLogCard(
                                    log: log,
                                    onTap: () {
                                      PoopDetailBottomSheet.show(
                                        context,
                                        log: log,
                                        isReadOnly: widget.isReadOnly,
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: widget.isReadOnly
          ? null
          : Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.fabGold,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.fabGold.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openAddSheet,
                  customBorder: const CircleBorder(),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSearchField() {
    return Container(
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
          hintText: 'Cari lokasi atau catatan...',
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
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFEDD5),
                width: 1.5,
              ),
            ),
            child: Image.asset(
              'lib/assets/homescreen assets/toilet.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Text('🚽', style: TextStyle(fontSize: 32)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Catatan Toilet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.isReadOnly
                ? 'Pasanganmu belum memiliki catatan toilet.'
                : 'Tekan tombol + di kanan bawah untuk mulai mencatat.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResultsState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 36,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Catatan Tidak Ditemukan',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tidak ada catatan yang cocok dengan "${_searchController.text.trim()}".',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
