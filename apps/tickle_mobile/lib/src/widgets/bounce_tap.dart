import 'package:flutter/material.dart';

class BounceTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressEndCallback? onLongPressEnd;
  final double scaleFactor;
  final Duration duration;

  const BounceTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.scaleFactor = 0.93,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<BounceTap> createState() => _BounceTapState();
}

class _BounceTapState extends State<BounceTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _hasGestures() {
    return widget.onTap != null ||
        widget.onLongPress != null ||
        widget.onLongPressStart != null ||
        widget.onLongPressEnd != null;
  }

  void _onTapDown(TapDownDetails details) {
    if (_hasGestures()) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_hasGestures()) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (_hasGestures()) {
      _controller.reverse();
    }
  }
  
  void _onLongPressStart(LongPressStartDetails details) {
    if (_hasGestures()) {
      _controller.forward();
    }
    widget.onLongPressStart?.call(details);
  }
  
  void _onLongPressEnd(LongPressEndDetails details) {
    if (_hasGestures()) {
      _controller.reverse();
    }
    widget.onLongPressEnd?.call(details);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onLongPressStart: widget.onLongPressStart != null ? _onLongPressStart : null,
      onLongPressEnd: widget.onLongPressEnd != null ? _onLongPressEnd : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
