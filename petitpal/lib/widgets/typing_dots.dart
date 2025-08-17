import 'package:flutter/material.dart';

class TypingDots extends StatefulWidget {
  const TypingDots({super.key, this.size = 10, this.color});
  final double size;
  final Color? color;
  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.onSurface;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        double p(int i) => ( (_c.value + i/3) % 1 );
        double s(int i) => 0.5 + 0.5 * (1 - ((p(i) - 0.5).abs() * 2)); // 0.5..1
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: widget.size, height: widget.size,
              decoration: BoxDecoration(
                color: color.withOpacity(s(i)),
                shape: BoxShape.circle,
              ),
            ),
          )),
        );
      },
    );
  }
}
