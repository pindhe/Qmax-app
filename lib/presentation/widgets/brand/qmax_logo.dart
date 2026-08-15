import 'package:flutter/material.dart';

class QmaxLogo extends StatelessWidget {
  const QmaxLogo({super.key, this.size = 88, this.light = true});
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final orange = Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: light ? Colors.white : orange,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Q',
          style: TextStyle(
            fontSize: size * 0.52,
            fontWeight: FontWeight.w900,
            color: light ? orange : Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}
