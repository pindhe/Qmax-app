import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class QmaxLiquidFooter extends StatefulWidget {
  const QmaxLiquidFooter({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;

  static const circle = 56.0;
  static const barHeight = 62.0;
  static const side = 14.0;

  @override
  State<QmaxLiquidFooter> createState() => _QmaxLiquidFooterState();
}

class _QmaxLiquidFooterState extends State<QmaxLiquidFooter> {
  late double _from;

  @override
  void initState() {
    super.initState();
    _from = widget.currentIndex.toDouble();
  }

  @override
  void didUpdateWidget(QmaxLiquidFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _from = oldWidget.currentIndex.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height: QmaxLiquidFooter.circle / 2 + QmaxLiquidFooter.barHeight + bottom + 10,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(widget.currentIndex),
        tween: Tween(begin: _from, end: widget.currentIndex.toDouble()),
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOutCubic,
        builder: (context, t, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final barWidth = width - QmaxLiquidFooter.side * 2;
              final itemWidth = barWidth / 3;
              final cx = QmaxLiquidFooter.side + itemWidth * (t + 0.5);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: QmaxLiquidFooter.side,
                    right: QmaxLiquidFooter.side,
                    top: QmaxLiquidFooter.circle / 2,
                    bottom: 6 + bottom * 0.25,
                    child: CustomPaint(
                      painter: _LiquidBarPainter(
                        centerX: cx - QmaxLiquidFooter.side,
                        color: const Color(0xFF0B1220),
                      ),
                    ),
                  ),
                  Positioned(
                    left: cx - QmaxLiquidFooter.circle / 2,
                    top: 0,
                    child: _ActiveBubble(
                      icon: _iconFor(t.round().clamp(0, 2), filled: true),
                    ),
                  ),
                  Positioned.fill(
                    top: QmaxLiquidFooter.circle / 2,
                    bottom: bottom * 0.2,
                    child: Row(
                      children: List.generate(3, (i) {
                        final selected = (t - i).abs() < 0.45;
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => widget.onTap(i),
                            child: Opacity(
                              opacity: selected ? 0 : 1,
                              child: Center(
                                child: _InactiveIcon(
                                  icon: _iconFor(i, filled: false),
                                  badge: i == 1 ? widget.cartCount : 0,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(int index, {required bool filled}) {
    return switch (index) {
      0 => filled ? Icons.home_rounded : Icons.home_outlined,
      1 => filled ? Icons.shopping_cart_rounded : Icons.shopping_cart_outlined,
      _ => filled ? Icons.person_rounded : Icons.person_outline,
    };
  }
}

class _ActiveBubble extends StatelessWidget {
  const _ActiveBubble({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: QmaxLiquidFooter.circle,
      height: QmaxLiquidFooter.circle,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF151C2A),
      ),
      child: Center(
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.orange, Color(0xFFFB923C)],
          ).createShader(bounds),
          child: Icon(icon, size: 28, color: Colors.white),
        ),
      ),
    );
  }
}

class _InactiveIcon extends StatelessWidget {
  const _InactiveIcon({required this.icon, required this.badge});
  final IconData icon;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final child = Icon(icon, color: const Color(0xFFE5E7EB), size: 26);
    if (badge <= 0) return child;
    return Badge(label: Text('$badge'), child: child);
  }
}

class _LiquidBarPainter extends CustomPainter {
  _LiquidBarPainter({required this.centerX, required this.color});

  final double centerX;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const corner = 28.0;
    const hole = 30.0;
    const spread = 22.0;
    final cx = centerX.clamp(hole + spread + 8, size.width - hole - spread - 8);

    final path = Path()
      ..moveTo(0, corner)
      ..quadraticBezierTo(0, 0, corner, 0)
      ..lineTo(cx - hole - spread, 0)
      ..cubicTo(
        cx - hole - spread * 0.25,
        0,
        cx - hole,
        hole * 0.12,
        cx - hole * 0.72,
        hole * 0.88,
      )
      ..cubicTo(
        cx - hole * 0.28,
        hole * 1.38,
        cx + hole * 0.28,
        hole * 1.38,
        cx + hole * 0.72,
        hole * 0.88,
      )
      ..cubicTo(
        cx + hole,
        hole * 0.12,
        cx + hole + spread * 0.25,
        0,
        cx + hole + spread,
        0,
      )
      ..lineTo(size.width - corner, 0)
      ..quadraticBezierTo(size.width, 0, size.width, corner)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidBarPainter oldDelegate) =>
      oldDelegate.centerX != centerX || oldDelegate.color != color;
}
