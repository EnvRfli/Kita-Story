class TransactionModel {
  final String id;
  final String userId;
  final String? partnerId;
  final bool isShared;
  final String type; // 'income' or 'expense'
  final String title;
  final String category;
  final double amount;
  final DateTime transactionDate;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    this.partnerId,
    this.isShared = true,
    required this.type,
    required this.title,
    required this.category,
    required this.amount,
    required this.transactionDate,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['added_by'] as String? ?? '',
      partnerId: json['partner_id'] as String?,
      isShared: json['is_shared'] as bool? ?? true,
      type: json['type'] as String? ?? 'expense',
      title: json['title'] as String? ?? 'Transaksi',
      category: json['category'] as String? ?? 'Lain-lain',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'] as String).toLocal()
          : DateTime.now(),
      note: json['note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (partnerId != null) 'partner_id': partnerId,
      'is_shared': isShared,
      'type': type,
      'title': title,
      'category': category,
      'amount': amount,
      'transaction_date': transactionDate.toUtc().toIso8601String(),
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? partnerId,
    bool? isShared,
    String? type,
    String? title,
    String? category,
    double? amount,
    DateTime? transactionDate,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      partnerId: partnerId ?? this.partnerId,
      isShared: isShared ?? this.isShared,
      type: type ?? this.type,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
