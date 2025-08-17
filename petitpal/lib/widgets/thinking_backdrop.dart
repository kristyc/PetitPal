import 'dart:math' as math;
import 'package:flutter/material.dart';

class ThinkingBackdrop extends StatefulWidget {
  const ThinkingBackdrop({super.key, required this.active});
  final bool active;

  @override
  State<ThinkingBackdrop> createState() => _ThinkingBackdropState();
}

class _ThinkingBackdropState extends State<ThinkingBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 9));
    _t = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(covariant ThinkingBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations || MediaQuery.of(context).accessibleNavigation;

    // Palettes
    const blueA = Color(0xFF0A0F1E);
    const blueB = Color(0xFF0E6BA8);
    const orangeA = Color(0xFF311402);
    const orangeB = Color(0xFFFF6A13); // deep orange

    if (reduceMotion) {
      return IgnorePointer(
        child: Container(color: widget.active ? orangeA : blueA),
      );
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _t,
        builder: (_, __) {
          final t = widget.active ? _t.value : 0.25; // freeze when idle
          Color lerp(Color a, Color b, double m) => Color.lerp(a, b, m)!;
          final a = widget.active ? lerp(orangeA, orangeB, t) : lerp(blueA, blueB, t);
          final b = widget.active ? lerp(orangeB, blueB, (t + .5) % 1) : lerp(blueB, blueA, (t + .5) % 1);
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1 + 2 * t, -0.8),
                end: Alignment(1 - 2 * t, 0.8),
                colors: [a.withOpacity(0.95), b.withOpacity(0.95)],
              ),
            ),
          );
        },
      ),
    );
  }
}
