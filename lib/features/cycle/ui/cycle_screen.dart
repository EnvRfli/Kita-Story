import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/cycle_content.dart';
import '../models/cycle_data.dart';
import '../models/cycle_day_log_model.dart';
import '../models/cycle_summary.dart';
import '../providers/cycle_provider.dart';
import '../utils/cycle_calculator.dart';
import '../utils/cycle_date_utils.dart';
import '../utils/cycle_insight_builder.dart';
import '../utils/cycle_role.dart';
import '../widgets/widgets.dart';

class CycleScreen extends StatefulWidget {
  final String? partnerId;
  final String? partnerName;
  final bool isReadOnly;

  const CycleScreen({
    super.key,
    this.partnerId,
    this.partnerName,
    this.isReadOnly = false,
  });

  @override
  State<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends State<CycleScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = cycleDateOnly(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  CycleRole _resolveRole(AuthProvider auth) {
    if (widget.isReadOnly) {
      return CycleAccess.resolveForPartner(partner: auth.partnerProfile);
    }
    return CycleAccess.resolve(
      me: auth.currentUserProfile,
      partner: auth.partnerProfile,
    );
  }

  String? _resolveUserId(AuthProvider auth, CycleRole role) {
    if (widget.isReadOnly) {
      return widget.partnerId ?? auth.partnerProfile?.id;
    }
    switch (role) {
      case CycleRole.owner:
        return auth.currentUserProfile?.id;
      case CycleRole.monitor:
        return auth.partnerProfile?.id;
      case CycleRole.hidden:
        return null;
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final role = _resolveRole(auth);
    final userId = _resolveUserId(auth, role);
    if (userId == null) return;

    await context.read<CycleProvider>().fetchCycleData(
          userId: userId,
          role: role,
          partnerName: _partnerName(auth),
        );
  }

  String? _partnerName(AuthProvider auth) {
    final explicit = widget.partnerName?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final name = auth.partnerProfile?.name.trim();
    if (name != null && name.isNotEmpty) return name;
    return null;
  }

  CycleSummary? _summaryForDate(DateTime date, CycleSummary base) {
    if (date.isBefore(base.lastPeriodStart)) return null;
    return CycleCalculator.compute(
      lastPeriodStart: base.lastPeriodStart,
      cycleLength: base.cycleLength,
      periodLength: base.periodLength,
      today: date,
      allowRollover: date.isAfter(base.today),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = _resolveRole(auth);
    final userId = _resolveUserId(auth, role);
    final provider = context.watch<CycleProvider>();
    final data = provider.dataFor(userId);
    final partnerName = _partnerName(auth);

    final title = role == CycleRole.monitor
        ? (partnerName != null ? 'Siklus $partnerName' : 'Siklus Pasangan')
        : 'Siklus Haid';

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(
              title,
              onSettings: role == CycleRole.owner && userId != null
                  ? () => CycleSettingsSheet.show(
                        context,
                        userId: userId,
                        settings: data?.settings,
                      )
                  : null,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: const Color(0xFFE11D48),
                backgroundColor: Colors.white,
                child: _buildBody(
                  role: role,
                  userId: userId,
                  data: data,
                  isLoading: provider.isLoadingFor(userId),
                  partnerName: partnerName,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: role == CycleRole.owner && userId != null
          ? _buildFab(userId, data)
          : null,
    );
  }

  Widget _buildHeader(String title, {VoidCallback? onSettings}) {
    return Container(
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
              } else {
                context.go('/home');
              }
            },
          ),
          Expanded(
            child: Text(
              title,
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
          if (onSettings != null)
            IconButton(
              icon: const Icon(
                Icons.tune_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
              tooltip: 'Atur siklus',
              onPressed: onSettings,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBody({
    required CycleRole role,
    required String? userId,
    required CycleData? data,
    required bool isLoading,
    required String? partnerName,
  }) {
    if (role == CycleRole.hidden || userId == null) {
      return _buildAccessDenied();
    }

    if (data == null && isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE11D48)),
        ),
      );
    }

    if (role == CycleRole.monitor) {
      return _buildMonitorContent(data: data, partnerName: partnerName);
    }

    return _buildOwnerContent(userId: userId, data: data);
  }

  Widget _buildOwnerContent({required String userId, required CycleData? data}) {
    final summary = data?.summary;

    if (data == null || summary == null) {
      return _buildOnboarding(userId);
    }

    final selected = _selectedDate;
    final selectedSummary = _summaryForDate(selected, summary);
    final selectedLog = data.logForDate(selected);
    final canLog = !selected.isAfter(summary.today);

    final insightMessage = CycleInsightBuilder.build(
      summary: selectedSummary ?? summary,
      role: CycleRole.owner,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      children: [
        if (data.isStale) ...[
          _buildStaleBanner(userId, data),
          const SizedBox(height: 10),
        ],
        if (summary.isLate) ...[
          CycleLateBanner(
            summary: summary,
            onConfirm: () => _openLogSheet(
              userId: userId,
              date: summary.today,
              initialFlow: 'medium',
            ),
          ),
          const SizedBox(height: 12),
        ],
        CycleMonthCalendar(
          data: data,
          summary: summary,
          selectedDate: selected,
          onSelectDate: (date) => setState(() => _selectedDate = date),
        ),
        const SizedBox(height: 12),
        CycleSelectedDayCard(
          date: selected,
          phase: selectedSummary?.phase,
          log: selectedLog,
          canLog: canLog,
          onLog: () => _openLogSheet(
            userId: userId,
            date: selected,
            log: selectedLog,
          ),
        ),
        const SizedBox(height: 16),
        CycleDailyInsights(
          summary: selectedSummary ?? summary,
          insight: insightMessage.body,
          onOpenAll: () => CycleInsightSheet.show(
            context,
            summary: selectedSummary ?? summary,
          ),
        ),
        const SizedBox(height: 16),
        _buildStatsCard(data, summary),
        const SizedBox(height: 12),
        CycleStreakCard(data: data),
        const SizedBox(height: 12),
        const _Disclaimer(),
      ],
    );
  }

  Widget _buildStatsCard(CycleData data, CycleSummary summary) {
    final ovulationDiff = summary.ovulationDate.difference(summary.today).inDays;
    final ovulationLabel = ovulationDiff == 0
        ? 'Hari ini'
        : (ovulationDiff > 0 ? '$ovulationDiff hari lagi' : 'Sudah lewat');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.auto_awesome_rounded,
              color: const Color(0xFF06B6D4),
              label: 'Ovulasi',
              value: 'Hari ${summary.ovulationDay}',
              subvalue: ovulationLabel,
            ),
          ),
          _statDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.favorite_rounded,
              color: const Color(0xFFE11D48),
              label: 'Masa subur',
              value: cycleShortDayRange(
                summary.fertileStart,
                summary.fertileEnd,
              ),
            ),
          ),
          _statDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.loop_rounded,
              color: const Color(0xFF8B5CF6),
              label: 'Siklus',
              value: '${data.cycleLength} hari',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 30,
      color: const Color(0xFFF1F5F9),
    );
  }

  Widget _buildMonitorContent({
    required CycleData? data,
    required String? partnerName,
  }) {
    final summary = data?.summary;

    if (data == null || summary == null) {
      return _buildPartnerEmptyState(partnerName);
    }

    final name = partnerName ?? 'pasanganmu';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        CyclePhaseHeroCard(
          summary: summary,
          partnerName: partnerName,
          isMonitor: true,
        ),
        if (summary.isLate) ...[
          const SizedBox(height: 12),
          CycleLateBanner(
            summary: summary,
            isPartner: true,
            partnerName: partnerName,
          ),
        ],
        const SizedBox(height: 12),
        _PartnerSymptomsCard(summary: summary),
        const SizedBox(height: 12),
        _PartnerGuideTeaser(
          summary: summary,
          partnerName: partnerName,
          onTap: () => CyclePartnerGuideSheet.show(
            context,
            summary: summary,
            partnerName: partnerName,
          ),
        ),
        const SizedBox(height: 12),
        CycleWeekOutlook(summary: summary),
        const SizedBox(height: 12),
        _buildPartnerLogsCard(data, name),
        const SizedBox(height: 12),
        const _Disclaimer(),
      ],
    );
  }

  Widget _buildPartnerLogsCard(CycleData data, String partnerName) {
    final logs = data.recentLogs.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notes_rounded,
                size: 16,
                color: Color(0xFF0F766E),
              ),
              const SizedBox(width: 6),
              Text(
                'Catatan terbaru $partnerName',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (logs.isEmpty)
            const Text(
              'Belum ada catatan harian.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
            )
          else
            ...logs.map(_buildPartnerLogRow),
        ],
      ),
    );
  }

  Widget _buildPartnerLogRow(CycleDayLogModel log) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: log.flowColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      cycleShortDate(log.logDate),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      log.flowLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: log.flowColor,
                      ),
                    ),
                    if (log.moodLabel != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${log.moodEmoji} ${log.moodLabel}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
                if (log.symptomLabels.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      log.symptomLabels.take(3).join(' · '),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                if (log.notes != null && log.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '"${log.notes}"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboarding(String userId) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF8FAB), Color(0xFFE11D48)],
                  ),
                ),
                alignment: Alignment.center,
                child: const Text('🌸', style: TextStyle(fontSize: 30)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Atur siklusmu dulu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Isi panjang siklus dan hari pertama haid terakhir. '
                'Setelah itu kamu bisa mencatat kondisi harian dan melihat prediksi fase.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => CycleSettingsSheet.show(
                        context,
                        userId: userId,
                        isOnboarding: true,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      child: const Center(
                        child: Text(
                          'Atur Siklus',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerEmptyState(String? partnerName) {
    final name = partnerName ?? 'Pasanganmu';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 28,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$name belum mengatur data siklus',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Minta $name mengisi pengaturan siklus di akunnya. '
                'Setelah itu fase, prediksi, dan panduan harian akan muncul di sini.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccessDenied() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1F2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 28,
                  color: Color(0xFFE11D48),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Fitur siklus tidak tersedia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Fitur ini untuk pengguna dengan gender perempuan, '
                'atau pengguna laki-laki yang pasangannya perempuan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStaleBanner(String userId, CycleData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: Color(0xFFC2410C),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Data siklusmu sudah lama. Perbarui agar prediksi lebih akurat.',
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                color: Color(0xFF9A3412),
              ),
            ),
          ),
          TextButton(
            onPressed: () => CycleSettingsSheet.show(
              context,
              userId: userId,
              settings: data.settings,
            ),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: const Text(
              'Perbarui',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFFC2410C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(String userId, CycleData? data) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE11D48),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openLogSheet(
            userId: userId,
            date: DateTime.now(),
            log: data?.todayLog,
          ),
          customBorder: const CircleBorder(),
          child: const Center(
            child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }

  Future<void> _openLogSheet({
    required String userId,
    required DateTime date,
    CycleDayLogModel? log,
    String? initialFlow,
  }) async {
    await CycleLogSheet.show(
      context,
      userId: userId,
      logToEdit: log,
      initialDate: date,
      initialFlow: initialFlow,
    );
  }
}

class _PartnerSymptomsCard extends StatelessWidget {
  final CycleSummary summary;

  const _PartnerSymptomsCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final content = CycleContent.forPhase(summary.phase);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: summary.phase.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.healing_rounded,
                  size: 14,
                  color: summary.phase.color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gejala umum di fase ${summary.phase.label}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                'Energi ${content.energyLevel}/5',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: content.commonSymptoms
                .take(4)
                .map(
                  (symptom) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      symptom,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PartnerGuideTeaser extends StatelessWidget {
  final CycleSummary summary;
  final String? partnerName;
  final VoidCallback onTap;

  const _PartnerGuideTeaser({
    required this.summary,
    required this.partnerName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = (partnerName == null || partnerName!.trim().isEmpty)
        ? 'pasanganmu'
        : partnerName!.trim();
    final firstTip = CycleContent.rotatingTips(
      CycleContent.forPhase(summary.phase).partnerTips,
      summary.phaseDayIndex,
      count: 1,
    ).first;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 19,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cara mendukung $name',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7C2D12),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstTip,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: Color(0xFF9A3412),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFFC2410C),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? subvalue;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.subvalue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF334155),
          ),
        ),
        if (subvalue != null) ...[
          const SizedBox(height: 1),
          Text(
            subvalue!,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ],
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Fitur ini bersifat edukatif dan bukan alat kontrasepsi atau diagnosis medis. '
        'Konsultasikan ke tenaga kesehatan untuk keluhan yang mengganggu.',
        style: TextStyle(
          fontSize: 10,
          height: 1.4,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
