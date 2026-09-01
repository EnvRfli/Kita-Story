import 'package:flutter/material.dart';
import 'checklist_item_model.dart';

class NoteModel {
  final String id;
  final String title;
  final String type; // 'text' or 'checklist'
  final String? content;
  final String color; // 'pink', 'yellow', 'orange', 'green', 'blue', 'purple'
  final bool isCompleted;
  final DateTime? completedAt;
  final String? addedBy;
  final String? lastUpdatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int sortOrder;
  final bool isShared;
  final String? partnerId;
  final List<ChecklistItemModel> items;

  const NoteModel({
    required this.id,
    required this.title,
    this.type = 'text',
    this.content,
    this.color = 'pink',
    this.isCompleted = false,
    this.completedAt,
    this.addedBy,
    this.lastUpdatedBy,
    this.createdAt,
    this.updatedAt,
    this.sortOrder = 0,
    this.isShared = false,
    this.partnerId,
    this.items = const [],
  });

  bool get isChecklist => type == 'checklist';

  factory NoteModel.fromJson(
    Map<String, dynamic> json, {
    List<ChecklistItemModel> items = const [],
  }) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Tanpa Judul',
      type: json['type'] as String? ?? 'text',
      content: json['content'] as String?,
      color: json['color'] as String? ?? 'pink',
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)?.toLocal()
          : null,
      addedBy: json['added_by'] as String?,
      lastUpdatedBy: json['last_updated_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)?.toLocal()
          : null,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isShared: json['is_shared'] as bool? ?? false,
      partnerId: json['partner_id'] as String?,
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'content': content,
      'color': color,
      'is_completed': isCompleted,
      'sort_order': sortOrder,
      'is_shared': isShared,
      if (partnerId != null) 'partner_id': partnerId,
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (addedBy != null) 'added_by': addedBy,
      if (lastUpdatedBy != null) 'last_updated_by': lastUpdatedBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  NoteModel copyWith({
    String? id,
    String? title,
    String? type,
    String? content,
    String? color,
    bool? isCompleted,
    DateTime? completedAt,
    String? addedBy,
    String? lastUpdatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sortOrder,
    bool? isShared,
    String? partnerId,
    List<ChecklistItemModel>? items,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      content: content ?? this.content,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      addedBy: addedBy ?? this.addedBy,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      isShared: isShared ?? this.isShared,
      partnerId: partnerId ?? this.partnerId,
      items: items ?? this.items,
    );
  }

  /// Color palette helper for pastel sticky cards
  Color get cardBackgroundColor {
    switch (color) {
      case 'yellow':
        return const Color(0xFFFFD166);
      case 'orange':
        return const Color(0xFFFFA07A);
      case 'green':
        return const Color(0xFFC4D685);
      case 'blue':
        return const Color(0xFF90CAF9);
      case 'purple':
        return const Color(0xFFCE93D8);
      case 'pink':
      default:
        return const Color(0xFFFF94B4);
    }
  }

  Color get cardTextColor {
    switch (color) {
      case 'yellow':
        return const Color(0xFF5D4037);
      case 'orange':
        return const Color(0xFF4E342E);
      case 'green':
        return const Color(0xFF1B5E20);
      case 'blue':
        return const Color(0xFF0D47A1);
      case 'purple':
        return const Color(0xFF4A148C);
      case 'pink':
      default:
        return const Color(0xFF880E4F);
    }
  }

  Color get cardCheckedItemColor {
    switch (color) {
      case 'yellow':
        return const Color(0xFFFF6F00);
      case 'orange':
        return const Color(0xFFE64A19);
      case 'green':
        return const Color(0xFF2E7D32);
      case 'blue':
        return const Color(0xFF1976D2);
      case 'purple':
        return const Color(0xFF7B1FA2);
      case 'pink':
      default:
        return const Color(0xFFD81B60);
    }
  }
}
