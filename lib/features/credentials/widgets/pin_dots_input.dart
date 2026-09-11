import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinDotsInput extends StatefulWidget {
  final TextEditingController controller;
  final int length;
  final FocusNode? focusNode;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final bool autoFocus;
  final Duration revealDuration;

  const PinDotsInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.focusNode,
    this.onCompleted,
    this.onChanged,
    this.autoFocus = true,
    this.revealDuration = const Duration(milliseconds: 650),
  });

  @override
  State<PinDotsInput> createState() => _PinDotsInputState();
}

class _PinDotsInputState extends State<PinDotsInput> {
  late FocusNode _effectiveFocusNode;
  int? _revealedIndex;
  Timer? _maskTimer;
  int _prevLength = 0;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode = widget.focusNode ?? FocusNode();
    _prevLength = widget.controller.text.length;
    widget.controller.addListener(_onTextChanged);

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_effectiveFocusNode.hasFocus) {
          _effectiveFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant PinDotsInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
      _prevLength = widget.controller.text.length;
    }
  }

  @override
  void dispose() {
    _maskTimer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    if (widget.focusNode == null) {
      _effectiveFocusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final currentLength = text.length;

    if (currentLength > _prevLength) {
      // User typed a new digit -> reveal it briefly
      final newIndex = currentLength - 1;
      _maskTimer?.cancel();
      setState(() {
        _revealedIndex = newIndex;
      });

      _maskTimer = Timer(widget.revealDuration, () {
        if (mounted) {
          setState(() {
            _revealedIndex = null;
          });
        }
      });
    } else {
      // Backspace or clear
      _maskTimer?.cancel();
      setState(() {
        _revealedIndex = null;
      });
    }

    _prevLength = currentLength;
    widget.onChanged?.call(text);

    if (currentLength == widget.length) {
      widget.onCompleted?.call(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!_effectiveFocusNode.hasFocus) {
          _effectiveFocusNode.requestFocus();
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Invisible Strictly-Numeric TextField
          Opacity(
            opacity: 0.0,
            child: SizedBox(
              width: 1,
              height: 1,
              child: TextField(
                controller: widget.controller,
                focusNode: _effectiveFocusNode,
                keyboardType: TextInputType.number,
                autofocus: widget.autoFocus,
                enableSuggestions: false,
                autocorrect: false,
                showCursor: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
              ),
            ),
          ),

          // 2. Visible Centered 6-Dot Indicators
          AnimatedBuilder(
            animation: Listenable.merge([widget.controller, _effectiveFocusNode]),
            builder: (context, _) {
              final text = widget.controller.text;
              final isFocused = _effectiveFocusNode.hasFocus;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.length, (index) {
                  final bool isFilled = index < text.length;
                  final bool isCurrentActive = isFocused && index == text.length;
                  final bool isRevealed = isFilled && index == _revealedIndex;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 44,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isCurrentActive
                          ? Colors.white
                          : (isFilled
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrentActive
                            ? const Color(0xFF0088FF)
                            : (isFilled
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFFE2E8F0)),
                        width: isCurrentActive ? 2.0 : 1.3,
                      ),
                      boxShadow: isCurrentActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0088FF)
                                    .withValues(alpha: 0.18),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) {
                          return ScaleTransition(
                            scale: anim,
                            child: child,
                          );
                        },
                        child: isRevealed
                            ? Text(
                                text[index],
                                key: ValueKey('revealed_$index'),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: -0.5,
                                ),
                              )
                            : (isFilled
                                ? Container(
                                    key: ValueKey('dot_$index'),
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF1E293B),
                                    ),
                                  )
                                : Container(
                                    key: ValueKey('empty_$index'),
                                    width: 7.5,
                                    height: 7.5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCurrentActive
                                          ? const Color(0xFF0088FF)
                                              .withValues(alpha: 0.5)
                                          : const Color(0xFFCBD5E1),
                                    ),
                                  )),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
