import 'dart:math';
import 'package:kita_story/features/games/sudoku/models/sudoku_cell.dart';
import 'package:kita_story/features/games/sudoku/models/sudoku_hint.dart';

class SudokuEngine {
  static const int _size = 9;
  final Random _random = Random();

  /// Generates a Sudoku puzzle based on difficulty.
  /// Easy: ~35-45 cells filled
  /// Normal: ~28-34 cells filled
  /// Hard: ~22-27 cells filled
  /// Expert: ~17-21 cells filled
  List<List<SudokuCell>> generatePuzzle(String difficulty) {
    // 1. Generate a full valid board
    List<List<int>> board = List.generate(_size, (_) => List.filled(_size, 0));
    _fillBoard(board);

    // 2. Remove cells based on difficulty
    int cellsToRemove;
    switch (difficulty.toLowerCase()) {
      case 'sangat mudah':
      case 'sangat_mudah':
        cellsToRemove = _random.nextInt(3) + 4; // Testing: 4-6 empty cells
        break;
      case 'mudah':
        cellsToRemove =
            _random.nextInt(10) + 36; // 36-45 removed -> 36-45 filled
        break;
      case 'normal':
        cellsToRemove =
            _random.nextInt(7) + 47; // 47-53 removed -> 28-34 filled
        break;
      case 'susah':
        cellsToRemove =
            _random.nextInt(6) + 54; // 54-59 removed -> 22-27 filled
        break;
      case 'sangat susah':
      case 'sangat_susah':
        cellsToRemove =
            _random.nextInt(5) + 60; // 60-64 removed -> 17-21 filled
        break;
      default:
        cellsToRemove = 40;
    }

    // 3. Create puzzle board by removing cells
    List<List<int>> puzzle = List.generate(
      _size,
      (r) => List.generate(_size, (c) => board[r][c]),
    );
    _removeCells(puzzle, cellsToRemove);

    // 4. Map to SudokuCell
    return List.generate(
      _size,
      (row) => List.generate(
        _size,
        (col) {
          int value = puzzle[row][col];
          int correct = board[row][col];
          return SudokuCell(
            value: value,
            isFixed: value != 0,
            hasError: false,
            correctValue: correct,
          );
        },
      ),
    );
  }

