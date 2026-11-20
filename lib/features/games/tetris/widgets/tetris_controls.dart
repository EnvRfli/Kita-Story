import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TetrisControls extends StatelessWidget {
  const TetrisControls({
    super.key,
    required this.onLeft,
    required this.onRight,
    required this.onRotate,
    required this.onSoftDrop,
    required this.onHardDrop,
    required this.onPause,
    this.enabled = true,
  });

  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onRotate;
  final VoidCallback onSoftDrop;
  final VoidCallback onHardDrop;
  final VoidCallback onPause;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _ControlButton(
                buttonKey: const ValueKey('tetris-control-left'),
                icon: Icons.arrow_back_rounded,
                label: 'Kiri',
                semanticLabel: 'Geser balok ke kiri',
                colors: const [Color(0xFF60A5FA), Color(0xFF2563EB)],
                enabled: enabled,
                onPressed: onLeft,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ControlButton(
                buttonKey: const ValueKey('tetris-control-rotate'),
                icon: Icons.rotate_right_rounded,
                label: 'Putar',
                semanticLabel: 'Putar balok',
                colors: const [Color(0xFFC084FC), Color(0xFF7C3AED)],
                enabled: enabled,
                onPressed: onRotate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ControlButton(
                buttonKey: const ValueKey('tetris-control-right'),
                icon: Icons.arrow_forward_rounded,
                label: 'Kanan',
                semanticLabel: 'Geser balok ke kanan',
                colors: const [Color(0xFF60A5FA), Color(0xFF2563EB)],
                enabled: enabled,
                onPressed: onRight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ControlButton(
                buttonKey: const ValueKey('tetris-control-soft-drop'),
                icon: Icons.keyboard_arrow_down_rounded,
                label: 'Turun',
                semanticLabel: 'Turunkan balok satu langkah',
                colors: const [Color(0xFF5EEAD4), Color(0xFF0D9488)],
                enabled: enabled,
                onPressed: onSoftDrop,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ControlButton(
                buttonKey: const ValueKey('tetris-control-hard-drop'),
                icon: Icons.vertical_align_bottom_rounded,
                label: 'Drop',
                semanticLabel: 'Jatuhkan balok langsung',
                colors: const [Color(0xFFFDBA74), Color(0xFFEA580C)],
                enabled: enabled,
                onPressed: onHardDrop,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ControlButton(
                buttonKey: const ValueKey('tetris-control-pause'),
                icon: Icons.pause_rounded,
                label: 'Jeda',
                semanticLabel: 'Jeda permainan',
                colors: const [Color(0xFF94A3B8), Color(0xFF475569)],
                enabled: enabled,
                repeat: false,
                onPressed: onPause,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ControlButton extends StatefulWidget {
  const _ControlButton({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.colors,
    required this.onPressed,
    this.enabled = true,
    this.repeat = true,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final String semanticLabel;
  final List<Color> colors;
  final VoidCallback onPressed;
  final bool enabled;
  final bool repeat;

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  Timer? _delayTimer;
  Timer? _repeatTimer;
  bool _pressed = false;

  @override
  void dispose() {
    _delayTimer?.cancel();
    _repeatTimer?.cancel();
    super.dispose();
  }

  void _start() {
    if (!widget.enabled) return;
    setState(() => _pressed = true);
    HapticFeedback.selectionClick();
    _fire();
    if (!widget.repeat) return;
    _delayTimer?.cancel();
    _delayTimer = Timer(const Duration(milliseconds: 260), () {
      _repeatTimer?.cancel();
      _repeatTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
        _fire();
      });
    });
  }

  void _stop() {
    if (_pressed) setState(() => _pressed = false);
    _delayTimer?.cancel();
    _repeatTimer?.cancel();
    _delayTimer = null;
    _repeatTimer = null;
  }

  void _fire() {
    if (!widget.enabled) return;
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: widget.enabled
          ? widget.colors
          : const [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
    );

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      onTap: widget.enabled ? widget.onPressed : null,
      child: GestureDetector(
        key: widget.buttonKey,
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _start(),
        onTapUp: (_) => _stop(),
        onTapCancel: _stop,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.enabled
                  ? [
                      BoxShadow(
                        color: widget.colors.last.withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: Colors.white, size: 21),
                const SizedBox(height: 1),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
