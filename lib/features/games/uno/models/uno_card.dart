import 'package:flutter/material.dart';

enum UnoColor {
  red,
  yellow,
  green,
  blue;

  String get label {
    switch (this) {
      case UnoColor.red:
        return 'Merah';
      case UnoColor.yellow:
        return 'Kuning';
      case UnoColor.green:
        return 'Hijau';
      case UnoColor.blue:
        return 'Biru';
    }
  }

  Color get primaryColor {
    switch (this) {
      case UnoColor.red:
        return const Color(0xFFE53935);
      case UnoColor.yellow:
        return const Color(0xFFF9A825);
      case UnoColor.green:
        return const Color(0xFF2E9E4F);
      case UnoColor.blue:
        return const Color(0xFF1E88E5);
    }
  }

  Color get darkColor {
    switch (this) {
      case UnoColor.red:
        return const Color(0xFFB71C1C);
      case UnoColor.yellow:
        return const Color(0xFFF57F17);
      case UnoColor.green:
        return const Color(0xFF1B5E20);
      case UnoColor.blue:
        return const Color(0xFF0D47A1);
    }
  }

  Color get lightColor {
    switch (this) {
      case UnoColor.red:
        return const Color(0xFFFFCDD2);
      case UnoColor.yellow:
        return const Color(0xFFFFF9C4);
      case UnoColor.green:
        return const Color(0xFFC8E6C9);
      case UnoColor.blue:
        return const Color(0xFFBBDEFB);
    }
  }

  static UnoColor? fromName(String? value) {
    if (value == null) return null;
    for (final color in UnoColor.values) {
      if (color.name == value) return color;
    }
    return null;
  }
}

enum UnoCardType {
  number,
  skip,
  reverse,
  drawOne,
  drawTwo,
  wild;

  String get dbValue {
    switch (this) {
      case UnoCardType.number:
        return 'number';
      case UnoCardType.skip:
        return 'skip';
      case UnoCardType.reverse:
        return 'reverse';
      case UnoCardType.drawOne:
        return 'draw_one';
      case UnoCardType.drawTwo:
        return 'draw_two';
      case UnoCardType.wild:
        return 'wild';
    }
  }

  static UnoCardType fromDb(String? value) {
    switch (value) {
      case 'skip':
        return UnoCardType.skip;
      case 'reverse':
        return UnoCardType.reverse;
      case 'draw_one':
        return UnoCardType.drawOne;
      case 'draw_two':
        return UnoCardType.drawTwo;
      case 'wild':
        return UnoCardType.wild;
      default:
        return UnoCardType.number;
    }
  }
}

@immutable
class UnoCard {
  final String id;
  final UnoColor? color;
  final UnoCardType type;
  final int? number;

  const UnoCard({
    required this.id,
    this.color,
    required this.type,
    this.number,
  });

  bool get isWild => color == null;
  bool get isNumber => type == UnoCardType.number;
  bool get isBlock =>
      type == UnoCardType.skip || type == UnoCardType.reverse;
  bool get isDraw =>
      type == UnoCardType.drawOne || type == UnoCardType.drawTwo;

  int get drawValue {
    if (type == UnoCardType.drawOne) return 1;
    if (type == UnoCardType.drawTwo) return 2;
    return 0;
  }

  String get symbol {
    switch (type) {
      case UnoCardType.number:
        return '${number ?? 0}';
      case UnoCardType.skip:
        return '⊘';
      case UnoCardType.reverse:
        return '⇄';
      case UnoCardType.drawOne:
        return '+1';
      case UnoCardType.drawTwo:
        return '+2';
      case UnoCardType.wild:
        return 'WILD';
    }
  }

  String get accessibleLabel {
    final colorLabel = color?.label ?? 'Wild';
    return '$colorLabel $symbol';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'color': color?.name,
        'type': type.dbValue,
        'number': number,
      };

  factory UnoCard.fromJson(Map<String, dynamic> json) {
    return UnoCard(
      id: json['id'] as String? ?? '',
      color: UnoColor.fromName(json['color'] as String?),
      type: UnoCardType.fromDb(json['type'] as String?),
      number: (json['number'] as num?)?.toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UnoCard && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$accessibleLabel ($id)';
}
