import 'dart:math';
import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  final double progress;
  final Color color;
  final double strokeWidth;
  final int? milestoneInterval;
  final int? targetCount;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.strokeWidth = 12.0,
    this.milestoneInterval = 33,
    this.targetCount,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return CustomPaint(
          painter: _RingPainter(
            progress: value,
            color: color,
            strokeWidth: strokeWidth,
            backgroundColor: color.withValues(alpha: 0.1),
            milestoneInterval: milestoneInterval,
            targetCount: targetCount,
          ),
          child: child,
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;
  final int? milestoneInterval;
  final int? targetCount;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
    this.milestoneInterval,
    this.targetCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - strokeWidth / 2;

    // Draw Background Ring
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw glow effect when near completion
    if (progress > 0.8) {
      final glowPaint = Paint()
        ..color = color.withOpacity((progress - 0.8) * 2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final sweepAngle = 2 * pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        glowPaint,
      );
    }

    // Draw Progress Arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Draw milestone markers
    if (milestoneInterval != null && targetCount != null && targetCount! > 0) {
      final milestones = (targetCount! / milestoneInterval!).floor();

      for (int i = 1; i <= milestones; i++) {
        final milestoneProgress = (i * milestoneInterval!) / targetCount!;
        final angle = -pi / 2 + (2 * pi * milestoneProgress);

        final markerX = center.dx + radius * cos(angle);
        final markerY = center.dy + radius * sin(angle);

        final markerPaint = Paint()
          ..color = progress >= milestoneProgress
              ? color
              : color.withOpacity(0.3)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(markerX, markerY),
          strokeWidth / 3,
          markerPaint,
        );

        // Draw white center
        final centerPaint = Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(markerX, markerY),
          strokeWidth / 6,
          centerPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
