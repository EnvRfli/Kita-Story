import 'package:flutter/material.dart';

enum CyclePhase { menstrual, follicular, ovulation, luteal }

extension CyclePhaseX on CyclePhase {
  String get label {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Haid';
      case CyclePhase.follicular:
        return 'Folikular';
      case CyclePhase.ovulation:
        return 'Ovulasi';
      case CyclePhase.luteal:
        return 'Luteal';
    }
  }

  String get title {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Fase Haid';
      case CyclePhase.follicular:
        return 'Fase Folikular';
      case CyclePhase.ovulation:
        return 'Fase Ovulasi';
      case CyclePhase.luteal:
        return 'Fase Luteal';
    }
  }

  String get emoji {
    switch (this) {
      case CyclePhase.menstrual:
        return '🌹';
      case CyclePhase.follicular:
        return '🌱';
      case CyclePhase.ovulation:
        return '✨';
      case CyclePhase.luteal:
        return '🌙';
    }
  }

  Color get color {
    switch (this) {
      case CyclePhase.menstrual:
        return const Color(0xFFE11D48);
      case CyclePhase.follicular:
        return const Color(0xFF10B981);
      case CyclePhase.ovulation:
        return const Color(0xFF06B6D4);
      case CyclePhase.luteal:
        return const Color(0xFFF59E0B);
    }
  }

  LinearGradient get gradient {
    switch (this) {
      case CyclePhase.menstrual:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFB7185), Color(0xFFBE123C)],
        );
      case CyclePhase.follicular:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF34D399), Color(0xFF059669)],
        );
      case CyclePhase.ovulation:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF22D3EE), Color(0xFF0284C7)],
        );
      case CyclePhase.luteal:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBBF24), Color(0xFFEA580C)],
        );
    }
  }
}

class CycleSummary {
  final CyclePhase phase;
  final int dayOfCycle;
  final int cycleLength;
  final int periodLength;
  final DateTime today;
  final DateTime lastPeriodStart;
  final DateTime cycleStart;
  final DateTime nextPeriodStart;
  final int ovulationDay;
  final DateTime ovulationDate;
  final DateTime fertileStart;
  final DateTime fertileEnd;
  final int daysUntilNextPeriod;
  final int phaseDayIndex;

  const CycleSummary({
    required this.phase,
    required this.dayOfCycle,
    required this.cycleLength,
    required this.periodLength,
    required this.today,
    required this.lastPeriodStart,
    required this.cycleStart,
    required this.nextPeriodStart,
    required this.ovulationDay,
    required this.ovulationDate,
    required this.fertileStart,
    required this.fertileEnd,
    required this.daysUntilNextPeriod,
    required this.phaseDayIndex,
  });

  bool get isLate => daysUntilNextPeriod < 0;

  int get lateDays => isLate ? -daysUntilNextPeriod : 0;

  bool get isFertileToday =>
      !today.isBefore(fertileStart) && !today.isAfter(fertileEnd);

  double get cycleProgress => ((dayOfCycle - 1) / cycleLength).clamp(0.0, 1.0);

  String get dayLabel {
    if (isLate) return 'Terlambat $lateDays hari';
    if (dayOfCycle > cycleLength) return 'Haid diperkirakan hari ini';
    return 'Hari $dayOfCycle dari $cycleLength';
  }

  String get periodCountdownLabel {
    if (isLate) return 'Terlambat $lateDays hari';
    if (daysUntilNextPeriod == 0) return 'Haid diperkirakan hari ini';
    return 'Haid berikutnya ±$daysUntilNextPeriod hari';
  }

  String get ovulationCountdownLabel {
    final diff = ovulationDate.difference(today).inDays;
    if (diff == 0) return 'Perkiraan ovulasi hari ini';
    if (diff > 0) return 'Perkiraan ovulasi $diff hari lagi';
    return 'Masa subur sudah lewat';
  }
}