  bool _fillBoard(List<List<int>> board) {
    for (int row = 0; row < _size; row++) {
      for (int col = 0; col < _size; col++) {
        if (board[row][col] == 0) {
          List<int> numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];
          numbers.shuffle(_random);

          for (int num in numbers) {
            if (_isValidMove(board, row, col, num)) {
              board[row][col] = num;
              if (_fillBoard(board)) {
                return true;
              }
              board[row][col] = 0; // backtrack
            }
          }
          return false; // No valid number found, trigger backtracking
        }
      }
    }
    return true; // Board is full
  }

  bool _isValidMove(List<List<int>> board, int row, int col, int num) {
    // Check row
    for (int i = 0; i < _size; i++) {
      if (board[row][i] == num) return false;
    }
    // Check column
    for (int i = 0; i < _size; i++) {
      if (board[i][col] == num) return false;
    }
    // Check 3x3 block
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[i + startRow][j + startCol] == num) return false;
      }
    }
    return true;
  }

  void _removeCells(List<List<int>> board, int count) {
    List<int> positions = List.generate(81, (i) => i);
    positions.shuffle(_random);

    int removed = 0;
    for (int pos in positions) {
      if (removed >= count) break;

      int r = pos ~/ _size;
      int c = pos % _size;

      int backup = board[r][c];
      if (backup != 0) {
        board[r][c] = 0;

        // Cek apakah dengan dihapusnya kotak ini, solusi masih unik (hanya 1)
        List<List<int>> copy = List.generate(_size, (i) => List.from(board[i]));
        if (_countSolutions(copy) != 1) {
          // Jika solusinya menjadi lebih dari 1 (butuh tebakan), kembalikan angkanya
          board[r][c] = backup;
        } else {
          removed++;
        }
      }
    }
  }

  /// Menghitung jumlah solusi dari papan saat ini (Maksimal dihitung sampai 2 untuk efisiensi)
  int _countSolutions(List<List<int>> board) {
    int count = 0;

    bool solve(int row, int col) {
      if (row == _size) {
        count++;
        return count >
            1; // Berhenti mencari jika sudah menemukan lebih dari 1 solusi
      }

      int nextRow = col == _size - 1 ? row + 1 : row;
      int nextCol = (col + 1) % _size;

      if (board[row][col] != 0) {
        return solve(nextRow, nextCol);
      }

      for (int num = 1; num <= 9; num++) {
        if (_isValidMove(board, row, col, num)) {
          board[row][col] = num;
          if (solve(nextRow, nextCol)) {
            return true; // Return true means we found multiple solutions and should stop
          }
          board[row][col] = 0;
        }
      }
      return false; // Belum menemukan > 1 solusi dari path ini
    }

    solve(0, 0);
    return count;
  }

  /// Validates a single move in the current grid.
  bool isValidEntry(List<List<SudokuCell>> grid, int row, int col, int num) {
    // Check row
    for (int i = 0; i < _size; i++) {
      if (i != col && !grid[row][i].hasError && grid[row][i].value == num) {
        return false;
      }
    }
    // Check column
    for (int i = 0; i < _size; i++) {
      if (i != row && !grid[i][col].hasError && grid[i][col].value == num) {
        return false;
      }
    }
    // Check 3x3 block
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        int r = i + startRow;
        int c = j + startCol;
        if ((r != row || c != col) &&
            !grid[r][c].hasError &&
            grid[r][c].value == num) {
          return false;
        }
      }
    }
    return true;
  }

  /// Checks if the entire board is filled and valid
  bool isGameWon(List<List<SudokuCell>> grid) {
    for (int row = 0; row < _size; row++) {
      for (int col = 0; col < _size; col++) {
        if (grid[row][col].value == 0 || grid[row][col].hasError) {
          return false;
        }
      }
    }
    return true;
  }

  /// Mengumpulkan area terkait (baris, kolom, blok)
  List<SudokuPosition> _getRelatedAreas(int row, int col) {
    Set<SudokuPosition> areas = {};
    for (int i = 0; i < _size; i++) {
      areas.add(SudokuPosition(row, i));
    }
    for (int i = 0; i < _size; i++) {
      areas.add(SudokuPosition(i, col));
    }
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        areas.add(SudokuPosition(startRow + i, startCol + j));
      }
    }
    return areas.toList();
  }

  /// Mencari letak semua angka [num] di papan sebagai bukti
  List<SudokuPosition> _findNumberInstances(
      List<List<SudokuCell>> grid, int num) {
    List<SudokuPosition> instances = [];
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size; c++) {
        if (grid[r][c].value == num) instances.add(SudokuPosition(r, c));
      }
    }
    return instances;
  }

  /// Menghasilkan hint berdasarkan logika deduktif manusia
  SudokuHint? getLogicalHint(List<List<SudokuCell>> grid) {
    // 1. Cari Naked Single
    for (int row = 0; row < _size; row++) {
      for (int col = 0; col < _size; col++) {
        if (grid[row][col].value == 0) {
          List<int> candidates = [];
          for (int num = 1; num <= 9; num++) {
            if (isValidEntry(grid, row, col, num)) {
              candidates.add(num);
            }
          }
          if (candidates.length == 1) {
            int value = candidates.first;
            List<SudokuPosition> areas = _getRelatedAreas(row, col);
            List<SudokuPosition> evidence = [];
            for (var pos in areas) {
              if (grid[pos.row][pos.col].value != 0) evidence.add(pos);
            }
            return SudokuHint(
              row: row,
              col: col,
              value: value,
              title: 'Kandidat Tunggal',
              reason:
                  'Kotak ini hanya bisa diisi angka $value karena 8 angka lainnya sudah ada di baris, kolom, atau blok yang bersilangan ini.',
              relatedAreas: areas,
              evidenceCells: evidence,
            );
          }
        }
      }
    }

    // 2. Cari Hidden Single - Baris
    for (int row = 0; row < _size; row++) {
      for (int num = 1; num <= 9; num++) {
        List<int> possibleCols = [];
        for (int col = 0; col < _size; col++) {
          if (grid[row][col].value == 0 && isValidEntry(grid, row, col, num)) {
            possibleCols.add(col);
          }
        }
        if (possibleCols.length == 1) {
          int col = possibleCols.first;
          List<SudokuPosition> areas =
              List.generate(_size, (i) => SudokuPosition(row, i));
          return SudokuHint(
            row: row,
            col: col,
            value: num,
            title: 'Angka Tunggal (Baris)',
            reason:
                'Di baris ini, hanya kotak ini yang bisa diisi angka $num. Kotak lain terblokir oleh angka $num yang sudah ada (lihat angka yang merah).',
            relatedAreas: areas,
            evidenceCells: _findNumberInstances(grid, num),
          );
        }
      }
    }

    // 3. Cari Hidden Single - Kolom
    for (int col = 0; col < _size; col++) {
      for (int num = 1; num <= 9; num++) {
        List<int> possibleRows = [];
        for (int row = 0; row < _size; row++) {
          if (grid[row][col].value == 0 && isValidEntry(grid, row, col, num)) {
            possibleRows.add(row);
          }
        }
        if (possibleRows.length == 1) {
          int row = possibleRows.first;
          List<SudokuPosition> areas =
              List.generate(_size, (i) => SudokuPosition(i, col));
          return SudokuHint(
            row: row,
            col: col,
            value: num,
            title: 'Angka Tunggal (Kolom)',
            reason: 'Di kolom ini, hanya kotak ini yang bisa diisi angka $num.',
            relatedAreas: areas,
            evidenceCells: _findNumberInstances(grid, num),
          );
        }
      }
    }

    // 4. Cari Hidden Single - Blok 3x3
    for (int block = 0; block < 9; block++) {
      int startRow = (block ~/ 3) * 3;
      int startCol = (block % 3) * 3;

      for (int num = 1; num <= 9; num++) {
        List<List<int>> possibleCells = [];
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            int row = startRow + i;
            int col = startCol + j;
            if (grid[row][col].value == 0 &&
                isValidEntry(grid, row, col, num)) {
              possibleCells.add([row, col]);
            }
          }
        }
        if (possibleCells.length == 1) {
          int row = possibleCells.first[0];
          int col = possibleCells.first[1];
          List<SudokuPosition> areas = [];
          for (int i = 0; i < 3; i++) {
            for (int j = 0; j < 3; j++) {
              areas.add(SudokuPosition(startRow + i, startCol + j));
            }
          }
          return SudokuHint(
            row: row,
            col: col,
            value: num,
            title: 'Angka Tunggal (Blok)',
            reason:
                'Di blok 3x3 ini, hanya kotak ini yang bisa diisi angka $num.',
            relatedAreas: areas,
            evidenceCells: _findNumberInstances(grid, num),
          );
        }
      }
    }

    // 5. Fallback
    for (int row = 0; row < _size; row++) {
      for (int col = 0; col < _size; col++) {
        if (grid[row][col].value == 0) {
          for (int num = 1; num <= 9; num++) {
            if (isValidEntry(grid, row, col, num)) {
              return SudokuHint(
                row: row,
                col: col,
                value: num,
                title: 'Deduksi Lanjutan',
                reason: 'Melalui perhitungan lanjutan, kotak ini adalah $num.',
                relatedAreas: _getRelatedAreas(row, col),
              );
            }
          }
        }
      }
    }

    return null;
  }
}
