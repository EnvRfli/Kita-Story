import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kita_story/core/network/supabase_client.dart';
import 'package:kita_story/core/services/activity_log_service.dart';
import 'package:kita_story/features/games/sudoku/models/sudoku_cell.dart';
import 'package:kita_story/features/games/sudoku/models/sudoku_hint.dart';
import 'package:kita_story/features/games/sudoku/engine/sudoku_engine.dart';

enum SudokuGameState { initial, playing, won, lost }

class SudokuProvider extends ChangeNotifier {
  final SudokuEngine _engine = SudokuEngine();
  
  List<List<SudokuCell>> _grid = [];
  List<List<SudokuCell>> get grid => _grid;

  SudokuPosition? _selectedCell;
  SudokuPosition? get selectedCell => _selectedCell;

  SudokuHint? _currentHint;
  SudokuHint? get currentHint => _currentHint;

  bool isNumberCompleted(int number) {
    int count = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_grid[r][c].value == number && !_grid[r][c].hasError) {
          count++;
        }
      }
    }
    return count >= 9;
  }

  String _difficulty = 'mudah';
  String get difficulty => _difficulty;

  int _mistakes = 0;
  int get mistakes => _mistakes;
  final int maxMistakes = 3;

  int _hintsLeft = 3;
  int get hintsLeft => _hintsLeft;

  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;

  SudokuGameState _gameState = SudokuGameState.initial;
  SudokuGameState get gameState => _gameState;

  Timer? _timer;

  int get pointsForDifficulty {
    switch (_difficulty.toLowerCase()) {
      case 'mudah': return 50;
      case 'normal': return 125;
      case 'susah': return 200;
      case 'sangat susah':
      case 'sangat_susah': return 300;
      default: return 50;
    }
  }

  void startGame(String difficulty) {
    _difficulty = difficulty;
    _grid = _engine.generatePuzzle(difficulty);
    _selectedCell = null;
    _currentHint = null;
    _mistakes = 0;
    _hintsLeft = 3;
    _elapsedSeconds = 0;
    _gameState = SudokuGameState.playing;
    
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_gameState == SudokuGameState.playing) {
        _elapsedSeconds++;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void selectCell(int row, int col) {
    if (_gameState != SudokuGameState.playing) return;
    if (_selectedCell?.row == row && _selectedCell?.col == col) return;
    
    _selectedCell = SudokuPosition(row, col);
    _currentHint = null;
    notifyListeners();
  }

  void inputNumber(int number) {
    if (_gameState != SudokuGameState.playing || _selectedCell == null) return;

    int r = _selectedCell!.row;
    int c = _selectedCell!.col;

    if (_grid[r][c].isFixed) return;

    // Clear error state if replacing
    _grid[r][c].hasError = false;

    // Validate move
    if (_grid[r][c].correctValue == number) {
      _grid[r][c].value = number;
      if (_engine.isGameWon(_grid)) {
        _gameState = SudokuGameState.won;
        _timer?.cancel();
        _saveGameAndPoints();
      }
    } else {
      _grid[r][c].value = number;
      _grid[r][c].hasError = true;
      _mistakes++;
      if (_mistakes >= maxMistakes) {
        _gameState = SudokuGameState.lost;
        _timer?.cancel();
        _saveLostGame();
      }
    }
    notifyListeners();
  }

  Future<void> _saveGameAndPoints() async {
    final client = SupabaseNetwork.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final points = pointsForDifficulty;

    try {
      final response = await client.from('game_history').insert({
        'game_type': 'sudoku',
        'difficulty': _difficulty,
        'user_id': user.id,
        'duration_seconds': _elapsedSeconds,
        'score': points,
        'status': 'completed'
      }).select().single();

      await ActivityLogService.recordActivityAndAddPoints(
        userId: user.id,
        points: points,
        activityType: 'play_sudoku',
        title: 'Bermain Sudoku ($_difficulty)',
        description: 'Menyelesaikan Sudoku level $_difficulty dalam waktu $_elapsedSeconds detik.',
        referenceId: response['id'],
      );
    } catch (e) {
      debugPrint('Error saving game history: $e');
    }
  }

  Future<void> _saveLostGame() async {
    final client = SupabaseNetwork.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      await client.from('game_history').insert({
        'game_type': 'sudoku',
        'difficulty': _difficulty,
        'user_id': user.id,
        'duration_seconds': _elapsedSeconds,
        'score': 0,
        'status': 'failed'
      });
    } catch (e) {
      debugPrint('Error saving lost game history: $e');
    }
  }

  void eraseSelected() {
    if (_gameState != SudokuGameState.playing || _selectedCell == null) return;
    int r = _selectedCell!.row;
    int c = _selectedCell!.col;
    
    if (_grid[r][c].isFixed) return;

    _grid[r][c].value = 0;
    _grid[r][c].hasError = false;
    notifyListeners();
  }

  SudokuHint? getHint() {
    if (_gameState != SudokuGameState.playing || _hintsLeft <= 0) return null;
    _currentHint = _engine.getLogicalHint(_grid);
    notifyListeners();
    return _currentHint;
  }

  void clearHint() {
    if (_currentHint != null) {
      _currentHint = null;
      notifyListeners();
    }
  }

  void applyHint(SudokuHint hint) {
    if (_gameState != SudokuGameState.playing || _hintsLeft <= 0) return;
    
    _hintsLeft--;
    _grid[hint.row][hint.col].value = hint.value;
    _grid[hint.row][hint.col].hasError = false;
    _currentHint = null;
    
    if (_engine.isGameWon(_grid)) {
       _gameState = SudokuGameState.won;
       _timer?.cancel();
       _saveGameAndPoints();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
