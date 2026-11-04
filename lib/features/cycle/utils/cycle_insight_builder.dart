import '../data/cycle_insight_content.dart';
import '../models/cycle_summary.dart';
import 'cycle_role.dart';

class CycleInsightMessage {
  final String title;
  final String body;

  const CycleInsightMessage({required this.title, required this.body});
}

class CycleInsightBuilder {
  static CycleInsightMessage build({
    required CycleSummary summary,
    required CycleRole role,
    String? partnerName,
  }) {
    final isPartner = role == CycleRole.monitor;
    final List<String> source;
    if (summary.isLate) {
      source = isPartner
          ? CycleInsightContent.latePartner
          : CycleInsightContent.lateOwner;
    } else {
      final map = isPartner
          ? CycleInsightContent.partner
          : CycleInsightContent.owner;
      source = map[summary.phase] ?? const [];
    }

    if (source.isEmpty) {
      return CycleInsightMessage(
        title: summary.phase.title,
        body: summary.periodCountdownLabel,
      );
    }

    final index = summary.isLate
        ? (summary.lateDays - 1) % source.length
        : (summary.phaseDayIndex - 1) % source.length;
    final insight = source[index < 0 ? 0 : index];

    if (isPartner) {
      final name = (partnerName?.trim().isNotEmpty ?? false)
          ? partnerName!.trim()
          : 'Pasangan';
      final title = summary.isLate
          ? '⚠️ Siklus $name · Terlambat ${summary.lateDays} hari'
          : '🌹 Siklus $name · ${summary.phase.label}';
      final body = summary.isLate
          ? '$insight Hari ini terlambat ${summary.lateDays} hari.'
          : '$insight Hari ke-${summary.dayOfCycle} siklusnya.';
      return CycleInsightMessage(title: title, body: body);
    }

    final title = summary.isLate
        ? '⏳ Haid terlambat ${summary.lateDays} hari'
        : '${summary.phase.emoji} Hari ${summary.dayOfCycle} · Fase ${summary.phase.label}';
    final body = '$insight ${summary.periodCountdownLabel}.';
    return CycleInsightMessage(title: title, body: body);
  }
}
