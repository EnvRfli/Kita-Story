class SudokuCell {
  int value;
  final bool isFixed;
  bool hasError;
  final int correctValue;

  SudokuCell({
    this.value = 0,
    this.isFixed = false,
    this.hasError = false,
    this.correctValue = 0,
  });

  bool get isEmpty => value == 0;

  SudokuCell copyWith({
    int? value,
    bool? isFixed,
    bool? hasError,
    int? correctValue,
  }) {
    return SudokuCell(
      value: value ?? this.value,
      isFixed: isFixed ?? this.isFixed,
      hasError: hasError ?? this.hasError,
      correctValue: correctValue ?? this.correctValue,
    );
  }

  @override
  String toString() => value.toString();
}

class SudokuPosition {
  final int row;
  final int col;

  const SudokuPosition(this.row, this.col);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SudokuPosition && other.row == row && other.col == col;
  }

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}
