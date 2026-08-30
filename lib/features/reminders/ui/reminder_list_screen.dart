import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/reminder_model.dart';
import '../providers/reminder_provider.dart';
import '../widgets/widgets.dart';

class ReminderListScreen extends StatefulWidget {
  final String? partnerId;
  final String? partnerName;
  final bool isReadOnly;

  const ReminderListScreen({
    super.key,
    this.partnerId,
    this.partnerName,
    this.isReadOnly = false,
  });

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final partner = authProvider.partnerProfile;
      Provider.of<ReminderProvider>(context, listen: false).fetchReminders(
        targetUserId: widget.isReadOnly ? widget.partnerId : null,
        partnerId: partner?.id,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReminderModel> _filterReminders(List<ReminderModel> reminders) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return reminders;

    return reminders.where((r) {
      final title = r.title.toLowerCase();
      final desc = (r.description ?? '').toLowerCase();
      return title.contains(query) || desc.contains(query);
    }).toList();
  }

  Future<void> _openAddReminder() async {
    await context.push('/add-reminder');
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    context.read<ReminderProvider>().fetchReminders(
          partnerId: authProvider.partnerProfile?.id,
        );
  }

  void _openReminderDetail(ReminderModel reminder, List<ReminderModel> list) {
    final index = list.indexOf(reminder);
    ReminderDetailBottomSheet.show(
      context,
      reminders: list,
      initialIndex: index != -1 ? index : 0,
      isReadOnly: widget.isReadOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isReadOnly
        ? (widget.partnerName != null && widget.partnerName!.trim().isNotEmpty
            ? 'Pengingat ${widget.partnerName}'
            : 'Pengingat Pasangan')
        : 'Pengingat';

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: Consumer<ReminderProvider>(
        builder: (_, provider, __) {
          final activeList = _filterReminders(provider.activeReminders);
          final expiredList = _filterReminders(provider.expiredReminders);
          final totalCount = activeList.length + expiredList.length;

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. Top Header App Bar
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
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
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

                // 2. Permanent Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: _buildSearchField(),
                ),

                // 2. Reminders List / Empty State
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      await provider.fetchReminders(
                        targetUserId:
                            widget.isReadOnly ? widget.partnerId : null,
                        partnerId: authProvider.partnerProfile?.id,
                      );
                    },
                    color: const Color(0xFFFF7A00),
                    backgroundColor: Colors.white,
                    child: provider.isLoading && totalCount == 0
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF7A00),
                              ),
                            ),
                          )
                        : totalCount == 0
                            ? _buildEmptyState()
                            : ListView(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  95,
                                ),
                                children: [
                                  // Active Reminders
                                  ...activeList.map((r) => ReminderCard(
                                        reminder: r,
                                        onTap: () => _openReminderDetail(
                                          r,
                                          activeList,
                                        ),
                                      )),

                                  // Expired Reminders (if any)
                                  if (expiredList.isNotEmpty) ...[
                                    if (activeList.isNotEmpty)
                                      const Padding(
                                        padding:
                                            EdgeInsets.only(top: 10, bottom: 12),
                                        child: Text(
                                          'Telah Lewat / Kadaluarsa',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ),
                                    ...expiredList.map((r) => ReminderCard(
                                          reminder: r,
                                          onTap: () => _openReminderDetail(
                                            r,
                                            expiredList,
                                          ),
                                        )),
                                  ],
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
                  onTap: _openAddReminder,
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
          hintText: 'Cari pengingat...',
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.alarm_on_rounded,
                size: 58,
                color: Color(0xFFFF7A00),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Belum Ada Pengingat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Catat hari ulang tahun, anniversary, jadwal kencan, atau tanggal penting lainnya bersama pasangan!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            if (!widget.isReadOnly) ...[
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _openAddReminder,
                icon:
                    const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                label: const Text(
                  'Buat Pengingat Pertama',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
