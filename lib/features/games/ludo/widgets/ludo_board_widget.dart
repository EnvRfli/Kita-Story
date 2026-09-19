import 'package:flutter/material.dart';
import '../engine/ludo_board_path.dart';
import '../models/ludo_game_state.dart';
import '../models/ludo_player.dart';
import '../models/ludo_token.dart';
import 'ludo_token_widget.dart';

class LudoBoardWidget extends StatelessWidget {
  final LudoGameState state;
  final ValueChanged<int>? onTokenSelected;

  const LudoBoardWidget({
    super.key,
    required this.state,
    this.onTokenSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = constraints.maxWidth / 15.0;

            return Stack(
              children: [
                // 1. Board Background and Cells Grid
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _LudoBoardPainter(),
                ),

                // 2. Active Tokens overlay
                ..._buildTokenWidgets(cellSize),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildTokenWidgets(double cellSize) {
    final widgets = <Widget>[];

    // Group tokens by their board coordinate so stacks are rendered nicely
    final groupedTokens = <LudoCoordinate, List<({LudoPlayer player, LudoToken token})>>{};

    for (final player in state.players) {
      for (final token in player.tokens) {
        final coord = LudoBoardPath.coordinateForToken(
          color: player.color,
          tokenId: token.id,
          isInYard: token.isInYard,
          isOnTrack: token.isOnTrack,
          isInHomeStretch: token.isInHomeStretch,
          isHome: token.isHome,
          step: token.step,
        );

        groupedTokens.putIfAbsent(coord, () => []).add((player: player, token: token));
      }
    }

    // Render grouped tokens
    groupedTokens.forEach((coord, items) {
      // Check if any token in this cell is movable by current player
      final movableItem = items.firstWhere(
        (it) =>
            it.player.color == state.currentPlayer.color &&
            state.movableTokenIds.contains(it.token.id),
        orElse: () => items.first,
      );

      final isMovable = state.currentPlayer.color == movableItem.player.color &&
          state.movableTokenIds.contains(movableItem.token.id);

      final tokenSize = cellSize * 0.85;

      widgets.add(
        Positioned(
          left: coord.col * cellSize + (cellSize - tokenSize) / 2,
          top: coord.row * cellSize + (cellSize - tokenSize) / 2,
          child: LudoTokenWidget(
            color: movableItem.player.color,
            isMovable: isMovable,
            count: items.length,
            size: tokenSize,
            onTap: () => onTokenSelected?.call(movableItem.token.id),
          ),
        ),
      );
    });

    return widgets;
  }
}

class _LudoBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 15.0;

    // 1. Draw Grid Cells
    final borderPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var r = 0; r < 15; r++) {
      for (var c = 0; c < 15; c++) {
        // Skip yards and center
        final inRedYard = r < 6 && c < 6;
        final inGreenYard = r < 6 && c >= 9;
        final inBlueYard = r >= 9 && c < 6;
        final inYellowYard = r >= 9 && c >= 9;
        final inCenter = r >= 6 && r <= 8 && c >= 6 && c <= 8;

        if (inRedYard || inGreenYard || inBlueYard || inYellowYard || inCenter) {
          continue;
        }

        final rect = Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize);

        // Check if colored home stretch
        Color? fillColor;
        if (r == 7 && c >= 1 && c <= 5) fillColor = LudoColor.red.primaryColor;
        if (c == 7 && r >= 1 && r <= 5) fillColor = LudoColor.green.primaryColor;
        if (c == 7 && r >= 9 && r <= 13) fillColor = LudoColor.blue.primaryColor;
        if (r == 7 && c >= 9 && c <= 13) fillColor = LudoColor.yellow.primaryColor;

        if (fillColor != null) {
          canvas.drawRect(rect, Paint()..color = fillColor);
        } else {
          canvas.drawRect(rect, Paint()..color = Colors.white);
        }

        canvas.drawRect(rect, borderPaint);
      }
    }

