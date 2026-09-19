import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ludo_game_state.dart';
import '../providers/ludo_game_provider.dart';
import '../widgets/ludo_board_widget.dart';
import '../widgets/ludo_game_over_dialog.dart';
import '../widgets/ludo_player_card.dart';

class LudoGameScreen extends StatefulWidget {
  const LudoGameScreen({super.key});

  @override
  State<LudoGameScreen> createState() => _LudoGameScreenState();
}

class _LudoGameScreenState extends State<LudoGameScreen> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LudoGameProvider>();
    final state = provider.state;

    // Trigger game over dialog when state is game over
    if (state.isGameOver && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameOverDialog(context, provider);
      });
    }

    return PopScope(
      canPop: state.isGameOver,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmExit(context, provider);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFCFD),
        body: SafeArea(
          child: Column(
            children: [
              // 1. Top App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF1E293B),
                        size: 22,
                      ),
                      onPressed: () => _confirmExit(context, provider),
                    ),
                    const Expanded(
                      child: Text(
                        'Ludo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    // Symmetrical balance or reaction button if online
                    if (provider.isOnline)
                      IconButton(
                        icon: const Icon(
                          Icons.add_reaction_rounded,
                          color: Color(0xFF0088FF),
                          size: 22,
                        ),
                        onPressed: () => _showReactionSheet(context, provider),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),

              // 2. Status message / Tip bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    state.statusMessage ?? '',
                    key: ValueKey(state.statusMessage),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: state.currentPlayer.color.darkColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // 3. Game Layout
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: state.players.length == 2
                      ? _buildTwoPlayerLayout(provider, state)
                      : _buildMultiPlayerLayout(provider, state),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  /// 2-Player Layout (Screenshot 2: Green top, Board center, Blue bottom)
  Widget _buildTwoPlayerLayout(LudoGameProvider provider, LudoGameState state) {
    final p1 = state.players[0]; // Green (Top)
    final p2 = state.players[1]; // Blue (Bottom)

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top Player Card (Green - Pemain 1)
        LudoPlayerCard(
          player: p1,
          isCurrentTurn: state.currentTurnIndex == 0,
          diceValue: state.currentTurnIndex == 0 ? state.diceValue : null,
          isRolling: provider.isRollingAnimation,
          canRoll: provider.canRoll() && state.currentTurnIndex == 0,
          onRollTap: provider.rollDice,
          layout: LudoPlayerCardLayout.twoPlayerTop,
        ),

        // Center Ludo Board 15x15
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: LudoBoardWidget(
              state: state,
              onTokenSelected: provider.selectToken,
            ),
          ),
        ),

        // Bottom Player Card (Blue - Pemain 2)
        LudoPlayerCard(
          player: p2,
          isCurrentTurn: state.currentTurnIndex == 1,
          diceValue: state.currentTurnIndex == 1 ? state.diceValue : null,
          isRolling: provider.isRollingAnimation,
          canRoll: provider.canRoll() && state.currentTurnIndex == 1,
          onRollTap: provider.rollDice,
          layout: LudoPlayerCardLayout.twoPlayerBottom,
        ),
      ],
    );
  }

  /// 4-Player Layout (Screenshot 3: Red & Green top, Board center, Blue & Yellow bottom)
  Widget _buildMultiPlayerLayout(LudoGameProvider provider, LudoGameState state) {
    final players = state.players;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top Row: Player 1 (Red) and Player 2 (Green)
        Row(
          children: [
            Expanded(
              child: LudoPlayerCard(
                player: players[0],
                isCurrentTurn: state.currentTurnIndex == 0,
                diceValue: state.currentTurnIndex == 0 ? state.diceValue : null,
                isRolling: provider.isRollingAnimation,
                canRoll: provider.canRoll() && state.currentTurnIndex == 0,
                onRollTap: provider.rollDice,
                layout: LudoPlayerCardLayout.fourPlayerTop,
              ),
            ),
            const SizedBox(width: 10),
            if (players.length >= 2)
              Expanded(
                child: LudoPlayerCard(
                  player: players[1],
                  isCurrentTurn: state.currentTurnIndex == 1,
                  diceValue: state.currentTurnIndex == 1 ? state.diceValue : null,
                  isRolling: provider.isRollingAnimation,
                  canRoll: provider.canRoll() && state.currentTurnIndex == 1,
                  onRollTap: provider.rollDice,
                  layout: LudoPlayerCardLayout.fourPlayerTop,
                ),
              ),
          ],
        ),

        // Center Ludo Board 15x15
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: LudoBoardWidget(
              state: state,
              onTokenSelected: provider.selectToken,
            ),
          ),
        ),

        // Bottom Row: Player 3 (Blue) and Player 4 (Yellow)
        Row(
          children: [
            if (players.length >= 3)
              Expanded(
                child: LudoPlayerCard(
                  player: players[2],
                  isCurrentTurn: state.currentTurnIndex == 2,
                  diceValue: state.currentTurnIndex == 2 ? state.diceValue : null,
                  isRolling: provider.isRollingAnimation,
                  canRoll: provider.canRoll() && state.currentTurnIndex == 2,
                  onRollTap: provider.rollDice,
                  layout: LudoPlayerCardLayout.fourPlayerBottom,
                ),
              ),
            if (players.length >= 4) ...[
              const SizedBox(width: 10),
              Expanded(
                child: LudoPlayerCard(
                  player: players[3],
                  isCurrentTurn: state.currentTurnIndex == 3,
                  diceValue: state.currentTurnIndex == 3 ? state.diceValue : null,
                  isRolling: provider.isRollingAnimation,
                  canRoll: provider.canRoll() && state.currentTurnIndex == 3,
                  onRollTap: provider.rollDice,
                  layout: LudoPlayerCardLayout.fourPlayerBottom,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showReactionSheet(BuildContext context, LudoGameProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final emojis = ['❤️', '😂', '🔥', '👏', '🎉', '🎲', '😱', '👍'];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kirim Reaksi ke Pasangan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: emojis.map((e) {
                  return GestureDetector(
                    onTap: () {
                      provider.sendReaction(e);
                      Navigator.of(context).pop();
                    },
                    child: Text(e, style: const TextStyle(fontSize: 30)),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGameOverDialog(BuildContext context, LudoGameProvider provider) {
    final winner = provider.state.winner ?? provider.state.currentPlayer;
    final isLocal = !provider.isOnline || provider.myColor == winner.color;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LudoGameOverDialog(
        winner: winner,
        isWinnerLocal: isLocal,
        totalMoves: provider.movesCount,
        onPlayAgain: () {
          Navigator.of(context).pop();
          _dialogShown = false;
          // Restart with same mode
          provider.startOfflineGame(
            mode: provider.state.mode,
            player1Name: provider.state.players[0].name,
            player2Name: provider.state.players.length > 1
                ? provider.state.players[1].name
                : null,
          );
        },
        onExit: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _confirmExit(BuildContext context, LudoGameProvider provider) {
    if (provider.state.isGameOver) {
      Navigator.of(context).pop();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Ludo?'),
        content: Text(
          provider.isOnline
              ? 'Jika kamu keluar, pertandingan ini akan dinyatakan menyerah.'
              : 'Kemajuan permainan tersimpan otomatis di perangkatmu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (provider.isOnline) {
                provider.surrender();
              }
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
