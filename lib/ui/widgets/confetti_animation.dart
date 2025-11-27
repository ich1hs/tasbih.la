import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiAnimation extends StatefulWidget {
  final VoidCallback? onComplete;

  const ConfettiAnimation({super.key, this.onComplete});

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Generate particles
    for (int i = 0; i < 50; i++) {
      _particles.add(
        ConfettiParticle(
          color: _getRandomColor(),
          initialX: _random.nextDouble(),
          initialY: _random.nextDouble() * 0.3,
          speedX: (_random.nextDouble() - 0.5) * 2,
          speedY: _random.nextDouble() * 2 + 1,
          rotation: _random.nextDouble() * pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 4,
          size: _random.nextDouble() * 8 + 4,
        ),
      );
    }

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  Color _getRandomColor() {
    final colors = [
      const Color(0xFF00BCD4), // Teal
      const Color(0xFF64FFDA), // Bright Teal
      const Color(0xFFFFD700), // Gold
      const Color(0xFFFF6B6B), // Red
      const Color(0xFF4ECDC4), // Turquoise
      const Color(0xFFFFA07A), // Light Salmon
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class ConfettiParticle {
  final Color color;
  final double initialX;
  final double initialY;
  final double speedX;
  final double speedY;
  final double rotation;
  final double rotationSpeed;
  final double size;

  ConfettiParticle({
    required this.color,
    required this.initialX,
    required this.initialY,
    required this.speedX,
    required this.speedY,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final x =
          particle.initialX * size.width +
          particle.speedX * progress * size.width * 0.3;
      final y =
          particle.initialY * size.height +
          particle.speedY * progress * size.height;

      // Apply gravity effect
      final gravity = progress * progress * 100;
      final finalY = y + gravity;

      // Fade out at the end
      final opacity = progress < 0.8 ? 1.0 : (1.0 - (progress - 0.8) / 0.2);

      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, finalY);
      canvas.rotate(
        particle.rotation + particle.rotationSpeed * progress * 2 * pi,
      );

      // Draw square confetti
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
