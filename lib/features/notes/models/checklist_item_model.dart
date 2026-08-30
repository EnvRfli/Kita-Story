class ChecklistItemModel {
  final String id;
  final String noteId;
  final String itemText;
  final bool isChecked;
  final int sortOrder;
  final String? checkedBy;
  final DateTime? checkedAt;
  final DateTime? createdAt;

  const ChecklistItemModel({
    required this.id,
    required this.noteId,
    required this.itemText,
    this.isChecked = false,
    this.sortOrder = 0,
    this.checkedBy,
    this.checkedAt,
    this.createdAt,
  });

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return ChecklistItemModel(
      id: json['id'] as String,
      noteId: json['note_id'] as String,
      itemText: json['item_text'] as String? ?? '',
      isChecked: json['is_checked'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      checkedBy: json['checked_by'] as String?,
      checkedAt: json['checked_at'] != null
          ? DateTime.tryParse(json['checked_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note_id': noteId,
      'item_text': itemText,
      'is_checked': isChecked,
      'sort_order': sortOrder,
      if (checkedBy != null) 'checked_by': checkedBy,
      if (checkedAt != null) 'checked_at': checkedAt!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  ChecklistItemModel copyWith({
    String? id,
    String? noteId,
    String? itemText,
    bool? isChecked,
    int? sortOrder,
    String? checkedBy,
    DateTime? checkedAt,
    DateTime? createdAt,
  }) {
    return ChecklistItemModel(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      itemText: itemText ?? this.itemText,
      isChecked: isChecked ?? this.isChecked,
      sortOrder: sortOrder ?? this.sortOrder,
      checkedBy: checkedBy ?? this.checkedBy,
      checkedAt: checkedAt ?? this.checkedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
