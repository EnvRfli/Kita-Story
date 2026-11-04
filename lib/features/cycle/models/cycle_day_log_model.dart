import 'package:flutter/material.dart';

import '../utils/cycle_date_utils.dart';

class CycleDayLogModel {
  final String id;
  final String userId;
  final DateTime logDate;
  final String flow;
  final String? mood;
  final List<String> symptoms;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CycleDayLogModel({
    required this.id,
    required this.userId,
    required this.logDate,
    this.flow = 'none',
    this.mood,
    this.symptoms = const [],
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  static const List<String> flowKeys = [
    'none',
    'spotting',
    'light',
    'medium',
    'heavy',
  ];

  static const List<String> moodKeys = [
    'happy',
    'calm',
    'sensitive',
    'sad',
    'irritable',
    'anxious',
    'energetic',
  ];

  static const List<String> symptomKeys = [
    'cramps',
    'headache',
    'bloating',
    'backache',
    'breast_tenderness',
    'acne',
    'fatigue',
    'cravings',
    'nausea',
    'insomnia',
    'mood_swing',
    'discharge',
  ];

  bool get hasBleeding => flow != 'none';

  String get dateKey => cycleDateKey(logDate);

  String get formattedDate => cycleLongDate(logDate);

  String get flowLabel {
    switch (flow) {
      case 'spotting':
        return 'Bercak';
      case 'light':
        return 'Ringan';
      case 'medium':
        return 'Sedang';
      case 'heavy':
        return 'Deras';
      case 'none':
      default:
        return 'Tidak ada';
    }
  }

  Color get flowColor {
    switch (flow) {
      case 'spotting':
        return const Color(0xFFF9A8D4);
      case 'light':
        return const Color(0xFFFB7185);
      case 'medium':
        return const Color(0xFFE11D48);
      case 'heavy':
        return const Color(0xFF9F1239);
      case 'none':
      default:
        return const Color(0xFFCBD5E1);
    }
  }

  String? get moodLabel => moodLabelFor(mood);

  String? get moodEmoji => moodEmojiFor(mood);

  List<String> get symptomLabels =>
      symptoms.map(symptomLabelFor).where((label) => label.isNotEmpty).toList();

  static String? moodLabelFor(String? key) {
    switch (key) {
      case 'happy':
        return 'Senang';
      case 'calm':
        return 'Tenang';
      case 'sensitive':
        return 'Sensitif';
      case 'sad':
        return 'Sedih';
      case 'irritable':
        return 'Mudah tersinggung';
      case 'anxious':
        return 'Cemas';
      case 'energetic':
        return 'Bersemangat';
      default:
        return null;
    }
  }

  static String? moodEmojiFor(String? key) {
    switch (key) {
      case 'happy':
        return '😊';
      case 'calm':
        return '😌';
      case 'sensitive':
        return '🥺';
      case 'sad':
        return '😢';
      case 'irritable':
        return '😤';
      case 'anxious':
        return '😰';
      case 'energetic':
        return '⚡';
      default:
        return null;
    }
  }

  static String symptomLabelFor(String key) {
    switch (key) {
      case 'cramps':
        return 'Kram';
      case 'headache':
        return 'Sakit kepala';
      case 'bloating':
        return 'Kembung';
      case 'backache':
        return 'Nyeri punggung';
      case 'breast_tenderness':
        return 'Nyeri payudara';
      case 'acne':
        return 'Jerawat';
      case 'fatigue':
        return 'Lelah';
      case 'cravings':
        return 'Ngidam';
      case 'nausea':
        return 'Mual';
      case 'insomnia':
        return 'Sulit tidur';
      case 'mood_swing':
        return 'Mood naik-turun';
      case 'discharge':
        return 'Keputihan';
      default:
        return '';
    }
  }

  factory CycleDayLogModel.fromJson(Map<String, dynamic> json) {
    final rawSymptoms = json['symptoms'];
    return CycleDayLogModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      logDate: cycleParseDate(json['log_date']) ?? DateTime.now(),
      flow: (json['flow'] as String?) ?? 'none',
      mood: json['mood'] as String?,
      symptoms: rawSymptoms is List
          ? rawSymptoms.map((item) => item.toString()).toList()
          : const [],
      notes: (json['notes'] as String?)?.trim().isEmpty == true
          ? null
          : (json['notes'] as String?)?.trim(),
      createdAt: cycleParseDate(json['created_at']),
      updatedAt: cycleParseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'log_date': cycleIsoDate(logDate),
      'flow': flow,
      'mood': mood,
      'symptoms': symptoms,
      'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toUtc().toIso8601String(),
    };
  }

  CycleDayLogModel copyWith({
    String? id,
    String? userId,
    DateTime? logDate,
    String? flow,
    String? mood,
    List<String>? symptoms,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CycleDayLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      logDate: logDate ?? this.logDate,
      flow: flow ?? this.flow,
      mood: mood ?? this.mood,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
