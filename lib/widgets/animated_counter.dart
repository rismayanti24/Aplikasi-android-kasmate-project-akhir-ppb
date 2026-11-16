import 'package:flutter/material.dart';
import '../data/kas_store.dart';

/// Widget animasi counter angka nominal rupiah secara mulus (counting up)
class AnimatedCounterRupiah extends StatelessWidget {
  final int targetValue;
  final TextStyle style;
  final String prefix;
  final Duration duration;

  const AnimatedCounterRupiah({
    super.key,
    required this.targetValue,
    required this.style,
    this.prefix = '',
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: targetValue.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          '$prefix${formatRupiah(value.round())}',
          style: style,
        );
      },
    );
  }
}