    // 2. Draw Yards
    _drawYard(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, 6 * cellSize, 6 * cellSize),
      color: LudoColor.red.primaryColor,
      cellSize: cellSize,
      slots: LudoBoardPath.yardSlots[LudoColor.red]!,
    );
    _drawYard(
      canvas: canvas,
      rect: Rect.fromLTWH(9 * cellSize, 0, 6 * cellSize, 6 * cellSize),
      color: LudoColor.green.primaryColor,
      cellSize: cellSize,
      slots: LudoBoardPath.yardSlots[LudoColor.green]!,
    );
    _drawYard(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 9 * cellSize, 6 * cellSize, 6 * cellSize),
      color: LudoColor.blue.primaryColor,
      cellSize: cellSize,
      slots: LudoBoardPath.yardSlots[LudoColor.blue]!,
    );
    _drawYard(
      canvas: canvas,
      rect: Rect.fromLTWH(9 * cellSize, 9 * cellSize, 6 * cellSize, 6 * cellSize),
      color: LudoColor.yellow.primaryColor,
      cellSize: cellSize,
      slots: LudoBoardPath.yardSlots[LudoColor.yellow]!,
    );

    // 3. Draw Center Home Triangles (rows 6..8, cols 6..8)
    _drawCenterHome(canvas, cellSize);

    // 4. Draw Start Arrows & Safe Stars
    _drawStartArrows(canvas, cellSize);
    _drawSafeStars(canvas, cellSize);
  }

  void _drawYard({
    required Canvas canvas,
    required Rect rect,
    required Color color,
    required double cellSize,
    required List<LudoCoordinate> slots,
  }) {
    // Outer colored quadrant
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()..color = color,
    );

    // Inner white container
    final innerPadding = cellSize * 0.8;
    final innerRect = rect.deflate(innerPadding);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(14)),
      Paint()..color = Colors.white,
    );

    // 4 slot circles inside
    for (final slot in slots) {
      final cx = slot.col * cellSize + cellSize / 2;
      final cy = slot.row * cellSize + cellSize / 2;
      final r = cellSize * 0.58;

      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()..color = color.withValues(alpha: 0.15),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r * 0.55,
        Paint()..color = Colors.white,
      );
    }
  }

  void _drawCenterHome(Canvas canvas, double cellSize) {
    final left = 6 * cellSize;
    final top = 6 * cellSize;
    final center = Offset(left + 1.5 * cellSize, top + 1.5 * cellSize);

    // Red Left Triangle
    final redPath = Path()
      ..moveTo(left, top)
      ..lineTo(center.dx, center.dy)
      ..lineTo(left, top + 3 * cellSize)
      ..close();
    canvas.drawPath(redPath, Paint()..color = LudoColor.red.primaryColor);

    // Green Top Triangle
    final greenPath = Path()
      ..moveTo(left, top)
      ..lineTo(left + 3 * cellSize, top)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(greenPath, Paint()..color = LudoColor.green.primaryColor);

    // Yellow Right Triangle
    final yellowPath = Path()
      ..moveTo(left + 3 * cellSize, top)
      ..lineTo(left + 3 * cellSize, top + 3 * cellSize)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(yellowPath, Paint()..color = LudoColor.yellow.primaryColor);

    // Blue Bottom Triangle
    final bluePath = Path()
      ..moveTo(left, top + 3 * cellSize)
      ..lineTo(center.dx, center.dy)
      ..lineTo(left + 3 * cellSize, top + 3 * cellSize)
      ..close();
    canvas.drawPath(bluePath, Paint()..color = LudoColor.blue.primaryColor);

    // Center circular badge with number 8 / logo as in mockup
    canvas.drawCircle(center, cellSize * 0.65, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      cellSize * 0.65,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '8',
        style: TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  void _drawStartArrows(Canvas canvas, double cellSize) {
    // Red Start (6, 1) -> Arrow pointing right
    _drawArrowIcon(
      canvas,
      const LudoCoordinate(6, 1),
      cellSize,
      LudoColor.red.primaryColor,
      Icons.arrow_forward_rounded,
    );

    // Green Start (1, 8) -> Arrow pointing down
    _drawArrowIcon(
      canvas,
      const LudoCoordinate(1, 8),
      cellSize,
      LudoColor.green.primaryColor,
      Icons.arrow_downward_rounded,
    );

    // Yellow Start (8, 13) -> Arrow pointing left
    _drawArrowIcon(
      canvas,
      const LudoCoordinate(8, 13),
      cellSize,
      LudoColor.yellow.primaryColor,
      Icons.arrow_back_rounded,
    );

    // Blue Start (13, 6) -> Arrow pointing up
    _drawArrowIcon(
      canvas,
      const LudoCoordinate(13, 6),
      cellSize,
      LudoColor.blue.primaryColor,
      Icons.arrow_upward_rounded,
    );
  }

  void _drawArrowIcon(
    Canvas canvas,
    LudoCoordinate coord,
    double cellSize,
    Color color,
    IconData icon,
  ) {
    final cx = coord.col * cellSize + cellSize / 2;
    final cy = coord.row * cellSize + cellSize / 2;

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: cellSize * 0.65,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );
  }

  void _drawSafeStars(Canvas canvas, double cellSize) {
    final starCoords = [
      const LudoCoordinate(2, 6),
      const LudoCoordinate(6, 12),
      const LudoCoordinate(12, 8),
      const LudoCoordinate(8, 2),
    ];

    for (final coord in starCoords) {
      final cx = coord.col * cellSize + cellSize / 2;
      final cy = coord.row * cellSize + cellSize / 2;

      // Draw subtle circular disc behind star
      canvas.drawCircle(
        Offset(cx, cy),
        cellSize * 0.38,
        Paint()..color = const Color(0xFFF1F5F9),
      );

      final icon = Icons.star_rounded;
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: cellSize * 0.55,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: const Color(0xFF94A3B8),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
