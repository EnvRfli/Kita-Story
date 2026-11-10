import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/ludo_board_path.dart';
import '../models/ludo_game_state.dart';
import '../models/ludo_motion.dart';
import '../models/ludo_player.dart';
import '../models/ludo_token.dart';
import 'ludo_token_widget.dart';

class LudoBoardWidget extends StatelessWidget {
  final LudoGameState state;
  final ValueChanged<int>? onTokenSelected;
  final LudoMotion? motion;
  final ValueChanged<String>? onMotionCompleted;
  final VoidCallback? onStep;
  final int rotationQuarterTurns;

  const LudoBoardWidget({
    super.key,
    required this.state,
    this.onTokenSelected,
    this.motion,
    this.onMotionCompleted,
    this.onStep,
    this.rotationQuarterTurns = 0,
  });

  @override
  Widget build(BuildContext context) {
    final board = AspectRatio(
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
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _LudoBoardPainter(
                    rotationQuarterTurns: rotationQuarterTurns,
                  ),
                ),
                ..._buildTokenWidgets(cellSize),
                if (motion != null)
                  _LudoMotionLayer(
                    key: ValueKey(motion!.id),
                    motion: motion!,
                    cellSize: cellSize,
                    onCompleted: () => onMotionCompleted?.call(motion!.id),
                    onStep: onStep,
                  ),
              ],
            );
          },
        ),
      ),
    );

    final turns = rotationQuarterTurns % 4;
    if (turns == 0) return board;
    return RotatedBox(quarterTurns: turns, child: board);
  }

  List<Widget> _buildTokenWidgets(double cellSize) {
    final widgets = <Widget>[];
    final hidden = motion?.hiddenTokenKeys ?? const <String>{};

    final groupedTokens =
        <LudoCoordinate, List<({LudoPlayer player, LudoToken token})>>{};

    for (final player in state.players) {
      for (final token in player.tokens) {
        final key = '${player.color.name}:${token.id}';
        if (hidden.contains(key)) continue;

        final coord = LudoBoardPath.coordinateForToken(
          color: player.color,
          tokenId: token.id,
          isInYard: token.isInYard,
          isOnTrack: token.isOnTrack,
          isInHomeStretch: token.isInHomeStretch,
          isHome: token.isHome,
          step: token.step,
        );

        groupedTokens
            .putIfAbsent(coord, () => [])
            .add((player: player, token: token));
      }
    }

    groupedTokens.forEach((coord, items) {
      // Different colors sharing a cell are split into their own mini token.
      final byColor = <LudoColor, List<({LudoPlayer player, LudoToken token})>>{};
      for (final item in items) {
        byColor.putIfAbsent(item.player.color, () => []).add(item);
      }

      final colorGroups = byColor.entries.toList();
      final offsets = _offsetsForCount(colorGroups.length);
      final tokenSize = _tokenSizeForCount(colorGroups.length, cellSize);

      for (var i = 0; i < colorGroups.length; i++) {
        final group = colorGroups[i].value;
        final color = colorGroups[i].key;
        final offset = offsets[i];

        final movableItem = group.firstWhere(
          (it) =>
              it.player.color == state.currentPlayer.color &&
              state.movableTokenIds.contains(it.token.id),
          orElse: () => group.first,
        );

        final isMovable = state.currentPlayer.color == movableItem.player.color &&
            state.movableTokenIds.contains(movableItem.token.id);

        widgets.add(
          Positioned(
            left: coord.col * cellSize +
                cellSize / 2 -
                tokenSize / 2 +
                offset.dx * cellSize,
            top: coord.row * cellSize +
                cellSize / 2 -
                tokenSize / 2 +
                offset.dy * cellSize,
            child: LudoTokenWidget(
              key: ValueKey(
                group
                    .map((it) => '${it.player.color.name}:${it.token.id}')
                    .join(','),
              ),
              color: color,
              isMovable: isMovable,
              count: group.length,
              size: tokenSize,
              counterRotate: rotationQuarterTurns % 4 == 2,
              onTap: () => onTokenSelected?.call(movableItem.token.id),
            ),
          ),
        );
      }
    });

    return widgets;
  }

  List<Offset> _offsetsForCount(int count) {
    switch (count) {
      case 2:
        return const [Offset(-0.24, 0), Offset(0.24, 0)];
      case 3:
        return const [
          Offset(0, -0.22),
          Offset(-0.22, 0.18),
          Offset(0.22, 0.18),
        ];
      case 4:
      default:
        if (count <= 1) return const [Offset.zero];
        return const [
          Offset(-0.2, -0.2),
          Offset(0.2, -0.2),
          Offset(-0.2, 0.2),
          Offset(0.2, 0.2),
        ];
    }
  }

  double _tokenSizeForCount(int count, double cellSize) {
    if (count <= 1) return cellSize * 0.9;
    if (count == 2) return cellSize * 0.62;
    if (count == 3) return cellSize * 0.54;
    return cellSize * 0.48;
  }
}

