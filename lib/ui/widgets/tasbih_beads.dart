import 'dart:math' as math;
import 'package:flutter/material.dart';

class TasbihBeads extends StatelessWidget {
  final int totalBeads;
  final int currentCount;
  final double size;
  final List<Color> colors;

  const TasbihBeads({
    super.key,
    this.totalBeads = 33,
    required this.currentCount,
    this.size = 300,
    this.colors = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TasbihBeadsPainter(
          totalBeads: totalBeads,
          currentCount: currentCount,
          colors: colors,
        ),
      ),
    );
  }
}

class _TasbihBeadsPainter extends CustomPainter {
  final int totalBeads;
  final int currentCount;
  final List<Color> colors;

  _TasbihBeadsPainter({
    required this.totalBeads,
    required this.currentCount,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 24;
    final beadRadius = (radius * 0.15).clamp(6.0, 12.0);
    
    final beadColor = colors.isNotEmpty ? colors[0] : Colors.grey;
    
    // Draw subtle track circle
    final trackPaint = Paint()
      ..color = beadColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = beadRadius * 2;
    canvas.drawCircle(center, radius, trackPaint);
    
    // Draw beads in a circle
    for (int i = 0; i < totalBeads; i++) {
      final angle = (2 * math.pi * i / totalBeads) - (math.pi / 2);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      final isActive = i < (currentCount % (totalBeads + 1));
      final isCurrentBead = i == (currentCount % (totalBeads + 1)) - 1;
      
      if (!isActive) {
        // Inactive: subtle dot
        final inactivePaint = Paint()
          ..color = beadColor.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), beadRadius * 0.6, inactivePaint);
      } else {
        // Active: solid bead
        if (isCurrentBead) {
          // Subtle glow for current
          final glowPaint = Paint()
            ..color = beadColor.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
          canvas.drawCircle(Offset(x, y), beadRadius * 1.4, glowPaint);
        }
        
        final activePaint = Paint()
          ..color = beadColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), beadRadius, activePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TasbihBeadsPainter oldDelegate) {
    return oldDelegate.currentCount != currentCount ||
        oldDelegate.totalBeads != totalBeads;
  }
}

// Animated version
class AnimatedTasbihBeads extends StatefulWidget {
  final int totalBeads;
  final int currentCount;
  final double size;
  final List<Color> colors;

  const AnimatedTasbihBeads({
    super.key,
    this.totalBeads = 33,
    required this.currentCount,
    this.size = 300,
    this.colors = const [],
  });

  @override
  State<AnimatedTasbihBeads> createState() => _AnimatedTasbihBeadsState();
}

class _AnimatedTasbihBeadsState extends State<AnimatedTasbihBeads>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  }

  @override
  void didUpdateWidget(AnimatedTasbihBeads oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentCount != oldWidget.currentCount) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return TasbihBeads(
          totalBeads: widget.totalBeads,
          currentCount: widget.currentCount,
          size: widget.size,
          colors: widget.colors,
        );
      },
    );
  }
}
