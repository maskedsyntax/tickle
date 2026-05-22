import 'dart:async';
import 'package:flutter/material.dart';
import 'bounce_tap.dart';
import '../utils/haptic_feedback.dart';

class RapidCountButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final void Function(int delta) onCommit;
  final void Function(int delta)? onTick;
  final String hapticLevel;
  final bool isDecrement;

  const RapidCountButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.onCommit,
    this.onTick,
    required this.hapticLevel,
    this.isDecrement = false,
  });

  @override
  State<RapidCountButton> createState() => _RapidCountButtonState();
}

class _RapidCountButtonState extends State<RapidCountButton> {
  Timer? _timer;
  int _pendingDelta = 0;
  int _tickCount = 0;

  void _startTimer() {
    _pendingDelta = 0;
    _tickCount = 0;
    
    // Provide initial haptic feedback to signal long press started
    HapticsHelper.selectionClick(widget.hapticLevel);

    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      _tickCount++;
      
      // Speed up as we hold it longer
      int step = 1;
      if (_tickCount > 30) step = 10;
      else if (_tickCount > 15) step = 5;
      else if (_tickCount > 8) step = 2;
      
      setState(() {
        _pendingDelta += step;
      });
      
      widget.onTick?.call(_pendingDelta);
      HapticsHelper.trigger(widget.hapticLevel);
    });
  }

  void _stopTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      _timer = null;
      if (_pendingDelta > 0) {
        widget.onCommit(_pendingDelta);
      }
      setState(() {
        _pendingDelta = 0;
        _tickCount = 0;
      });
      widget.onTick?.call(0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BounceTap(
      onTap: widget.onTap,
      onLongPressStart: (_) => _startTimer(),
      onLongPressEnd: (_) => _stopTimer(),
      child: widget.child,
    );
  }
}
