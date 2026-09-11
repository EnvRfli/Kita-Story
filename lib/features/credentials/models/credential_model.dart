import '../../../core/services/encryption_service.dart';

class CredentialField {
  String label;
  String value;

  CredentialField({
    required this.label,
    required this.value,
  });

  factory CredentialField.fromJson(Map<String, dynamic> json) {
    return CredentialField(
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
    };
  }

  CredentialField copyWith({
    String? label,
    String? value,
  }) {
    return CredentialField(
      label: label ?? this.label,
      value: value ?? this.value,
    );
  }
}

class CredentialModel {
  final String id;
  final String userId;
  final String? categoryId;
  final String categoryName;
  final String? subcategoryId;
  final String subcategoryName;
  final String title;
  final List<CredentialField> fields;
  final String? encryptedData;
  final String? keterangan;
  final bool isSharedWithPartner;
  final String? partnerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CredentialModel({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.categoryName,
    this.subcategoryId,
    required this.subcategoryName,
    required this.title,
    this.fields = const [],
    this.encryptedData,
    this.keterangan,
    this.isSharedWithPartner = false,
    this.partnerId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convenience getters for legacy or quick lookups
  String? get usernameId {
    try {
      return fields.firstWhere(
        (f) =>
            f.label.toLowerCase().contains('user') ||
            f.label.toLowerCase().contains('id') ||
            f.label.toLowerCase().contains('username'),
      ).value;
    } catch (_) {
      return null;
    }
  }

  String? get password {
    try {
      return fields.firstWhere(
        (f) =>
            f.label.toLowerCase().contains('sandi') ||
            f.label.toLowerCase().contains('pass'),
      ).value;
    } catch (_) {
      return null;
    }
  }

  String? get email {
    try {
      return fields.firstWhere(
        (f) => f.label.toLowerCase().contains('email'),
      ).value;
    } catch (_) {
      return null;
    }
  }

  String? get nomorRekening {
    try {
      return fields.firstWhere(
        (f) =>
            f.label.toLowerCase().contains('rekening') ||
            f.label.toLowerCase().contains('rek'),
      ).value;
    } catch (_) {
      return null;
    }
  }

  factory CredentialModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final encData = (json['encrypted_data'] as String?) ??
        (json['secret_value'] as String?);
    List<CredentialField> parsedFields = [];

    if (encData != null && encData.isNotEmpty) {
      final effectiveUserId = currentUserId ?? json['user_id'] as String? ?? '';
      final decrypted = EncryptionService.decryptJson(encData, effectiveUserId);
      if (decrypted is List) {
        parsedFields = decrypted
            .whereType<Map<String, dynamic>>()
            .map((item) => CredentialField.fromJson(item))
            .toList();
      }
    }

    // Fallback: If no dynamic fields decrypted, check legacy columns
    if (parsedFields.isEmpty) {
      if (json['username_id'] != null &&
          (json['username_id'] as String).isNotEmpty) {
        parsedFields.add(
          CredentialField(
            label: 'Username/ID',
            value: json['username_id'] as String,
          ),
        );
      }
      if (json['email'] != null && (json['email'] as String).isNotEmpty) {
        parsedFields.add(
          CredentialField(
            label: 'Email',
            value: json['email'] as String,
          ),
        );
      }
      if (json['nomor_rekening'] != null &&
          (json['nomor_rekening'] as String).isNotEmpty) {
        parsedFields.add(
          CredentialField(
            label: 'Nomor Rekening',
            value: json['nomor_rekening'] as String,
          ),
        );
      }
      if (json['password'] != null &&
          (json['password'] as String).isNotEmpty) {
        parsedFields.add(
          CredentialField(
            label: 'Kata Sandi',
            value: json['password'] as String,
          ),
        );
      }
    }

    return CredentialModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String? ?? json['category'] as String? ?? 'Lainnya',
      subcategoryId: json['subcategory_id'] as String?,
      subcategoryName: json['subcategory_name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      fields: parsedFields,
      encryptedData: encData,
      keterangan: json['keterangan'] as String? ?? json['notes'] as String?,
      isSharedWithPartner: json['is_shared_with_partner'] as bool? ?? false,
      partnerId: json['partner_id'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({String? targetUserId}) {
    final effectiveUserId = targetUserId ?? userId;
    final enc = EncryptionService.encryptJson(
      fields.map((f) => f.toJson()).toList(),
      effectiveUserId,
    );

    return {
      'id': id,
      'user_id': userId,
      'category_id': (categoryId != null && categoryId!.trim().isNotEmpty) ? categoryId : null,
      'category_name': categoryName,
      'subcategory_id': (subcategoryId != null && subcategoryId!.trim().isNotEmpty) ? subcategoryId : null,
      'subcategory_name': subcategoryName,
      'title': title,
      'encrypted_data': enc,
      'keterangan': keterangan,
      'is_shared_with_partner': isSharedWithPartner,
      'partner_id': (partnerId != null && partnerId!.trim().isNotEmpty) ? partnerId : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CredentialModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryName,
    String? subcategoryId,
    String? subcategoryName,
    String? title,
    List<CredentialField>? fields,
    String? encryptedData,
    String? keterangan,
    bool? isSharedWithPartner,
    String? partnerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CredentialModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      title: title ?? this.title,
      fields: fields ?? this.fields,
      encryptedData: encryptedData ?? this.encryptedData,
      keterangan: keterangan ?? this.keterangan,
      isSharedWithPartner: isSharedWithPartner ?? this.isSharedWithPartner,
      partnerId: partnerId ?? this.partnerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