class _LudoMotionLayer extends StatefulWidget {
  final LudoMotion motion;
  final double cellSize;
  final VoidCallback onCompleted;
  final VoidCallback? onStep;

  const _LudoMotionLayer({
    super.key,
    required this.motion,
    required this.cellSize,
    required this.onCompleted,
    this.onStep,
  });

  @override
  State<_LudoMotionLayer> createState() => _LudoMotionLayerState();
}

class _LudoMotionLayerState extends State<_LudoMotionLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final int _segments;
  int _lastSegment = 0;

  @override
  void initState() {
    super.initState();
    _segments = math.max(1, widget.motion.path.length - 1);
    final duration = widget.motion.isYardExit
        ? 480
        : widget.motion.stepDurationMs * _segments;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: duration),
    );

    _controller.addListener(_handleTick);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onCompleted();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  void _handleTick() {
    final segment =
        (_controller.value * _segments).floor().clamp(0, _segments);
    if (segment > _lastSegment) {
      _lastSegment = segment;
      widget.onStep?.call();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cellSize = widget.cellSize;
    final tokenSize = cellSize * 0.92;
    final color = widget.motion.color.primaryColor;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final raw = _controller.value * _segments;
          final segment = raw.floor().clamp(0, _segments - 1);
          final t = (raw - segment).clamp(0.0, 1.0);
          final smoothT = Curves.easeInOutCubic.transform(t);
          final from = widget.motion.path[segment];
          final to = widget.motion.path[segment + 1];

          final col = from.col + (to.col - from.col) * smoothT;
          final row = from.row + (to.row - from.row) * smoothT;
          final hop = math.sin(math.pi * smoothT) *
              (widget.motion.isYardExit ? cellSize * 0.82 : cellSize * 0.04);

          final left = col * cellSize + (cellSize - tokenSize) / 2;
          final top = row * cellSize + (cellSize - tokenSize) / 2 - hop;

          final scale = widget.motion.isYardExit
              ? 0.6 + 0.4 * Curves.easeOutCubic.transform(t)
              : 1.0 + math.sin(math.pi * smoothT) * 0.045;

          final isLastSegment = segment >= _segments - 1;
          final burstOpacity = isLastSegment && smoothT > 0.45
              ? ((smoothT - 0.45) / 0.55).clamp(0.0, 1.0)
              : 0.0;

          return Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                child: Transform.rotate(
                  angle: math.sin(math.pi * smoothT) * 0.025,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: tokenSize,
                      height: tokenSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: color,
                          width: tokenSize * 0.17,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.55),
                            blurRadius: 14,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: tokenSize * 0.44,
                          height: tokenSize * 0.44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: widget.motion.color.gradientColors,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (burstOpacity > 0 &&
                  (widget.motion.reachedHome ||
                      widget.motion.capturedTokens.isNotEmpty))
                Positioned(
                  left: to.col * cellSize - cellSize * 0.2,
                  top: to.row * cellSize - cellSize * 0.35,
                  child: Opacity(
                    opacity: burstOpacity,
                    child: Transform.scale(
                      scale: 0.7 + burstOpacity * 0.6,
                      child: Text(
                        widget.motion.capturedTokens.isNotEmpty ? '💥' : '✨',
                        style: TextStyle(fontSize: cellSize * 1.05),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LudoBoardPainter extends CustomPainter {
  final int rotationQuarterTurns;

  _LudoBoardPainter({this.rotationQuarterTurns = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 15.0;

    final borderPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var r = 0; r < 15; r++) {
      for (var c = 0; c < 15; c++) {
        final inRedYard = r < 6 && c < 6;
        final inGreenYard = r < 6 && c >= 9;
        final inBlueYard = r >= 9 && c < 6;
        final inYellowYard = r >= 9 && c >= 9;
        final inCenter = r >= 6 && r <= 8 && c >= 6 && c <= 8;

        if (inRedYard || inGreenYard || inBlueYard || inYellowYard || inCenter) {
          continue;
        }

        final rect =
            Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize);

        Color? fillColor;
        if (r == 7 && c >= 1 && c <= 5) fillColor = LudoColor.red.primaryColor;
        if (c == 7 && r >= 1 && r <= 5) {
          fillColor = LudoColor.green.primaryColor;
        }
        if (c == 7 && r >= 9 && r <= 13) {
          fillColor = LudoColor.blue.primaryColor;
        }
        if (r == 7 && c >= 9 && c <= 13) {
          fillColor = LudoColor.yellow.primaryColor;
        }

        if (fillColor != null) {
          canvas.drawRect(rect, Paint()..color = fillColor);
        } else {
          canvas.drawRect(rect, Paint()..color = Colors.white);
        }

        canvas.drawRect(rect, borderPaint);
      }
    }

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

    _drawCenterHome(canvas, cellSize);
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
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()..color = color,
    );

    final innerPadding = cellSize * 0.8;
    final innerRect = rect.deflate(innerPadding);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(14)),
      Paint()..color = Colors.white,
    );

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

    final redPath = Path()
      ..moveTo(left, top)
      ..lineTo(center.dx, center.dy)
      ..lineTo(left, top + 3 * cellSize)
      ..close();
    canvas.drawPath(redPath, Paint()..color = LudoColor.red.primaryColor);

    final greenPath = Path()
      ..moveTo(left, top)
      ..lineTo(left + 3 * cellSize, top)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(greenPath, Paint()..color = LudoColor.green.primaryColor);

    final yellowPath = Path()
      ..moveTo(left + 3 * cellSize, top)
      ..lineTo(left + 3 * cellSize, top + 3 * cellSize)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(yellowPath, Paint()..color = LudoColor.yellow.primaryColor);

    final bluePath = Path()
      ..moveTo(left, top + 3 * cellSize)
      ..lineTo(center.dx, center.dy)
      ..lineTo(left + 3 * cellSize, top + 3 * cellSize)
      ..close();
    canvas.drawPath(bluePath, Paint()..color = LudoColor.blue.primaryColor);

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

    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );

    if (rotationQuarterTurns % 4 == 2) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(math.pi);
      canvas.translate(-center.dx, -center.dy);
      textPainter.paint(canvas, textOffset);
      canvas.restore();
    } else {
      textPainter.paint(canvas, textOffset);
    }
  }

  void _drawStartArrows(Canvas canvas, double cellSize) {
    _drawArrowIcon(
      canvas,
      const LudoCoordinate(6, 1),
      cellSize,
      LudoColor.red.primaryColor,
      Icons.arrow_forward_rounded,
    );
    _drawArrowIcon(
      canvas,
      const LudoCoordinate(1, 8),
      cellSize,
      LudoColor.green.primaryColor,
      Icons.arrow_downward_rounded,
    );
    _drawArrowIcon(
      canvas,
      const LudoCoordinate(8, 13),
      cellSize,
      LudoColor.yellow.primaryColor,
      Icons.arrow_back_rounded,
    );
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
  bool shouldRepaint(covariant _LudoBoardPainter oldDelegate) {
    return oldDelegate.rotationQuarterTurns != rotationQuarterTurns;
  }
}
